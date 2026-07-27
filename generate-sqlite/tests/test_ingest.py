"""Stage 1 loaders against synthetic archives.

Covers the parts of ingest.py that are easy to get silently wrong: the two
nutrient id namespaces, the fractional nutrient_nbr collision, duplicate
nutrient rows, measure-unit resolution, and the data_type filter.
"""
from __future__ import annotations

import sys
from pathlib import Path

import polars as pl
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src import ingest, store  # noqa: E402

# nutrient.csv is shared by every fixture archive. 205 vs 205.2 is the real
# collision that an int cast would merge; 307 is the sodium row FNDDS refers
# to by its legacy number.
NUTRIENT_CSV = """id,name,unit_name,nutrient_nbr,rank
1003,Protein,G,203,600.0
1004,Total lipid (fat),G,204,800.0
1005,"Carbohydrate, by difference",G,205,1110.0
1050,"Carbohydrate, other",G,205.2,1120.0
1093,"Sodium, Na",MG,307,5800.0
"""


def _write(dir_, name, text):
    (dir_ / name).write_text(text)


@pytest.fixture
def foundation(tmp_path):
    """Modern-id archive with a duplicate nutrient row and a real portion."""
    d = tmp_path / "foundation_food_2026-04-30"
    d.mkdir()
    _write(d, "nutrient.csv", NUTRIENT_CSV)
    _write(
        d,
        "food.csv",
        "fdc_id,data_type,description,food_category_id,publication_date\n"
        "1105073,foundation_food,\"Bananas, overripe, raw\",9,2020-04-01\n"
        "999999,sub_sample_food,Sample of something,9,2020-04-01\n",
    )
    # two rows for the same (food, nutrient) — must average to 2.0, not duplicate
    _write(
        d,
        "food_nutrient.csv",
        "id,fdc_id,nutrient_id,amount\n"
        "1,1105073,1004,1.0\n"
        "2,1105073,1004,3.0\n"
        "3,1105073,1005,22.0\n"
        "4,1105073,1050,0.5\n"
        "5,999999,1004,99.0\n",
    )
    _write(d, "measure_unit.csv", "id,name\n1119,Banana\n9999,undetermined\n")
    _write(
        d,
        "food_portion.csv",
        "id,fdc_id,seq_num,amount,measure_unit_id,portion_description,modifier,"
        "gram_weight,data_points,footnote,min_year_acquired\n"
        "267488,1105073,1,1.0,1119,,Peeled,110.0,50,,2019\n"
        # FNDDS style: no amount, count inline in the text, code in modifier
        "267489,1105073,2,,9999,1 cup mashed,10205,225.0,,,\n"
        # a measure of two — the app cannot use it, so it must not be ingested
        "267490,1105073,3,2.0,9999,,waffles,80.0,,,\n"
        # FNDDS with no count anywhere: no amount and no leading 1 in the text
        "267491,1105073,4,,9999,Quantity not specified,90000,244.0,,,\n"
        "267492,999999,1,1.0,1119,,,100.0,,,\n",
    )
    _write(d, "foundation_food.csv", "fdc_id,NDB_number,footnote\n1105073,100254,\n")
    return d


@pytest.fixture
def survey(tmp_path):
    """FNDDS archive: food_nutrient.nutrient_id holds legacy nutrient_nbr."""
    d = tmp_path / "survey_fndds_food_2024-10-31"
    d.mkdir()
    _write(d, "nutrient.csv", NUTRIENT_CSV)
    _write(
        d,
        "food.csv",
        "fdc_id,data_type,description,food_category_id,publication_date\n"
        "2705384,survey_fndds_food,\"Milk, whole\",,2024-10-31\n",
    )
    _write(
        d,
        "food_nutrient.csv",
        "id,fdc_id,nutrient_id,amount\n"
        "10,2705384,307,125.0\n"
        "11,2705384,205,4.8\n"
        "12,2705384,205.2,0.1\n",
    )
    _write(
        d,
        "survey_fndds_food.csv",
        "fdc_id,food_code,wweia_category_number,start_date,end_date\n"
        "2705384,11100000,1004,2021-01-01,2023-12-31\n",
    )
    return d


def _ids(*values):
    return pl.Series("fdc_id", list(values), dtype=pl.Int64)


def test_modern_ids_resolve_and_duplicates_average(foundation):
    df = ingest._load_nutrients(foundation, _ids(1105073))
    by_id = {r["nutrient_id"]: r for r in df.to_dicts()}

    assert by_id[1004]["amount"] == 2.0, "duplicate rows must average, not duplicate"
    assert by_id[1004]["nutrient_name"] == "Total lipid (fat)"
    assert by_id[1004]["unit_name"] == "G"
    assert df.height == 3, "one row per (fdc_id, nutrient_id)"


def test_fractional_nutrient_nbr_does_not_collide(foundation):
    """205 and 205.2 are distinct nutrients; an int cast would merge them."""
    df = ingest._load_nutrients(foundation, _ids(1105073))
    amounts = {r["nutrient_id"]: r["amount"] for r in df.to_dicts()}
    assert amounts[1005] == 22.0
    assert amounts[1050] == 0.5


def test_legacy_nutrient_numbers_map_to_canonical_ids(survey):
    """FNDDS refers to sodium as 307; it must land as canonical id 1093."""
    df = ingest._load_nutrients(survey, _ids(2705384))
    by_id = {r["nutrient_id"]: r for r in df.to_dicts()}

    assert 307 not in by_id, "legacy numbers must not survive into the table"
    assert by_id[1093]["amount"] == 125.0
    assert by_id[1093]["nutrient_name"] == "Sodium, Na"
    # the fractional pair must stay separated on the legacy side too
    assert by_id[1005]["amount"] == 4.8
    assert by_id[1050]["amount"] == 0.1


def test_nutrients_exclude_unrequested_foods(foundation):
    df = ingest._load_nutrients(foundation, _ids(1105073))
    assert 999999 not in df["fdc_id"].to_list()


def test_portions_resolve_measure_unit(foundation):
    rows = ingest._load_portions(foundation, _ids(1105073)).to_dicts()

    banana = next(r for r in rows if r["seq_num"] == 1)
    assert banana["measure_unit"] == "Banana"
    assert banana["modifier"] == "Peeled"
    assert banana["gram_weight"] == 110.0

    # 9999 is a placeholder, not a unit; FNDDS-style rows carry the text
    # instead, and their modifier is a measure code that must not become a label
    cup = next(r for r in rows if r["seq_num"] == 2)
    assert cup["measure_unit"] is None
    assert cup["portion_description"] == "1 cup mashed"
    assert cup["modifier"] is None


def test_portions_keep_only_measures_of_one(foundation):
    """The app logs quantity x portion, so '2 waffles' is unusable — and the
    amount column is dropped once every surviving row is a measure of one."""
    df = ingest._load_portions(foundation, _ids(1105073))
    assert df["seq_num"].to_list() == [1, 2]
    assert "amount" not in df.columns


def test_metadata_schema_is_uniform_across_archives(foundation, survey):
    found = ingest._load_metadata(foundation, "foundation_food")
    surv = ingest._load_metadata(survey, "survey_fndds_food")
    assert found.schema == surv.schema, "child frames must concat across archives"

    assert found.to_dicts()[0]["ndb_number"] == "100254"
    assert found.to_dicts()[0]["food_code"] is None

    row = surv.to_dicts()[0]
    assert row["food_code"] == "11100000"
    assert row["wweia_category_number"] == "1004"
    assert str(row["start_date"]) == "2021-01-01"
    assert row["ndb_number"] is None


# The fallback-nutrient-id coalescing this file used to test against the
# food_macros view now lives in the wide app_food_nutrition table; see
# tests/test_appdb.py::test_wide_table_coalesces_fallback_nutrient_ids.


def test_child_upsert_replaces_rather_than_appends(tmp_path):
    """Re-ingest must not duplicate, and a portion dropped upstream must vanish."""
    con = store.connect(tmp_path / "children.duckdb")
    store.init_db(con)
    two = pl.DataFrame(
        {"fdc_id": [7, 7], "seq_num": [1, 2],
         "measure_unit": ["Banana", None], "portion_description": [None, "1 cup"],
         "modifier": ["Peeled", None], "gram_weight": [110.0, 225.0],
         "data_points": [50, None], "footnote": [None, None]},
        schema=ingest._PORTION_SCHEMA,
    )
    store.upsert_ingest_children(con, {"portions": two})
    store.upsert_ingest_children(con, {"portions": two})
    assert con.execute("SELECT count(*) FROM food_portions").fetchone()[0] == 2

    store.upsert_ingest_children(con, {"portions": two.head(1)})
    assert con.execute("SELECT count(*) FROM food_portions").fetchone()[0] == 1
    con.close()


def test_load_frames_filters_provenance_rows_everywhere(foundation, survey, monkeypatch):
    """Foundation food.csv is mostly sample/provenance rows — none of them, and
    none of their child rows, may reach the output frames."""
    archives = {
        "foundation_food": ingest.Archive("foundation_food", "2026-04-30", foundation),
        "survey_fndds_food": ingest.Archive("survey_fndds_food", "2024-10-31", survey),
    }
    # the fixtures are already-extracted dirs; skip the unzip step
    monkeypatch.setattr(ingest, "extract_archive", lambda a, root=None: a.path)

    frames = ingest.load_frames(archives)

    assert sorted(frames["foods"]["fdc_id"].to_list()) == [1105073, 2705384]
    for name in ingest.CHILD_TABLES:
        assert 999999 not in frames[name]["fdc_id"].to_list(), name

    food = {r["fdc_id"]: r for r in frames["foods"].to_dicts()}
    assert food[1105073]["fat_g"] == 2.0, "fat_g comes from the averaged nutrient frame"
    assert str(food[1105073]["publication_date"]) == "2020-04-01"
    assert food[2705384]["food_code"] == "11100000"
