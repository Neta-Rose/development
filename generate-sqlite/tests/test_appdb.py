"""Stage 7 — app catalog build + SQLite export.

Deterministic, no network, no API key. Everything runs against a small
hand-built fixture so the invariants are checkable by eye.
"""
from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src import appdb, cluster, config, schema, store  # noqa: E402


def _enrich_all(c):
    """Stand in for Stage 4: name every clustered item, type every preparation.

    Deterministic and offline — the point of these tests is the export, and an
    unenriched catalog would only ever exercise the nameless fallback.
    """
    items = c.execute(
        "SELECT merged_food_id FROM merged_foods ORDER BY merged_food_id"
    ).fetchall()
    names = {
        1: ("Plain yogurt", "🥛", 0.85), 2: ("Strawberries", "🍓", 0.7),
        3: ("Tap water", "💧", 1.0), 4: ("Ranch dip", "🥣", 0.3),
        10: ("Whole milk", "🥛", 1.0), 11: ("Rolled oats", "🌾", 0.6),
        12: ("Egg", "🥚", 0.95), 13: ("Egg", "🥚", 0.95),
    }
    for (item,) in items:
        name, emoji, commonness = names.get(item, ("Food", "🍽️", 0.4))
        store.apply_enrichment(
            c, merged_food_id=item, display_name=name, emoji=emoji,
            commonness=commonness, keywords="curd; yoghurt" if item == 1 else "kw",
            confidence=0.95, review_status="auto_approved",
        )


@pytest.fixture
def con(tmp_path):
    """Eight foods with enough child rows to exercise every derived table.

    fdc 1 carries the preferred nutrient ids, fdc 2 only the fallback ids
    (energy as Atwater 2047, sugar as 1063) plus one long-tail nutrient.
    fdc 3 has no nutrients and no portions at all. fdc 10/11 are SR-Legacy
    rows referenced as ingredients of an FNDDS recipe. fdc 12/13 are two
    preparations of one egg, the only pair Stage 3b can group — everything
    else here is a singleton item.

    Stage 3b and a stand-in Stage 4 run as part of the fixture because that is
    the pipeline order: Stage 7 exports the grouping and the naming, so a
    fixture without them would only ever test the degenerate catalog.
    """
    c = store.connect(tmp_path / "t.duckdb")
    store.init_db(c)
    c.execute(
        """
        INSERT INTO foods (fdc_id, data_type, food_category, description, ndb_number,
                           base_name, base_key, food_kind, prep_label)
        VALUES (1, 'sr_legacy_food', 'Dairy', 'Yogurt, plain', NULL,
                'yogurt', 'yogurt', 'ingredient', NULL),
               (2, 'foundation_food', 'Fruits', 'Strawberries, raw', NULL,
                'strawberry', 'strawberry', 'ingredient', 'raw'),
               (3, 'survey_fndds_food', 'Beverages', 'Water, tap', NULL,
                'tap water', 'tap water', 'ingredient', NULL),
               (4, 'sr_legacy_food', 'Sauces', 'Ranch dip', NULL,
                'ranch dip', 'dip ranch', 'dish', NULL),
               (10, 'sr_legacy_food', 'Dairy', 'Milk, whole', '1077',
                'whole milk', 'milk whole', 'ingredient', NULL),
               (11, 'sr_legacy_food', 'Cereals', 'Oats, rolled', '8120',
                'rolled oats', 'oat rolled', 'ingredient', NULL),
               -- one food at two preparations: the only pair Stage 3b groups
               (12, 'sr_legacy_food', 'Dairy and Egg Products',
                'Egg, whole, raw, fresh', NULL, 'egg', 'egg', 'ingredient', 'raw'),
               (13, 'sr_legacy_food', 'Dairy and Egg Products',
                'Egg, whole, cooked, hard-boiled', NULL,
                'egg', 'egg', 'ingredient', 'boiled')
        """
    )
    c.execute(
        """
        INSERT INTO food_nutrients (fdc_id, nutrient_id, nutrient_name, unit_name,
                                    nutrient_rank, amount)
        VALUES (1, 1008, 'Energy', 'KCAL', 300, 61.0),
               (1, 1003, 'Protein', 'G', 600, 3.5),
               (1, 2000, 'Total Sugars', 'G', 1500, 4.7),
               (1, 1265, 'SFA 16:0', 'G', 9700, 0.8),
               (2, 2047, 'Energy (Atwater General)', 'KCAL', 280, 32.0),
               (2, 1063, 'Sugars, Total', 'G', 1500, 4.9),
               (2, 1265, 'SFA 16:0', 'G', 9700, 0.01),
               (12, 1003, 'Protein', 'G', 600, 12.6),
               (12, 1004, 'Total lipid (fat)', 'G', 800, 9.5),
               (12, 1005, 'Carbohydrate, by difference', 'G', 1110, 0.7),
               -- same ratio as fdc 12 (one item) but visibly leaner in
               -- absolute terms, so level 3 splits it into its own preparation
               (13, 1003, 'Protein', 'G', 600, 10.0),
               (13, 1004, 'Total lipid (fat)', 'G', 800, 7.0),
               (13, 1005, 'Carbohydrate, by difference', 'G', 1110, 0.6)
        """
    )
    c.execute(
        """
        INSERT INTO food_portions (fdc_id, seq_num, measure_unit,
                                   portion_description, modifier, gram_weight)
        VALUES (1, 2, NULL, NULL, 'container (6 oz)', 170.0),
               (1, 1, 'cup', NULL, NULL, 245.0),
               (2, 1, NULL, '1 cup, halves', NULL, 152.0)
        """
    )
    c.execute(
        """
        INSERT INTO food_attributes (fdc_id, seq_num, attribute_type, name, value)
        VALUES (1, 1, 'Common Name', 'x', 'curd'),
               (1, 2, 'Additional Description', 'x', 'yoghurt'),
               (4, 1, 'Additional Description', 'x', 'yogurt based')
        """
    )
    # one FNDDS recipe (fdc 3) made of two catalog foods, linked by NDB number
    c.execute(
        """
        INSERT INTO input_foods (fdc_id, seq_num, ingredient_code, ingredient_description)
        VALUES (3, 1, '1077', 'Milk, whole'),
               (3, 2, '8120', 'Oats, rolled')
        """
    )
    cluster.run(c)
    _enrich_all(c)
    yield c
    c.close()


def test_wide_table_coalesces_fallback_nutrient_ids(con):
    """USDA records the same quantity under several ids; fdc 2 stores energy
    as Atwater 2047 and sugar as 1063. The pivot must coalesce, not NULL out."""
    appdb.build(con)
    rows = {
        r[0]: r[1:]
        for r in con.execute(
            "SELECT food_id, energy_kcal, sugar_g FROM app_food_nutrition ORDER BY food_id"
        ).fetchall()
    }
    assert rows[1] == (61.0, 4.7), "preferred ids"
    assert rows[2] == (32.0, 4.9), "fallback ids must be coalesced in"


def test_wide_and_long_tables_share_no_nutrient(con):
    """The long tail exists so nothing is stored twice; an overlap would mean
    ~600k duplicated rows in the shipped file."""
    appdb.build(con)
    long_ids = {
        r[0] for r in con.execute("SELECT DISTINCT nutrient_id FROM app_food_nutrients").fetchall()
    }
    wide_ids = {n for ids in config.APP_NUTRIENTS.values() for n in ids}
    assert long_ids & wide_ids == set()
    assert 1265 in long_ids, "SFA 16:0 is not a curated column, so it belongs to the tail"


def test_list_macros_match_the_detail_page(con):
    """app_foods duplicates four macros for the search list. If the copy ever
    disagreed with app_food_nutrition the two screens would show different
    numbers for the same food."""
    appdb.build(con)
    mismatched = con.execute(
        """
        SELECT count(*) FROM app_foods f JOIN app_food_nutrition n USING (food_id)
        WHERE f.kcal_100g IS DISTINCT FROM n.energy_kcal
           OR f.protein_100g IS DISTINCT FROM n.protein_g
           OR f.fat_100g IS DISTINCT FROM n.fat_g
           OR f.carb_100g IS DISTINCT FROM n.carb_g
        """
    ).fetchone()[0]
    assert mismatched == 0


def test_every_food_survives_with_no_nutrients_or_portions(con):
    """fdc 3 has neither. It must still be searchable and loggable, with a
    NULL serving the app reads as 'per 100 g' — not dropped by an inner join."""
    appdb.build(con)
    assert con.execute("SELECT count(*) FROM app_foods").fetchone()[0] == 8
    row = con.execute(
        "SELECT serving_g, serving_label, kcal_100g FROM app_foods WHERE food_id = 3"
    ).fetchone()
    assert row == (None, None, None)


def test_portion_labels_are_bare_units(con):
    """Every portion is a measure of one, so its label carries no count: the
    app renders quantity x label. Portions are renumbered by seq_num, so the
    default serving is 'cup' (seq_num 1), not whichever row was inserted first.
    """
    appdb.build(con)
    assert con.execute(
        "SELECT serving_g, serving_label FROM app_foods WHERE food_id = 1"
    ).fetchone() == (245.0, "cup")
    labels = con.execute(
        "SELECT seq, label, gram_weight FROM app_food_portions WHERE food_id = 1 ORDER BY seq"
    ).fetchall()
    # measure_unit is NULL on seq 2, so the modifier wins the coalesce
    assert labels == [(1, "cup", 245.0), (2, "container (6 oz)", 170.0)]
    # FNDDS writes the count into its text; the leading '1 ' is stripped
    assert con.execute(
        "SELECT label FROM app_food_portions WHERE food_id = 2"
    ).fetchone() == ("cup, halves",)


def test_pairs_are_symmetric_and_come_from_recipe_ingredients(con):
    """FNDDS ingredient_code resolves to foods.ndb_number; both directions are
    stored so 'what goes with this' is one range scan either way."""
    appdb.build(con)
    pairs = set(con.execute("SELECT food_id, pair_food_id FROM app_food_pairs").fetchall())
    assert pairs == {(10, 11), (11, 10)}


def test_every_food_belongs_to_exactly_one_merged_item(con):
    """The join the app's search runs on every keystroke is an inner one, so a
    food whose item row is missing is a food that can never be found again."""
    appdb.build(con)
    assert con.execute(
        "SELECT count(*) FROM app_foods f"
        " LEFT JOIN app_merged_foods m USING (merged_food_id)"
        " WHERE m.merged_food_id IS NULL OR f.merged_food_id IS NULL"
    ).fetchone()[0] == 0
    # fdc 12/13 are one egg in two preparations, named once for the pair
    assert con.execute(
        "SELECT merged_food_id, display_name, n_foods, n_preps "
        "FROM app_merged_foods WHERE n_foods > 1"
    ).fetchall() == [(12, "Egg", 2, 2)]
    assert con.execute("SELECT count(*) FROM app_merged_foods").fetchone()[0] == 7
    # every food carries the id of the preparation it belongs to, and each
    # preparation's representative points at itself
    assert con.execute(
        "SELECT count(*) FROM app_foods WHERE prep_id IS NULL"
    ).fetchone()[0] == 0
    assert con.execute(
        "SELECT count(*) FROM app_foods WHERE food_id = prep_id"
    ).fetchone()[0] == con.execute("SELECT sum(n_preps) FROM app_merged_foods").fetchone()[0]


def test_merged_foods_is_total_even_if_stage_3b_never_ran(con):
    """Stage 7 must not depend on Stage 3b having run: a catalog whose foods
    all point at items that do not exist would be silently unsearchable."""
    con.execute("DELETE FROM merged_preps")
    con.execute("DELETE FROM merged_foods")
    con.execute("UPDATE foods SET merged_food_id = NULL, prep_id = NULL")
    appdb.build(con)
    assert con.execute("SELECT count(*) FROM app_merged_foods").fetchone()[0] == 8
    assert con.execute(
        "SELECT count(*) FROM app_foods f"
        " LEFT JOIN app_merged_foods m USING (merged_food_id)"
        " WHERE m.merged_food_id IS NULL"
    ).fetchone()[0] == 0
    # every food is its own singleton, so search degrades to the flat catalog
    assert con.execute(
        "SELECT count(*) FROM app_merged_foods WHERE n_foods <> 1"
    ).fetchone()[0] == 0
    # unnamed, but still searchable: the FTS name falls back to the description
    assert con.execute("SELECT count(*) FROM app_food_fts WHERE name IS NULL").fetchone()[0] == 0


def test_build_is_idempotent(con):
    first = appdb.build(con)
    assert appdb.build(con) == first


def _app_connection(catalog_path, tmp_path):
    """The app's connection shape: the writable log as main, catalog ATTACH-ed.

    search_sql() runs against `log_entries` for its recency term, so it can
    only be executed on a connection that has both — which is also the only
    setup that proves the shipped query is legal. bm25() in an ORDER BY beside
    a join is exactly the construct that raises "unable to use function bm25 in
    the requested context" at RUNTIME, so nothing but executing it catches a
    regression.
    """
    sq = sqlite3.connect(tmp_path / "log.sqlite")
    sq.executescript(appdb.log_ddl())
    sq.execute("ATTACH ? AS catalog", (str(catalog_path),))
    return sq


def test_export_produces_a_queryable_sqlite_catalog(con, tmp_path):
    appdb.build(con)
    path = tmp_path / "foods.sqlite"
    counts = appdb.export_sqlite(con, path)
    assert counts["foods"] == 8
    assert counts["food_nutrition"] == 4  # fdc 3/10/11 carry no nutrients

    sq = _app_connection(path, tmp_path)
    primary, fallback = appdb.search_sql()
    args = ("2000-01-01", "yogurt*", "yogurt", 5)

    # A food NAMED yogurt must outrank one that only mentions it in aka.
    assert [r[0] for r in sq.execute(primary, args)] == [1, 4]
    # aka column: USDA's own synonym finds the food its description never names
    assert [r[0] for r in sq.execute(primary, ("2000-01-01", "curd*", "curd", 5))] == [1]
    # typo fallback: MATCH-ing the misspelling directly would find nothing
    assert sq.execute(
        fallback, ("2000-01-01", "strawberrys", "strawberrys", 5)
    ).fetchall() == []
    assert [r[0] for r in sq.execute(
        fallback, ("2000-01-01", appdb.trigram_query("stawberry"), "stawberry", 5)
    )] == [2]

    # the commonness score rides along, landing in its own column and not in
    # whatever column happens to sit at the same position
    assert sq.execute(
        "SELECT commonness, kcal_100g FROM catalog.foods WHERE food_id = 1"
    ).fetchone() == (0.85, 61.0)

    # variable_fat is a DuckDB BOOLEAN landing in a SQLite INTEGER column, so
    # the app can filter on it directly. Without it exported, the flag would
    # exist only on user-created foods and mean nothing for the catalog.
    assert set(sq.execute(
        "SELECT variable_fat FROM catalog.foods WHERE variable_fat IS NOT NULL"
    ).fetchall()) <= {(0,), (1,)}

    # the detail-page long tail survived the export
    assert sq.execute(
        "SELECT n.name, fn.amount FROM catalog.food_nutrients fn"
        " JOIN catalog.nutrients n USING (nutrient_id) WHERE fn.food_id = 1"
    ).fetchall() == [("SFA 16:0", 0.8)]

    # search reaches both catalog tables by rowid, never by scanning them
    plan = " ".join(r[3] for r in sq.execute("EXPLAIN QUERY PLAN " + primary, args))
    assert "SEARCH c USING INTEGER PRIMARY KEY" in plan
    assert "SEARCH m USING INTEGER PRIMARY KEY" in plan
    assert "SCAN c " not in plan and "SCAN m " not in plan
    sq.close()


def test_search_collapses_to_merged_items(con, tmp_path):
    """One result per food the user recognizes, not one per USDA row — while
    every preparation stays individually findable and individually loggable."""
    appdb.build(con)
    path = tmp_path / "foods.sqlite"
    appdb.export_sqlite(con, path)
    sq = _app_connection(path, tmp_path)
    primary, fallback = appdb.search_sql()

    # two egg rows, one result, named and priced as its default preparation
    rows = sq.execute(primary, ("2000-01-01", "egg*", "egg", 10)).fetchall()
    assert [(r[0], r[1], r[9], r[10]) for r in rows] == [(12, "Egg", 2, 2)]
    # a word that appears ONLY in a non-default member's description still
    # finds the item — that is what the deduplicated `members` column is for
    assert [r[0] for r in sq.execute(
        primary, ("2000-01-01", "hard*", "hard", 10)
    )] == [12]
    # a preparation label is searchable, and typo-tolerant — it is on screen in
    # the variant selector, so it is text the user can misspell
    assert 12 in [r[0] for r in sq.execute(
        primary, ("2000-01-01", "boiled*", "boiled", 10)
    )]
    assert 12 in [r[0] for r in sq.execute(
        fallback, ("2000-01-01", appdb.trigram_query("boilde"), "boilde", 10)
    )]

    # exactly one FTS row per item, never per food
    assert sq.execute("SELECT count(*) FROM catalog.food_fts").fetchone()[0] == \
        sq.execute("SELECT count(*) FROM catalog.merged_foods").fetchone()[0]

    # the variant picker behind a result row, and the index it rides on
    assert sq.execute(
        "SELECT food_id, prep_type FROM catalog.foods"
        " WHERE merged_food_id = 12 AND food_id = prep_id ORDER BY food_id"
    ).fetchall() == [(12, "raw"), (13, "boiled")]
    plan = " ".join(
        r[3] for r in sq.execute(
            "EXPLAIN QUERY PLAN SELECT food_id FROM catalog.foods WHERE merged_food_id = 12"
        )
    )
    assert "ix_foods_merged" in plan, "the variant list must not scan the catalog"
    sq.close()


def test_recency_boost_follows_the_item_not_the_food(con, tmp_path):
    """Logging one preparation must boost the whole item.

    The flat query could not express this: it joined recent logs on food_id, so
    logging boiled egg did nothing for a search that would return the raw one.
    """
    appdb.build(con)
    path = tmp_path / "foods.sqlite"
    appdb.export_sqlite(con, path)
    sq = _app_connection(path, tmp_path)
    primary, _ = appdb.search_sql()

    # log the NON-default preparation of the egg item
    sq.execute(
        "INSERT INTO log_entries (food_id, grams, logged_at, name) VALUES (13, 50, ?, ?)",
        ("2026-07-01T08:00", "Egg"),
    )
    # the query still runs, and the recency term now sees the egg ITEM even
    # though the row it returns is the other preparation
    assert [r[0] for r in sq.execute(primary, ("2000-01-01", "egg*", "egg", 10))] == [12]
    assert sq.execute(
        "SELECT count(*) FROM log_entries l JOIN catalog.foods cf ON cf.food_id = l.food_id"
        " WHERE cf.merged_food_id = 12"
    ).fetchone()[0] == 1, "a logged preparation counts toward its item"
    sq.close()


def test_export_overwrites_a_previous_run(con, tmp_path):
    """Re-exporting must replace the file, not append to or merge with it."""
    appdb.build(con)
    path = tmp_path / "foods.sqlite"
    appdb.export_sqlite(con, path)
    assert appdb.export_sqlite(con, path)["foods"] == 8


@pytest.mark.parametrize(
    "value, ok",
    [("🥛", True), ("🧑🏽‍🍳", True), ("🍽️", True), ("x", False), (":)", False),
     ("🥛🥛", False), ("apple", False), ("", False)],
)
def test_emoji_validation(value, ok):
    """The one free-text field the model can answer with a word or an ASCII
    face; skin-tone and variation-selector forms must still pass."""
    assert schema.is_emoji(value) is ok
