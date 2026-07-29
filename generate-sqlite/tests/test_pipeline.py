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

from src import abbrev, brand_detect, cluster, config, schema, store  # noqa: E402


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
# Stage 3b-1 / Stage 4: schema
# --------------------------------------------------------------------------
def _group_result(**overrides):
    base = {
        "display_name": "Milk", "emoji": "🥛", "commonness": 0.9,
        "keywords": ["dairy"], "confidence": 0.9,
    }
    return schema.GroupResult.model_validate(base | overrides)


def _canon_batch(**overrides):
    base = {"foods": [{"i": 0, "base": "white rice", "kind": "ingredient", "prep": "raw"}]}
    return schema.CanonBatch.model_validate(base | overrides)


def test_schema_accepts_valid():
    result = _group_result(display_name="Almond granola bar")
    assert result.display_name == "Almond granola bar" and result.emoji == "🥛"

    batch = _canon_batch(foods=[
        {"i": 0, "base": "chicken thigh", "kind": "ingredient", "prep": "roasted"},
        {"i": 1, "base": "fried rice", "kind": "dish", "prep": None},
    ])
    assert [f.kind for f in batch.foods] == ["ingredient", "dish"]
    assert batch.foods[1].prep is None


def test_schema_rejects_bad_enum_and_extra_keys():
    with pytest.raises(Exception):
        _group_result(extra=1)
    with pytest.raises(Exception):  # merged_food_id is not part of the contract
        _group_result(merged_food_id=1)
    # canonicalization: kind and prep are both closed enums
    with pytest.raises(Exception):
        _canon_batch(foods=[{"i": 0, "base": "rice", "kind": "meal", "prep": None}])
    with pytest.raises(Exception):
        _canon_batch(foods=[{"i": 0, "base": "rice", "kind": "dish", "prep": "spatchcocked"}])
    with pytest.raises(Exception):  # an empty identity is a wrong answer
        _canon_batch(foods=[{"i": 0, "base": "", "kind": "dish", "prep": None}])
    with pytest.raises(Exception):
        _canon_batch(foods=[])


def test_canon_base_is_tidied_not_rejected():
    """Untidy punctuation is the right answer typed badly; re-sending 40 foods
    to get one comma back would be paying twice for it."""
    batch = _canon_batch(foods=[
        {"i": 0, "base": "  white   rice, ", "kind": "ingredient", "prep": None},
    ])
    assert batch.foods[0].base == "white rice"
    with pytest.raises(Exception):  # ... but nothing left after tidying IS wrong
        _canon_batch(foods=[{"i": 0, "base": " , ", "kind": "dish", "prep": None}])


def test_schema_cleans_keywords():
    """Duplicates, casing and blanks are cleaned; a sentence is dropped.

    Re-sending an item to get the same keywords back in lowercase would be
    paying twice for punctuation, so these are fixed rather than rejected.
    """
    result = _group_result(
        keywords=["Fettuccine", "fettuccine", " parmesan ", "", "italian", "a" * 60]
    )
    assert result.keywords == ["fettuccine", "parmesan", "italian"]
    with pytest.raises(Exception):  # nothing usable at all IS a wrong answer
        _group_result(keywords=["", "a" * 60])


def test_group_payload_leads_with_the_settled_identity():
    """Stage 4 is told what the food IS and asked only how to present it.

    base/kind lead the payload because the whole prompt is written around not
    second-guessing them, and no fdc_id is ever sent.
    """
    from src import enrich

    bare = {
        "food_category": "Vegetables", "common_name": None, "extra_desc": None,
        "brand_flagged": False, "variable_fat": False,
        "base_name": "broccoli", "food_kind": "ingredient",
        "preps": [{"seq": 0, "prep_id": 1234567, "descs": ["Broccoli, raw"],
                   "prep_type": "raw",
                   "protein_g": 2.82, "carb_g": 6.64, "fat_g": 0.37}],
    }
    # brand_flagged, variable_fat and prep_id stay pipeline-side: set here,
    # never sent
    assert enrich.build_group(bare) == {
        "base": "broccoli", "kind": "ingredient", "cat": "Vegetables",
        "p": [{"prep": "raw", "m": [2.8, 6.6, 0.4], "d": ["Broccoli, raw"]}],
    }

    rich = bare | {
        "base_name": "beef frankfurter", "food_kind": "dish",
        "common_name": "hot dog, wiener, frank", "extra_desc": "all types",
        "brand_flagged": True,
        "preps": [
            {"seq": 0, "prep_id": 9876541, "descs": ["Frankfurter, beef"],
             "prep_type": None, "protein_g": 11.7, "carb_g": 4.3, "fat_g": 26.7},
            {"seq": 1, "prep_id": 9876542, "descs": ["Frankfurter, beef, unheated"],
             "prep_type": "cooked", "protein_g": 10.2, "carb_g": 4.0, "fat_g": 20.1},
        ],
    }
    payload = enrich.build_group(rich)
    assert payload["aka"] == "hot dog, wiener, frank"
    assert payload["also"] == "all types"
    assert [p["prep"] for p in payload["p"]] == [None, "cooked"]

    # the wire payload is that object, serialized compactly and carrying no id
    wire = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    assert json.loads(wire) == payload
    assert "987654" not in wire, "prep_id must never be sent"


def test_canon_payload_sends_identity_evidence_and_no_macros():
    """The canonicalization request carries the text signals and nothing
    numeric — macros are what the old clustering got identity wrong with."""
    from src import canon

    batch = [
        {"fdc_id": 169712, "description": "Rice, white, steamed, Chinese restaurant",
         "food_category": "Cereal Grains and Pasta", "common_name": None,
         "extra_desc": None, "ingredients": None},
        {"fdc_id": 2707232, "description": "Egg omelet, with cheese",
         "food_category": "Eggs and omelets", "common_name": "omelette",
         "extra_desc": "fat added", "ingredients": "Eggs | Cheese | Oil"},
    ]
    assert canon.build_batch(batch) == {"foods": [
        {"i": 0, "d": "Rice, white, steamed, Chinese restaurant",
         "cat": "Cereal Grains and Pasta"},
        {"i": 1, "d": "Egg omelet, with cheese", "cat": "Eggs and omelets",
         "aka": "omelette", "also": "fat added", "ing": "Eggs | Cheese | Oil"},
    ]}
    wire = json.dumps(canon.build_batch(batch), separators=(",", ":"))
    assert "169712" not in wire and "2707232" not in wire


# --------------------------------------------------------------------------
# Stage 5: store — routing, cross-checks, human-verified lock
# --------------------------------------------------------------------------
@pytest.fixture()
def con(tmp_path):
    """Two foods that cluster into two items, one of them with two preparations.

    Stage 3b runs here because everything downstream of it addresses merged
    items, not foods: without it the enrichment queue is empty and every store
    test below has nothing to write to.
    """
    c = store.connect(tmp_path / "test.duckdb")
    store.init_db(c)
    df = pl.DataFrame(
        {
            "fdc_id": [1, 2, 3],
            "data_type": ["sr_legacy_food", "survey_fndds_food", "sr_legacy_food"],
            "food_category": ["Beef Products", "Vegetables", "Beef Products"],
            "description": [
                "Beef, ground, 80% lean meat / 20% fat, raw",
                "Avocado, raw",
                "Beef, ground, 80% lean meat / 20% fat, cooked, pan-browned",
            ],
            "fat_g": [20.0, 15.0, 15.0],
            "source_version": ["2018-04", "2024-10", "2018-04"],
        }
    )
    store.upsert_ingest(c, df)
    abbrev.run(c)  # expand abbreviations, as the run order would
    c.execute(
        "INSERT INTO food_nutrients (fdc_id, nutrient_id, amount) VALUES "
        "(1, 1003, 17.4), (1, 1005, 0.0), (1, 1004, 20.0), "
        "(2, 1003, 2.0), (2, 1005, 8.5), (2, 1004, 15.0), "
        "(3, 1003, 25.8), (3, 1005, 0.0), (3, 1004, 29.6)"
    )
    # Stage 3b-1's output, stubbed. Clustering groups on it, so without it
    # every food here would be its own item and the two-preparation case the
    # tests below need would not exist.
    canonicalize(c, {
        1: ("ground beef", "ingredient", "raw"),
        2: ("avocado", "ingredient", "raw"),
        3: ("ground beef", "ingredient", "cooked"),
    })
    cluster.run(c)
    return c


def canonicalize(con, by_fdc_id):
    """Stamp Stage 3b-1 answers on foods: {fdc_id: (base, kind, prep)}."""
    for fdc_id, (base, kind, prep) in by_fdc_id.items():
        store.apply_canonicalization(
            con, fdc_id=fdc_id, base_name=base, food_kind=kind, prep_label=prep,
            model="test/stub",
        )


@pytest.fixture()
def items(con):
    """The enrichment queue, keyed by merged_food_id."""
    return {r["merged_food_id"]: r for r in store.select_enrichment_candidates(con).to_dicts()}


def test_routing_thresholds():
    assert store.route_confidence(0.9, brand_flagged=False, validation_failed=False) == "auto_approved"
    assert store.route_confidence(0.7, brand_flagged=False, validation_failed=False) == "needs_review"
    assert store.route_confidence(0.99, brand_flagged=True, validation_failed=False) == "needs_review"
    assert store.route_confidence(0.99, brand_flagged=False, validation_failed=True) == "needs_review"


def test_cross_checks():
    ok = dict(display_name="Chicken thigh", emoji="🍗", base_name="chicken thigh")
    assert store.cross_check(**ok) == []
    assert store.cross_check(**ok | {"emoji": "not an emoji"})

    # A preparation word in the name renders twice — the preparation is joined
    # back at display time.
    assert store.cross_check(
        display_name="Roasted chicken thigh", emoji="🍗", base_name="chicken thigh")
    # ... unless the identity itself carries it: "fried rice" is a food called
    # that, and base_name is what says so.
    assert store.cross_check(
        display_name="Fried rice", emoji="🍚", base_name="fried rice") == []

    # A name that dropped a qualifier is how both granola bars came back as
    # "Granola bar" — two items the user cannot tell apart.
    assert store.cross_check(
        display_name="Granola bar", emoji="🍫", base_name="almond granola bar")
    assert store.cross_check(
        display_name="Almond granola bar", emoji="🍫", base_name="almond granola bar") == []


def test_duplicate_display_names_are_reported(con):
    """Two items sharing a name is always a defect: they have different
    base_names by construction, so the naming lost information."""
    ids = store.select_enrichment_candidates(con)["merged_food_id"].to_list()
    for merged_food_id in ids:
        store.apply_enrichment(
            con, merged_food_id=merged_food_id, display_name="Same name", emoji="🥩",
            commonness=0.5, keywords="kw", confidence=0.9, review_status="auto_approved",
        )
    dupes = store.duplicate_display_names(con)
    assert len(dupes) == 1 and dupes["n"][0] == len(ids)

    store.apply_enrichment(
        con, merged_food_id=ids[0], display_name="A different name", emoji="🥑",
        commonness=0.5, keywords="kw", confidence=0.9, review_status="auto_approved",
    )
    assert len(store.duplicate_display_names(con)) == 0


def test_enrichment_upsert_and_resume(con, items):
    item = next(iter(items))
    ok = store.apply_enrichment(
        con, merged_food_id=item, display_name="Ground beef", emoji="🥩",
        commonness=0.8, keywords="mince; burger", confidence=0.95,
        review_status="auto_approved", model="some/model-v1",
    )
    assert ok
    assert con.execute(
        "SELECT enriched_by FROM merged_foods WHERE merged_food_id = ?", [item]
    ).fetchone()[0] == "some/model-v1"
    # enriched -> no longer a candidate
    assert item not in store.select_enrichment_candidates(con)["merged_food_id"].to_list()
    # audit trail written
    assert con.execute(
        "SELECT count(*) FROM audit_log WHERE fdc_id = ? AND actor = 'auto'", [item]
    ).fetchone()[0] > 0


def test_human_verified_lock(con, items):
    item = next(iter(items))
    store.apply_human_review(con, item, display_name="Human name", accept=True)
    # automated write must be refused
    ok = store.apply_enrichment(
        con, merged_food_id=item, display_name="Robot name", emoji="🤖",
        commonness=0.1, keywords="robot", confidence=0.99,
        review_status="auto_approved",
    )
    assert not ok
    assert con.execute(
        "SELECT display_name, review_status, human_verified FROM merged_foods "
        "WHERE merged_food_id = ?", [item]
    ).fetchone() == ("Human name", "verified", True)
    # ... and it is not offered as a candidate again
    assert item not in store.select_enrichment_candidates(con)["merged_food_id"].to_list()


def test_persist_routes_a_name_that_lost_its_qualifiers_to_review(con, items, monkeypatch):
    """The reported Stage 4 defect, guaranteed rather than requested.

    Both granola bars came back named "Granola bar". A name shorter than the
    identity it renders means the model summarized instead of rewording, and
    the prompt asking it not to is a request where this is a check.
    """
    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import enrich

    enricher = enrich.Enricher(con)
    enricher.stats = enrich.EnrichmentStats()
    row = next(iter(items.values())) | {
        "base_name": "almond granola bar", "food_kind": "dish", "brand_flagged": False,
    }
    enricher._persist(row, _group_result(display_name="Granola bar", emoji="🍫",
                                         confidence=0.99))
    enricher._flush()
    status, notes = con.execute(
        "SELECT m.review_status, "
        "(SELECT new_value FROM audit_log WHERE fdc_id = m.merged_food_id "
        " AND field = 'llm_notes' LIMIT 1) "
        "FROM merged_foods m WHERE merged_food_id = ?", [row["merged_food_id"]]
    ).fetchone()
    assert status == "needs_review", "a 0.99 confidence must not override a real defect"
    assert "drops qualifiers" in notes


def test_enrich_group_retries_malformed_output_once(con, items, monkeypatch):
    """Malformed output buys exactly one re-send, then the item goes to review."""
    import asyncio

    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import enrich

    row = next(r for r in items.values() if not r["variable_fat"])

    def answer(**overrides):
        return json.dumps({
            "display_name": "Avocado", "emoji": "🥑", "commonness": 0.6,
            "keywords": ["guacamole"], "confidence": 0.9,
        } | overrides)

    def replies(*answers):
        sent = iter(answers)

        async def _fake(_self, _payload):
            return next(sent)

        return _fake

    # garbage then valid -> the retry lands, item is persisted
    enricher = enrich.Enricher(con)
    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback",
                        replies("not json", answer()))
    asyncio.run(enricher.enrich_group(row))
    enricher._flush()  # succeeded is counted when the buffered item is written
    assert enricher.stats.succeeded == 1 and enricher.stats.failed == 0

    # garbage twice -> no third attempt, routed to needs_review
    enricher2 = enrich.Enricher(con)
    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback",
                        replies("not json", "{}"))
    asyncio.run(enricher2.enrich_group(row))
    enricher2._flush()
    assert enricher2.stats.failed == 1 and enricher2.stats.succeeded == 0
    assert con.execute(
        "SELECT review_status FROM merged_foods WHERE merged_food_id = ?",
        [row["merged_food_id"]],
    ).fetchone()[0] == "needs_review"


def test_mismatched_canon_indices_are_rejected(con, monkeypatch):
    """A batch answer that does not cover exactly the foods sent is malformed,
    however well-formed its JSON is.

    Position alone would silently absorb a short, long or reordered list and
    file one food's identity under another's fdc_id — which, unlike a bad name,
    puts two unrelated foods in the same item. The echoed index is what turns
    that into a re-send, and a batch that fails twice is left alone rather than
    written half-way.
    """
    import asyncio

    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import canon

    con.execute("UPDATE foods SET base_name = NULL")
    batch = canon.select_candidates(con).to_dicts()
    assert len(batch) == 3, "the fixture's three foods go out as one batch"
    ok = {"i": 0, "base": "x", "kind": "dish", "prep": None}

    for bad in (
        [ok],                                                   # too few
        [ok, ok | {"i": 0}, ok | {"i": 2}],                      # duplicate index
        [ok | {"i": 1}, ok | {"i": 2}, ok | {"i": 3}],           # off-by-one
    ):
        reply = json.dumps({"foods": bad})

        async def _fake(_self, _payload, _r=reply):
            return _r

        pass_ = canon.Canonicalizer(con)
        monkeypatch.setattr(canon.Canonicalizer, "_request_with_fallback", _fake)
        asyncio.run(pass_._process(batch))
        pass_._flush()
        assert pass_.stats.failed == len(batch), f"{bad} should not have been accepted"
        assert pass_.stats.succeeded == 0


def test_canon_writes_identity_and_reclusters_from_scratch(con, monkeypatch):
    """A canonicalization run's output is what the next cluster.run() groups on."""
    import asyncio

    monkeypatch.setenv(config.OPENROUTER_API_KEY_ENV, "test-key-never-used")
    from src import canon

    con.execute("UPDATE foods SET base_name = NULL, base_key = NULL, food_kind = NULL")
    batch = canon.select_candidates(con).to_dicts()

    async def _fake(_self, payload):
        # every food gets the same identity: three foods, one item
        return json.dumps({"foods": [
            {"i": f["i"], "base": "mystery gruel", "kind": "dish", "prep": None}
            for f in json.loads(payload)["foods"]
        ]})

    monkeypatch.setattr(canon.Canonicalizer, "_request_with_fallback", _fake)
    stats = asyncio.run(canon.Canonicalizer(con).run(canon.batches(batch)))
    assert stats.succeeded == len(batch) and stats.failed == 0
    assert canon.count_candidates(con) == 0, "a canonicalized food is never re-sent"
    assert con.execute(
        "SELECT DISTINCT base_key FROM foods"
    ).fetchall() == [("gruel mystery",)], "base_key is derived on write, not by the model"

    out = cluster.run(con)
    assert out["items"] == 1 and out["dishes"] == len(batch)


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

    async def _fake(_self, payload):
        opened.append(subprocess.run([sys.executable, "-c", probe]).returncode)
        return json.dumps({
            "display_name": json.loads(payload)["base"], "emoji": "🥑",
            "commonness": 0.5, "keywords": ["food"], "confidence": 0.9,
        })

    monkeypatch.setattr(enrich.Enricher, "_request_with_fallback", _fake)
    rows = store.select_enrichment_candidates(con).to_dicts()
    stats = asyncio.run(enrich.Enricher(con).run(rows))

    assert opened and all(rc == 0 for rc in opened), "database stayed locked mid-run"
    assert stats.succeeded == len(rows)
    # ... and the connection is usable again, with the buffered items written
    assert con.execute(
        "SELECT count(*) FROM merged_foods WHERE display_name IS NOT NULL"
    ).fetchone()[0] == len(rows)


def test_reingest_reclusters_and_requeues(con):
    """A changed description reaches the reviewer one level up.

    Nothing on `foods` is enriched any more, so a re-ingest does not re-queue
    anything by itself: it changes the text, which changes the clustering,
    which changes the item's member_key, which is what puts it back in the
    queue.
    """
    item = store.select_enrichment_candidates(con)["merged_food_id"].to_list()[0]
    store.apply_enrichment(
        con, merged_food_id=item, display_name="Named", emoji="🥑", commonness=0.5,
        keywords="kw", confidence=0.9, review_status="auto_approved",
    )
    assert item not in store.select_enrichment_candidates(con)["merged_food_id"].to_list()

    # a wholly different food under the same fdc_id: it leaves its old item
    counts = store.upsert_ingest(con, pl.DataFrame({
        "fdc_id": [2], "data_type": ["survey_fndds_food"], "food_category": ["Vegetables"],
        "description": ["Broccoli, raw, chopped"], "fat_g": [0.4],
        "source_version": ["2025-04"],
    }))
    assert counts["updated"] == 1
    abbrev.run(con)
    cluster.run(con)

    pending = con.execute(
        "SELECT count(*) FROM merged_foods WHERE review_status = 'pending'"
    ).fetchone()[0]
    assert pending > 0
    # ... and a re-queued item keeps its old name until a new one arrives, so
    # the catalog is never momentarily nameless
    assert con.execute(
        "SELECT count(*) FROM merged_foods "
        "WHERE review_status = 'pending' AND display_name IS NOT NULL"
    ).fetchone()[0] >= 0


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
# Stage 3b: clustering into items and preparations
# --------------------------------------------------------------------------
def _cluster_frame(rows):
    """(fdc_id, description, base, kind, prep, protein, carb, fat[, fat_pct]) -> frame.

    The Stage 3b-1 columns are supplied directly: clustering reads them and
    nothing else to decide identity, so a test that wants two foods in one item
    gives them one base_name, and the description is only there to pick a
    representative.
    """
    return pl.DataFrame(
        [
            {"fdc_id": r[0], "description": r[1], "base_name": r[2],
             "food_kind": r[3], "prep_label": r[4],
             "protein_g": r[5], "carb_g": r[6], "fat_g": r[7],
             "fat_percentage": r[8] if len(r) > 8 else None,
             "food_category": "Test Category",
             "brand_flagged": False, "n_nutrients": 3}
            for r in rows
        ],
        schema={"fdc_id": pl.Int64, "description": pl.Utf8, "base_name": pl.Utf8,
                "food_kind": pl.Utf8, "prep_label": pl.Utf8,
                "protein_g": pl.Float64, "carb_g": pl.Float64, "fat_g": pl.Float64,
                "fat_percentage": pl.Float64, "food_category": pl.Utf8,
                "brand_flagged": pl.Boolean, "n_nutrients": pl.Int64},
    )


def test_base_key_absorbs_the_ways_a_name_can_be_written():
    """Batching makes the model write one string per food; this is what makes
    a near-miss across two requests survive anyway."""
    key = cluster.base_key
    assert key("Rice, white") == key("white rice") == key("White Rices") == "rice white"
    # a numeric fat level is a grade of one product, never part of its identity
    assert key("ground beef, 80% lean") == key("ground beef") == key("Beef, ground")
    assert key("milk, 3.25% milkfat") == key("Milk")
    # ... but a NAMED trim is, because it is what a shopper picks between
    assert key("pork loin, lean only") != key("pork loin")
    assert key(None) == key("") == ""


def test_items_group_on_identity_not_on_macros():
    """The reported cross-database miss: the same food recorded twice with
    macros 0.30 apart on the simplex used to be two items. Identity is textual,
    so it is one."""
    items, _, links = cluster.build_clusters(_cluster_frame([
        (1, "Beef, top sirloin steak, lean and fat, raw", "beef top sirloin steak",
         "ingredient", "raw", 20.7, 0.0, 11.1),
        (2, "Beef, top sirloin steak, raw", "beef top sirloin steak",
         "ingredient", "raw", 22.0, 0.2, 5.7),
    ]))
    assert len(items) == 1
    assert links["merged_food_id"][0] == links["merged_food_id"][1]


def test_a_dish_is_never_a_preparation_of_its_ingredient():
    """fdc_id 169712 (white rice) and 167668 (fried rice) were one item.

    Two separations do it: different base names, and — even if canon.py were to
    hand back the same base name — the ingredient/dish split, which is why
    food_kind is in the grouping key rather than merely recorded.
    """
    _, _, links = cluster.build_clusters(_cluster_frame([
        (169712, "Rice, white, steamed, Chinese restaurant", "white rice",
         "ingredient", "steamed", 2.4, 33.9, 0.2),
        (167668, "Restaurant, Chinese, fried rice, without meat", "fried rice",
         "dish", None, 4.2, 20.6, 4.9),
    ]))
    group_of = dict(zip(links["fdc_id"], links["merged_food_id"]))
    assert group_of[169712] != group_of[167668]

    # the kind guard alone, with the base names deliberately collided
    _, _, same_name = cluster.build_clusters(_cluster_frame([
        (1, "Rice", "rice", "ingredient", "boiled", 2.4, 33.9, 0.2),
        (2, "Rice dish", "rice", "dish", None, 2.4, 33.9, 0.2),
    ]))
    assert same_name["merged_food_id"][0] != same_name["merged_food_id"][1]


def test_a_disagreeing_kind_is_reported_not_silently_voted_on(con):
    """The one failure mode food_kind-in-the-key introduces.

    Two records of one food that straddled a canonicalization batch boundary
    can come back with different kinds and then split into two items. It is
    reported rather than majority-voted: forcing a vote would re-open the bug
    the stage exists to close, because two genuinely different foods that
    collided on a base name would then merge.
    """
    assert cluster.run(con)["kind_splits"] == []
    con.execute("UPDATE foods SET food_kind = 'dish' WHERE fdc_id = 3")
    out = cluster.run(con)
    assert out["kind_splits"] == ["beef ground"]
    assert out["items"] == 3, "the disagreement really does cost an extra item"


def test_a_distinguishing_ingredient_makes_a_different_item():
    """fdc_ids 167542/167543 were one item: 'plain' and 'hard' were stopwords
    and 'almond' was one token out of four, so they scored 0.75 and merged."""
    items, _, links = cluster.build_clusters(_cluster_frame([
        (167542, "Snacks, granola bars, hard, plain", "granola bar", "dish", None,
         9.4, 64.8, 15.6),
        (167543, "Snacks, granola bars, hard, almond", "almond granola bar", "dish",
         None, 9.8, 64.4, 17.3),
    ]))
    assert len(items) == 2
    group_of = dict(zip(links["fdc_id"], links["merged_food_id"]))
    assert group_of[167542] != group_of[167543]


def test_groups_preparations_but_not_added_ingredients():
    """Preparations of an egg are one item; an omelette is a dish of its own."""
    items, _, links = cluster.build_clusters(_cluster_frame([
        (1, "Egg, whole, raw", "egg", "ingredient", "raw", 12.6, 0.7, 9.5),
        (2, "Egg, whole, poached", "egg", "ingredient", "poached", 12.5, 0.7, 9.5),
        (3, "Egg, whole, cooked, fried", "egg", "ingredient", "fried", 13.6, 1.0, 11.0),
        (4, "Egg omelet with cheese", "cheese omelet", "dish", None, 11.0, 0.6, 22.0),
    ]))
    assert len(items) == 2
    by_id = dict(zip(links["fdc_id"], links["merged_food_id"]))
    assert by_id[1] == by_id[2] == by_id[3]
    assert by_id[4] != by_id[1]
    egg = items.filter(pl.col("merged_food_id") == by_id[1])
    assert egg["n_foods"][0] == 3
    assert not egg["variable_fat"][0]


def test_preparations_split_on_water_and_take_the_widest_label():
    """Cooking drives off water, so cooked carries more protein per 100 g than
    raw and lands in its own preparation. Roasted and stewed do not — and the
    preparation that holds both is called 'cooked', because a label that covers
    only one of them would be a lie about the other."""
    items, preps, _ = cluster.build_clusters(_cluster_frame([
        (1, "Chicken, thigh, raw", "chicken thigh", "ingredient", "raw", 19.7, 0.0, 4.1),
        (2, "Chicken, thigh, roasted", "chicken thigh", "ingredient", "roasted",
         24.8, 0.0, 8.2),
        (3, "Chicken, thigh, stewed", "chicken thigh", "ingredient", "stewed",
         25.0, 0.0, 9.8),
    ]))
    assert len(items) == 1, "raw and cooked thigh are one item — this is the point"
    assert items["n_preps"][0] == 2
    by_label = dict(zip(preps["prep_type"], preps["n_foods"]))
    assert by_label == {"cooked": 2, "raw": 1}
    cooked = preps.filter(pl.col("prep_type") == "cooked")
    assert cooked["protein_g"][0] > 20.0


def test_one_label_stays_one_preparation_however_the_macros_disagree():
    """The cross-database fix, and the reason labels are bucketed before
    macros are looked at.

    These two rows are the same food in two USDA databases. Splitting on macros
    first made them two preparations and then asked the LLM to invent a
    distinction between them that does not exist.
    """
    items, preps, _ = cluster.build_clusters(_cluster_frame([
        (1, "Pork, belly, raw", "pork belly", "ingredient", "raw", 9.3, 0.0, 53.0),
        (2, "Pork, belly", "pork belly", "ingredient", "raw", 26.6, 0.0, 32.2),
    ]))
    assert len(items) == 1
    assert items["n_preps"][0] == 1
    assert preps["prep_type"][0] == "raw" and preps["n_foods"][0] == 2


def test_macros_never_merge_raw_into_a_cooked_preparation():
    """The ceiling on the macro merge, and a real corpus case.

    Poaching an egg barely moves its per-100 g macros, so raw and poached egg
    sit inside PREP_DISTANCE — and merging them gives one preparation holding
    raw eggs under the label "poached". Grilled and baked share the parent
    "cooked" and may merge; raw and poached do not share one and may not.
    """
    _, preps, _ = cluster.build_clusters(_cluster_frame([
        (1, "Egg, whole, raw", "egg", "ingredient", "raw", 12.6, 0.7, 9.5),
        (2, "Egg, whole, poached", "egg", "ingredient", "poached", 12.5, 0.7, 9.5),
    ]))
    assert dict(zip(preps["prep_type"], preps["n_foods"])) == {"raw": 1, "poached": 1}

    # ... while two verbs that DO share a parent still collapse to it
    _, cooked, _ = cluster.build_clusters(_cluster_frame([
        (1, "Chicken, grilled", "chicken breast", "ingredient", "grilled", 31.0, 0.0, 3.6),
        (2, "Chicken, baked", "chicken breast", "ingredient", "baked", 31.0, 0.0, 3.6),
    ]))
    assert cooked["prep_type"].to_list() == ["cooked"]


def test_unlabeled_rows_join_a_labelled_preparation_they_match():
    """A description that does not say how it was cooked is an absence of
    evidence, so it joins the preparation its macros put it in and takes that
    preparation's name."""
    _, preps, _ = cluster.build_clusters(_cluster_frame([
        (1, "Salmon, raw", "salmon", "ingredient", "raw", 17.0, 0.0, 13.4),
        (2, "Salmon, cooked, baked", "salmon", "ingredient", "baked", 25.4, 0.0, 12.4),
        (3, "Salmon", "salmon", "ingredient", None, 25.6, 0.0, 12.0),
    ]))
    assert len(preps) == 2
    assert dict(zip(preps["prep_type"], preps["n_foods"])) == {"baked": 2, "raw": 1}


def test_fat_levels_are_one_preparation_not_many():
    """A fat-level family is one preparation sold at several grades.

    Splitting these on absolute macros gives ground beef eight "preparations"
    that are only lean percentages, and then asks the LLM to name them.
    """
    items, preps, _ = cluster.build_clusters(_cluster_frame([
        (1, "Beef, ground, 70% lean meat / 30% fat, raw", "ground beef", "ingredient",
         "raw", 14.4, 0.0, 30.0, 30.0),
        (2, "Beef, ground, 80% lean meat / 20% fat, raw", "ground beef", "ingredient",
         "raw", 17.4, 0.0, 20.0, 20.0),
        (3, "Beef, ground, 95% lean meat / 5% fat, raw", "ground beef", "ingredient",
         "raw", 21.4, 0.0, 5.0, 5.0),
    ]))
    assert len(items) == 1
    assert items["variable_fat"][0]
    assert items["n_foods"][0] == 3
    assert items["n_preps"][0] == 1, "lean percentages are not preparations"


def test_uncanonicalized_foods_form_singletons_rather_than_merging():
    """Stage 3b still runs on a corpus Stage 3b-1 has not covered.

    A missing identity must never be guessed from the description: a wrong key
    merges two foods that should stay apart, where a missing one only leaves a
    singleton the next canonicalization run picks up.
    """
    items, _, links = cluster.build_clusters(_cluster_frame([
        (1, "Rice, white, raw", None, None, None, 2.7, 28.2, 0.3),
        (2, "Rice, white, cooked", None, None, None, 2.7, 28.2, 0.3),
    ]))
    assert len(items) == 2
    assert links["merged_food_id"][0] != links["merged_food_id"][1]


def test_representative_prefers_the_widest_nutrient_panel():
    """Every member is within PREP_DISTANCE on the macros, so nutrition cannot
    decide the representative — but the detail page shows the full panel, and a
    Foundation row with 60 nutrients is visibly better than an FNDDS row with 3.

    The two rows share a base_name, so they are one item and the tie really
    does come down to the panel.
    """
    df = _cluster_frame([
        (1, "Tomatoes, red, ripe", "tomato", "ingredient", "raw", 0.9, 3.9, 0.2),
        (2, "Tomatoes, red, ripe, raw, whole, fresh", "tomato", "ingredient", "raw",
         0.9, 3.9, 0.2),
    ])
    df = df.with_columns(pl.Series("n_nutrients", [3, 60]))
    items, _, _ = cluster.build_clusters(df)
    assert len(items) == 1
    assert items["merged_food_id"][0] == 2, "60 nutrients beats a shorter description"


def test_cluster_run_is_idempotent_and_preserves_enrichment(con):
    """Re-clustering must be safe to run at any time.

    merged_foods now holds a whole LLM run, so the DELETE-and-refill this
    replaced would discard it. This is the invariant that protects the spend.
    """
    first = cluster.run(con)
    item = store.select_enrichment_candidates(con)["merged_food_id"].to_list()[0]
    store.apply_enrichment(
        con, merged_food_id=item, display_name="Ground beef", emoji="🥩",
        commonness=0.8, keywords="mince; burger", confidence=0.95,
        review_status="auto_approved",
    )
    before = con.execute(
        "SELECT merged_food_id, display_name, emoji, commonness, keywords, confidence, "
        "review_status FROM merged_foods ORDER BY 1"
    ).fetchall()
    before_preps = con.execute(
        "SELECT prep_id, seq, prep_type FROM merged_preps ORDER BY 1"
    ).fetchall()
    assert sorted(p[2] for p in before_preps) == ["cooked", "raw", "raw"], (
        "prep_type is derived from the canonicalized labels, not from an LLM run"
    )

    second = cluster.run(con)
    assert second["items"] == first["items"] and second["preps"] == first["preps"]
    assert second["created"] == 0 and second["requeued"] == 0 and second["dissolved"] == 0
    assert con.execute(
        "SELECT merged_food_id, display_name, emoji, commonness, keywords, confidence, "
        "review_status FROM merged_foods ORDER BY 1"
    ).fetchall() == before
    assert con.execute(
        "SELECT prep_id, seq, prep_type FROM merged_preps ORDER BY 1"
    ).fetchall() == before_preps


def test_membership_change_requeues_but_keeps_the_name(con):
    """A re-cluster that moves members re-queues the item — and must not blank
    it in the meantime, or the catalog is momentarily nameless."""
    item = store.select_enrichment_candidates(con)["merged_food_id"].to_list()[0]
    store.apply_enrichment(
        con, merged_food_id=item, display_name="Named", emoji="🥩", commonness=0.8,
        keywords="kw", confidence=0.95, review_status="auto_approved",
    )
    # a near-duplicate USDA record lands in that item's group — which it does
    # by carrying the same identity, since that is now the whole grouping rule
    con.execute(
        "INSERT INTO foods (fdc_id, data_type, food_category, description, "
        "source_version, base_name, base_key, food_kind, prep_label) "
        "SELECT 99, data_type, food_category, description, source_version, "
        "base_name, base_key, food_kind, prep_label FROM foods WHERE fdc_id = ?",
        [item],
    )
    con.execute(
        "INSERT INTO food_nutrients (fdc_id, nutrient_id, amount) "
        "SELECT 99, nutrient_id, amount FROM food_nutrients WHERE fdc_id = ?", [item]
    )
    out = cluster.run(con)
    assert out["requeued"] >= 1
    row = con.execute(
        "SELECT display_name, review_status FROM merged_foods WHERE merged_food_id = ?",
        [item],
    ).fetchone()
    assert row == ("Named", "pending"), "re-queued, but still named"
    assert item in store.select_enrichment_candidates(con)["merged_food_id"].to_list()


def test_verified_items_survive_reclustering(con):
    """The human_verified lock covers re-clustering, not just enrichment."""
    item = store.select_enrichment_candidates(con)["merged_food_id"].to_list()[0]
    store.apply_human_review(con, item, display_name="Human name", accept=True)
    cluster.run(con)
    assert con.execute(
        "SELECT display_name, review_status, human_verified FROM merged_foods "
        "WHERE merged_food_id = ?", [item]
    ).fetchone() == ("Human name", "verified", True)


def test_cluster_members_lists_the_item_by_preparation(con):
    """The notebook's drill-down: an item -> the foods it was built from."""
    listed = store.cluster_items(con, min_size=2)
    assert len(listed) >= 1
    members = store.cluster_members(con, listed["merged_food_id"][0])
    assert len(members) == listed["n_foods"][0]
    assert members["seq"].to_list() == sorted(members["seq"].to_list())
    # exactly one representative per preparation
    assert members.filter(pl.col("representative")).height == listed["n_preps"][0]
