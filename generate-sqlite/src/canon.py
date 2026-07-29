"""Stage 3b-1 — extract what each USDA row *is*, before anything groups them.

One LLM request per batch of ``config.CANON_BATCH_SIZE`` foods, each answered
with ``{base, kind, prep}``: the food's identity with every preparation and
grading word removed, whether it is an ingredient or a composed dish, and how
this particular record was prepared. Stage 3b then groups on ``base`` and
``kind`` alone.

This stage exists because the two things clustering has to know are semantic
judgments, and the thresholds that used to stand in for them could not be tuned
into agreement. Measured on the 13,694-food corpus:

* **Is this word an ingredient or a handling word?** "Snacks, granola bars,
  hard, almond" and "Snacks, granola bars, hard, plain" scored 0.75 on token
  overlap — ``hard`` and ``plain`` were stopwords, ``almond`` was one token out
  of four — and merged into one item. No stopword list fixes that, because the
  list is the thing making the mistake.
* **Is this a dish or a preparation of an ingredient?** "Rice, white, steamed,
  Chinese restaurant" and "Restaurant, Chinese, fried rice, without meat" also
  scored 0.75, with close macros, and merged. ``kind`` is the answer, and no
  amount of word overlap recovers it.

Macros were the other half of the old test and were worse: they are not an
identity signal at all. 6,586 token-similar pairs were rejected on the
protein/carb/fat ratio, 698 of them the same food recorded in two USDA
databases with different numbers. Nothing here reads a macro.

Design:

* **The batch is the consistency mechanism, not a cost optimization.** The one
  way this pass fails is by writing "chicken thigh" in one request and "thigh,
  chicken" in the next, which splits an item in two. Candidates come out of
  :func:`select_candidates` ordered so that description-siblings are adjacent,
  so "Rice, white, raw" and "Rice, white, steamed" go out in the same request
  and the model writes one string for both. ``base_key`` normalization in
  ``cluster.py`` catches the rest.
* Foods are addressed by their 0-based position in the request and the model
  echoes it back, exactly as Stage 4 does — the model never handles a 7-digit
  fdc_id it could mangle, and the echo turns a short, long or reordered answer
  into a re-send instead of silently filing one food's identity under another.
* Resumable and idempotent on ``foods.base_name IS NULL``. A batch that fails
  validation twice is left un-canonicalized rather than half-written; those
  rows fall back to keying on their own description in Stage 3b, which makes
  them singleton items — visible, and fixed by re-running.
* Transport (pacing, retries, the json_schema→tool fallback, the
  detach/flush/reattach lock dance) is ``enrich._LLMPass``, shared with Stage 4.
"""
from __future__ import annotations

import json
import logging

import duckdb
import polars as pl
from pydantic import ValidationError

from . import config, enrich, schema, store

log = logging.getLogger("fdc_enrich.canon")

# ---------------------------------------------------------------------------
# The static instruction block. Byte-identical across every request in a run,
# which is what makes a prompt-cache hit possible — and at ~1,100 tokens against
# a ~900-token batch payload, it is about half the input of this pass.
# ---------------------------------------------------------------------------
STATIC_INSTRUCTIONS = """You read USDA FoodData Central descriptions and say what each food IS. The input is a JSON object with a "foods" array; return JSON matching the schema, one answer per input food, echoing each food's "i".

Input keys per food: i = its index, echo it back; d = the USDA description; cat = the USDA food category; aka = USDA "Common Name" synonyms; also = USDA "Additional Description"; ing = the recipe's ingredients, when USDA records them.

Answer three questions about each food.

base — the food's identity: what a shopper would say they are buying, with nothing about how this particular record was cooked or graded. 2 to 6 words, lowercase, natural word order ("white rice", not "rice, white"). Two USDA rows of the SAME food must produce the SAME string, and two rows of DIFFERENT foods must produce DIFFERENT strings. That is the whole job — these strings are compared for equality, so an inconsistent one splits a food in two and a careless one merges two foods into one.

KEEP anything that makes it a different thing on the shelf:
* ingredients and flavours — "almond granola bar" and "granola bar" are different foods, so are "strawberry yogurt" and "yogurt"
* the form the food takes — ground beef, beef steak, beef broth; egg noodles, rice noodles
* a part or cut — chicken thigh, chicken breast, pork loin, beef brisket
* macro-bearing qualifiers a shopper picks between — "with skin" / "skinless", "lean only" / "lean and fat", "with meat" / "without meat", "whole milk" / "skim milk", "sweetened" / "unsweetened"
* words that are part of the dish's NAME even though they look like cooking: fried rice, refried beans, smoked salmon, roast beef (the deli meat), baked beans

DROP everything that describes handling rather than identity:
* every cooking method and state: raw, cooked, roasted, baked, boiled, fried, grilled, steamed, braised, broiled, dried, canned, frozen, smoked, toasted, poached, scrambled, stewed, microwaved, sauteed, blanched, pickled, cured, breaded, drained, heated, unheated, fresh, refrigerated, prepared, "from raw", "from frozen"
* doneness and texture: soft-boiled, hard-boiled, firm, tender
* USDA grade and trim: choice, select, prime, all grades, "trimmed to 1/8\\" fat", "separable", "retail cuts"
* NUMERIC fat levels: "80% lean / 20% fat", "2% milkfat", "3.25% milkfat". Say "ground beef" and "milk", never "80% lean ground beef". These are grades of one product and the pipeline groups them deliberately. A NAMED trim ("lean only", "with skin") is different — keep those.
* salt, seasoning, added water, "with added vitamin D", "enriched"
* brand names, restaurant names, "Restaurant,", "Fast Foods," — name the generic food
* bureaucratic filler: NFS, "not further specified", "not specified", "year round average", "as packaged", "ready-to-heat", "all types", "commercially prepared", "home recipe"
* size and packaging: large, medium, small, sliced, chopped, piece, cup, "Grade A"

kind — "ingredient" or "dish".
* "ingredient" = a single food, whatever was done to it. Rice, chicken thigh, milk, an apple, flour, butter, a raw egg. An ingredient normally exists in the corpus at several preparations, and those preparations belong together.
* "dish" = something composed of several foods, or a manufactured product with a recipe. Fried rice, lasagna, a granola bar, bread, a hot dog, ice cream, a sandwich, soup, a cake.
* This is a hard separation, and it is why it is asked: a dish is NEVER a preparation of an ingredient it happens to be made of. Fried rice is not a preparation of rice, an omelet is not a preparation of egg, and french fries are not a preparation of potato. When "ing" lists several real foods, that is a dish. When the category says "mixed dishes", that is a dish.
* Borderline single-ingredient processed foods (cheese, yogurt, butter, oil, flour, dried pasta) are "ingredient": a cook reaches for them as one thing.

prep — how THIS record was prepared, one label from the enum, or null when the description does not say. Read it off the text; do not guess from the food type. Chicken is not "cooked" just because chicken is usually cooked, and a food whose description says nothing about preparation is null. Pick the label the description actually uses (roasted, braised, fried); the pipeline widens it to "cooked" itself when the numbers turn out not to separate them. When the preparation word is part of the name and you kept it in base ("fried rice"), prep is null — it is not a state this record is in, it is what the food is.

Examples:

{"foods":[{"i":0,"d":"Rice, white, steamed, Chinese restaurant","cat":"Cereal Grains and Pasta"},{"i":1,"d":"Restaurant, Chinese, fried rice, without meat","cat":"Restaurant Foods"},{"i":2,"d":"Snacks, granola bars, hard, plain","cat":"Snacks"},{"i":3,"d":"Snacks, granola bars, hard, almond","cat":"Snacks"}]} -> {"foods":[{"i":0,"base":"white rice","kind":"ingredient","prep":"steamed"},{"i":1,"base":"fried rice","kind":"dish","prep":null},{"i":2,"base":"granola bar","kind":"dish","prep":null},{"i":3,"base":"almond granola bar","kind":"dish","prep":null}]}
{"foods":[{"i":0,"d":"Chicken, broilers or fryers, dark meat, thigh, meat only, raw","cat":"Poultry Products"},{"i":1,"d":"Chicken, broilers or fryers, thigh, meat only, cooked, roasted","cat":"Poultry Products"},{"i":2,"d":"Chicken thigh, stewed, skin not eaten","cat":"Chicken, whole pieces"},{"i":3,"d":"Chicken thigh, rotisserie, skin eaten","cat":"Chicken, whole pieces"}]} -> {"foods":[{"i":0,"base":"chicken thigh","kind":"ingredient","prep":"raw"},{"i":1,"base":"chicken thigh","kind":"ingredient","prep":"roasted"},{"i":2,"base":"chicken thigh, skinless","kind":"ingredient","prep":"stewed"},{"i":3,"base":"chicken thigh, with skin","kind":"ingredient","prep":"roasted"}]}
{"foods":[{"i":0,"d":"Beef, ground, 80% lean meat / 20% fat, patty, cooked, broiled","cat":"Beef Products"},{"i":1,"d":"Beef, ground, 95% lean meat / 5% fat, raw","cat":"Beef Products"},{"i":2,"d":"Egg omelet or scrambled egg, with cheese, fat added","cat":"Eggs and omelets","ing":"Eggs, Grade A, Large, egg whole | Cheese as ingredient in sandwiches | Oil or table fat, NFS"},{"i":3,"d":"Egg, whole, cooked, hard-boiled","cat":"Dairy and Egg Products"}]} -> {"foods":[{"i":0,"base":"ground beef patty","kind":"ingredient","prep":"broiled"},{"i":1,"base":"ground beef","kind":"ingredient","prep":"raw"},{"i":2,"base":"cheese omelet","kind":"dish","prep":null},{"i":3,"base":"egg","kind":"ingredient","prep":"boiled"}]}"""


class Canonicalizer(enrich._LLMPass):
    """Stage 3b-1's pass: one request per batch of foods."""

    instructions = STATIC_INSTRUCTIONS
    response_format = schema.CANON_RESPONSE_FORMAT
    tool = schema.CANON_TOOL

    async def _fetch(self, batch: list[dict]) -> list[schema.CanonResult]:
        raw = await self._send(build_batch(batch))
        result = schema.CanonBatch.model_validate(json.loads(raw))
        # The response has to answer for exactly the foods that were sent, once
        # each. Position alone would silently absorb a short, long or reordered
        # list and file one food's identity under another's fdc_id — which,
        # unlike a bad name, would put two unrelated foods in one item.
        got = sorted(r.i for r in result.foods)
        if got != list(range(len(batch))):
            raise ValueError(f"indices {got} do not match the {len(batch)} foods sent")
        return sorted(result.foods, key=lambda r: r.i)

    async def _process(self, batch: list[dict]) -> None:
        """One request for one batch; malformed output gets one re-send.

        A batch that fails twice is left un-canonicalized. It is NOT written
        half-way and NOT given a guessed identity: a wrong base_name merges two
        foods that should stay apart, where a missing one only leaves a
        singleton item that the next run picks up.
        """
        for _ in range(2):
            try:
                answers = await self._fetch(batch)
            except (json.JSONDecodeError, ValidationError, ValueError) as exc:
                error = f"{type(exc).__name__}: {exc}"
                continue
            except Exception as exc:  # exhausted retries / hard API error
                log.error("OpenRouter request failed for a batch of %d starting at "
                          "fdc_id=%s: %s: %s",
                          len(batch), batch[0]["fdc_id"], type(exc).__name__, exc)
                self._fail(batch, f"{type(exc).__name__}: {exc}")
                return
            self._pending.extend(
                ("write", {
                    "fdc_id": row["fdc_id"],
                    "base_name": answer.base,
                    "food_kind": answer.kind,
                    "prep_label": answer.prep,
                    "model": self.model,
                })
                for row, answer in zip(batch, answers)
            )
            return
        self._fail(batch, error)

    def _fail(self, batch: list[dict], error: str) -> None:
        self.stats.failed += len(batch)
        self.stats.errors.append(f"fdc_id={batch[0]['fdc_id']} +{len(batch) - 1}: {error}")

    def _write(self, kind: str, payload: dict) -> bool:
        store.apply_canonicalization(self.con, **payload)
        self.stats.succeeded += 1
        return True


def build_batch(batch: list[dict]) -> dict:
    """One request's foods, keyed to the legend in STATIC_INSTRUCTIONS.

    Optional keys are omitted when absent so the common food stays cheap.
    ``ing`` is FNDDS's own recipe decomposition (``input_foods``), present on
    5,431 foods, and it is the strongest available evidence for ``kind``: a
    description that reads like one food but lists four ingredients is a dish.

    Macros are deliberately NOT sent. They are what the old clustering used to
    decide identity with, they are wrong for it — the same food differs by more
    across two USDA databases than two different foods differ within one — and
    sending them would only invite the model to reason from them.
    """
    foods = []
    for i, row in enumerate(batch):
        food: dict = {"i": i, "d": row["description"]}
        if row["food_category"]:
            food["cat"] = row["food_category"]
        if row.get("common_name"):
            food["aka"] = row["common_name"]
        if row.get("extra_desc"):
            food["also"] = row["extra_desc"]
        if row.get("ingredients"):
            food["ing"] = row["ingredients"]
        foods.append(food)
    return {"foods": foods}


CANON_PENDING = "f.base_name IS NULL"


def select_candidates(
    con: duckdb.DuckDBPyConnection,
    limit: int | None = None,
    where: str = CANON_PENDING,
) -> pl.DataFrame:
    """Foods still needing an identity, ordered so siblings are adjacent.

    The ORDER BY is the load-bearing part. Batching is what makes the model
    write one base name for a food's several USDA records, and it only works if
    those records land in the same batch — so rows are ordered by the first
    word of the description and then by the description itself, which puts
    "Rice, white, raw" next to "Rice, white, steamed" and every cut of beef in
    one run of rows. Ordering by fdc_id instead would scatter them and the pass
    would produce a different string for each.

    ``limit`` takes a PREFIX of that order rather than a sample across it, on
    purpose: a sample would break up exactly the sibling runs the order exists
    to create, and the sample run would then look less consistent than the real
    one.
    """
    q = f"""
        WITH attrs AS (
            SELECT fdc_id,
                   string_agg(DISTINCT value, '; ')
                       FILTER (WHERE attribute_type = 'Common Name') AS common_name,
                   string_agg(DISTINCT value, '; ')
                       FILTER (WHERE attribute_type = 'Additional Description') AS extra_desc
            FROM food_attributes
            WHERE attribute_type IN ('Common Name', 'Additional Description')
              AND coalesce(value, '') <> ''
            GROUP BY fdc_id
        ),
        ing AS (
            SELECT fdc_id,
                   string_agg(ingredient_description, ' | '
                              ORDER BY seq_num, ingredient_description) AS ingredients
            FROM (
                SELECT fdc_id, seq_num, ingredient_description,
                       row_number() OVER (PARTITION BY fdc_id
                                          ORDER BY seq_num, ingredient_description) AS rn
                FROM input_foods
                WHERE coalesce(ingredient_description, '') <> ''
            )
            WHERE rn <= {int(config.MAX_INPUT_FOODS)}
            GROUP BY fdc_id
        )
        SELECT f.fdc_id, f.description, f.food_category,
               a.common_name, a.extra_desc, i.ingredients
        FROM foods f
        LEFT JOIN attrs a USING (fdc_id)
        LEFT JOIN ing i USING (fdc_id)
        WHERE {where}
        ORDER BY lower(split_part(f.description, ',', 1)), lower(f.description), f.fdc_id
    """
    if limit is not None:
        q += f" LIMIT {int(limit)}"
    return con.execute(q).pl()


def count_candidates(
    con: duckdb.DuckDBPyConnection, where: str = CANON_PENDING
) -> int:
    return con.execute(f"SELECT count(*) FROM foods f WHERE {where}").fetchone()[0]


def batches(rows: list[dict], size: int = config.CANON_BATCH_SIZE) -> list[list[dict]]:
    """Chunk the ordered candidates into requests. Pure."""
    return [rows[i:i + size] for i in range(0, len(rows), size)]


async def run(
    con: duckdb.DuckDBPyConnection,
    limit: int | None = None,
    model: str = config.MODEL,
    concurrency: int = config.CONCURRENCY,
    reasoning: dict | None = None,
    progress_cb=None,
) -> enrich.EnrichmentStats:
    """Stage 3b-1 driver: canonicalize every food that has no identity yet.

    ``limit`` counts FOODS, not requests. Safe to interrupt and re-run — a food
    with a base_name is never re-sent, and a batch that failed simply comes back
    in the next run's candidate set.
    """
    rows = select_candidates(con, limit=limit).to_dicts()
    pass_ = Canonicalizer(con, model=model, concurrency=concurrency, reasoning=reasoning)
    stats = await pass_.run(batches(rows), progress_cb=progress_cb)
    # run() counts units, and a unit here is a batch. Every other number in the
    # stats is per food, so this one has to be too.
    stats.requested = len(rows)
    return stats
