"""Stage 3b — group the corpus into items, each with its preparations.

The catalog carries one row per USDA record, so "Whole raw egg", "Poached egg",
"Boiled or poached egg" and "Fried egg, no added fat" are four foods where a
user sees one food in four preparations, and ground beef is nine foods at nine
fat levels. This stage builds the two-level structure the app shows: an **item**
(one row in the search list) holding one or more **preparations** (the variant
selector).

**Identity is a key here, not a pairwise test.** Stage 3b-1 (``canon.py``) has
already read each food's ``base_name`` — its identity with every preparation,
grade and trim word removed — so an item is just every food sharing a
``base_key`` and a ``food_kind``. Being a key rather than a relation is the
point: a key is transitive for free, which is exactly what the greedy
complete-linkage machinery this replaced existed to fake.

What went away with it, and why (all measured on the 13,694-food corpus):

* **Token overlap** (Jaccard ≥ 0.70 over stopword-filtered description words).
  It cannot tell an ingredient word from a handling word, and the stopword list
  was the thing making the call: "granola bars, hard, plain" and "granola bars,
  hard, almond" scored 0.75 and became one item.
* **The protein:carb:fat ratio** (within 0.20 on the simplex). Macros are not
  an identity signal — the same food recorded in two USDA databases differs by
  more than two different foods do within one. 6,586 token-similar pairs were
  rejected by it, 698 of them cross-database duplicates of the same food.
* **The fat-free projection**, which existed only to rescue fat-level families
  from the ratio test. With no ratio test there is nothing to rescue: the
  numeric "% lean" is stripped from base_key, so every grade of ground beef
  keys alike on the way in.

Macros still do the one job they are good at. :func:`split_preps` separates an
item's preparations, seeded by the labels Stage 3b-1 read off the descriptions
and merged where the numbers say two labels are one preparation.
"""
from __future__ import annotations

import hashlib
import re

import polars as pl

from . import config

# Words are letters only: digits and punctuation carry no identity ("Grade A"
# is a grade), and stripping them is also what folds "80% lean" out of a base
# name — see _FAT_LEVEL_RE, which runs first so the number goes with its unit.
_WORD_RE = re.compile(r"[a-z]+")

# A stated numeric fat level, dropped before keying. Every grade of ground beef
# and every fat level of milk is one item sold at several grades, so they have
# to key alike; canon.py is told not to emit these, and this is the guarantee.
_FAT_LEVEL_RE = re.compile(r"\d+(\.\d+)?\s*%\s*(lean|fat|milkfat)?")


def _singular(word: str) -> str:
    """Crude singularizer: 'eggs' -> 'egg', 'molasses' -> 'molasses'.

    A stemmer would be a dependency for one rule. Plural-s is the only
    inflection that actually splits food names in this corpus, and the ss/us/is
    guard covers the words where stripping it would be wrong.
    """
    if len(word) >= 4 and word.endswith("s") and not word.endswith(("ss", "us", "is")):
        return word[:-1]
    return word


def base_key(base_name: str | None) -> str:
    """Normalize a base_name into the string items are grouped by.

    Absorbs the ways an LLM can write the same identity differently across two
    requests — case, plural, punctuation, word order — so "Rice, white",
    "white rice" and "White Rices" are one item. That is the residual risk this
    pass exists to cover: batching in canon.py is what makes the model *write*
    one string for a food's several records, and this is what makes near-misses
    survive anyway.

    Sorting the tokens is what handles word order, and it is safe precisely
    because a base_name has already been stripped to identity words: no food in
    this corpus is distinguished from another only by the order of the same
    words.

    Returns "" for an empty name, which the caller must not treat as a key —
    see :func:`_row`.
    """
    if not base_name:
        return ""
    text = _FAT_LEVEL_RE.sub(" ", base_name.lower())
    words = sorted({
        w for w in (_singular(w) for w in _WORD_RE.findall(text))
        if w not in config.BASE_KEY_STOPWORDS
    })
    return " ".join(words)


def _prep_vector(macros: tuple[float, float, float], variable_fat: bool) -> tuple[float, ...]:
    """What the preparation split compares — per 100 g, or per 100 g of lean.

    For an ordinary item that is the three macros as they are. For a fat-level
    family it cannot be: leanness moves fat and protein together, so raw ground
    beef ranges over 27.5 g to 3.0 g of fat and 15.1 g to 22.0 g of protein,
    and comparing those directly splits one preparation into eight "preps" that
    are only fat levels. Measured, this basis takes the cooked patty group from
    6 preparations to 1 and raw ground beef from 8 to 2, while leaving chicken
    thigh and egg alone.
    """
    protein, carb, fat = macros
    if not variable_fat:
        return (protein, carb, fat)
    lean = max(1.0, 100.0 - fat)
    return (protein * 100 / lean, carb * 100 / lean)


def _prep_distance(a: tuple[float, ...], b: tuple[float, ...]) -> float:
    """Worst macro's relative gap, floored so near-zero macros stay comparable."""
    return max(abs(x - y) / max(config.PREP_FLOOR_G, x, y) for x, y in zip(a, b))


def is_variable_fat(group: list[dict]) -> bool:
    """True when the item spans fat levels rather than sitting at one point.

    A stated fat level (Stage 2's ``fat_percentage`` regex) is the whole test.
    It has to be deterministic and it has to be known before the LLM runs,
    because :func:`_prep_vector` changes basis on the answer.
    """
    return any(r["fat_level"] for r in group)


def _mean(rows: list[dict], i: int) -> float:
    return sum(r["macros"][i] for r in rows) / len(rows)


def _parent(label: str | None) -> str | None:
    """The widest label that still describes this one. Its own, if it has none."""
    return config.PREP_PARENT.get(label, label) if label else None


def _compatible(a: set[str | None], b: set[str | None]) -> bool:
    """Whether two preparation buckets are even allowed to merge.

    The macro test may only merge *within* a label family, and that ceiling is
    load-bearing. Poaching an egg barely moves its per-100 g macros, so raw and
    poached egg sit inside PREP_DISTANCE of each other — and merging them
    produces one preparation holding raw eggs under the label "poached", which
    is worse than the extra row it saves. Grilled and baked chicken land on the
    same numbers too, but they share the parent "cooked", so merging them
    yields a label that is true of both.

    A null label is compatible with anything: the description not saying how a
    food was prepared is an absence of evidence, so the macros are all there is
    to go on and they are allowed to decide.
    """
    pa = {_parent(x) for x in a} - {None}
    pb = {_parent(x) for x in b} - {None}
    return not pa or not pb or pa == pb


def _widest_label(labels: set[str | None]) -> str | None:
    """One label for the preparations that merged.

    ``_compatible`` guarantees every named label here shares a parent, so
    "grilled" and "baked" together become "cooked" while a bucket that only
    ever held "broiled" keeps the more informative "broiled".

    A null label loses to any real one: the sibling that states a preparation
    describes the bucket better than the one that is silent about it.
    """
    named = {label for label in labels if label}
    if not named:
        return None
    return named.pop() if len(named) == 1 else _parent(min(named))


def split_preps(group: list[dict]) -> list[tuple[str | None, list[dict]]]:
    """Split one item into (label, members) preparations. Labels first, macros second.

    The order matters and it is the fix for a real failure. Splitting on macros
    alone — as this did — meant the same food recorded in two USDA databases
    with different numbers became two preparations, and the LLM was then asked
    to invent a distinction between them that does not exist. Bucketing by the
    label Stage 3b-1 read off each description puts them together first, and
    the macro pass only ever *merges* buckets from there.

    So a bucket survives as its own preparation only when both its text and its
    numbers say it is different, and the merge itself is capped by
    :func:`_compatible` — macros may join "grilled" to "baked" but never "raw"
    to "poached". Complete-linkage on the merge, so a merged bucket stays
    macro-coherent rather than chaining.

    Ordered by descending total macros, so the most concentrated preparation is
    seq 0 — dried before cooked before raw, which is stable and happens to read
    well in the selector.
    """
    variable_fat = is_variable_fat(group)
    buckets: dict[str | None, list[dict]] = {}
    for row in group:
        buckets.setdefault(row["prep_label"], []).append(row)

    # Merge buckets whose macros agree. Sorted by descending concentration so
    # the pass is deterministic; None last, so a stated label always seeds a
    # bucket before the unlabeled rows are asked to join one.
    merged: list[list[list[dict]]] = []
    for label in sorted(buckets, key=lambda k: (k is None, -_mean(buckets[k], 0), k or "")):
        rows = buckets[label]
        vector = _prep_vector(tuple(_mean(rows, i) for i in range(3)), variable_fat)
        for prep in merged:
            if _compatible({label}, {r["prep_label"] for o in prep for r in o}) and all(
                _prep_distance(
                    vector,
                    _prep_vector(tuple(_mean(other, i) for i in range(3)), variable_fat),
                ) <= config.PREP_DISTANCE
                for other in prep
            ):
                prep.append(rows)
                break
        else:
            merged.append([rows])

    preps = [
        (
            _widest_label({r["prep_label"] for bucket in prep for r in bucket}),
            sorted((r for bucket in prep for r in bucket),
                   key=lambda r: (-sum(r["macros"]), r["fdc_id"])),
        )
        for prep in merged
    ]
    preps.sort(key=lambda p: (-sum(_mean(p[1], i) for i in range(3)), p[1][0]["fdc_id"]))
    return preps


def representative(rows: list[dict]) -> dict:
    """The member whose fdc_id addresses a preparation (and so an item).

    Widest nutrient panel first: every member is within PREP_DISTANCE on the
    macros by construction, so nutrition cannot decide it, but the detail page
    shows the full panel and a Foundation row with 60 nutrients is visibly
    better than an FNDDS row with 6. Then shortest description, then fdc_id, so
    the choice — and therefore merged_food_id — is stable across re-runs.
    """
    return min(rows, key=lambda r: (-r["n_nutrients"], len(r["description"]), r["fdc_id"]))


def member_key(rows: list[dict]) -> str:
    """A short stable digest of an item's membership.

    Stage 4's queue predicate keys off this: when re-clustering changes who is
    in a group, its LLM naming is stale and the row goes back in the queue.
    Comparing membership directly would mean storing the whole list.
    """
    joined = ",".join(str(fdc_id) for fdc_id in sorted(r["fdc_id"] for r in rows))
    return hashlib.blake2b(joined.encode(), digest_size=16).hexdigest()


def _row(record: dict) -> dict:
    """One frame row as the clustering functions want it.

    The ``base_key`` fallback is what keeps this stage runnable on a corpus
    Stage 3b-1 has not covered yet — a food with no identity keys on its own
    fdc_id and forms a singleton item, which is visible in the counts and fixed
    by running the canonicalization pass. Guessing an identity from the
    description instead would be worse than useless: a wrong key merges two
    foods that should stay apart, where a missing one only fails to merge.
    """
    macros = tuple(float(record[k] or 0.0) for k in config.MERGE_MACRO_KEYS)
    key = base_key(record.get("base_name"))
    return {
        "fdc_id": record["fdc_id"],
        "description": record["description"],
        "food_category": record["food_category"],
        "brand_flagged": bool(record["brand_flagged"]),
        "n_nutrients": int(record["n_nutrients"] or 0),
        "base_key": key or f"\x00{record['fdc_id']}",
        "food_kind": record.get("food_kind") or "",
        "prep_label": record.get("prep_label"),
        "macros": macros,
        # Stage 2 parsed a "% lean"/"% fat"/"% milkfat" out of the name.
        "fat_level": record["fat_percentage"] is not None,
    }


def build_groups(rows: list[dict]) -> list[list[dict]]:
    """Partition foods into items: one per (base_key, food_kind).

    ``food_kind`` is in the key and is not decoration. It is the rule that a
    dish is never a preparation of the ingredient it is made of, enforced where
    it cannot be argued with: even if canon.py were to hand back the same base
    name for "fried rice" and "white rice", the ingredient/dish split still
    keeps them two items.

    Sorted output so the item order — and therefore nothing at all, but also
    every diagnostic that prints it — is reproducible across runs.
    """
    groups: dict[tuple[str, str], list[dict]] = {}
    for row in rows:
        groups.setdefault((row["base_key"], row["food_kind"]), []).append(row)
    return [groups[k] for k in sorted(groups)]


def kind_splits(rows: list[dict]) -> list[str]:
    """base_keys that two records disagree about the kind of.

    The one failure mode putting food_kind in the grouping key introduces: a
    food whose records straddle a canonicalization batch boundary can come back
    labelled "ingredient" in one batch and "dish" in the next, and then splits
    into two items.

    Reported, never auto-corrected. Forcing a majority vote would fix this at
    the cost of re-opening the bug the whole stage exists to close — two
    genuinely different foods that collided on a base name would then merge,
    which is a wrong merge where this is only a duplicate row. Measured on the
    first 200 foods of the corpus this list was empty, because the batching
    orders siblings adjacently; when it is not, the fix is the prompt.
    """
    kinds: dict[str, set[str]] = {}
    for row in rows:
        kinds.setdefault(row["base_key"], set()).add(row["food_kind"])
    return sorted(k for k, v in kinds.items() if len(v) > 1)


def build_clusters(df: pl.DataFrame) -> tuple[pl.DataFrame, pl.DataFrame, pl.DataFrame]:
    """Group a foods frame into (items, preps, links) frames. Pure.

    Expects columns fdc_id, description, food_category, fat_percentage,
    brand_flagged, n_nutrients, base_name, food_kind, prep_label and the three
    macro columns named by config.MERGE_MACRO_KEYS.
    """
    rows = [_row(r) for r in df.iter_rows(named=True)]
    items, preps, links = [], [], []

    for group in build_groups(rows):
        prep_groups = split_preps(group)
        # The largest preparation's representative addresses the whole item, so
        # the search list shows the macros of the form most USDA records
        # describe. max() keeps the first on a tie, which is the most
        # concentrated one.
        default = representative(max(prep_groups, key=lambda p: len(p[1]))[1])

        items.append({
            "merged_food_id": default["fdc_id"],
            "member_key": member_key(group),
            "n_foods": len(group),
            "n_preps": len(prep_groups),
            "food_category": default["food_category"],
            "variable_fat": is_variable_fat(group),
            "brand_flagged": any(r["brand_flagged"] for r in group),
        })
        for seq, (label, prep) in enumerate(prep_groups):
            head = representative(prep)
            preps.append({
                "prep_id": head["fdc_id"],
                "merged_food_id": default["fdc_id"],
                "seq": seq,
                "n_foods": len(prep),
                "prep_type": label,
                **{key: _mean(prep, i) for i, key in enumerate(config.MERGE_MACRO_KEYS)},
            })
            links.extend(
                {
                    "fdc_id": r["fdc_id"],
                    "merged_food_id": default["fdc_id"],
                    "prep_id": head["fdc_id"],
                }
                for r in prep
            )

    return (
        pl.DataFrame(items, schema={
            "merged_food_id": pl.Int64, "member_key": pl.Utf8, "n_foods": pl.Int32,
            "n_preps": pl.Int32, "food_category": pl.Utf8, "variable_fat": pl.Boolean,
            "brand_flagged": pl.Boolean,
        }),
        pl.DataFrame(preps, schema={
            "prep_id": pl.Int64, "merged_food_id": pl.Int64, "seq": pl.Int32,
            "n_foods": pl.Int32, "prep_type": pl.Utf8, "protein_g": pl.Float64,
            "carb_g": pl.Float64, "fat_g": pl.Float64,
        }),
        pl.DataFrame(links, schema={
            "fdc_id": pl.Int64, "merged_food_id": pl.Int64, "prep_id": pl.Int64,
        }),
    )


def load_candidates(con) -> pl.DataFrame:
    """Every food with its identity and its three macros pivoted out of
    food_nutrients."""
    from . import store

    macros = store.pivot_columns_sql(config.merge_macro_nutrients())
    return con.execute(
        f"""
        WITH m AS (
            SELECT fdc_id, {macros}, count(*) AS n_nutrients
            FROM food_nutrients GROUP BY fdc_id
        )
        SELECT f.fdc_id, f.description, f.food_category, f.fat_percentage,
               f.brand_flagged, f.base_name, f.food_kind, f.prep_label,
               coalesce(m.n_nutrients, 0) AS n_nutrients,
               {", ".join(f"m.{k}" for k in config.MERGE_MACRO_KEYS)}
        FROM foods f LEFT JOIN m USING (fdc_id)
        ORDER BY f.fdc_id
        """
    ).pl()


def run(con) -> dict:
    """Stage 3b driver: rebuild merged_foods, merged_preps and the foods links."""
    from . import store

    df = load_candidates(con)
    if df.is_empty():
        return {"foods": 0, "items": 0, "preps": 0}
    rows = [_row(r) for r in df.iter_rows(named=True)]
    items, preps, links = build_clusters(df)
    written = store.write_clusters(con, items, preps, links)
    return {
        "foods": len(df),
        "items": len(items),
        "preps": len(preps),
        "uncanonicalized": int(df["base_name"].is_null().sum()),
        "kind_splits": kind_splits(rows),
        "dishes": int((df["food_kind"] == "dish").sum()),
        "multi_food_items": int((items["n_foods"] > 1).sum()),
        "multi_prep_items": int((items["n_preps"] > 1).sum()),
        "variable_fat": int(items["variable_fat"].sum()),
        "largest_item": int(items["n_foods"].max()),
        **written,
    }
