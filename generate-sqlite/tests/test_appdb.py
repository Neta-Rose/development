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

from src import appdb, config, merge, schema, store  # noqa: E402


@pytest.fixture
def con(tmp_path):
    """Eight foods with enough child rows to exercise every derived table.

    fdc 1 carries the preferred nutrient ids, fdc 2 only the fallback ids
    (energy as Atwater 2047, sugar as 1063) plus one long-tail nutrient.
    fdc 3 has no nutrients and no portions at all. fdc 10/11 are SR-Legacy
    rows referenced as ingredients of an FNDDS recipe. fdc 12/13 are two
    preparations of one egg, the only pair Stage 6b can merge — everything
    else here is a singleton group.

    Stage 6b runs as part of the fixture because that is the pipeline order:
    Stage 7 exports the grouping, so a fixture without it would only ever test
    the degenerate all-singletons catalog.
    """
    c = store.connect(tmp_path / "t.duckdb")
    store.init_db(c)
    c.execute(
        """
        INSERT INTO foods (fdc_id, data_type, food_category, description,
                           display_name, emoji, ndb_number, commonness, variable_fat)
        VALUES (1, 'sr_legacy_food', 'Dairy', 'Yogurt, plain', 'Plain yogurt', '🥛', NULL, 0.85, true),
               (2, 'foundation_food', 'Fruits', 'Strawberries, raw', NULL, NULL, NULL, NULL, false),
               (3, 'survey_fndds_food', 'Beverages', 'Water, tap', NULL, NULL, NULL, 1.0, NULL),
               (4, 'sr_legacy_food', 'Sauces', 'Ranch dip', 'Ranch dip', '🥣', NULL, 0.3, false),
               (10, 'sr_legacy_food', 'Dairy', 'Milk, whole', 'Whole milk', '🥛', '1077', 1.0, true),
               (11, 'sr_legacy_food', 'Cereals', 'Oats, rolled', 'Rolled oats', '🌾', '8120', 0.6, false),
               (12, 'sr_legacy_food', 'Dairy and Egg Products', 'Egg, whole, raw, fresh',
                'Raw egg', '🥚', NULL, 0.95, NULL),
               (13, 'sr_legacy_food', 'Dairy and Egg Products', 'Egg, whole, hard-boiled',
                'Boiled egg', '🥚', NULL, 0.7, NULL)
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
               (13, 1003, 'Protein', 'G', 600, 12.6),
               (13, 1004, 'Total lipid (fat)', 'G', 800, 9.9),
               (13, 1005, 'Carbohydrate, by difference', 'G', 1110, 1.1)
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
    merge.run(c)
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
    food whose group row is missing is a food that can never be found again."""
    appdb.build(con)
    assert con.execute(
        "SELECT count(*) FROM app_foods f"
        " LEFT JOIN app_merged_foods m USING (merged_food_id)"
        " WHERE m.merged_food_id IS NULL OR f.merged_food_id IS NULL"
    ).fetchone()[0] == 0
    # fdc 12/13 are one egg in two preparations; the shorter name is canonical
    assert con.execute(
        "SELECT merged_food_id, display_name, n_foods FROM app_merged_foods WHERE n_foods > 1"
    ).fetchall() == [(12, "Raw egg", 2)]
    assert con.execute("SELECT count(*) FROM app_merged_foods").fetchone()[0] == 7


def test_merged_foods_is_total_even_if_stage_6b_never_ran(con):
    """Stage 7 must not depend on Stage 6b having run: a catalog whose foods
    all point at groups that do not exist would be silently unsearchable."""
    con.execute("DELETE FROM merged_foods")
    con.execute("UPDATE foods SET merged_food_id = NULL")
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


def test_build_is_idempotent(con):
    first = appdb.build(con)
    assert appdb.build(con) == first


def test_export_produces_a_queryable_sqlite_catalog(con, tmp_path):
    appdb.build(con)
    path = tmp_path / "foods.sqlite"
    counts = appdb.export_sqlite(con, path)
    assert counts["foods"] == 8
    assert counts["food_nutrition"] == 4  # fdc 3/10/11 carry no nutrients

    sq = sqlite3.connect(path)
    primary, fallback = appdb.search_sql()

    # A food NAMED yogurt must outrank one that only mentions it in aka, even
    # though the latter is enriched and the former is not. Weighting a
    # display_name column instead of the displayed name inverts this.
    assert [r[0] for r in sq.execute(primary, ("yogurt*", 5))] == [1, 4]
    # aka column: USDA's own synonym finds the food its description never names
    assert [r[0] for r in sq.execute(primary, ("curd*", 5))] == [1]
    # typo fallback: MATCH-ing the misspelling directly would find nothing
    assert sq.execute(fallback, ("strawberrys", 5)).fetchall() == []
    assert [r[0] for r in sq.execute(fallback, (appdb.trigram_query("stawberry"), 5))] == [2]

    # the commonness score rides along, landing in its own column and not in
    # whatever column happens to sit at the same position
    assert sq.execute(
        "SELECT commonness, kcal_100g FROM foods WHERE food_id = 1"
    ).fetchone() == (0.85, 61.0)
    assert sq.execute("SELECT commonness FROM foods WHERE food_id = 2").fetchone()[0] is None

    # variable_fat is a DuckDB BOOLEAN landing in a SQLite INTEGER column, so
    # the app can filter on it directly. Without it exported, the flag would
    # exist only on user-created foods and mean nothing for the catalog.
    assert sq.execute(
        "SELECT food_id, variable_fat FROM foods WHERE variable_fat IS NOT NULL ORDER BY food_id"
    ).fetchall() == [(1, 1), (2, 0), (4, 0), (10, 1), (11, 0)]

    # the detail-page long tail survived the export
    assert sq.execute(
        "SELECT n.name, fn.amount FROM food_nutrients fn JOIN nutrients n USING (nutrient_id)"
        " WHERE fn.food_id = 1"
    ).fetchall() == [("SFA 16:0", 0.8)]

    # search must not scan the foods table
    plan = " ".join(
        r[3] for r in sq.execute(
            "EXPLAIN QUERY PLAN SELECT f.food_id FROM food_fts s JOIN foods f"
            " ON f.food_id = s.rowid WHERE food_fts MATCH 'yog*'"
            " ORDER BY bm25(food_fts, 10.0, 3.0, 1.0) LIMIT 30"
        )
    )
    assert "SCAN foods" not in plan
    assert "SEARCH f USING INTEGER PRIMARY KEY" in plan
    sq.close()


def test_export_collapses_search_to_merged_items(con, tmp_path):
    """One result per food the user recognizes, not one per USDA row — while
    every variant stays individually findable and individually loggable."""
    appdb.build(con)
    path = tmp_path / "foods.sqlite"
    appdb.export_sqlite(con, path)
    sq = sqlite3.connect(path)
    primary, fallback = appdb.search_sql()

    # two egg rows, one result, named and priced as its canonical variant
    rows = sq.execute(primary, ("egg*", 10)).fetchall()
    assert [(r[0], r[1], r[7]) for r in rows] == [(12, "Raw egg", 2)]
    # a variant's own name still finds the group — that is why FTS indexes
    # every row and only the result set collapses
    assert [r[0] for r in sq.execute(primary, ("boiled*", 10))] == [12]
    assert [r[0] for r in sq.execute(fallback, (appdb.trigram_query("boilde"), 10))] == [12]
    # ungrouped foods are unaffected: still one row each, still their own id
    assert [r[0] for r in sq.execute(primary, ("yogurt*", 5))] == [1, 4]

    # the variant picker behind a result row, and the index it rides on
    assert sq.execute(
        "SELECT food_id, display_name FROM foods WHERE merged_food_id = 12 ORDER BY food_id"
    ).fetchall() == [(12, "Raw egg"), (13, "Boiled egg")]
    plan = " ".join(
        r[3] for r in sq.execute(
            "EXPLAIN QUERY PLAN SELECT food_id FROM foods WHERE merged_food_id = 12"
        )
    )
    assert "ix_foods_merged" in plan, "the variant list must not scan the catalog"
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
