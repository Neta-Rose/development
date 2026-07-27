"""Stage 4 — LLM enrichment via OpenRouter (async, resumable, idempotent).

Three independent passes share everything below: :class:`Enricher` (naming,
emoji, prep_type, variable_fat), :class:`CommonnessEnricher` (one number: how
commonly the food is eaten) and :class:`KeywordsEnricher` (search terms). Each
has its own instruction block, output schema and candidate queue; only the
question differs.

Design:

* One food item per request. The fdc_id is never shown to the model — the
  request carries exactly one food, so nothing needs addressing and there is
  no long number to mangle.
* Throughput comes from ``config.CONCURRENCY`` in-flight requests, not from
  packing items together. Requests are spaced to
  ``config.REQUESTS_PER_MINUTE`` by a shared pacer (0 = no pacing, the right
  setting on a paid model, where the meter is tokens and not requests), and
  429/5xx/timeouts back off via tenacity — honouring Retry-After when the
  server sends it, and slowing every in-flight request, since the limit is
  per-account. Retries live in tenacity alone; the SDK's own retry layer is
  disabled, because nesting the two multiplies out to 18 full-prompt requests
  for one bad row and is invisible to the pacer.
* Structured output is enforced with ``response_format`` (json_schema,
  strict). If the model rejects that, the run transparently falls back to a
  forced tool call carrying the same schema. Everything is re-validated
  with pydantic; malformed rows get one retry, then are routed to
  needs_review.
* The static instruction block is a single module constant, byte-identical
  across calls. At ~985 tokens it is ~96% of the input of a whole run, so on a
  paid model prompt caching is the only cost lever that matters — nothing else
  in the request is big enough to be worth optimizing. Keeping the block
  byte-identical is what makes a cache hit possible; ``cached_tokens`` in the
  stats is what proves it happened. Caches are per-provider, so
  ``config.PROVIDER_ORDER`` pins routing once the sample shows which provider
  caches, and the run sends one request alone before fanning out so the cache
  is written once instead of by N concurrent cold misses.
* A run does not sit on the DuckDB file lock while it waits on the network.
  The candidate rows are read, the database is detached for the whole request
  phase, and completed rows are buffered and written back in batches of
  ``config.FLUSH_EVERY`` — each flush re-attaches, writes in one transaction,
  and detaches again. The lock is therefore held for a moment per few hundred
  rows instead of for the hours a full run takes, which leaves the database
  openable by a DuckDB shell (or a hand-edit) while enrichment runs.
  Detaching also checkpoints, so a flushed batch is durable in the main file
  rather than sitting in a WAL a killed kernel would never replay: a crash or
  Ctrl-C loses at most the rows since the last flush. Re-runs skip
  already-enriched rows and NEVER touch human-verified rows (enforced again in
  store).
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import time
from dataclasses import dataclass, field

import duckdb
from openai import (
    APIConnectionError,
    APIStatusError,
    APITimeoutError,
    AsyncOpenAI,
    BadRequestError,
)
from pydantic import ValidationError
from tenacity import (
    retry,
    retry_if_exception,
    stop_after_attempt,
    wait_exponential,
)

from . import config, schema, store

log = logging.getLogger("fdc_enrich.enrich")

# ---------------------------------------------------------------------------
# The static instruction block. Do not interpolate per-request facts into it —
# per-row facts belong in build_item. The prep_type enum is deliberately NOT
# restated: response_format (and the tool fallback) already carry it, and
# store.cross_check catches strays.
# ---------------------------------------------------------------------------
STATIC_INSTRUCTIONS = """You name USDA FoodData Central items for a grocery-style catalog. The input is one item as a JSON object; return JSON matching the schema.

Input keys (optional ones are omitted when absent): desc = USDA description, authoritative; cat = USDA food category; aka = USDA "Common Name" synonyms; also = USDA "Additional Description".

display_name: what a shopper would call this on a label — 2 to 5 words, natural word order, at most one comma. Rewrite desc as a phrase; never copy it back as a comma list. Drop bureaucratic filler ("ready-to-heat", "as packaged", "year round average", "not further specified", "in processing"). Keep only qualifiers that distinguish this item from its siblings (fat level, salted/unsalted, skin/boneless, sweetened/unsweetened). Never add an attribute that is not in the input. Use aka/also only to word what desc already says more clearly — never to introduce a different food. When desc carries a brand name, name the generic food, not the brand.

Whatever you put in prep_type must NOT also appear in display_name — the two fields are stored separately and joined later, so repeating it duplicates it. If you set prep_type "frozen", the word "frozen" (and "frozen as packaged", "ready-to-heat") is gone from display_name.

emoji: exactly one emoji character, the app's list icon for this food. Pick the closest food emoji — the ingredient itself when there is one (🥕 for carrots), otherwise the dish or its dominant component (🍲 for a stew, 🥪 for a sandwich). Never a word, never two emoji, never an ASCII face. When nothing fits, 🍽️.

prep_type: only when the preparation is stated or unambiguously implied in desc. Never infer it from the food type — chicken is not "cooked" just because chicken is usually cooked. In doubt, null.

variable_fat: true only for families sold at several fat levels (ground meat by lean %, milk and dairy by milkfat %, meat cuts by fat grade). False for everything outside meat and dairy however fatty — "avocado, raw" is false.

confidence: 0..1 in the whole output — display_name, emoji, prep_type and variable_fat together. Your least certain field sets it, not the average: a good name with a doubtful emoji is a low-confidence row. 0.80 or above publishes with no human check; below it goes to a reviewer. Be honest — composite dishes, "not specified"/"not further specified" items, brand-contaminated descriptions and anything you had to give 🍽️ belong below 0.80.

Examples (one item shown per line):

{"desc":"Beef, ground, 80% lean meat / 20% fat, raw","cat":"Beef Products"} -> {"display_name":"Ground beef (80% lean)","emoji":"🥩","prep_type":"raw","variable_fat":true,"confidence":0.97}
{"desc":"Milk, not further specified","cat":"Milk, whole"} -> {"display_name":"Milk","emoji":"🥛","prep_type":null,"variable_fat":true,"confidence":0.72}
{"desc":"Frankfurter, beef, low fat","cat":"Sausages and Luncheon Meats","aka":"hot dog, wiener, frank"} -> {"display_name":"Beef hot dog, low fat","emoji":"🌭","prep_type":null,"variable_fat":true,"confidence":0.93}
{"desc":"Candies, NESTLE, BUTTERFINGER Bar","cat":"Sweets"} -> {"display_name":"Candy bar","emoji":"🍫","prep_type":null,"variable_fat":false,"confidence":0.55}
{"desc":"Tomatoes, red, ripe, year round average","cat":"Vegetables and Vegetable Products"} -> {"display_name":"Tomatoes","emoji":"🍅","prep_type":null,"variable_fat":false,"confidence":0.96}
{"desc":"Waffles, buttermilk, frozen, ready-to-heat","cat":"Baked Products"} -> {"display_name":"Buttermilk waffles","emoji":"🧇","prep_type":"frozen","variable_fat":false,"confidence":0.94}
{"desc":"Sweet potatoes, french fried, frozen as packaged, salt added in processing","cat":"Vegetables and Vegetable Products"} -> {"display_name":"Sweet potato fries, salted","emoji":"🍠","prep_type":"frozen","variable_fat":false,"confidence":0.93}"""

# The Stage 4b instruction block — same rules as above (byte-identical across
# calls, no per-row facts). Kept short on purpose: this pass returns one
# number, so instructions and output format are nearly the whole bill.
COMMONNESS_INSTRUCTIONS = """Rate how commonly a food is eaten and how likely it is to be sitting in an ordinary home kitchen. Input is one USDA FoodData Central item as JSON (desc = description, cat = category, aka/also = synonyms). Reply {"c":<0..1>}, interpolating freely.

1.0 staple, in nearly every kitchen, eaten most days: eggs, milk, butter, rice, bread, onions
0.7 common, in most kitchens, not daily: yogurt, olive oil, canned tuna, frozen peas, bacon
0.4 familiar, bought for a purpose or a dish: parmesan, maple syrup, quinoa, sour cream
0.2 niche, one cuisine or a specialty aisle: tahini, duck breast, plantain, buckwheat groats
0.05 rare, exotic or institutional: turtle meat, emu, agar, whale, commodity bulk items

Rate the whole item, not just its base food: an ordinary food in an unusual form (dried egg powder, dehydrated milk) is far less common than the food itself. Ignore brand names."""

# The Stage 4c instruction block — same rules again (byte-identical, no per-row
# facts). Longer than the commonness one because the failure mode here is a
# keyword that pulls up the wrong food, and that has to be spelled out.
KEYWORDS_INSTRUCTIONS = """Generate search keywords for a food, so a shopper who types anything reasonable finds it. Input is one USDA FoodData Central item as JSON (desc = description, authoritative; cat = category; aka/also = synonyms). Reply {"k":[...]} — 6 to 12 terms, lowercase, most useful first.

Cover whichever of these apply:
* other names for the same food, including regional and non-English ones people actually type: aubergine, cilantro, garbanzo, soda, courgette
* for a dish or a composite product, its core ingredients — for pasta alfredo: fettuccine, parmesan, cream, butter
* cuisine or origin (italian, mexican, thai, cajun) and the meal or occasion it belongs to (breakfast, dessert, snack, cookout)
* the broader food it is one of (pasta, citrus, shellfish, leafy greens) and the form it is bought or served in (fillet, ground, wedge, dip)
* the everyday word for a bureaucratic description: frankfurter -> hot dog

Rules. Single words or short phrases, no punctuation. Skip any word already in desc — that text is searched directly, so repeating it buys nothing. No brand names, no nutrition claims, no USDA vocabulary. Never a term that would also pull up a different food ("cheese" for a cheesecake, "chicken" for chicken-flavored broth) — matching is loose, so one wrong keyword costs more than three missing ones. When in doubt return fewer.

Examples (one item shown per line):

{"desc":"Pasta with alfredo sauce, restaurant","cat":"Pasta mixed dishes"} -> {"k":["fettuccine","noodles","parmesan","cream","butter","italian","dinner"]}
{"desc":"Frankfurter, beef","cat":"Sausages and Luncheon Meats"} -> {"k":["hot dog","wiener","sausage","bun","cookout","barbecue","ballpark"]}
{"desc":"Chickpeas (garbanzo beans, bengal gram), mature seeds, canned","cat":"Legumes and Legume Products"} -> {"k":["hummus","falafel","legume","pulses","curry","middle eastern","indian","salad"]}
{"desc":"Tomatoes, red, ripe, raw","cat":"Vegetables and Vegetable Products"} -> {"k":["salad","sandwich","salsa","caprese","marinara","italian","garden"]}"""


@dataclass
class EnrichmentStats:
    requested: int = 0
    succeeded: int = 0
    auto_approved: int = 0
    needs_review: int = 0
    failed: int = 0
    skipped_locked: int = 0
    prompt_tokens: int = 0
    completion_tokens: int = 0
    # of prompt_tokens, how many were served from the provider's prompt cache
    cached_tokens: int = 0
    # of completion_tokens, how many were reasoning. Must stay 0: a reasoning
    # model that ignores reasoning={"enabled": False} costs ~10x in output.
    reasoning_tokens: int = 0
    # what OpenRouter says it actually charged (post cache discount), summed
    actual_cost_usd: float = 0.0
    elapsed_s: float = 0.0
    errors: list[str] = field(default_factory=list)

    @property
    def cache_hit_rate(self) -> float:
        return self.cached_tokens / self.prompt_tokens if self.prompt_tokens else 0.0

    @property
    def est_cost_usd(self) -> float:
        """Real cost when OpenRouter reported one, else the price constants.

        The constants are hand-maintained and describe whatever MODEL was set
        when someone last edited config; usage.cost is authoritative and
        already reflects any cache discount, so it wins whenever present.
        """
        if self.actual_cost_usd:
            return self.actual_cost_usd
        return (
            self.prompt_tokens / 1e6 * config.PROMPT_PRICE_PER_M
            + self.completion_tokens / 1e6 * config.COMPLETION_PRICE_PER_M
        )

    def estimate_full_run(self, remaining_rows: int) -> dict:
        """Extrapolate the sample to the remaining corpus."""
        if not self.succeeded:
            return {}
        per_row_cost = self.est_cost_usd / self.succeeded
        per_row_s = self.elapsed_s / self.succeeded
        return {
            "remaining_rows": remaining_rows,
            "est_cost_usd": round(per_row_cost * remaining_rows, 4),
            "est_wall_clock_min": round(per_row_s * remaining_rows / 60, 1),
        }


class _SchemaUnsupported(Exception):
    """The model rejected response_format json_schema; fall back to tools."""


def _is_retryable(exc: BaseException) -> bool:
    if isinstance(exc, (APIConnectionError, APITimeoutError)):
        return True
    if isinstance(exc, APIStatusError):
        return exc.status_code == 429 or exc.status_code >= 500
    return False


_WAIT_EXPONENTIAL = wait_exponential(multiplier=1, min=2, max=60)


def _retry_after_seconds(exc: BaseException) -> float | None:
    """Retry-After from a rate-limit response, when the server sent a usable one."""
    response = getattr(exc, "response", None)
    headers = getattr(response, "headers", None)
    raw = headers.get("retry-after") if headers else None
    if raw is None:
        return None
    try:
        return max(0.0, float(raw))
    except (TypeError, ValueError):
        return None  # HTTP-date form is legal but rare here; exponential covers it


def _wait_rate_limited(retry_state) -> float:
    """Honour Retry-After when offered, else fall back to exponential.

    On a 429 this also pushes the shared pacer forward: the free-tier limit is
    per-account, so one rejection means every other in-flight request should
    slow down too, not just this one.
    """
    exc = retry_state.outcome.exception() if retry_state.outcome else None
    delay = _retry_after_seconds(exc) if exc is not None else None
    if delay is None:
        delay = _WAIT_EXPONENTIAL(retry_state)
    if isinstance(exc, APIStatusError) and exc.status_code == 429 and retry_state.args:
        retry_state.args[0].pacer.backoff(delay)  # args[0] is the Enricher
    return delay


def _log_retry(retry_state) -> None:
    """before_sleep hook: one line per 429/5xx/timeout before it backs off."""
    exc = retry_state.outcome.exception()
    wait = getattr(retry_state.next_action, "sleep", 0.0)
    status = getattr(exc, "status_code", None)
    kind = "rate limit (429)" if status == 429 else (
        f"error {status}" if status else type(exc).__name__
    )
    log.warning(
        "OpenRouter %s on attempt %d/%d; retrying in %.1fs",
        kind, retry_state.attempt_number, config.MAX_RETRIES, wait,
    )


def make_client() -> AsyncOpenAI:
    api_key = os.environ.get(config.OPENROUTER_API_KEY_ENV)
    if not api_key:
        raise RuntimeError(
            f"{config.OPENROUTER_API_KEY_ENV} is not set. Copy .env.example to .env "
            "and add your OpenRouter key (loaded via python-dotenv)."
        )
    return AsyncOpenAI(
        base_url=config.OPENROUTER_BASE_URL,
        api_key=api_key,
        timeout=config.REQUEST_TIMEOUT_S,
        # tenacity owns retries. The SDK's default of 2 nests *inside* every
        # tenacity attempt (up to 18 full-prompt requests for one row, each
        # billed) and never reaches pacer.backoff, so the pacer can't see it.
        max_retries=0,
        default_headers={
            # optional OpenRouter attribution headers
            "HTTP-Referer": "https://github.com/jd252387/projects",
            "X-Title": "fdc-enrich",
        },
    )


def build_item(row: dict) -> dict:
    """Per-item fields, keyed to the legend in STATIC_INSTRUCTIONS.

    Optional keys are omitted when absent so the common row stays cheap;
    insertion order is fixed, so the serialization is deterministic without
    sorting (and puts desc first, where it matters most).
    """
    payload: dict = {
        "desc": row["description"],
        "cat": row["food_category"]
    }
    if row["common_name"]:
        payload["aka"] = row["common_name"]
    if row["extra_desc"]:
        payload["also"] = row["extra_desc"]
    # fat_percentage and brand_flagged are deliberately NOT sent: both are
    # already visible in desc, and both drive deterministic pipeline decisions
    # (_persist forces variable_fat; route_confidence forces review) that the
    # model must not second-guess or anchor on. data_type is not sent either:
    # it says where a row came from, not what the food is, and the model
    # cannot act on provenance it has no way to verify.
    return payload


class _Pacer:
    """Spaces requests to an account-wide rate. Shared by every coroutine.

    OpenRouter's free tier meters the whole account, so a 429 anyone receives
    is information about everyone: backoff() pushes the shared clock forward
    rather than letting each coroutine rediscover the limit on its own.
    """

    def __init__(self, rpm: float):
        self.interval = 60.0 / rpm if rpm else 0.0
        self.lock = asyncio.Lock()
        self.next = 0.0

    async def wait(self) -> None:
        if not self.interval:
            return
        async with self.lock:
            now = time.monotonic()
            delay = max(0.0, self.next - now)
            self.next = max(now, self.next) + self.interval
        if delay:
            # deliberately outside the lock — holding it across the sleep
            # would serialize the run instead of merely pacing it
            await asyncio.sleep(delay)

    def backoff(self, seconds: float) -> None:
        self.next = max(self.next, time.monotonic() + seconds)


class Enricher:
    # What this pass asks the model for. A subclass swaps these five to run a
    # different enrichment over the same request/retry/pacing/flush machinery;
    # everything below is pass-agnostic.
    instructions = STATIC_INSTRUCTIONS
    candidate_where = store.ENRICHMENT_PENDING
    result_model = schema.EnrichmentResult
    response_format = schema.RESPONSE_FORMAT
    tool = schema.ENRICHMENT_TOOL
    # A row whose output never validated is routed to the human review queue.
    routes_failures_to_review = True

    def __init__(
        self,
        con: duckdb.DuckDBPyConnection,
        model: str = config.MODEL,
        concurrency: int = config.CONCURRENCY,
        rpm: float = config.REQUESTS_PER_MINUTE,
        instructions: str | None = None,
        reasoning: dict | None = None,
    ):
        self.con = con
        self.db_path = store.attached_path(con)
        # completed rows waiting for the next batched write; see _flush
        self._pending: list[tuple[str, dict]] = []
        self.model = model
        if instructions is not None:
            self.instructions = instructions
        # OpenRouter unified reasoning config, e.g. {"effort": "high"} or
        # {"max_tokens": 512}; default disables it (previous hardcoded behaviour)
        self.reasoning = reasoning if reasoning is not None else {"enabled": False}
        self.semaphore = asyncio.Semaphore(concurrency)
        self.pacer = _Pacer(rpm)
        self.client = make_client()
        # flips to True for the whole run the first time the model rejects
        # response_format json_schema
        self.use_tools = False
        self.stats = EnrichmentStats()

    @retry(
        retry=retry_if_exception(_is_retryable),
        wait=_wait_rate_limited,
        stop=stop_after_attempt(config.MAX_RETRIES),
        before_sleep=_log_retry,
        reraise=True,
    )
    async def _request(self, payload: str) -> str:
        extra_body: dict = {
            "reasoning": self.reasoning,
            # makes OpenRouter return usage.cost / cache_discount / cached
            # token counts, so cost is measured rather than guessed
            "usage": {"include": True},
        }
        if config.PROVIDER_ORDER:
            # caches are per-provider; free routing means mostly cache misses
            extra_body["provider"] = {
                "order": list(config.PROVIDER_ORDER),
                "allow_fallbacks": False,
            }
        kwargs: dict = {
            "model": self.model,
            "temperature": 0,
            "messages": [
                {"role": "system", "content": self.instructions},
                {"role": "user", "content": payload},
            ],
            "extra_body": extra_body,
        }
        if self.use_tools:
            kwargs["tools"] = [self.tool]
            kwargs["tool_choice"] = {
                "type": "function",
                "function": {"name": self.tool["function"]["name"]},
            }
        else:
            kwargs["response_format"] = self.response_format
        # inside the retry, so re-attempts are paced too
        await self.pacer.wait()
        try:
            resp = await self.client.chat.completions.create(**kwargs)
        except BadRequestError as exc:
            msg = str(exc).lower()
            if not self.use_tools and any(
                s in msg for s in ("response_format", "json_schema", "structured")
            ):
                raise _SchemaUnsupported() from exc
            raise
        if resp.usage:
            self._record_usage(resp.usage)
        message = resp.choices[0].message
        if message.tool_calls:
            return message.tool_calls[0].function.arguments
        return message.content or ""

    def _record_usage(self, usage) -> None:
        """Fold one response's usage into the stats.

        Every field past prompt/completion tokens is optional and provider
        dependent — OpenRouter omits the details objects entirely on providers
        that don't report them — so nothing here may raise on a missing key.
        """
        self.stats.prompt_tokens += usage.prompt_tokens or 0
        self.stats.completion_tokens += usage.completion_tokens or 0
        self.stats.actual_cost_usd += getattr(usage, "cost", None) or 0.0
        prompt_details = getattr(usage, "prompt_tokens_details", None)
        self.stats.cached_tokens += getattr(prompt_details, "cached_tokens", None) or 0
        completion_details = getattr(usage, "completion_tokens_details", None)
        self.stats.reasoning_tokens += (
            getattr(completion_details, "reasoning_tokens", None) or 0
        )

    async def _request_with_fallback(self, payload: str) -> str:
        try:
            return await self._request(payload)
        except _SchemaUnsupported:
            # model lacks structured outputs -> tool-calling for the rest
            self.use_tools = True
            return await self._request(payload)

    def _persist(self, row: dict, result: schema.EnrichmentResult) -> None:
        """Apply the deterministic post-rules and queue the row for _flush.

        Nothing here touches DuckDB — the rules are pure, and the write is
        buffered so the request phase can run with the file lock released.
        """
        # deterministic post-rules override the LLM where the pipeline has
        # stronger evidence
        variable_fat = result.variable_fat
        notes = ""  # pipeline provenance only; the model no longer writes notes
        fat_pct = row["fat_percentage"]
        if fat_pct is not None and not variable_fat:
            variable_fat = True  # auto-true whenever fat_percentage is non-null
            notes = (notes + " | " if notes else "") + "variable_fat forced true (fat_percentage present)"
        if (
            variable_fat
            and fat_pct is None
            and not config.is_meat_dairy_category(row["food_category"])
        ):
            variable_fat = False  # category gate
            notes = (notes + " | " if notes else "") + "variable_fat forced false (category gate)"

        issues = store.cross_check(
            prep_type=result.prep_type,
            variable_fat=variable_fat,
            fat_percentage=fat_pct,
            description=row["description"],
            food_category=row["food_category"],
            emoji=result.emoji,
        )
        review_status = store.route_confidence(
            result.confidence,
            brand_flagged=bool(row["brand_flagged"]),
            validation_failed=bool(issues),
        )
        if issues:
            notes = (notes + " | " if notes else "") + "; ".join(issues)

        self._pending.append(("write", dict(
            fdc_id=row["fdc_id"],
            display_name=result.display_name,
            emoji=result.emoji,
            prep_type=result.prep_type,
            variable_fat=variable_fat,
            confidence=result.confidence,
            review_status=review_status,
            notes=notes,
            source_version=row["source_version"],
            model=self.model,
            reasoning=json.dumps(self.reasoning, separators=(",", ":")),
        )))

    def _write(self, payload: dict) -> bool:
        """Persist one completed row. False = refused (human-verified lock)."""
        return store.apply_enrichment(self.con, **payload)

    def _fail(self, row: dict, error: str) -> None:
        self.stats.failed += 1
        self.stats.errors.append(f"fdc_id={row['fdc_id']}: {error}")
        if self.routes_failures_to_review:
            self._pending.append(("fail", {"fdc_id": row["fdc_id"], "error": error}))

    def _flush(self) -> None:
        """Write everything buffered since the last flush.

        The only place a run touches DuckDB: it takes the file lock, writes the
        batch in one transaction and gives the lock straight back (which
        checkpoints, so the batch lands in the main file). The success counters
        are incremented here rather than in _persist because "written" is not
        decided until store re-checks the human-verified lock.
        """
        if not self._pending:
            return
        pending, self._pending = self._pending, []
        with store.locked(self.con, self.db_path):
            self.con.begin()
            try:
                for kind, payload in pending:
                    if kind == "fail":
                        store.mark_validation_failed(self.con, **payload)
                    elif not self._write(payload):
                        self.stats.skipped_locked += 1
                    else:
                        self.stats.succeeded += 1
                        # a pass without review routing (commonness) leaves both
                        # counters at 0 rather than inventing a status for them
                        status = payload.get("review_status")
                        if status == "auto_approved":
                            self.stats.auto_approved += 1
                        elif status:
                            self.stats.needs_review += 1
                self.con.commit()
            except Exception:
                self.con.rollback()
                raise

    async def _fetch(self, row: dict):
        async with self.semaphore:
            # compact separators: matches the few-shot examples byte-for-byte
            # and saves a token per key over json.dumps' default ", " / ": "
            raw = await self._request_with_fallback(
                json.dumps(build_item(row), ensure_ascii=False, separators=(",", ":"))
            )
        return self.result_model.model_validate(json.loads(raw))

    async def enrich_row(self, row: dict) -> None:
        """One request for one row; malformed output gets one retry, then the
        row is routed to needs_review."""
        for _ in range(2):
            try:
                result = await self._fetch(row)
            except (json.JSONDecodeError, ValidationError, ValueError) as exc:
                error = f"{type(exc).__name__}: {exc}"
                continue  # malformed output — one re-send, then review
            except Exception as exc:  # exhausted retries / hard API error
                log.error("OpenRouter request failed for fdc_id=%s: %s: %s",
                          row["fdc_id"], type(exc).__name__, exc)
                self._fail(row, f"{type(exc).__name__}: {exc}")
                return
            self._persist(row, result)
            return
        self._fail(row, error)

    async def run(self, rows: list[dict], progress_cb=None) -> EnrichmentStats:
        self.stats = EnrichmentStats(requested=len(rows))
        self._pending.clear()
        start = time.monotonic()
        done = 0
        reported = 0

        async def _one(row: dict) -> None:
            nonlocal done, reported
            await self.enrich_row(row)
            done += 1
            if len(self._pending) >= config.FLUSH_EVERY:
                self._flush()
            # throttled: a full run is ~15k rows and every call is a
            # synchronous UI write on the event loop
            if progress_cb and (
                done - reported >= config.PROGRESS_EVERY or done == len(rows)
            ):
                reported = done
                progress_cb(done, len(rows), self.stats, time.monotonic() - start)

        # The whole request phase runs with the database detached — it touches
        # no tables, so squatting on an exclusive file lock for the length of a
        # full run would lock everything else out for nothing. Each _flush
        # borrows the lock back for its batch.
        with store.unlocked(self.con):
            try:
                # First row alone, then fan out: the instruction block is
                # identical on every request, so letting N cold requests race
                # means N cache misses (and N cache writes) instead of one
                # write and N-1 hits.
                if rows:
                    await _one(rows[0])
                await asyncio.gather(*(_one(r) for r in rows[1:]))
            finally:
                # also on Ctrl-C: these rows are already paid for
                self._flush()
        self.stats.elapsed_s = time.monotonic() - start
        if self.stats.reasoning_tokens:
            log.warning(
                "%d reasoning tokens billed — reasoning=%s was not honoured by the "
                "provider; output cost is inflated.",
                self.stats.reasoning_tokens, self.reasoning,
            )
        return self.stats


class CommonnessEnricher(Enricher):
    """Stage 4b: how commonly a food is eaten / stocked, 0..1.

    A second pass rather than a sixth field on the first one: it asks a
    different question (about the food in the world, not about the text of the
    description), so it gets its own short instruction block, and it re-runs
    independently — re-scoring the corpus never risks the names and emoji the
    naming pass produced, and vice versa.
    """

    instructions = COMMONNESS_INSTRUCTIONS
    candidate_where = store.COMMONNESS_PENDING
    result_model = schema.CommonnessResult
    response_format = schema.COMMONNESS_RESPONSE_FORMAT
    tool = schema.COMMONNESS_TOOL
    # No reviewer ever sees a commonness score, so a failed row must not be
    # pushed into the review queue. It keeps commonness NULL, which is exactly
    # what makes it a candidate again on the next run.
    routes_failures_to_review = False

    def _persist(self, row: dict, result: schema.CommonnessResult) -> None:
        self._pending.append(("write", dict(
            fdc_id=row["fdc_id"],
            commonness=result.c,
            source_version=row["source_version"],
        )))

    def _write(self, payload: dict) -> bool:
        return store.apply_commonness(self.con, **payload)


class KeywordsEnricher(Enricher):
    """Stage 4c: search keywords — synonyms, ingredients, cuisine, occasion.

    A third pass for the same reasons 4b is a second one: a different question,
    its own prompt and its own queue, so re-running it (a keyword prompt is the
    kind of thing that gets tuned twice) never risks the names, emoji or scores
    the other passes produced.

    Stored as one '; '-joined string, matching how USDA's own synonyms are
    aggregated — Stage 7 concatenates the two into the same FTS column, so this
    pass needs no app-side change to be searchable.
    """

    instructions = KEYWORDS_INSTRUCTIONS
    candidate_where = store.KEYWORDS_PENDING
    result_model = schema.KeywordsResult
    response_format = schema.KEYWORDS_RESPONSE_FORMAT
    tool = schema.KEYWORDS_TOOL
    # As with commonness: no reviewer ever sees keywords, so a failed row must
    # not land in the review queue. It keeps keywords NULL, which is what makes
    # it a candidate again next run.
    routes_failures_to_review = False

    def _persist(self, row: dict, result: schema.KeywordsResult) -> None:
        self._pending.append(("write", dict(
            fdc_id=row["fdc_id"],
            keywords="; ".join(result.k),
            source_version=row["source_version"],
        )))

    def _write(self, payload: dict) -> bool:
        return store.apply_keywords(self.con, **payload)


async def run(
    con: duckdb.DuckDBPyConnection,
    limit: int | None = None,
    model: str = config.MODEL,
    concurrency: int = config.CONCURRENCY,
    reasoning: dict | None = None,
    progress_cb=None,
    enricher_cls: type[Enricher] = Enricher,
) -> EnrichmentStats:
    """Stage 4 driver: select candidates from DuckDB, enrich, persist.

    ``limit=config.SAMPLE_SIZE`` gives the pre-flight cost/latency sample;
    ``limit=None`` runs the full remaining queue. Safe to interrupt and
    re-run — completed rows are skipped, human-verified rows are untouchable.
    One item per request; ``concurrency`` and ``config.REQUESTS_PER_MINUTE``
    are what govern throughput.

    ``enricher_cls=CommonnessEnricher`` runs Stage 4b instead — same driver,
    same machinery, different question and its own candidate queue.
    """
    candidates = store.select_enrichment_candidates(
        con, limit=limit, where=enricher_cls.candidate_where
    )
    rows = candidates.to_dicts()
    enricher = enricher_cls(
        con, model=model, concurrency=concurrency, reasoning=reasoning,
    )
    return await enricher.run(rows, progress_cb=progress_cb)
