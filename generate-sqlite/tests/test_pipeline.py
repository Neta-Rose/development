"""Offline tests for the deterministic layers: abbreviation expansion, brand detection,
schema validation, and the store's routing + human-verified lock.

No network and no API key required.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import polars as pl
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src import abbrev, brand_detect, config, merge, schema, store  # noqa: E402


# --------------------------------------------------------------------------
# Stage 2: abbreviation expansion
# --------------------------------------------------------------------------
def test_abbreviations_whole_token():
    result = abbrev.expand_description("Bread, w/ raisins, NFS")
    assert result.description == "Bread, with raisins, not further specified"
    # "w" inside a word must not expand
    result2 = abbrev.expand_description("Sandwich w/o mayo & cheese")
    assert result2.description == "Sandwich without mayo & cheese"  # "&" is left alone


def test_casing_is_left_alone():
    """Expansion must not touch casing: proper-noun capitalization is the last
    brand signal on rows that miss config.BRAND_TOKENS."""
    for text in (
        "Crackers, snack, Goya Crackers",
        "CEREALS, USDA commodity, RTE",
        "George Weston Bakeries, Thomas English Muffins",
    ):
        assert abbrev.expand_description(text).description == text


def test_idempotent():
    once = abbrev.expand_description("Milk, NFS, w/ 2% fat")
    twice = abbrev.expand_description(once.description)
    assert once.description == twice.description


def test_fat_percentage_regex():
    assert abbrev.expand_description("Beef, ground, 80% lean meat / 20% fat, raw").fat_percentage == 20.0
    assert abbrev.expand_description("Milk, 2% milkfat").fat_percentage == 2.0
    # lean-only converts to fat share
    assert abbrev.expand_description("Beef, ground, 95% lean, raw").fat_percentage == 5.0
    assert abbrev.expand_description("Avocado, raw").fat_percentage is None


def test_preparation_tokens_never_stripped():
    text = "Chicken, roasted, skin removed, without salt, drained"
    result = abbrev.expand_description(text)
    for token in ("roasted", "without", "salt", "drained"):
        assert token in result.description.lower()


def test_substitutions_are_logged():
    result = abbrev.expand_description("Bread w/ jam & butter, NFS")
    rules = {rule for rule, _, _ in result.substitutions}
    assert {"abbrev:w/", "abbrev:NFS"} <= rules


# --------------------------------------------------------------------------
# Stage 3: brand detection
# --------------------------------------------------------------------------
def test_brand_token_list():
    assert brand_detect.detect_brand("McDONALD'S, Big Mac", "sr_legacy_food")
    assert brand_detect.detect_brand("Cereals ready-to-eat, KELLOGG'S CORN FLAKES", "sr_legacy_food")


def test_allcaps_heuristic_respects_whitelist():
    assert brand_detect.detect_brand("Candies, HERSHEY'S special", "sr_legacy_food")
    assert not brand_detect.detect_brand("Chicken, NFS, RTE, USDA commodity", "sr_legacy_food")
    assert not brand_detect.detect_brand("Butter, salted", "sr_legacy_food")


def test_only_sr_legacy_flagged():
    assert not brand_detect.detect_brand("MCDONALD'S hamburger", "survey_fndds_food")


# --------------------------------------------------------------------------
# Stage 4: schema
# --------------------------------------------------------------------------
def test_schema_accepts_valid():
    result = schema.EnrichmentResult.model_validate(
        {"display_name": "Milk", "emoji": "🥛", "prep_type": None,
         "variable_fat": True, "confidence": 0.9}
    )
    assert result.prep_type is None


def test_schema_rejects_bad_enum_and_extra_keys():
    with pytest.raises(Exception):
        schema.EnrichmentResult.model_validate(
            {"display_name": "x", "emoji": "🥛", "prep_type": "microwaved",
             "variable_fat": False, "confidence": 0.5}
        )
    with pytest.raises(Exception):
        schema.EnrichmentResult.model_validate(
            {"display_name": "x", "emoji": "🥛", "prep_type": None,
             "variable_fat": False, "confidence": 0.5, "extra": 1}
        )
    # fdc_id and notes are no longer part of the contract
    with pytest.raises(Exception):
        schema.EnrichmentResult.model_validate(
            {"fdc_id": 1, "display_name": "x", "emoji": "🥛", "prep_type": None,
             "variable_fat": False, "confidence": 0.5}
        )


def test_user_payload_omits_absent_optional_keys():
    """Optional signal is sent when present and costs nothing when absent."""
    from src import enrich

    bare = {
        "description": "Broccoli, raw", "food_category": "Vegetables",
        "data_type": "foundation_food", "common_name": None, "extra_desc": None,
        "fat_percentage": None, "brand_flagged": False,
    }
    # data_type, fat_percentage and brand_flagged stay pipeline-side: set here,
    # never sent
    assert enrich.build_item(bare) == {
        "desc": "Broccoli, raw", "cat": "Vegetables",
    }

    rich = bare | {
        "description": "Frankfurter, beef, low fat", "data_type": "sr_legacy_food",
        "common_name": "hot dog, wiener, frank", "extra_desc": "all types",
        "fat_percentage": 20.0, "brand_flagged": True,
    }
    assert enrich.build_item(rich) == {
        "desc": "Frankfurter, beef, low fat", "cat": "Vegetables",
        "aka": "hot dog, wiener, frank", "also": "all types",
    }

    # the wire payload is that object, serialized compactly and with no id
    wire = json.dumps(enrich.build_item(rich), ensure_ascii=False, separators=(",", ":"))
    assert json.loads(wire) == enrich.build_item(rich)
    assert '"desc":' in wire


# --------------------------------------------------------------------------
# Stage 5: store — routing, cross-checks, human-verified lock
# --------------------------------------------------------------------------
@pytest.fixture()
def con(tmp_path):
    c = store.connect(tmp_path / "test.duckdb")
    store.init_db(c)
    df = pl.DataFrame(
        {
            "fdc_id": [1, 2],
            "data_type": ["sr_legacy_food", "survey_fndds_food"],
            "food_category": ["Beef Products", "Vegetables"],
            "description": ["Beef, ground, 80% lean meat / 20% fat, raw", "Avocado, raw"],
            "fat_g": [20.0, 15.0],
            "source_version": ["2018-04", "2024-10"],
        }
    )
    store.upsert_ingest(c, df)
    abbrev.run(c)  # expand abbreviations, as the run order would
    return c


def test_routing_thresholds():
    assert store.route_confidence(0.9, brand_flagged=False, validation_failed=False) == "auto_approved"
    assert store.route_confidence(0.7, brand_flagged=False, validation_failed=False) == "needs_review"
    assert store.route_confidence(0.99, brand_flagged=True, validation_failed=False) == "needs_review"
    assert store.route_confidence(0.99, brand_flagged=False, validation_failed=True) == "needs_review"


def test_cross_checks():
    issues = store.cross_check(
        prep_type="raw", variable_fat=True, fat_percentage=None,
        description="Avocado, raw", food_category="Fruits",
    )
    assert any("variable_fat" in i for i in issues)
    issues2 = store.cross_check(
        prep_type="raw", variable_fat=True, fat_percentage=20.0,
        description="Beef, ground, 80% lean meat / 20% fat, raw",
        food_category="Beef Products",
    )
    assert issues2 == []


def test_enrichment_upsert_and_resume(con):
    ok = store.apply_enrichment(
        con, fdc_id=1, display_name="Ground beef (80% lean)", emoji="🥩", prep_type="raw",
        variable_fat=True, confidence=0.95, review_status="auto_approved",
        model="some/model-v1",
    )
    assert ok
    assert con.execute("SELECT enriched_by FROM foods WHERE fdc_id = 1").fetchone()[0] == "some/model-v1"
    # enriched at current version -> no longer a candidate
    remaining = store.select_enrichment_candidates(con)["fdc_id"].to_list()
    assert 1 not in remaining
    # audit trail written
    audit = con.execute("SELECT count(*) FROM audit_log WHERE fdc_id = 1 AND actor = 'auto'").fetchone()[0]
    assert audit > 0


def test_human_verified_lock(con):
    store.apply_human_review(con, 1, display_name="Human name", prep_type="raw",
                             variable_fat=True, accept=True)
    # automated write must be refused
    ok = store.apply_enrichment(
        con, fdc_id=1, display_name="Robot name", emoji="🤖", prep_type=None,
        variable_fat=False, confidence=0.99, review_status="auto_approved",
    )
    assert not ok
    row = con.execute("SELECT display_name, review_status, human_verified FROM foods WHERE fdc_id = 1").fetchone()
    assert row == ("Human name", "verified", True)
    # re-ingest must not touch the verified row either
    df = pl.DataFrame(
        {
            "fdc_id": [1], "data_type": ["sr_legacy_food"], "food_category": ["Beef Products"],
            "description": ["CHANGED"], "fat_g": [1.0], "source_version": ["2099-01"],
        }
    )
    counts = store.upsert_ingest(con, df)
    assert counts["locked_skipped"] == 1
    assert con.execute("SELECT description FROM foods WHERE fdc_id = 1").fetchone()[0] != "CHANGED"


def test_persist_rules_force_variable_fat(con, monkeypatch):
    """The deterministic post-rules override the LLM: fat_percentage non-null
    forces variable_fat true; non-meat/dairy category gates it false."""
    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import enrich

    enricher = enrich.Enricher(con)
    rows = {r["fdc_id"]: r for r in store.select_enrichment_candidates(con).to_dicts()}

    # row 1: ground beef with fat_percentage=20 — LLM says false, rule forces true
    enricher._persist(rows[1], schema.EnrichmentResult(
        display_name="Ground beef", emoji="🥩", prep_type="raw",
        variable_fat=False, confidence=0.9))
    enricher._flush()  # _persist only buffers; the write happens here
    vf, status = con.execute("SELECT variable_fat, review_status FROM foods WHERE fdc_id = 1").fetchone()
    assert vf is True and status == "auto_approved"

    # row 2: avocado (Vegetables) — LLM says true, category gate forces false
    enricher._persist(rows[2], schema.EnrichmentResult(
        display_name="Avocado", emoji="🥑", prep_type="raw",
        variable_fat=True, confidence=0.95))
    enricher._flush()
    vf2 = con.execute("SELECT variable_fat FROM foods WHERE fdc_id = 2").fetchone()[0]
    assert vf2 is False


def test_enrich_row_retries_malformed_output_once(con, monkeypatch):
    """Malformed output buys exactly one re-send, then the row goes to review."""
    import asyncio

    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import enrich

    row = {r["fdc_id"]: r for r in store.select_enrichment_candidates(con).to_dicts()}[2]
    good = json.dumps({"display_name": "Avocado", "emoji": "🥑", "prep_type": "raw",
                       "variable_fat": False, "confidence": 0.9})

    def replies(*answers):
        sent = iter(answers)

        async def _fake(_self, _payload):
            return next(sent)

        return _fake

    # garbage then valid -> the retry lands, row is persisted
    enricher = enrich.Enricher(con)
    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback", replies("not json", good))
    asyncio.run(enricher.enrich_row(row))
    enricher._flush()  # succeeded is counted when the buffered row is written
    assert enricher.stats.succeeded == 1 and enricher.stats.failed == 0

    # garbage twice -> no third attempt, routed to needs_review
    enricher2 = enrich.Enricher(con)
    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback", replies("not json", "{}"))
    asyncio.run(enricher2.enrich_row(row))
    enricher2._flush()
    assert enricher2.stats.failed == 1 and enricher2.stats.succeeded == 0
    assert con.execute("SELECT review_status FROM foods WHERE fdc_id = 2").fetchone()[0] == "needs_review"


def test_run_releases_the_file_lock_during_requests(con, monkeypatch):
    """A run must not sit on the exclusive DuckDB file lock while it is waiting
    on the network — that is the whole reason writes are buffered."""
    import asyncio
    import subprocess
    import sys

    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import enrich

    db = store.attached_path(con)
    # a separate process, because connections inside one process share DuckDB's
    # instance cache and would open a locked file quite happily
    probe = f"import duckdb; duckdb.connect({db!r}).execute('SELECT count(*) FROM foods')"
    opened = []

    async def _fake(_self, _payload):
        opened.append(subprocess.run([sys.executable, "-c", probe]).returncode)
        return json.dumps({"display_name": "Avocado", "emoji": "🥑", "prep_type": "raw",
                           "variable_fat": False, "confidence": 0.9})

    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback", _fake)
    rows = store.select_enrichment_candidates(con).to_dicts()
    stats = asyncio.run(enrich.Enricher(con).run(rows))

    assert opened and all(rc == 0 for rc in opened), "database stayed locked mid-run"
    assert stats.succeeded == len(rows)
    # ... and the connection is usable again, with the buffered rows written
    assert con.execute(
        "SELECT count(*) FROM foods WHERE display_name IS NOT NULL"
    ).fetchone()[0] == len(rows)


def test_commonness_pass_is_independent(con, monkeypatch):
    """Stage 4b writes only commonness, scores human-verified rows too, and
    drops out of its own queue once a row has a score."""
    import asyncio

    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import enrich

    async def _fake(_self, _payload):
        return json.dumps({"c": 0.9})

    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback", _fake)
    # verified rows are locked against the naming pass but must still be scored
    store.apply_human_review(con, 1, display_name="Human name", accept=True)

    stats = asyncio.run(enrich.run(con, enricher_cls=enrich.CommonnessEnricher))
    assert stats.succeeded == 2 and stats.skipped_locked == 0
    assert con.execute("SELECT count(*) FROM foods WHERE commonness = 0.9").fetchone()[0] == 2
    # the naming pass's own fields are untouched by it
    assert con.execute("SELECT display_name FROM foods WHERE fdc_id = 1").fetchone()[0] == "Human name"
    assert con.execute("SELECT display_name FROM foods WHERE fdc_id = 2").fetchone()[0] is None
    # scored rows leave the queue
    assert store.count_enrichment_candidates(con, enrich.CommonnessEnricher.candidate_where) == 0


def test_keywords_pass_cleans_and_reaches_search(con, monkeypatch):
    """Stage 4c writes only keywords, cleans what the model returns, and lands
    them in the FTS text Stage 7 builds."""
    import asyncio

    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import appdb, enrich

    async def _fake(_self, _payload):
        # duplicate, mixed case, blank and a sentence: all handled, not rejected
        return json.dumps({"k": ["Fettuccine", "fettuccine", " parmesan ", "",
                                 "italian", "a" * 60]})

    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback", _fake)
    # verified rows are locked against the naming pass but must still get keywords
    store.apply_human_review(con, 1, display_name="Human name", accept=True)

    stats = asyncio.run(enrich.run(con, enricher_cls=enrich.KeywordsEnricher))
    assert stats.succeeded == 2 and stats.skipped_locked == 0
    assert con.execute("SELECT keywords FROM foods WHERE fdc_id = 1").fetchone()[0] == (
        "fettuccine; parmesan; italian"
    )
    # the other passes' fields are untouched
    assert con.execute("SELECT display_name FROM foods WHERE fdc_id = 1").fetchone()[0] == "Human name"
    assert con.execute("SELECT count(*) FROM foods WHERE commonness IS NOT NULL").fetchone()[0] == 0
    # keyworded rows leave the queue
    assert store.count_enrichment_candidates(con, store.KEYWORDS_PENDING) == 0

    # and Stage 7 puts them in the searchable `aka` column
    appdb.build(con)
    aka = con.execute("SELECT aka FROM app_food_fts WHERE food_id = 1").fetchone()[0]
    assert "fettuccine" in aka


def test_reingest_requeues_changed_rows(con):
    df = pl.DataFrame(
        {
            "fdc_id": [2], "data_type": ["survey_fndds_food"], "food_category": ["Vegetables"],
            "description": ["Avocado, raw, California"], "fat_g": [15.0],
            "source_version": ["2025-04"],
        }
    )
    store.apply_enrichment(
        con, fdc_id=2, display_name="Avocado", emoji="🥑", prep_type="raw",
        variable_fat=False, confidence=0.9, review_status="auto_approved",
    )
    counts = store.upsert_ingest(con, df)
    assert counts["updated"] == 1
    status = con.execute("SELECT review_status FROM foods WHERE fdc_id = 2").fetchone()[0]
    assert status == "pending"  # re-queued for enrichment at the new version
    abbrev.run(con)  # re-expand the new description, as the run order would
    assert 2 in store.select_enrichment_candidates(con)["fdc_id"].to_list()


def test_usage_accounting_survives_missing_provider_fields(con, monkeypatch):
    """cost/cached/reasoning are optional and provider-dependent — a provider
    that reports none of them must still bill correctly, not crash."""
    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import enrich

    class _Bare:  # the minimum every provider returns
        prompt_tokens, completion_tokens = 1000, 50

    class _Full:  # OpenRouter with usage.include on a caching provider
        prompt_tokens, completion_tokens = 1000, 50
        cost = 0.002
        prompt_tokens_details = type("D", (), {"cached_tokens": 900})()
        completion_tokens_details = type("D", (), {"reasoning_tokens": 0})()

    enricher = enrich.Enricher(con)
    enricher._record_usage(_Bare())
    assert enricher.stats.cached_tokens == 0
    assert enricher.stats.actual_cost_usd == 0.0
    # no reported cost -> falls back to the price constants
    assert enricher.stats.est_cost_usd == pytest.approx(
        1000 / 1e6 * config.PROMPT_PRICE_PER_M + 50 / 1e6 * config.COMPLETION_PRICE_PER_M
    )

    enricher._record_usage(_Full())
    assert enricher.stats.cached_tokens == 900
    assert enricher.stats.cache_hit_rate == pytest.approx(900 / 2000)
    # a reported cost is authoritative and wins over the constants
    assert enricher.stats.est_cost_usd == pytest.approx(0.002)


def test_init_db_leaves_no_wal(tmp_path):
    """Schema changes must land in the main file, not the WAL.

    DuckDB 1.5.4 cannot replay a WAL containing an ALTER on a table with a
    function-valued DEFAULT (foods.updated_at), so a WAL left behind by
    init_db strands every subsequent write if the process is killed.
    """
    db = tmp_path / "t.duckdb"
    con = store.connect(db)
    store.init_db(con)
    assert not (tmp_path / "t.duckdb.wal").exists(), "init_db must checkpoint its migrations"

    # data written after init_db is checkpointable and survives a reopen
    store.upsert_ingest(con, pl.DataFrame({
        "fdc_id": [1], "data_type": ["sr_legacy_food"], "food_category": ["Beef"],
        "description": ["Beef, ground"], "fat_g": [20.0], "source_version": ["2025-04"],
    }))
    con.execute("CHECKPOINT")
    con.close()
    reopened = store.connect(db)
    assert reopened.execute("SELECT count(*) FROM foods").fetchone()[0] == 1


# --------------------------------------------------------------------------
# Stage 6b: merge / dedup
# --------------------------------------------------------------------------
def test_merge_key_normalizes_plurals_and_preparations():
    # plural collapses, preparation words drop: same food, one key
    assert merge.merge_key("Poached eggs") == merge.merge_key("Soft-boiled egg") == {"egg"}
    assert merge.merge_key("Whole raw egg") == {"egg"}
    # an added ingredient is a different key
    assert merge.merge_key("Egg omelette") != merge.merge_key("Poached eggs")
    # seasoning carries no macros, so it must not split a key
    assert merge.merge_key("Tilapia, seasoned with salt and pepper") == merge.merge_key("Tilapia")
    # word boundaries, not substrings: eggplant is not an egg
    assert "egg" not in merge.merge_key("Eggplant, raw")
    # fat levels are digits, which never reach the key
    assert merge.merge_key("Ground beef (70% lean)") == merge.merge_key("Ground beef (95% lean)")


def _merge_frame(rows):
    """(fdc_id, name, category, prep, protein, carb, fat[, fat_pct]) -> input frame."""
    return pl.DataFrame(
        [
            {"fdc_id": r[0], "display_name": r[1], "description": r[1],
             "food_category": r[2], "prep_type": r[3], "emoji": None,
             "protein_g": r[4], "carb_g": r[5], "fat_g": r[6],
             "fat_percentage": r[7] if len(r) > 7 else None}
            for r in rows
        ],
        schema={"fdc_id": pl.Int64, "display_name": pl.Utf8, "description": pl.Utf8,
                "food_category": pl.Utf8, "prep_type": pl.Utf8, "emoji": pl.Utf8,
                "protein_g": pl.Float64, "carb_g": pl.Float64, "fat_g": pl.Float64,
                "fat_percentage": pl.Float64},
    )


def test_merge_groups_preparations_but_not_added_ingredients():
    """Preparations of an egg are one item; an omelette's oil makes another."""
    merged, links = merge.build_merges(_merge_frame([
        (1, "Whole raw egg", "Dairy and Egg Products", "raw", 12.6, 0.7, 9.5),
        (2, "Poached egg", "Dairy and Egg Products", "cooked", 12.5, 0.7, 9.5),
        (3, "Fried egg, no added fat", "Dairy and Egg Products", "cooked", 13.6, 1.0, 11.0),
        # same base, but oil pushes the ratio well off the egg point
        (4, "Egg omelette with oil", "Dairy and Egg Products", "cooked", 11.0, 0.6, 22.0),
    ]))
    assert len(merged) == 2
    by_id = dict(zip(links["fdc_id"], links["merged_food_id"]))
    assert by_id[1] == by_id[2] == by_id[3]
    assert by_id[4] != by_id[1]
    # canonical name prefers the unprepared member over the shorter "Poached egg"
    egg = merged.filter(pl.col("merged_food_id") == by_id[1])
    assert egg["display_name"][0] == "Whole raw egg"
    assert egg["n_foods"][0] == 3
    assert not egg["variable_fat"][0]


def test_merge_collapses_fat_levels_and_marks_variable_fat():
    merged, links = merge.build_merges(_merge_frame([
        (1, "Ground beef (70% lean)", "Beef Products", "raw", 14.4, 0.0, 30.0, 30.0),
        (2, "Ground beef (95% lean)", "Beef Products", "raw", 21.4, 0.0, 5.0, 5.0),
        (3, "Ground beef", "Beef Products", None, 17.4, 0.0, 14.0, None),
    ]))
    assert len(merged) == 1
    assert merged["display_name"][0] == "Ground beef"
    assert merged["variable_fat"][0]
    assert merged["n_foods"][0] == 3
    assert set(links["fdc_id"]) == {1, 2, 3}


def test_fat_variant_path_needs_a_stated_fat_level():
    """A fried-in-oil egg must not merge into the raw egg group.

    It shares the {egg} block key and, like every near-zero-carb food, projects
    to ~1.0 on the fat-free basis — so the projection alone cannot tell it from
    a genuine fat level. Only the fat_percentage gate keeps the oil out.
    """
    merged, links = merge.build_merges(_merge_frame([
        (1, "Whole raw egg", "Dairy and Egg Products", "raw", 12.6, 0.7, 9.5),
        (2, "Fried egg", "Dairy and Egg Products", "cooked", 9.5, 0.7, 13.0),
    ]))
    assert len(merged) == 2, "added frying fat is a different ingredient, not a fat level"


def test_fat_variant_path_is_gated_to_meat_and_dairy():
    """The fat-free projection must not merge an added-fat vegetable back in."""
    merged, _ = merge.build_merges(_merge_frame([
        (1, "Carrots", "Vegetables and Vegetable Products", "raw", 0.9, 9.6, 0.2),
        (2, "Carrots with added fat", "Vegetables and Vegetable Products", "cooked", 0.8, 8.2, 6.0, 6.0),
    ]))
    assert len(merged) == 2


def test_merge_does_not_chain_across_blocks(con):
    """A chain of pairwise-close foods must not collapse into one group.

    Union-find over "ratio distance < threshold" takes the transitive closure
    of a non-transitive relation and swallows the whole corpus; this is the
    regression guard for that.
    """
    step = config.MERGE_DISTANCE * 0.6  # each neighbour is close, the ends are not
    rows = [
        (i + 1, f"Chain food {chr(97 + i) * 3}", "Vegetables and Vegetable Products", None,
         10.0 + i * step * 100, 90.0 - i * step * 100, 0.0)
        for i in range(8)
    ]
    merged, _ = merge.build_merges(_merge_frame(rows))
    # distinct names -> distinct blocks -> no group may span them
    assert int(merged["n_foods"].max()) == 1


def test_merge_run_is_idempotent(con):
    store.apply_enrichment(
        con, fdc_id=1, display_name="Ground beef", emoji="🥩", prep_type="raw",
        variable_fat=True, confidence=0.95, review_status="auto_approved",
    )
    con.execute(
        "INSERT INTO food_nutrients (fdc_id, nutrient_id, amount) VALUES "
        "(1, 1003, 17.4), (1, 1005, 0.0), (1, 1004, 20.0), "
        "(2, 1003, 2.0), (2, 1005, 8.5), (2, 1004, 15.0)"
    )
    first = merge.run(con)
    assert first["foods"] == 2 and first["merged_foods"] == 2 and first["linked"] == 2
    ids = con.execute("SELECT fdc_id, merged_food_id FROM foods ORDER BY fdc_id").fetchall()
    assert merge.run(con) == first
    assert con.execute("SELECT fdc_id, merged_food_id FROM foods ORDER BY fdc_id").fetchall() == ids
    # each food is its own group here, so the link points at itself
    assert ids == [(1, 1), (2, 2)]


def test_merge_members_lists_the_group_with_its_ratios(con):
    """The notebook's drill-down: a merged item -> the foods it merged from."""
    # same name, same macro ratio -> one group of two, something to drill into
    con.execute(
        "INSERT INTO food_nutrients (fdc_id, nutrient_id, amount) VALUES "
        "(1, 1003, 17.4), (1, 1005, 0.0), (1, 1004, 20.0), "
        "(2, 1003, 8.7), (2, 1005, 0.0), (2, 1004, 10.0)"
    )
    con.execute("UPDATE foods SET display_name = 'Ground beef'")
    merge.run(con)
    groups = store.merge_groups(con, min_size=2)
    assert len(groups) == 1 and groups["n_foods"][0] == 2

    members = store.merge_members(con, groups["merged_food_id"][0])
    assert members["fdc_id"].to_list() == [1, 2]  # canonical first
    assert members["canonical"].to_list() == [True, False]
    assert members["p"][0] == round(17.4 / 37.4, 3)
    # a food with no nutrient rows still shows up, just without a ratio
    con.execute("DELETE FROM food_nutrients WHERE fdc_id = 2")
    assert store.merge_members(con, groups["merged_food_id"][0])["p"][1] is None
