"""Stage 5 — DuckDB persistence: upserts, human-verified lock, audit log.

DuckDB (data/foods.duckdb) is the single source of truth; in-memory frames
are always transient. Invariants enforced here:

* Automated passes NEVER write rows where ``human_verified = true``. The
  lock is enforced both in the WHERE clause of every automated UPDATE and by
  pre-checks, so no caller can bypass it accidentally.
* Every write appends to ``audit_log`` (actor 'auto' or 'human').
* Confidence routing and validation cross-checks live here + config.
"""
from __future__ import annotations

import json
from contextlib import contextmanager
from pathlib import Path

import duckdb
import polars as pl

from . import abbrev
from . import config
from . import schema

DDL = """
CREATE TABLE IF NOT EXISTS foods (
    fdc_id BIGINT PRIMARY KEY,
    data_type TEXT NOT NULL,
    food_category TEXT,
    description TEXT NOT NULL,
    display_name TEXT,
    emoji TEXT,
    prep_type TEXT,
    fat_percentage DOUBLE,
    variable_fat BOOLEAN,
    brand_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    confidence DOUBLE,
    commonness DOUBLE,
    keywords TEXT,
    review_status TEXT NOT NULL DEFAULT 'pending',
    human_verified BOOLEAN NOT NULL DEFAULT FALSE,
    source_version TEXT,
    fat_g DOUBLE,
    enriched_by TEXT,
    enriched_reasoning TEXT,
    publication_date DATE,
    ndb_number TEXT,
    food_code TEXT,
    wweia_category_number TEXT,
    start_date DATE,
    end_date DATE,
    usda_footnote TEXT,
    updated_at TIMESTAMP NOT NULL DEFAULT current_timestamp
);

-- migrations for databases created before these columns existed
ALTER TABLE foods ADD COLUMN IF NOT EXISTS emoji TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS enriched_by TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS enriched_reasoning TEXT;
ALTER TABLE foods DROP COLUMN IF EXISTS enriched_batch_size;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS publication_date DATE;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS ndb_number TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS food_code TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS wweia_category_number TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS end_date DATE;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS usda_footnote TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS commonness DOUBLE;
-- Stage 4c search keywords, '; '-joined like the USDA synonyms they join in FTS.
ALTER TABLE foods ADD COLUMN IF NOT EXISTS keywords TEXT;
-- Stage 6b: which merged_foods item this food is a variant/preparation of.
ALTER TABLE foods ADD COLUMN IF NOT EXISTS merged_food_id BIGINT;

-- Stage 6b output: one row per distinct food, with its preparations and fat
-- levels hanging off it via foods.merged_food_id. Derived and idempotent —
-- CREATE OR REPLACE-d wholesale on every run, like the app_* tables.
--
-- merged_food_id IS the canonical member's fdc_id rather than a surrogate:
-- nothing to sequence, and an id stays put across re-runs as long as the
-- canonical member does. There is no preparations table because there is
-- nothing to put in one — a preparation is a foods row that already carries
-- its own prep_type and its own food_nutrients.
CREATE TABLE IF NOT EXISTS merged_foods (
    merged_food_id BIGINT PRIMARY KEY,
    display_name TEXT NOT NULL,
    emoji TEXT,
    food_category TEXT,
    -- true when the group was formed across fat levels (ground beef 70% .. 97%
    -- lean, milk whole .. skim) rather than at one point in the simplex.
    variable_fat BOOLEAN NOT NULL DEFAULT FALSE,
    n_foods INTEGER NOT NULL,
    protein_ratio DOUBLE,
    carb_ratio DOUBLE,
    fat_ratio DOUBLE,
    updated_at TIMESTAMP NOT NULL DEFAULT current_timestamp
);

-- Child tables: verbatim USDA mirrors, one row per (food, nutrient/portion/...).
-- Not covered by the human_verified lock and not audited: nobody hand-edits a
-- nutrient value, and gating raw facts behind the lock would leave verified
-- foods stuck with stale nutrition after a re-release.
CREATE TABLE IF NOT EXISTS food_nutrients (
    fdc_id BIGINT NOT NULL,
    nutrient_id BIGINT NOT NULL,
    nutrient_name TEXT,
    unit_name TEXT,
    nutrient_rank DOUBLE,
    amount DOUBLE,
    PRIMARY KEY (fdc_id, nutrient_id)
);

-- Only measures of one are ingested (see ingest._load_portions), so there is
-- no amount column: every row is "one <measure_unit/modifier/description>".
CREATE TABLE IF NOT EXISTS food_portions (
    fdc_id BIGINT NOT NULL,
    seq_num BIGINT,
    measure_unit TEXT,
    portion_description TEXT,
    modifier TEXT,
    gram_weight DOUBLE,
    data_points BIGINT,
    footnote TEXT
);

CREATE TABLE IF NOT EXISTS food_attributes (
    fdc_id BIGINT NOT NULL,
    seq_num BIGINT,
    attribute_type TEXT,
    name TEXT,
    value TEXT
);

CREATE TABLE IF NOT EXISTS input_foods (
    fdc_id BIGINT NOT NULL,
    seq_num BIGINT,
    fdc_of_input_food BIGINT,
    amount DOUBLE,
    ingredient_code TEXT,
    ingredient_description TEXT,
    unit TEXT,
    portion_description TEXT,
    gram_weight DOUBLE,
    retention_code TEXT
);

CREATE TABLE IF NOT EXISTS audit_log (
    fdc_id BIGINT NOT NULL,
    field TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    actor TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT current_timestamp,
    source_version TEXT
);

CREATE TABLE IF NOT EXISTS cleanup_log (
    fdc_id BIGINT NOT NULL,
    rule TEXT NOT NULL,
    old_text TEXT,
    new_text TEXT,
    timestamp TIMESTAMP NOT NULL DEFAULT current_timestamp
);
"""


def pivot_columns_sql(nutrients: dict[str, tuple[int, ...]]) -> str:
    """SELECT-list that pivots the long food_nutrients table into one column
    per nutrient, for use under a ``GROUP BY fdc_id``.

    Each nutrient coalesces its fallback ids in the order config lists them,
    because USDA records the same quantity under several ids and no single one
    covers the whole corpus. Stage 7 (appdb) builds the wide app table from
    this; passing a dict rather than reading config directly keeps it testable
    with a two-entry fixture.
    """
    return ", ".join(
        "coalesce({}) AS {}".format(
            ", ".join(f"max(amount) FILTER (WHERE nutrient_id = {int(n)})" for n in ids),
            name,
        )
        for name, ids in nutrients.items()
    )

# Per-food USDA metadata carried straight through from the archives.
USDA_METADATA_COLS = (
    "publication_date",
    "ndb_number",
    "food_code",
    "wweia_category_number",
    "start_date",
    "end_date",
    "usda_footnote",
)

# ingest.load_frames key -> destination table, for the Stage 1 child upsert.
CHILD_TABLES = {
    "nutrients": "food_nutrients",
    "portions": "food_portions",
    "attributes": "food_attributes",
    "input_foods": "input_foods",
}


# The file database is ATTACHed to an in-memory root rather than opened
# directly, which is what makes unlocked() possible: the file lock is
# exclusive and process-wide for as long as the file is attached, so a
# long-running phase that touches no tables (a whole LLM run, or the user
# hand-editing the database in a DuckDB shell) would otherwise be locked out
# by a connection that is merely open. A directly-opened database cannot be
# detached; an attached one can, without tearing down the connection object
# every notebook cell holds.
DB_ALIAS = "foods_db"


def _attach(con: duckdb.DuckDBPyConnection, db_path: Path | str) -> None:
    con.execute(f"ATTACH '{db_path}' AS {DB_ALIAS}")
    con.execute(f"USE {DB_ALIAS}")


def _detach(con: duckdb.DuckDBPyConnection) -> None:
    con.execute("USE memory")  # cannot detach the current database
    con.execute(f"DETACH {DB_ALIAS}")


def attached_path(con: duckdb.DuckDBPyConnection) -> str | None:
    """Path of the attached database file, or None while it is detached."""
    row = con.execute(
        "SELECT path FROM duckdb_databases() WHERE database_name = ?", [DB_ALIAS]
    ).fetchone()
    return row[0] if row else None


@contextmanager
def unlocked(con: duckdb.DuckDBPyConnection):
    """Release the file lock for the body; re-attach on the way out.

    Yields the path, which :func:`locked` needs to take the lock back for a
    write. DETACH checkpoints and closes the file, so what is released is a
    consistent database, not a WAL another process has to replay.
    """
    path = attached_path(con)
    _detach(con)
    try:
        yield path
    finally:
        _attach(con, path)


@contextmanager
def locked(con: duckdb.DuckDBPyConnection, db_path: str):
    """Hold the file lock for the body only, releasing it again afterwards.

    A no-op when the database is already attached, so the same write path works
    both inside an :func:`unlocked` phase and in a plain connected session.
    """
    if attached_path(con) is not None:
        yield
        return
    _attach(con, db_path)
    try:
        yield
    finally:
        _detach(con)


def connect(db_path: Path | str = config.DB_PATH) -> duckdb.DuckDBPyConnection:
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()
    # DuckDB only checkpoints on clean close or once the WAL passes this
    # threshold (default 16MB). A notebook kernel that gets killed never closes
    # cleanly, so everything since the last checkpoint is left in the WAL — and
    # a WAL is not something to rely on here (see init_db). 4MB bounds the loss
    # to roughly 1k enriched rows instead of a whole run.
    con.execute("SET checkpoint_threshold = '4MB'")
    _attach(con, db_path)
    return con


def _migrate_single_description(con: duckdb.DuckDBPyConnection) -> None:
    """Collapse original_description/cleaned_description into one column.

    Stage 2 used to store a normalized copy alongside the raw text. It now
    expands abbreviations into ``description`` in place, so the raw column is
    renamed (it keeps the true source casing, which the old cleaned column had
    destroyed) and the normalized copy is dropped. Re-run stage 2 afterwards to
    re-apply expansions. Idempotent: a no-op once migrated.
    """
    cols = {r[0] for r in con.execute("DESCRIBE foods").fetchall()}
    if "original_description" in cols:
        con.execute("ALTER TABLE foods RENAME COLUMN original_description TO description")
    if "cleaned_description" in cols:
        con.execute("ALTER TABLE foods DROP COLUMN cleaned_description")


def _migrate_drop_portion_amount(con: duckdb.DuckDBPyConnection) -> None:
    """Drop food_portions.amount, keeping only the measures of one.

    Stage 1 used to ingest every portion and store its amount. It now ingests
    only measures of one, which makes the column constant. Applying the same
    filter here saves a full re-ingest; it has to run BEFORE the column is
    dropped, because afterwards a "2 waffles" row is indistinguishable from a
    "1 waffle" one. Idempotent: a no-op once migrated.
    """
    if "amount" not in {r[0] for r in con.execute("DESCRIBE food_portions").fetchall()}:
        return
    # coalesce, because NOT (NULL OR FALSE) is NULL, not TRUE: without it every
    # FNDDS row whose text carries no count ('Quantity not specified') survives.
    con.execute(
        "DELETE FROM food_portions WHERE NOT coalesce("
        "amount = 1 OR (amount IS NULL AND portion_description LIKE '1 %'), false)"
    )
    # FNDDS puts its numeric measure code in modifier, not display text.
    con.execute("UPDATE food_portions SET modifier = NULL WHERE regexp_matches(modifier, '^\\d+$')")
    con.execute("ALTER TABLE food_portions DROP COLUMN amount")


def init_db(con: duckdb.DuckDBPyConnection) -> None:
    con.execute(DDL)
    _migrate_single_description(con)
    _migrate_drop_portion_amount(con)
    # The old food_macros view is superseded by the wide app_food_nutrition
    # table that appdb.build materializes; it re-scanned all 1M nutrient rows
    # on every read.
    con.execute("DROP VIEW IF EXISTS food_macros")
    # Force the schema into the main file before any data is written on top.
    #
    # DuckDB (1.5.4) cannot replay a WAL containing an ALTER TABLE on a table
    # that has a function-valued DEFAULT — foods.updated_at is
    # `DEFAULT current_timestamp`, and replaying the ALTER re-binds that
    # default through a catalog that isn't attached yet, which aborts replay
    # with an internal error and strands *every* write in that WAL. The ALTERs
    # above run on every startup, so without this checkpoint one killed kernel
    # can cost a whole enrichment run. Checkpointing here keeps schema changes
    # and data in separate WAL generations; a data-only WAL replays fine.
    con.execute("CHECKPOINT")


def _audit(
    con: duckdb.DuckDBPyConnection,
    fdc_id: int,
    field: str,
    old_value,
    new_value,
    actor: str,
    source_version: str | None,
) -> None:
    con.execute(
        "INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        [
            fdc_id,
            field,
            None if old_value is None else str(old_value),
            None if new_value is None else str(new_value),
            actor,
            source_version,
        ],
    )


# --------------------------------------------------------------------------
# Stage 1: ingest upsert
# --------------------------------------------------------------------------
def upsert_ingest(con: duckdb.DuckDBPyConnection, df: pl.DataFrame) -> dict:
    """Set-based upsert of the ingested foods frame.

    * New fdc_ids are inserted with review_status='pending'.
    * Existing NON-verified rows whose source data changed are updated and
      reset to 'pending' (so they get re-expanded/re-enriched), with audit
      entries per changed field.
    * Rows with human_verified=true are never touched.
    """
    con.register("incoming", df)

    # USDA metadata columns are carried through when the frame supplies them.
    # They stay out of the change-detection predicate below on purpose: any
    # re-release also bumps source_version, which already triggers the update.
    meta = [c for c in USDA_METADATA_COLS if c in df.columns]

    inserted = con.execute(
        "SELECT count(*) FROM incoming i LEFT JOIN foods f USING (fdc_id) WHERE f.fdc_id IS NULL"
    ).fetchone()[0]
    changed = con.execute(
        """
        SELECT count(*) FROM foods f JOIN incoming i USING (fdc_id)
        WHERE NOT f.human_verified
          AND (f.description IS DISTINCT FROM i.description
               OR f.source_version IS DISTINCT FROM i.source_version
               OR f.food_category IS DISTINCT FROM i.food_category)
        """
    ).fetchone()[0]
    locked = con.execute(
        "SELECT count(*) FROM foods f JOIN incoming i USING (fdc_id) WHERE f.human_verified"
    ).fetchone()[0]

    # audit changed fields on non-verified existing rows
    for field in ("description", "food_category", "source_version"):
        con.execute(
            f"""
            INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
            SELECT f.fdc_id, '{field}', f.{field}, i.{field}, 'auto', i.source_version
            FROM foods f JOIN incoming i USING (fdc_id)
            WHERE NOT f.human_verified AND f.{field} IS DISTINCT FROM i.{field}
            """
        )

    con.execute(
        f"""
        UPDATE foods SET
            data_type = i.data_type,
            food_category = i.food_category,
            description = i.description,
            fat_g = i.fat_g,
            source_version = i.source_version,
            {"".join(f"{c} = i.{c}, " for c in meta)}
            review_status = 'pending',
            updated_at = current_timestamp
        FROM incoming i
        WHERE foods.fdc_id = i.fdc_id
          AND NOT foods.human_verified
          AND (foods.description IS DISTINCT FROM i.description
               OR foods.source_version IS DISTINCT FROM i.source_version
               OR foods.food_category IS DISTINCT FROM i.food_category)
        """
    )

    con.execute(
        """
        INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
        SELECT i.fdc_id, 'ingest', NULL, i.description, 'auto', i.source_version
        FROM incoming i LEFT JOIN foods f USING (fdc_id) WHERE f.fdc_id IS NULL
        """
    )
    con.execute(
        f"""
        INSERT INTO foods (fdc_id, data_type, food_category, description,
                           fat_g, source_version, {"".join(f"{c}, " for c in meta)}review_status)
        SELECT i.fdc_id, i.data_type, i.food_category, i.description,
               i.fat_g, i.source_version, {"".join(f"i.{c}, " for c in meta)}'pending'
        FROM incoming i LEFT JOIN foods f USING (fdc_id) WHERE f.fdc_id IS NULL
        """
    )
    con.unregister("incoming")
    return {"inserted": inserted, "updated": changed, "locked_skipped": locked}


def upsert_ingest_children(
    con: duckdb.DuckDBPyConnection, frames: dict[str, pl.DataFrame]
) -> dict[str, int]:
    """Replace the USDA child rows (nutrients, portions, attributes, inputs)
    for every food present in the incoming frames.

    Delete-then-insert per fdc_id rather than a row-level upsert: these tables
    are a verbatim mirror of the archive, so a re-release that drops a portion
    or a nutrient must drop it here too. No human_verified check and no audit
    rows — see the note on the child tables in DDL.
    """
    counts: dict[str, int] = {}
    for key, table in CHILD_TABLES.items():
        df = frames.get(key)
        if df is None:
            continue
        cols = ", ".join(df.columns)
        con.register("incoming_child", df)
        con.execute(f"DELETE FROM {table} WHERE fdc_id IN (SELECT fdc_id FROM incoming_child)")
        con.execute(f"INSERT INTO {table} ({cols}) SELECT {cols} FROM incoming_child")
        con.unregister("incoming_child")
        counts[table] = df.height
    return counts


# --------------------------------------------------------------------------
# Stage 2: abbreviation-expansion writes
# --------------------------------------------------------------------------
def update_expansions(
    con: duckdb.DuckDBPyConnection, expanded_df: pl.DataFrame, log_df: pl.DataFrame
) -> int:
    """Persist expanded description + fat_percentage; append cleanup + audit logs.

    Expansion rewrites ``description`` in place. It is idempotent, every
    substitution lands in cleanup_log and every rewrite in audit_log, and the
    raw USDA text is recoverable by re-running ingest.
    """
    con.register("expanded", expanded_df)

    changed = con.execute(
        """
        SELECT count(*) FROM foods f JOIN expanded e USING (fdc_id)
        WHERE NOT f.human_verified
          AND (f.description IS DISTINCT FROM e.description
               OR f.fat_percentage IS DISTINCT FROM e.fat_percentage)
        """
    ).fetchone()[0]

    for field in ("description", "fat_percentage"):
        con.execute(
            f"""
            INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
            SELECT f.fdc_id, '{field}', f.{field}, e.{field}, 'auto', f.source_version
            FROM foods f JOIN expanded e USING (fdc_id)
            WHERE NOT f.human_verified AND f.{field} IS DISTINCT FROM e.{field}
            """
        )
    con.execute(
        """
        UPDATE foods SET
            description = e.description,
            fat_percentage = e.fat_percentage,
            updated_at = current_timestamp
        FROM expanded e
        WHERE foods.fdc_id = e.fdc_id
          AND NOT foods.human_verified
          AND (foods.description IS DISTINCT FROM e.description
               OR foods.fat_percentage IS DISTINCT FROM e.fat_percentage)
        """
    )
    con.unregister("expanded")

    if not log_df.is_empty():
        con.register("clog", log_df)
        # only keep log rows for rows we were allowed to write
        con.execute(
            """
            INSERT INTO cleanup_log (fdc_id, rule, old_text, new_text)
            SELECT l.fdc_id, l.rule, l.old_text, l.new_text
            FROM clog l JOIN foods f USING (fdc_id)
            WHERE NOT f.human_verified
            """
        )
        con.unregister("clog")
    return changed


# --------------------------------------------------------------------------
# Stage 3: brand flags
# --------------------------------------------------------------------------
def update_brand_flags(con: duckdb.DuckDBPyConnection, flags: pl.DataFrame) -> int:
    con.register("flags", flags)
    changed = con.execute(
        """
        SELECT count(*) FROM foods f JOIN flags b USING (fdc_id)
        WHERE NOT f.human_verified AND f.brand_flagged IS DISTINCT FROM b.brand_flagged
        """
    ).fetchone()[0]
    con.execute(
        """
        INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
        SELECT f.fdc_id, 'brand_flagged', f.brand_flagged, b.brand_flagged, 'auto', f.source_version
        FROM foods f JOIN flags b USING (fdc_id)
        WHERE NOT f.human_verified AND f.brand_flagged IS DISTINCT FROM b.brand_flagged
        """
    )
    con.execute(
        """
        UPDATE foods SET brand_flagged = b.brand_flagged, updated_at = current_timestamp
        FROM flags b
        WHERE foods.fdc_id = b.fdc_id
          AND NOT foods.human_verified
          AND foods.brand_flagged IS DISTINCT FROM b.brand_flagged
        """
    )
    con.unregister("flags")
    return changed


# --------------------------------------------------------------------------
# Stage 4/5: enrichment writes + routing + cross-checks
# --------------------------------------------------------------------------
def route_confidence(confidence: float, brand_flagged: bool, validation_failed: bool) -> str:
    """Confidence routing per config thresholds. brand_flagged and
    validation failures always force human review."""
    if validation_failed or brand_flagged:
        return "needs_review"
    return "auto_approved" if confidence >= config.HIGH_THRESHOLD else "needs_review"


def cross_check(
    *,
    prep_type: str | None,
    variable_fat: bool,
    fat_percentage: float | None,
    description: str,
    food_category: str | None,
    emoji: str | None = None,
) -> list[str]:
    """Validation cross-checks before persisting. Returns list of issues."""
    issues: list[str] = []
    if prep_type is not None and prep_type not in config.PREP_TYPES:
        issues.append(f"prep_type {prep_type!r} not in enum")
    if emoji is not None and not schema.is_emoji(emoji):
        issues.append(f"emoji {emoji!r} is not a single pictographic character")
    if fat_percentage is not None:
        if not abbrev.FAT_TOKEN_RE.search(description):
            issues.append("fat_percentage set but no %fat/%lean/%milkfat token in source")
    if variable_fat and fat_percentage is None and not config.is_meat_dairy_category(food_category):
        issues.append("variable_fat=true outside meat/dairy category without fat_percentage")
    return issues


# Which rows an LLM pass still owes work on. One predicate per pass, over the
# `foods f` alias below; passed in rather than hardcoded so both passes share
# one query (they need the same per-row input, only a different gate).
ENRICHMENT_PENDING = (
    "NOT f.human_verified "
    "AND (f.display_name IS NULL OR f.emoji IS NULL OR f.review_status = 'pending')"
)
# No human_verified clause: see apply_commonness.
COMMONNESS_PENDING = "f.commonness IS NULL"
# Same, for the same reason: see apply_keywords.
KEYWORDS_PENDING = "f.keywords IS NULL"


def select_enrichment_candidates(
    con: duckdb.DuckDBPyConnection,
    limit: int | None = None,
    where: str = ENRICHMENT_PENDING,
) -> pl.DataFrame:
    """Rows that still need enrichment at the current source_version.

    Resumability: enriched rows carry a non-null display_name, a non-null
    emoji and a non-'pending' review_status; ingest resets review_status to
    'pending' whenever a row's source data/version changes, which naturally
    re-queues it. Human-verified rows are never selected. brand_flagged rows
    sort last (down-ranked — the catalog is biased toward generic foods).

    ``emoji IS NULL`` is part of the gate so rows enriched before emoji was an
    output field are re-queued to pick one up; without it they would ship to
    the app with no icon and never be selected again.

    There is no "stage 2 has run" gate any more: expansion writes description
    in place, so an un-expanded row is merely one whose abbreviations are still
    cryptic, not one that would break. Run stage 2 first for best results.

    ``common_name`` / ``extra_desc`` come from ``food_attributes``: USDA's own
    shopper-facing synonyms ("hot dog, wiener, frank") and qualifiers ("leche
    fresca"), present on ~5k rows. Aggregated in a CTE rather than joined
    directly — a food can carry several values and a plain join would multiply
    candidate rows.
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
        )
        SELECT f.fdc_id, f.data_type, f.food_category, f.description,
               f.fat_percentage, f.brand_flagged, f.source_version,
               a.common_name, a.extra_desc
        FROM foods f
        LEFT JOIN attrs a USING (fdc_id)
        WHERE {where}
        ORDER BY f.brand_flagged, f.fdc_id
    """
    if limit is not None:
        q += f" LIMIT {int(limit)}"
    return con.execute(q).pl()


def count_enrichment_candidates(
    con: duckdb.DuckDBPyConnection, where: str = ENRICHMENT_PENDING
) -> int:
    return con.execute(f"SELECT count(*) FROM foods f WHERE {where}").fetchone()[0]


def apply_enrichment(
    con: duckdb.DuckDBPyConnection,
    *,
    fdc_id: int,
    display_name: str,
    emoji: str | None,
    prep_type: str | None,
    variable_fat: bool,
    confidence: float,
    review_status: str,
    notes: str = "",
    source_version: str | None = None,
    model: str | None = None,
    reasoning: str | None = None,
) -> bool:
    """Write one enrichment result, respecting the human-verified lock.

    Returns False (and writes nothing) when the row is missing or verified.
    Called once per completed LLM row so progress is durable immediately.
    """
    row = con.execute(
        "SELECT human_verified, display_name, emoji, prep_type, variable_fat, confidence, "
        "review_status, source_version FROM foods WHERE fdc_id = ?",
        [fdc_id],
    ).fetchone()
    if row is None or row[0]:
        return False
    old = dict(
        zip(("human_verified", "display_name", "emoji", "prep_type", "variable_fat",
             "confidence", "review_status", "source_version"), row)
    )
    sv = source_version or old["source_version"]

    new_values = {
        "display_name": display_name,
        "emoji": emoji,
        "prep_type": prep_type,
        "variable_fat": variable_fat,
        "confidence": confidence,
        "review_status": review_status,
    }
    for field, new in new_values.items():
        if old[field] != new:
            _audit(con, fdc_id, field, old[field], new, "auto", sv)
    if notes:
        _audit(con, fdc_id, "llm_notes", None, notes, "auto", sv)

    con.execute(
        """
        UPDATE foods SET
            display_name = ?, emoji = ?, prep_type = ?, variable_fat = ?, confidence = ?,
            review_status = ?, enriched_by = ?, enriched_reasoning = ?,
            updated_at = current_timestamp
        WHERE fdc_id = ? AND NOT human_verified
        """,
        [display_name, emoji, prep_type, variable_fat, confidence, review_status, model,
         reasoning, fdc_id],
    )
    return True


def apply_commonness(
    con: duckdb.DuckDBPyConnection,
    *,
    fdc_id: int,
    commonness: float,
    source_version: str | None = None,
) -> bool:
    """Write one commonness score (Stage 4b). False when the row is gone.

    Deliberately NOT gated on human_verified, unlike every other automated
    write here: commonness is machine-only — no reviewer UI shows or edits it —
    so there is no human value to protect, and gating it would leave every
    verified row permanently unscored with no way to ever fill it in.
    """
    row = con.execute(
        "SELECT commonness, source_version FROM foods WHERE fdc_id = ?", [fdc_id]
    ).fetchone()
    if row is None:
        return False
    if row[0] != commonness:
        _audit(con, fdc_id, "commonness", row[0], commonness, "auto",
               source_version or row[1])
    con.execute(
        "UPDATE foods SET commonness = ?, updated_at = current_timestamp WHERE fdc_id = ?",
        [commonness, fdc_id],
    )
    return True


def apply_keywords(
    con: duckdb.DuckDBPyConnection,
    *,
    fdc_id: int,
    keywords: str,
    source_version: str | None = None,
) -> bool:
    """Write one food's search keywords (Stage 4c). False when the row is gone.

    Not gated on human_verified, for the same reason as
    :func:`apply_commonness`: keywords are machine-only search fodder that no
    reviewer UI shows or edits, so there is no human value to protect, and
    gating would leave every verified row permanently unsearchable by synonym.
    """
    row = con.execute(
        "SELECT keywords, source_version FROM foods WHERE fdc_id = ?", [fdc_id]
    ).fetchone()
    if row is None:
        return False
    if row[0] != keywords:
        _audit(con, fdc_id, "keywords", row[0], keywords, "auto",
               source_version or row[1])
    con.execute(
        "UPDATE foods SET keywords = ?, updated_at = current_timestamp WHERE fdc_id = ?",
        [keywords, fdc_id],
    )
    return True


# --------------------------------------------------------------------------
# Stage 6b: merge groups
# --------------------------------------------------------------------------
def write_merges(
    con: duckdb.DuckDBPyConnection, merged: pl.DataFrame, links: pl.DataFrame
) -> dict[str, int]:
    """Replace merged_foods and repoint every foods.merged_food_id. Idempotent.

    Two deliberate departures from this module's invariants:

    * **No human_verified lock.** merged_food_id is derived grouping metadata,
      not an enriched field a reviewer ever sets, so there is no human value to
      protect — and gating it would leave verified rows permanently unmergeable
      with no way to ever fill them in. Same reasoning as apply_commonness.
    * **No audit_log rows.** Both tables are recomputed wholesale from the
      foods/food_nutrients they summarize, so an audit trail would be 13.7k
      no-op rows per run recording that a derivation still derives the same
      thing. Same posture as the app_* tables in appdb.
    """
    con.register("merged_in", merged)
    con.register("links_in", links)
    try:
        # CREATE OR REPLACE would drop the declared types and PK from DDL, so
        # the table is emptied and refilled instead.
        con.execute("DELETE FROM merged_foods")
        cols = ", ".join(merged.columns)
        con.execute(f"INSERT INTO merged_foods ({cols}) SELECT {cols} FROM merged_in")
        # Every food is in exactly one group, so a plain UPDATE covers the
        # table; no NULL-out pass is needed for foods that left a group.
        con.execute(
            """
            UPDATE foods SET merged_food_id = l.merged_food_id, updated_at = current_timestamp
            FROM links_in l
            WHERE foods.fdc_id = l.fdc_id
              AND foods.merged_food_id IS DISTINCT FROM l.merged_food_id
            """
        )
    finally:
        con.unregister("merged_in")
        con.unregister("links_in")
    return {
        "merged_foods": con.execute("SELECT count(*) FROM merged_foods").fetchone()[0],
        "linked": con.execute(
            "SELECT count(*) FROM foods WHERE merged_food_id IS NOT NULL"
        ).fetchone()[0],
    }


def merge_groups(
    con: duckdb.DuckDBPyConnection, min_size: int = 2, limit: int | None = None
) -> pl.DataFrame:
    """The merge groups, largest first — the master half of the tuning read-out.

    Members are not joined in: :func:`merge_members` fetches them for the one
    group being looked at, so the list stays one row per merged item. That is
    what makes ``limit=None`` (LIMIT NULL, i.e. all ~2.2k of them) cheap enough
    to be the default — a truncated list silently hides groups from review.
    """
    return con.execute(
        """
        SELECT m.merged_food_id, m.emoji, m.display_name, m.n_foods, m.variable_fat,
               m.food_category,
               round(m.protein_ratio, 3) AS p, round(m.carb_ratio, 3) AS c,
               round(m.fat_ratio, 3) AS f
        FROM merged_foods m
        WHERE m.n_foods >= ?
        ORDER BY m.n_foods DESC, m.display_name
        LIMIT ?
        """,
        [min_size, limit],
    ).pl()


def merge_members(con: duckdb.DuckDBPyConnection, merged_food_id: int) -> pl.DataFrame:
    """The foods one merged item was built from, canonical member first.

    Carries each member's own protein/carb/fat ratio, because that triple is
    what the grouping actually compared: a member that does not belong shows up
    as the one whose ratio sits away from the rest of the column.
    """
    macros = pivot_columns_sql(config.merge_macro_nutrients())
    return con.execute(
        f"""
        WITH m AS (SELECT fdc_id, {macros} FROM food_nutrients GROUP BY fdc_id),
        r AS (
            SELECT *, nullif(
                coalesce(protein_g, 0) + coalesce(carb_g, 0) + coalesce(fat_g, 0), 0
            ) AS total FROM m
        )
        SELECT fd.fdc_id = ? AS canonical, fd.fdc_id, fd.emoji, fd.display_name,
               fd.description, fd.data_type, fd.prep_type, fd.fat_percentage,
               r.protein_g, r.carb_g, r.fat_g,
               round(r.protein_g / r.total, 3) AS p,
               round(r.carb_g / r.total, 3) AS c,
               round(r.fat_g / r.total, 3) AS f
        FROM foods fd LEFT JOIN r ON r.fdc_id = fd.fdc_id
        WHERE fd.merged_food_id = ?
        ORDER BY canonical DESC, fd.fdc_id
        """,
        [merged_food_id, merged_food_id],
    ).pl()


def mark_validation_failed(con: duckdb.DuckDBPyConnection, fdc_id: int, error: str) -> None:
    """Route a malformed/unvalidatable LLM response to human review."""
    row = con.execute(
        "SELECT human_verified, review_status, source_version FROM foods WHERE fdc_id = ?",
        [fdc_id],
    ).fetchone()
    if row is None or row[0]:
        return
    _audit(con, fdc_id, "validation_error", row[1], error[:500], "auto", row[2])
    con.execute(
        "UPDATE foods SET review_status = 'needs_review', updated_at = current_timestamp "
        "WHERE fdc_id = ? AND NOT human_verified",
        [fdc_id],
    )


# --------------------------------------------------------------------------
# Stage 6: review queue + human writes
# --------------------------------------------------------------------------
def review_queue(con: duckdb.DuckDBPyConnection, limit: int = 500) -> pl.DataFrame:
    return con.execute(
        """
        SELECT fdc_id, data_type, food_category, description,
               display_name, emoji, prep_type, fat_percentage,
               variable_fat, brand_flagged, confidence
        FROM foods
        WHERE review_status = 'needs_review' AND NOT human_verified
        ORDER BY confidence ASC NULLS FIRST, fdc_id
        LIMIT ?
        """,
        [limit],
    ).pl()


def apply_human_review(
    con: duckdb.DuckDBPyConnection,
    fdc_id: int,
    *,
    display_name: str | None = None,
    emoji: str | None = None,
    prep_type: str | None = None,
    variable_fat: bool | None = None,
    accept: bool,
) -> bool:
    """Accept (-> verified) or reject a row. Either way the human has spoken:
    human_verified becomes true, so no automated pass ever overwrites it."""
    row = con.execute(
        "SELECT display_name, emoji, prep_type, variable_fat, review_status, source_version "
        "FROM foods WHERE fdc_id = ?",
        [fdc_id],
    ).fetchone()
    if row is None:
        return False
    old_display, old_emoji, old_prep, old_vf, old_status, sv = row

    new_status = "verified" if accept else "rejected"
    new_display = display_name if (accept and display_name) else old_display
    new_emoji = emoji if (accept and emoji) else old_emoji
    new_prep = prep_type if accept else old_prep
    new_vf = variable_fat if (accept and variable_fat is not None) else old_vf

    for field, old, new in (
        ("display_name", old_display, new_display),
        ("emoji", old_emoji, new_emoji),
        ("prep_type", old_prep, new_prep),
        ("variable_fat", old_vf, new_vf),
        ("review_status", old_status, new_status),
        ("human_verified", False, True),
    ):
        if old != new:
            _audit(con, fdc_id, field, old, new, "human", sv)

    con.execute(
        """
        UPDATE foods SET
            display_name = ?, emoji = ?, prep_type = ?, variable_fat = ?,
            review_status = ?, human_verified = TRUE, updated_at = current_timestamp
        WHERE fdc_id = ?
        """,
        [new_display, new_emoji, new_prep, new_vf, new_status, fdc_id],
    )
    return True


# --------------------------------------------------------------------------
# Shared reads
# --------------------------------------------------------------------------
def load_foods(
    con: duckdb.DuckDBPyConnection, columns: list[str] | None = None
) -> pl.DataFrame:
    cols = ", ".join(columns) if columns else "*"
    return con.execute(f"SELECT {cols} FROM foods ORDER BY fdc_id").pl()


def status_summary(con: duckdb.DuckDBPyConnection) -> pl.DataFrame:
    return con.execute(
        """
        SELECT data_type, review_status, count(*) AS n,
               sum(CASE WHEN brand_flagged THEN 1 ELSE 0 END) AS brand_flagged
        FROM foods
        GROUP BY data_type, review_status
        ORDER BY data_type, review_status
        """
    ).pl()


def audit_tail(con: duckdb.DuckDBPyConnection, limit: int = 50) -> pl.DataFrame:
    return con.execute(
        "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT ?", [limit]
    ).pl()
