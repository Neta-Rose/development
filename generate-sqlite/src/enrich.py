"""Stage 4 — LLM enrichment via OpenRouter (async, resumable, idempotent).

One pass over the merged items Stage 3b built, one request per item, asking
only how to *present* it: display_name, emoji, keywords, commonness.

Everything factual was settled upstream. Stage 3b-1 (``canon.py``) already read
each member's identity and preparation off its description, and Stage 3b
grouped on that identity — so this pass no longer types preparations, no longer
has to infer "which of these is the cooked one" from a macro contrast, and no
longer decides anything that clustering depends on. What is left is naming, and
naming is the one thing that genuinely needs the whole item in front of it.

The transport — pacing, retries, structured-output fallback, buffered writes,
usage accounting — lives in :class:`_LLMPass`, shared with ``canon.py``:

* Throughput comes from ``config.CONCURRENCY`` in-flight requests. Requests are
  spaced to ``config.REQUESTS_PER_MINUTE`` by a shared pacer (0 = no pacing,
  the right setting on a paid model, where the meter is tokens and not
  requests), and 429/5xx/timeouts back off via tenacity — honouring Retry-After
  when the server sends it, and slowing every in-flight request, since the
  limit is per-account. Retries live in tenacity alone; the SDK's own retry
  layer is disabled, because nesting the two multiplies out to 18 full-prompt
  requests for one bad row and is invisible to the pacer.
* Structured output is enforced with ``response_format`` (json_schema,
  strict). If the model rejects that, the run transparently falls back to a
  forced tool call carrying the same schema. Everything is re-validated with
  pydantic; malformed rows get one retry, then are routed to needs_review.
* The static instruction block is a single module constant, byte-identical
  across calls, so prompt caching can hit. ``cached_tokens`` in the stats is
  what proves it happened. Caches are per-provider, so ``config.PROVIDER_ORDER``
  pins routing once the sample shows which provider caches, and the run sends
  one request alone before fanning out so the cache is written once instead of
  by N concurrent cold misses.
* A run does not sit on the DuckDB file lock while it waits on the network. The
  candidate rows are read, the database is detached for the whole request
  phase, and completed rows are buffered and written back in batches of
  ``config.FLUSH_EVERY`` — each flush re-attaches, writes in one transaction,
  and detaches again. Detaching also checkpoints, so a crash or Ctrl-C loses at
  most the rows since the last flush. Re-runs skip already-enriched rows and
  NEVER touch human-verified rows (enforced again in store).
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
# per-item facts belong in build_group.
# ---------------------------------------------------------------------------
STATIC_INSTRUCTIONS = """You write the shopper-facing label for a food in a grocery-style catalog. The input is one item as a JSON object; return JSON matching the schema.

An item is one food a shopper recognizes. It has already been identified for you: "base" is its canonical identity, worked out from the USDA descriptions of every record in it, and "kind" says whether it is a single ingredient or a composed dish. Its "p" array holds that food's preparations, each with "prep" (its preparation label, already assigned), "m" ([protein, carb, fat] grams per 100 g) and "d" (up to four USDA descriptions). Other keys: cat = USDA food category; aka = USDA "Common Name" synonyms; also = USDA "Additional Description".

The identity and the grouping are settled and are not yours to revisit. Do not rename the food into a different food, do not widen it, do not narrow it.

display_name: "base", written the way a label would write it. Sentence case, natural word order, 2 to 6 words, at most one comma.
* KEEP EVERY QUALIFIER "base" CARRIES. They are there because they are what separates this item from the one next to it in the list: "almond granola bar" must not become "Granola bar", "pork loin, lean only" must not become "Pork loin", "egg noodles" must not become "Noodles". Two items whose names come out identical is the single worst failure of this task — the shopper cannot tell them apart, and one of them is unloggable.
* SINGULAR, not plural. A shopper logs "Lemon", not "Lemons"; "Almond", not "Almonds". The exception is a food whose name is only ever plural — "baked beans", "egg noodles", "grits", "mashed potatoes" — where the singular would be a different food or no food at all.
* NEVER ADD A PREPARATION WORD. Not raw, cooked, roasted, baked, boiled, fried, grilled, steamed, braised, broiled, dried, canned, frozen, smoked, toasted, poached, scrambled, stewed, microwaved, sauteed, blanched, pickled, cured, breaded, drained — nor "fresh", "heated" or "prepared". The preparation is stored separately and joined back at display time, so a word in both places is shown twice. "base" has already had these removed; putting one back is a defect. The exception is a word that is part of the food's NAME rather than a description of its state: "fried rice", "refried beans", "smoked salmon" are dishes called that, and "base" will say so.
* Rewrite as a phrase; never echo a description back as a comma list. Drop bureaucratic filler ("ready-to-heat", "as packaged", "year round average", "not further specified", "in processing"). Never add an attribute that is not in the input. When a description carries a brand name, name the generic food, not the brand.

emoji: exactly one emoji character, the app's list icon for this food. Pick the closest food emoji — the ingredient itself when there is one (🥕 for carrots), otherwise the dish or its dominant component (🍲 for a stew, 🥪 for a sandwich). Never a word, never two emoji, never an ASCII face. When nothing fits, 🍽️.

keywords: 10 to 20 lowercase terms so a shopper who types anything reasonable finds this item, most useful first. Cover whichever apply: other names for the same food, including regional and non-English ones people actually type (aubergine, cilantro, garbanzo, courgette); for a dish, its core ingredients (for pasta alfredo: fettuccine, parmesan, cream, butter); cuisine or origin (italian, thai, cajun) and the meal or occasion (breakfast, dessert, cookout); the broader food it is one of (pasta, citrus, shellfish) and the form it is served in (fillet, ground, wedge, dip); the everyday word for a bureaucratic description (frankfurter -> hot dog). Single words or short phrases, no punctuation. Skip any word already in the descriptions or in display_name — that text is searched directly, so repeating it buys nothing. No brand names, no nutrition claims, no USDA vocabulary. Never a term that would also pull up a different food ("cheese" for a cheesecake, "chicken" for chicken-flavored broth) — matching is loose, so one wrong keyword costs more than three missing ones.

commonness: 0..1, how likely this food is to be in an ordinary home kitchen. Near 1.0 for a staple eaten most days (eggs, milk, butter, rice, bread, onions), down through common kitchen items (yogurt, olive oil, canned tuna, frozen peas, bacon), familiar things bought for a specific dish (parmesan, maple syrup, quinoa, sour cream), niche items from one cuisine or a specialty aisle (tahini, duck breast, plantain), to near 0 for something rare, exotic or institutional (turtle meat, emu, agar, commodity bulk items). These are anchor points on a continuum, not a menu — judge each food on its own and output a precise value reflecting exactly how common it is (0.63, 0.28, 0.91, ...). Do not round to a nearby anchor. Rate the food as a whole, not its rarest preparation, and ignore brand names.

confidence: 0..1 in the whole output — name, emoji, keywords together. Your least certain field sets it, not the average: a good name with a doubtful emoji is a low-confidence item. 0.80 or above publishes with no human check; below it goes to a reviewer. Be honest — composite dishes, "not specified" items, brand-contaminated descriptions, anything you had to give 🍽️, and any name you could not make distinguishing belong below 0.80.

Examples (one item per line, abbreviated):

{"base":"chicken thigh","kind":"ingredient","cat":"Poultry Products","p":[{"prep":"fried","m":[28.2,1.2,10.3],"d":["Chicken, broilers or fryers, thigh, meat only, cooked, fried"]},{"prep":"cooked","m":[24.8,0,8.9],"d":["Chicken, broilers or fryers, thigh, meat only, cooked, roasted"]},{"prep":"raw","m":[19.7,0,4.1],"d":["Chicken, broilers or fryers, dark meat, thigh, meat only, raw"]}]} -> {"display_name":"Chicken thigh","emoji":"🍗","commonness":0.75,"keywords":["dark meat","poultry","bone in","drumstick","curry","roast dinner","fried chicken","teriyaki","asian","barbecue","weeknight","protein"],"confidence":0.94}
{"base":"almond granola bar","kind":"dish","cat":"Snacks","p":[{"prep":null,"m":[9.8,64.4,17.3],"d":["Snacks, granola bars, hard, almond"]}]} -> {"display_name":"Almond granola bar","emoji":"🍫","commonness":0.45,"keywords":["cereal bar","muesli bar","snack bar","oats","hiking","trail","lunchbox","breakfast on the go","nuts","chewy"],"confidence":0.92}
{"base":"fried rice","kind":"dish","cat":"Rice mixed dishes","p":[{"prep":null,"m":[4.2,20.6,4.9],"d":["Restaurant, Chinese, fried rice, without meat"]}]} -> {"display_name":"Fried rice","emoji":"🍚","commonness":0.5,"keywords":["chinese","takeout","wok","stir fry","soy sauce","egg","scallion","leftover rice","asian","side dish","cantonese"],"confidence":0.93}
{"base":"tomato","kind":"ingredient","cat":"Vegetables and Vegetable Products","p":[{"prep":"raw","m":[0.9,3.9,0.2],"d":["Tomatoes, red, ripe, year round average"]}]} -> {"display_name":"Tomato","emoji":"🍅","commonness":0.95,"keywords":["salad","sandwich","salsa","caprese","marinara","italian","garden","vine","sauce","bruschetta","sofrito"],"confidence":0.96}
{"base":"beef frankfurter","kind":"dish","cat":"Sausages and Luncheon Meats","aka":"hot dog, wiener, frank","p":[{"prep":null,"m":[11.7,4.3,26.7],"d":["Frankfurter, beef"]}]} -> {"display_name":"Beef frankfurter","emoji":"🌭","commonness":0.6,"keywords":["hot dog","wiener","sausage","bun","cookout","barbecue","ballpark","street food","american","grill","mustard","picnic"],"confidence":0.93}"""


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
        retry_state.args[0].pacer.backoff(delay)  # args[0] is the pass
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


def build_group(row: dict) -> dict:
    """One item and its preparations, keyed to the legend in STATIC_INSTRUCTIONS.

    Optional keys are omitted when absent so the common item stays cheap;
    insertion order is fixed, so the serialization is deterministic without
    sorting.

    ``base`` and ``kind`` lead, because they are the answer to the question the
    model is NOT being asked — what this food is — and the whole prompt is
    written around not second-guessing them.

    Preparations go out in seq order carrying the label Stage 3b-1 assigned.
    They are context for the naming, not the subject of the request, so they no
    longer carry an echoed index: there is nothing per-preparation to map an
    answer back onto. Macros are rounded to one decimal — the second decimal is
    three characters of noise on every preparation of every request.

    brand_flagged and variable_fat are deliberately NOT sent. Both drive
    deterministic pipeline decisions (route_confidence forces review) that the
    model must not second-guess or anchor on. data_type is not sent either: it
    says where a row came from, not what the food is, and the model cannot act
    on provenance it has no way to verify.
    """
    payload: dict = {"base": row["base_name"], "kind": row["food_kind"]}
    payload["cat"] = row["food_category"]
    if row["common_name"]:
        payload["aka"] = row["common_name"]
    if row["extra_desc"]:
        payload["also"] = row["extra_desc"]
    payload["p"] = [
        {
            "prep": prep["prep_type"],
            "m": [round(float(prep[k] or 0.0), 1) for k in config.MERGE_MACRO_KEYS],
            "d": list(prep["descs"]),
        }
        for prep in row["preps"]
    ]
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


class _LLMPass:
    """Everything an OpenRouter pass over this database needs except the question.

    Two passes now share it — Stage 3b-1 asks what each food *is*, Stage 4 asks
    how to present an item — and they differ only in the four hooks at the
    bottom: which rows are candidates, what one request looks like, how the
    answer validates, and what gets written. Pacing, retry/backoff, the
    json_schema→tool fallback, usage accounting and the detach/flush/reattach
    lock dance are identical for both and are written once here.

    A subclass supplies ``instructions`` / ``response_format`` / ``tool`` as
    class attributes and implements ``_process`` and ``_write``.
    """

    instructions: str = ""
    response_format: dict = {}
    tool: dict = {}

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
        # completed units waiting for the next batched write; see _flush
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

    async def _send(self, payload: dict) -> str:
        """One request, serialized compactly.

        Compact separators match the few-shot examples byte-for-byte and save a
        token per key over json.dumps' default ", " / ": ".
        """
        async with self.semaphore:
            return await self._request_with_fallback(
                json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
            )

    # --- the four hooks a pass supplies ------------------------------------

    async def _process(self, unit) -> None:
        """Fetch, validate and buffer one unit of work. Never raises."""
        raise NotImplementedError

    def _write(self, kind: str, payload: dict) -> bool:
        """Persist one buffered result inside the flush transaction.

        Returns False when the write was refused (the human-verified lock),
        which _flush counts as skipped rather than succeeded.
        """
        raise NotImplementedError

    # ----------------------------------------------------------------------

    def _flush(self) -> None:
        """Write everything buffered since the last flush.

        The only place a run touches DuckDB: it takes the file lock, writes the
        batch in one transaction and gives the lock straight back (which
        checkpoints, so the batch lands in the main file). The success counters
        are incremented here rather than at buffer time because "written" is not
        decided until store re-checks the human-verified lock.
        """
        if not self._pending:
            return
        pending, self._pending = self._pending, []
        with store.locked(self.con, self.db_path):
            self.con.begin()
            try:
                for kind, payload in pending:
                    if not self._write(kind, payload):
                        self.stats.skipped_locked += 1
                self.con.commit()
            except Exception:
                self.con.rollback()
                raise

    async def run(self, units: list, progress_cb=None) -> EnrichmentStats:
        self.stats = EnrichmentStats(requested=len(units))
        self._pending.clear()
        start = time.monotonic()
        done = 0
        reported = 0

        async def _one(unit) -> None:
            nonlocal done, reported
            await self._process(unit)
            done += 1
            if len(self._pending) >= config.FLUSH_EVERY:
                self._flush()
            # throttled: a full run is thousands of units and every call is a
            # synchronous UI write on the event loop
            if progress_cb and (
                done - reported >= config.PROGRESS_EVERY or done == len(units)
            ):
                reported = done
                progress_cb(done, len(units), self.stats, time.monotonic() - start)

        # The whole request phase runs with the database detached — it touches
        # no tables, so squatting on an exclusive file lock for the length of a
        # full run would lock everything else out for nothing. Each _flush
        # borrows the lock back for its batch.
        with store.unlocked(self.con):
            try:
                # First unit alone, then fan out: the instruction block is
                # identical on every request, so letting N cold requests race
                # means N cache misses (and N cache writes) instead of one
                # write and N-1 hits.
                if units:
                    await _one(units[0])
                await asyncio.gather(*(_one(u) for u in units[1:]))
            finally:
                # also on Ctrl-C: these units are already paid for
                self._flush()
        self.stats.elapsed_s = time.monotonic() - start
        if self.stats.reasoning_tokens:
            log.warning(
                "%d reasoning tokens billed — reasoning=%s was not honoured by the "
                "provider; output cost is inflated.",
                self.stats.reasoning_tokens, self.reasoning,
            )
        return self.stats


class Enricher(_LLMPass):
    # What this pass asks the model for. Class attributes rather than module
    # references because the notebook's prompt-comparison cell overrides
    # `instructions` per instance.
    instructions = STATIC_INSTRUCTIONS
    candidate_where = store.ENRICHMENT_PENDING
    response_format = schema.RESPONSE_FORMAT
    tool = schema.ENRICHMENT_TOOL

    def _persist(self, row: dict, result: schema.GroupResult) -> None:
        """Apply the deterministic post-rules and queue the item for _flush.

        Nothing here touches DuckDB — the rules are pure, and the write is
        buffered so the request phase can run with the file lock released.
        """
        issues = store.cross_check(
            display_name=result.display_name,
            emoji=result.emoji,
            base_name=row["base_name"],
        )
        review_status = store.route_confidence(
            result.confidence,
            brand_flagged=bool(row["brand_flagged"]),
            validation_failed=bool(issues),
        )
        self._pending.append(("write", dict(
            merged_food_id=row["merged_food_id"],
            display_name=result.display_name,
            emoji=result.emoji,
            commonness=result.commonness,
            keywords="; ".join(result.keywords),
            confidence=result.confidence,
            review_status=review_status,
            notes="; ".join(issues),
            source_version=row["source_version"],
            model=self.model,
            reasoning=json.dumps(self.reasoning, separators=(",", ":")),
        )))

    def _write(self, kind: str, payload: dict) -> bool:
        if kind == "fail":
            store.mark_validation_failed(self.con, **payload)
            return True
        if not store.apply_enrichment(self.con, **payload):
            return False
        self.stats.succeeded += 1
        if payload["review_status"] == "auto_approved":
            self.stats.auto_approved += 1
        else:
            self.stats.needs_review += 1
        return True

    def _fail(self, row: dict, error: str) -> None:
        self.stats.failed += 1
        self.stats.errors.append(f"merged_food_id={row['merged_food_id']}: {error}")
        self._pending.append(
            ("fail", {"merged_food_id": row["merged_food_id"], "error": error})
        )

    async def _fetch(self, row: dict) -> schema.GroupResult:
        raw = await self._send(build_group(row))
        return schema.GroupResult.model_validate(json.loads(raw))

    async def enrich_group(self, row: dict) -> None:
        """One request for one item; malformed output gets one retry, then the
        item is routed to needs_review."""
        for _ in range(2):
            try:
                result = await self._fetch(row)
            except (json.JSONDecodeError, ValidationError, ValueError) as exc:
                error = f"{type(exc).__name__}: {exc}"
                continue  # malformed output — one re-send, then review
            except Exception as exc:  # exhausted retries / hard API error
                log.error("OpenRouter request failed for merged_food_id=%s: %s: %s",
                          row["merged_food_id"], type(exc).__name__, exc)
                self._fail(row, f"{type(exc).__name__}: {exc}")
                return
            self._persist(row, result)
            return
        self._fail(row, error)

    _process = enrich_group


async def run(
    con: duckdb.DuckDBPyConnection,
    limit: int | None = None,
    model: str = config.MODEL,
    concurrency: int = config.CONCURRENCY,
    reasoning: dict | None = None,
    progress_cb=None,
) -> EnrichmentStats:
    """Stage 4 driver: select candidate items from DuckDB, enrich, persist.

    ``limit=config.SAMPLE_SIZE`` gives the pre-flight cost/latency sample;
    ``limit=None`` runs the full remaining queue. Safe to interrupt and
    re-run — completed items are skipped, human-verified items are
    untouchable. One merged item per request; ``concurrency`` and
    ``config.REQUESTS_PER_MINUTE`` are what govern throughput.
    """
    candidates = store.select_enrichment_candidates(con, limit=limit)
    rows = candidates.to_dicts()
    enricher = Enricher(con, model=model, concurrency=concurrency, reasoning=reasoning)
    return await enricher.run(rows, progress_cb=progress_cb)
