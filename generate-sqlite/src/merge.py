"""Stage 6b — merge duplicate foods that share the same base ingredients.

The catalog carries one row per USDA record, so "Whole raw egg", "Poached egg",
"Boiled or poached egg" and "Fried egg, no added fat" are four foods where a
user sees one food in four preparations, and ground beef is nine foods at nine
fat levels. This stage groups them into ``merged_foods`` and points each
``foods.merged_food_id`` at its group.

Two foods are the same item when the same base ingredients drive their macros,
which shows up as the same **protein:carb:fat ratio**. The ratio is what makes
this work without an LLM or an ingredient list:

* invariant to water, so raw and cooked steak land on the same point even
  though cooked steak has more protein per gram;
* invariant to seasoning, so salt-and-pepper tilapia lands on plain tilapia —
  seasonings carry no meaningful macros, so they cannot move a ratio;
* *not* invariant to a macro-bearing addition, so an omelette's oil pushes it
  off the egg point and it stays a separate item. That is the whole test for
  "different ingredients", and it needs no knowledge of what the ingredients
  are.

Fat-level variants are the deliberate exception (:func:`_fat_free_ratio`).

Nothing here is clustered globally — see :func:`cluster_block` for why that is
load-bearing rather than an optimization.
"""
from __future__ import annotations

import math
import re

import polars as pl

from . import config

# Words are letters only: digits and punctuation carry no ingredient signal
# ("80% lean" is a fat level, "Grade A" is a grade), so dropping them is what
# lets the lean levels of ground beef share one key.
_WORD_RE = re.compile(r"[a-z]+")


def _singular(word: str) -> str:
    """Crude singularizer: 'eggs' -> 'egg', 'molasses' -> 'molasses'.

    A stemmer would be a dependency for one rule. Plural-s is the only
    inflection that actually splits food names in this corpus, and the ss/us/is
    guard covers the words where stripping it would be wrong.
    """
    if len(word) >= 4 and word.endswith("s") and not word.endswith(("ss", "us", "is")):
        return word[:-1]
    return word


def merge_key(name: str) -> frozenset[str]:
    """The blocking key for a display name: its ingredient words, as a set.

    Set equality — not overlap — is what blocks two foods together, and that is
    deliberate. Overlap on a common head noun ("egg") plus a coincidental ratio
    match merges "Poached egg" into "Scrambled egg whites with meat"; requiring
    the whole key to match keeps {egg} and {egg, white} apart.

    Word boundaries also mean "Eggplant" tokenizes to {eggplant} and never
    matches {egg} — a substring test would have merged them.
    """
    return frozenset(
        w
        for w in (_singular(w) for w in _WORD_RE.findall(name.lower()))
        if len(w) >= 3 and w not in config.MERGE_STOPWORDS
    )


def macro_ratio(protein: float, carb: float, fat: float) -> tuple[float, float, float] | None:
    """Each macro's share of the three. None when the food has no macros at all."""
    total = protein + carb + fat
    if total <= 0:
        return None
    return (protein / total, carb / total, fat / total)


def _fat_free_ratio(ratio: tuple[float, float, float]) -> float | None:
    """Protein's share of protein+carb — the ratio with fat projected out.

    Ground beef spans protein shares of 0.32 (70% lean) to 0.88 (97% lean),
    which is nowhere near MERGE_DISTANCE in the full simplex, but all of it is
    protein 1.0 / carb 0.0 once fat is dropped. Same for milk across whole /
    2% / 1% / skim. So fat-level variants are found by comparing on this
    projection instead, which is only sound where fat really is the only thing
    varying — hence the guards in :func:`_fat_variant_eligible`.
    """
    protein, carb, _ = ratio
    lean = protein + carb
    return protein / lean if lean > 0 else None


def _fat_variant_eligible(ratio: tuple[float, float, float], food_category: str | None) -> bool:
    """Whether a food may be matched on the fat-free projection at all.

    The projection throws away a dimension, so it merges far more eagerly than
    the full ratio and needs guarding. Category, because a stated fat level
    means fat content for meat and dairy but can mean something else
    elsewhere — without it "Cooked carrots with added fat" merges into
    "Carrots". Fat share, because a rendered fat projects onto whatever it was
    rendered from — without it "Chicken fat, raw" merges into "Canned
    chicken".

    Not sufficient on its own: see :func:`cluster_block` for the stated-level
    requirement that keeps a fried egg out of the raw egg group.
    """
    return (
        config.is_meat_dairy_category(food_category)
        and ratio[2] < config.MERGE_PURE_FAT_RATIO
    )


def cluster_block(rows: list[dict], distance: float = config.MERGE_DISTANCE) -> list[list[dict]]:
    """Split one blocking key's foods into groups by macro ratio.

    Greedy complete-linkage: a food joins the first group *all* of whose
    members it is within ``distance`` of, else it starts its own.

    Complete-linkage and per-block, both load-bearing. The obvious
    implementation — union-find over every pair of foods closer than the
    threshold — takes the transitive closure of a relation that is not
    transitive, and A~B~C with A far from C chains the corpus into one blob.
    Measured on the full 13.6k foods, every threshold tried collapsed
    8.5k-12.5k of them into a single group. Requiring the new member to be
    close to *every* existing one bounds a group's diameter, and clustering
    inside a block means a chain can never grow past that block.

    The second, fat-variant path matches on the fat-free projection instead,
    and needs a stated fat level to be meaningful. Every near-zero-carb food
    projects to ~1.0, so the projection alone cannot tell "Ground beef (70%
    lean)" from "Fried egg" and would pull fried-in-oil eggs into the raw egg
    group. The requirement is on the *group*: it must already hold a member
    whose name states a fat level (``fat_level``, parsed by Stage 2 from "80%
    lean / 20% fat" or "2% milkfat"). A food without one may still join, but
    only inside the group's existing fat range — so plain "Ground beef" lands
    among the lean levels that bracket it, while nothing can extend a group
    into fat it did not already span.

    Blocks are small (<= 36 foods in this corpus), so O(n^2) is free.
    """
    groups: list[list[dict]] = []
    # Stated fat levels first, then by ratio. Greedy first-fit is inherently
    # order-dependent, and the sort is what makes it reproducible — but the
    # leading key does real work too: a group's fat range has to be complete
    # before an unlabeled food is asked whether it falls inside it, or plain
    # "Ground beef" is tested against whichever lean level happened to arrive
    # first and misses.
    for row in sorted(rows, key=lambda r: (not r["fat_level"], r["ratio"], r["fdc_id"])):
        for group in groups:
            if all(math.dist(row["ratio"], o["ratio"]) <= distance for o in group):
                group.append(row)
                break
            if _joins_as_fat_variant(row, group, distance):
                group.append(row)
                break
        else:
            groups.append([row])
    return groups


def _joins_as_fat_variant(row: dict, group: list[dict], distance: float) -> bool:
    """Whether ``row`` is another fat level of ``group``. See cluster_block."""
    if row["fat_free"] is None or not row["fat_variant_ok"]:
        return False
    if not any(o["fat_level"] for o in group):
        return False
    if not all(
        o["fat_free"] is not None
        and o["fat_variant_ok"]
        and abs(row["fat_free"] - o["fat_free"]) <= distance
        for o in group
    ):
        return False
    if row["fat_level"]:
        return True
    fats = [o["ratio"][2] for o in group]
    return min(fats) <= row["ratio"][2] <= max(fats)


def canonical(group: list[dict]) -> dict:
    """The member whose name the group takes.

    Shortest display_name, but an unprepared member wins over a shorter
    prepared one: the egg group's shortest name is "Fried egg", which is a
    poor label for a group that is mostly raw and boiled eggs. Ties break on
    fdc_id so the choice — and therefore merged_food_id — is stable.
    """
    return min(
        group,
        key=lambda r: (r["prep_type"] not in (None, "raw"), len(r["display_name"]), r["fdc_id"]),
    )


def is_variable_fat(group: list[dict], distance: float = config.MERGE_DISTANCE) -> bool:
    """True when the group spans fat levels rather than sitting at one point."""
    return any(
        math.dist(a["ratio"], b["ratio"]) > distance for a in group for b in group
    )


def build_merges(df: pl.DataFrame) -> tuple[pl.DataFrame, pl.DataFrame]:
    """Group a foods frame into (merged_foods, links) frames. Pure.

    Expects columns fdc_id, display_name, food_category, prep_type, emoji and
    the three macro columns named by config.MERGE_MACRO_KEYS.
    """
    blocks: dict[frozenset[str], list[dict]] = {}
    for r in df.iter_rows(named=True):
        name = r["display_name"] or r["description"]
        ratio = macro_ratio(
            *(float(r[k] or 0.0) for k in config.MERGE_MACRO_KEYS)
        )
        row = {
            "fdc_id": r["fdc_id"],
            "display_name": name,
            "food_category": r["food_category"],
            "prep_type": r["prep_type"],
            "emoji": r["emoji"],
            # A food with no macros at all (99 rows: spices, water, tea) has no
            # ratio to compare, so it gets a key nothing else can share and
            # ends up its own singleton rather than pooling with the others.
            "ratio": ratio or (0.0, 0.0, 0.0),
            "fat_free": _fat_free_ratio(ratio) if ratio else None,
            "fat_variant_ok": bool(ratio) and _fat_variant_eligible(ratio, r["food_category"]),
            # Stage 2 parsed a "% lean"/"% fat"/"% milkfat" out of the name.
            "fat_level": r["fat_percentage"] is not None,
        }
        key = merge_key(name) if ratio else frozenset({f"\0{r['fdc_id']}"})
        blocks.setdefault(key, []).append(row)

    merged, links = [], []
    for _, rows in sorted(blocks.items(), key=lambda kv: sorted(kv[0])):
        for group in cluster_block(rows):
            head = canonical(group)
            merged.append({
                "merged_food_id": head["fdc_id"],
                "display_name": head["display_name"],
                "emoji": head["emoji"],
                "food_category": head["food_category"],
                "variable_fat": is_variable_fat(group),
                "n_foods": len(group),
                "protein_ratio": head["ratio"][0],
                "carb_ratio": head["ratio"][1],
                "fat_ratio": head["ratio"][2],
            })
            links.extend(
                {"fdc_id": r["fdc_id"], "merged_food_id": head["fdc_id"]} for r in group
            )

    return (
        pl.DataFrame(merged, schema={
            "merged_food_id": pl.Int64, "display_name": pl.Utf8, "emoji": pl.Utf8,
            "food_category": pl.Utf8, "variable_fat": pl.Boolean, "n_foods": pl.Int32,
            "protein_ratio": pl.Float64, "carb_ratio": pl.Float64, "fat_ratio": pl.Float64,
        }),
        pl.DataFrame(links, schema={"fdc_id": pl.Int64, "merged_food_id": pl.Int64}),
    )


def load_candidates(con) -> pl.DataFrame:
    """Every food with its three macros pivoted out of food_nutrients."""
    from . import store

    macros = store.pivot_columns_sql(config.merge_macro_nutrients())
    return con.execute(
        f"""
        WITH m AS (
            SELECT fdc_id, {macros}
            FROM food_nutrients GROUP BY fdc_id
        )
        SELECT f.fdc_id, f.display_name, f.description, f.food_category,
               f.prep_type, f.emoji, f.fat_percentage,
               {", ".join(f"m.{k}" for k in config.MERGE_MACRO_KEYS)}
        FROM foods f LEFT JOIN m USING (fdc_id)
        ORDER BY f.fdc_id
        """
    ).pl()


def run(con) -> dict:
    """Stage 6b driver: rebuild merged_foods and foods.merged_food_id."""
    from . import store

    df = load_candidates(con)
    if df.is_empty():
        return {"foods": 0, "merged_foods": 0, "groups": 0, "variable_fat": 0}
    merged, links = build_merges(df)
    written = store.write_merges(con, merged, links)
    return {
        "foods": len(df),
        "groups": int((merged["n_foods"] > 1).sum()),
        "variable_fat": int(merged["variable_fat"].sum()),
        "largest_group": int(merged["n_foods"].max()),
        **written,
    }
