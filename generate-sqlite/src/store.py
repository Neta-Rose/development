"""Stage 5 — DuckDB persistence: upserts, human-verified lock, audit log.

DuckDB (data/foods.duckdb) is the single source of truth; in-memory frames
are always transient. Invariants enforced here:

* Automated passes NEVER write rows where ``human_verified = true``. The
  lock is enforced both in the WHERE clause of every automated UPDATE and by
  pre-checks, so no caller can bypass it accidentally. It lives on
  ``merged_foods`` only — that is where naming and review moved when
  enrichment became per-group, and nothing on ``foods`` is human-authored.
* Every write appends to ``audit_log`` (actor 'auto' or 'human').
* Confidence routing and validation cross-checks live here + config.
"""
from __future__ import annotations

import json
import re
from contextlib import contextmanager
from pathlib import Path

import duckdb
import polars as pl

from . import abbrev
from . import config
from . import schema

DDL = """
-- Verbatim USDA facts plus the two links Stage 3b computes. Nothing on this
-- table is human-authored or LLM-authored any more: naming moved up to
-- merged_foods when enrichment became per-group, and with it the review
-- columns and the human_verified lock.
CREATE TABLE IF NOT EXISTS foods (
    fdc_id BIGINT PRIMARY KEY,
    data_type TEXT NOT NULL,
    food_category TEXT,
    description TEXT NOT NULL,
    fat_percentage DOUBLE,
    brand_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    source_version TEXT,
    fat_g DOUBLE,
    publication_date DATE,
    ndb_number TEXT,
    food_code TEXT,
    wweia_category_number TEXT,
    start_date DATE,
    end_date DATE,
    usda_footnote TEXT,
    -- Stage 3b-1 (LLM): what this food IS, read off its description. The only
    -- LLM-authored columns on this table, and they are facts about the row
    -- rather than presentation — naming still lives on merged_foods.
    --
    -- base_name is the identity with every preparation, grade and trim word
    -- removed; base_key is its normalized form and is what Stage 3b GROUPs BY,
    -- so these two columns ARE the clustering. food_kind ('ingredient' /
    -- 'dish') is the hard guard that keeps fried rice out of white rice.
    base_name TEXT,
    base_key TEXT,
    food_kind TEXT,
    prep_label TEXT,
    canon_by TEXT,
    -- Stage 3b: the item this food belongs to, and which of its preparations.
    merged_food_id BIGINT,
    prep_id BIGINT,
    updated_at TIMESTAMP NOT NULL DEFAULT current_timestamp
);

-- migrations for databases created before these columns existed
ALTER TABLE foods DROP COLUMN IF EXISTS enriched_batch_size;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS publication_date DATE;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS ndb_number TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS food_code TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS wweia_category_number TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS end_date DATE;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS usda_footnote TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS merged_food_id BIGINT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS prep_id BIGINT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS base_name TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS base_key TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS food_kind TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS prep_label TEXT;
ALTER TABLE foods ADD COLUMN IF NOT EXISTS canon_by TEXT;

-- Enrichment moved to merged_foods; these are dead here. Dropped rather than
-- left in place: a foods.review_status that means nothing, beside a
-- merged_foods.review_status that means everything, is how someone loses an
-- afternoon.
ALTER TABLE foods DROP COLUMN IF EXISTS display_name;
ALTER TABLE foods DROP COLUMN IF EXISTS emoji;
ALTER TABLE foods DROP COLUMN IF EXISTS prep_type;
ALTER TABLE foods DROP COLUMN IF EXISTS variable_fat;
ALTER TABLE foods DROP COLUMN IF EXISTS confidence;
ALTER TABLE foods DROP COLUMN IF EXISTS commonness;
ALTER TABLE foods DROP COLUMN IF EXISTS keywords;
ALTER TABLE foods DROP COLUMN IF EXISTS review_status;
ALTER TABLE foods DROP COLUMN IF EXISTS human_verified;
ALTER TABLE foods DROP COLUMN IF EXISTS enriched_by;
ALTER TABLE foods DROP COLUMN IF EXISTS enriched_reasoning;

-- Stage 3b's items: one row per food a user recognizes, with its preparations
-- in merged_preps and its members pointed here by foods.merged_food_id. This
-- is also Stage 4's target — the LLM names an item, not a USDA row.
--
-- merged_food_id IS the default preparation's fdc_id rather than a surrogate:
-- nothing to sequence, an id stays put across re-runs as long as its
-- representative does, and a group id is therefore a real, loggable food whose
-- macros, portions and nutrients are just that foods row.
--
-- Unlike the derived table this replaces, it is NOT rebuilt wholesale: it
-- holds a full enrichment run. See write_clusters.
CREATE TABLE IF NOT EXISTS merged_foods (
    merged_food_id BIGINT PRIMARY KEY,
    -- digest of the member fdc_ids; when it changes the naming is stale and
    -- the row goes back in Stage 4's queue.
    member_key TEXT NOT NULL,
    n_foods INTEGER NOT NULL,
    n_preps INTEGER NOT NULL,
    food_category TEXT,
    -- true when the item spans fat levels (ground beef 70% .. 97% lean, milk
    -- whole .. skim). Computed, not asked for: the preparation split changes
    -- basis on it and runs before the LLM does.
    variable_fat BOOLEAN NOT NULL DEFAULT FALSE,
    -- any member flagged; forces review like a low confidence does.
    brand_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    -- Stage 4 (LLM). NULL until it runs.
    display_name TEXT,
    emoji TEXT,
    commonness DOUBLE,
    keywords TEXT,
    confidence DOUBLE,
    review_status TEXT NOT NULL DEFAULT 'pending',
    human_verified BOOLEAN NOT NULL DEFAULT FALSE,
    enriched_by TEXT,
    enriched_reasoning TEXT,
    source_version TEXT,
    updated_at TIMESTAMP NOT NULL DEFAULT current_timestamp
);

-- One row per preparation of an item: the entries in the app's variant
-- selector. prep_id is the preparation's representative fdc_id, so — like
-- merged_food_id — it is a real loggable food carrying the real nutrient
-- vector, and the macros here are only the subgroup mean the LLM is shown.
--
-- seq is the 0-based address the Stage 4 request uses to talk about a
-- preparation, so the model never handles a 7-digit fdc_id it could mangle.
CREATE TABLE IF NOT EXISTS merged_preps (
    prep_id BIGINT PRIMARY KEY,
    merged_food_id BIGINT NOT NULL,
    seq INTEGER NOT NULL,
    n_foods INTEGER NOT NULL,
    protein_g DOUBLE,
    carb_g DOUBLE,
    fat_g DOUBLE,
    -- The label Stage 3b-1 read off the members' descriptions, widened to the
    -- parent label when two of them merged into one preparation. Derived, not
    -- an LLM answer at this level -- write_clusters refills it wholesale.
    prep_type TEXT,
    updated_at TIMESTAMP NOT NULL DEFAULT current_timestamp
);

-- suspicious was the model reporting two preparations it could not tell apart,
-- which only ever happened because the split was made on macros alone and so
-- put the same food's two USDA records in separate preparations. Labels are
-- bucketed before macros now, so the case it described cannot arise.
ALTER TABLE merged_preps DROP COLUMN IF EXISTS suspicious;

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


def _migrate_group_enrichment(con: duckdb.DuckDBPyConnection) -> None:
    """Drop the pre-Stage-3b merged_foods so the DDL can recreate it.

    The old table held only derived data (one row per macro-ratio group, its
    display columns copied down from a canonical member), and every column it
    had either changed meaning or went away. ALTERing it into the new shape
    would be more code than rebuilding it, and there is nothing in it worth
    keeping: the naming it carried was copied from foods.display_name, which
    this same migration is about to drop.

    Runs BEFORE the DDL, unlike the other migrations — they repair a table the
    DDL has already created, this one clears the way for it. Idempotent: keyed
    on a column only the old shape has.
    """
    tables = {r[0] for r in con.execute("SHOW TABLES").fetchall()}
    if "merged_foods" not in tables:
        return
    cols = {r[0] for r in con.execute("DESCRIBE merged_foods").fetchall()}
    if "protein_ratio" in cols:
        con.execute("DROP TABLE merged_foods")


def init_db(con: duckdb.DuckDBPyConnection) -> None:
    _migrate_group_enrichment(con)
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

    * New fdc_ids are inserted.
    * Existing rows whose source data changed are updated, with audit entries
      per changed field.

    No human_verified check: nothing on ``foods`` is human-authored since
    naming moved to merged_foods, so there is nothing here to protect. A
    changed description still reaches the reviewer, just one level up — it
    re-clusters, which changes the item's member_key, which puts it back in
    Stage 4's queue (see :func:`write_clusters`).
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
        WHERE f.description IS DISTINCT FROM i.description
           OR f.source_version IS DISTINCT FROM i.source_version
           OR f.food_category IS DISTINCT FROM i.food_category
        """
    ).fetchone()[0]

    for field in ("description", "food_category", "source_version"):
        con.execute(
            f"""
            INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
            SELECT f.fdc_id, '{field}', f.{field}, i.{field}, 'auto', i.source_version
            FROM foods f JOIN incoming i USING (fdc_id)
            WHERE f.{field} IS DISTINCT FROM i.{field}
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
            updated_at = current_timestamp
        FROM incoming i
        WHERE foods.fdc_id = i.fdc_id
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
                           fat_g, source_version{"".join(f", {c}" for c in meta)})
        SELECT i.fdc_id, i.data_type, i.food_category, i.description,
               i.fat_g, i.source_version{"".join(f", i.{c}" for c in meta)}
        FROM incoming i LEFT JOIN foods f USING (fdc_id) WHERE f.fdc_id IS NULL
        """
    )
    con.unregister("incoming")
    return {"inserted": inserted, "updated": changed}


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

    No human_verified check: nothing on ``foods`` is human-authored since
    naming moved to merged_foods.
    """
    con.register("expanded", expanded_df)

    changed = con.execute(
        """
        SELECT count(*) FROM foods f JOIN expanded e USING (fdc_id)
        WHERE f.description IS DISTINCT FROM e.description
           OR f.fat_percentage IS DISTINCT FROM e.fat_percentage
        """
    ).fetchone()[0]

    for field in ("description", "fat_percentage"):
        con.execute(
            f"""
            INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
            SELECT f.fdc_id, '{field}', f.{field}, e.{field}, 'auto', f.source_version
            FROM foods f JOIN expanded e USING (fdc_id)
            WHERE f.{field} IS DISTINCT FROM e.{field}
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
          AND (foods.description IS DISTINCT FROM e.description
               OR foods.fat_percentage IS DISTINCT FROM e.fat_percentage)
        """
    )
    con.unregister("expanded")

    if not log_df.is_empty():
        con.register("clog", log_df)
        con.execute(
            """
            INSERT INTO cleanup_log (fdc_id, rule, old_text, new_text)
            SELECT l.fdc_id, l.rule, l.old_text, l.new_text
            FROM clog l JOIN foods f USING (fdc_id)
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
        WHERE f.brand_flagged IS DISTINCT FROM b.brand_flagged
        """
    ).fetchone()[0]
    con.execute(
        """
        INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
        SELECT f.fdc_id, 'brand_flagged', f.brand_flagged, b.brand_flagged, 'auto', f.source_version
        FROM foods f JOIN flags b USING (fdc_id)
        WHERE f.brand_flagged IS DISTINCT FROM b.brand_flagged
        """
    )
    con.execute(
        """
        UPDATE foods SET brand_flagged = b.brand_flagged, updated_at = current_timestamp
        FROM flags b
        WHERE foods.fdc_id = b.fdc_id
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


_PREP_WORDS = frozenset(config.PREP_TYPES) | frozenset({
    "fresh", "heated", "unheated", "prepared", "cooking",
})
_NAME_WORD_RE = re.compile(r"[a-z]+")


def cross_check(
    *,
    display_name: str,
    emoji: str | None,
    base_name: str | None,
) -> list[str]:
    """Validation cross-checks before persisting an item. Returns issues.

    The prep_type checks that used to live here are gone with the field: a
    preparation label is read off its own description in Stage 3b-1 now, so
    there is no cross-item contrast left to contradict.

    What replaced them are the two ways Stage 4 is actually observed to fail.
    Both are only checkable because ``base_name`` is the grouping key: two
    items necessarily have different base names, so any collision downstream of
    that is the naming losing information the pipeline already had.

    * **A preparation word in the name.** The preparation is stored separately
      and joined back at display time, so "Roasted chicken thigh" renders as
      "Roasted chicken thigh - roasted". Checked against base_name, not
      blindly: "Fried rice" is a food called that, and base_name says so, so a
      preparation word the identity already carries is not an error.
    * **A name that dropped a qualifier.** If display_name has fewer content
      words than base_name, the model summarized instead of rewording — that is
      how both granola bars came back as "Granola bar". Cheap proxy, and it is
      the direction that matters: adding a word is a different (rarer) mistake.
    """
    issues: list[str] = []
    if emoji is not None and not schema.is_emoji(emoji):
        issues.append(f"emoji {emoji!r} is not a single pictographic character")

    name_words = set(_NAME_WORD_RE.findall(display_name.lower()))
    base_words = set(_NAME_WORD_RE.findall((base_name or "").lower()))
    stray = sorted((name_words & _PREP_WORDS) - base_words)
    if stray:
        issues.append(f"preparation word(s) {stray} in display_name {display_name!r}")
    if base_name and len(name_words) < len(base_words):
        issues.append(
            f"display_name {display_name!r} drops qualifiers from base {base_name!r}"
        )
    return issues


def duplicate_display_names(con: duckdb.DuckDBPyConnection) -> pl.DataFrame:
    """Items that ended up sharing a display_name. Should be empty.

    A post-run audit rather than a per-item check, because it is inherently a
    cross-item property and Stage 4 writes items one at a time and out of
    order. Every row here is a real defect: the two items have different
    base_names by construction (that is what made them two items), so the
    catalog is showing one name for two different foods and the user cannot
    pick between them.
    """
    return con.execute(
        """
        SELECT display_name, count(*) AS n,
               string_agg(merged_food_id::VARCHAR, ', ') AS merged_food_ids
        FROM merged_foods
        WHERE display_name IS NOT NULL
        GROUP BY display_name HAVING count(*) > 1
        ORDER BY n DESC, display_name
        """
    ).pl()


# Which items Stage 4 still owes work on, over the `merged_foods m` alias
# below. An enriched item carries a display_name, an emoji and a non-'pending'
# review_status; write_clusters resets review_status to 'pending' whenever an
# item's membership changes, which re-queues it.
ENRICHMENT_PENDING = (
    "NOT m.human_verified "
    "AND (m.display_name IS NULL OR m.emoji IS NULL OR m.review_status = 'pending')"
)


def select_enrichment_candidates(
    con: duckdb.DuckDBPyConnection,
    limit: int | None = None,
    where: str = ENRICHMENT_PENDING,
) -> pl.DataFrame:
    """Items that still need naming, each with its preparations nested.

    One row per merged item, not per food: Stage 4 names a whole item and types
    all of its preparations in one request, so the unit of work here is the
    item. ``preps`` is a list of structs ordered by seq, and that order IS the
    address the request uses — see enrich.build_group.

    Member descriptions are capped at MAX_GROUP_DESCRIPTIONS per preparation.
    Past that they are near-duplicates of each other (that is why they are in
    one preparation) and only cost tokens.

    ``common_name`` / ``extra_desc`` come from ``food_attributes``: USDA's own
    shopper-facing synonyms ("hot dog, wiener, frank") and qualifiers ("leche
    fresca"), present on ~5k rows. Aggregated over all members of the item.

    brand_flagged items sort last — the catalog is biased toward generic foods.
    """
    cap = int(config.MAX_GROUP_DESCRIPTIONS)
    q = f"""
        WITH attrs AS (
            SELECT f.merged_food_id,
                   string_agg(DISTINCT a.value, '; ')
                       FILTER (WHERE a.attribute_type = 'Common Name') AS common_name,
                   string_agg(DISTINCT a.value, '; ')
                       FILTER (WHERE a.attribute_type = 'Additional Description') AS extra_desc
            FROM food_attributes a
            JOIN foods f USING (fdc_id)
            WHERE a.attribute_type IN ('Common Name', 'Additional Description')
              AND coalesce(a.value, '') <> ''
              AND f.merged_food_id IS NOT NULL
            GROUP BY f.merged_food_id
        ),
        prep_rows AS (
            SELECT p.merged_food_id, p.seq, p.prep_id, p.prep_type,
                   p.protein_g, p.carb_g, p.fat_g,
                   list(f.description ORDER BY length(f.description), f.fdc_id)[1:{cap}] AS descs
            FROM merged_preps p
            JOIN foods f ON f.prep_id = p.prep_id
            GROUP BY p.merged_food_id, p.seq, p.prep_id, p.prep_type,
                     p.protein_g, p.carb_g, p.fat_g
        ),
        -- The item's identity, taken from its default preparation's
        -- representative — which IS the row merged_food_id names.
        ident AS (
            SELECT fdc_id AS merged_food_id, base_name, food_kind FROM foods
        )
        SELECT m.merged_food_id, m.food_category, m.brand_flagged, m.variable_fat,
               m.source_version, a.common_name, a.extra_desc,
               id.base_name, id.food_kind,
               list({{'seq': pr.seq, 'prep_id': pr.prep_id, 'descs': pr.descs,
                     'prep_type': pr.prep_type,
                     'protein_g': pr.protein_g, 'carb_g': pr.carb_g, 'fat_g': pr.fat_g}}
                    ORDER BY pr.seq) AS preps
        FROM merged_foods m
        JOIN prep_rows pr ON pr.merged_food_id = m.merged_food_id
        LEFT JOIN attrs a ON a.merged_food_id = m.merged_food_id
        LEFT JOIN ident id ON id.merged_food_id = m.merged_food_id
        WHERE {where}
        GROUP BY m.merged_food_id, m.food_category, m.brand_flagged, m.variable_fat,
                 m.source_version, a.common_name, a.extra_desc,
                 id.base_name, id.food_kind
        ORDER BY m.brand_flagged, m.merged_food_id
    """
    if limit is not None:
        q += f" LIMIT {int(limit)}"
    return con.execute(q).pl()


def count_enrichment_candidates(
    con: duckdb.DuckDBPyConnection, where: str = ENRICHMENT_PENDING
) -> int:
    return con.execute(f"SELECT count(*) FROM merged_foods m WHERE {where}").fetchone()[0]


def apply_canonicalization(
    con: duckdb.DuckDBPyConnection,
    *,
    fdc_id: int,
    base_name: str,
    food_kind: str,
    prep_label: str | None,
    model: str | None = None,
) -> None:
    """Write one food's Stage 3b-1 identity. Idempotent.

    No human_verified gate, unlike every other automated write here: the lock
    lives on merged_foods and nothing on `foods` is human-authored. Re-running
    the stage overwrites, which is the point — a fixed prompt is applied by
    deleting these columns and running again.

    ``base_key`` is derived here rather than stored by the caller, so the one
    normalization that clustering depends on cannot drift between the writer
    and the reader.
    """
    from . import cluster  # local: cluster imports store for its own run()

    base_key = cluster.base_key(base_name)
    row = con.execute(
        "SELECT base_name, food_kind, prep_label, source_version FROM foods "
        "WHERE fdc_id = ?", [fdc_id]
    ).fetchone()
    if row is None:
        return
    old = dict(zip(("base_name", "food_kind", "prep_label", "source_version"), row))
    for field, new in (("base_name", base_name), ("food_kind", food_kind),
                       ("prep_label", prep_label)):
        if old[field] != new:
            _audit(con, fdc_id, field, old[field], new, "auto", old["source_version"])
    con.execute(
        """
        UPDATE foods SET base_name = ?, base_key = ?, food_kind = ?, prep_label = ?,
                         canon_by = ?, updated_at = current_timestamp
        WHERE fdc_id = ?
        """,
        [base_name, base_key, food_kind, prep_label, model, fdc_id],
    )


def apply_enrichment(
    con: duckdb.DuckDBPyConnection,
    *,
    merged_food_id: int,
    display_name: str,
    emoji: str | None,
    commonness: float,
    keywords: str,
    confidence: float,
    review_status: str,
    notes: str = "",
    source_version: str | None = None,
    model: str | None = None,
    reasoning: str | None = None,
) -> bool:
    """Write one item's presentation fields.

    Returns False (and writes nothing) when the item is missing or verified.

    No preparations any more: ``merged_preps.prep_type`` is filled by
    write_clusters from the label Stage 3b-1 read off each member's
    description, so it is settled before this pass runs and is not the LLM's to
    move.
    """
    row = con.execute(
        "SELECT human_verified, display_name, emoji, commonness, keywords, confidence, "
        "review_status, source_version FROM merged_foods WHERE merged_food_id = ?",
        [merged_food_id],
    ).fetchone()
    if row is None or row[0]:
        return False
    old = dict(
        zip(("human_verified", "display_name", "emoji", "commonness", "keywords",
             "confidence", "review_status", "source_version"), row)
    )
    sv = source_version or old["source_version"]

    new_values = {
        "display_name": display_name,
        "emoji": emoji,
        "commonness": commonness,
        "keywords": keywords,
        "confidence": confidence,
        "review_status": review_status,
    }
    for field, new in new_values.items():
        if old[field] != new:
            _audit(con, merged_food_id, field, old[field], new, "auto", sv)
    if notes:
        _audit(con, merged_food_id, "llm_notes", None, notes, "auto", sv)

    con.execute(
        """
        UPDATE merged_foods SET
            display_name = ?, emoji = ?, commonness = ?, keywords = ?, confidence = ?,
            review_status = ?, enriched_by = ?, enriched_reasoning = ?,
            updated_at = current_timestamp
        WHERE merged_food_id = ? AND NOT human_verified
        """,
        [display_name, emoji, commonness, keywords, confidence, review_status, model,
         reasoning, merged_food_id],
    )
    return True


# --------------------------------------------------------------------------
# Stage 3b: cluster writes
# --------------------------------------------------------------------------
def write_clusters(
    con: duckdb.DuckDBPyConnection,
    items: pl.DataFrame,
    preps: pl.DataFrame,
    links: pl.DataFrame,
) -> dict[str, int]:
    """Upsert merged_foods / merged_preps and repoint every food. Idempotent.

    An upsert, not the DELETE-and-refill this replaced, and that is the whole
    reason this function is long. merged_foods used to hold nothing but
    derivable grouping metadata; it now holds an entire enrichment run, so
    emptying it to re-derive the same 8.3k groups would discard ~8.3k LLM
    calls. Re-clustering has to be safe to run at any time.

    Three cases, and they are what the audit rows record:

    * **unchanged membership** — the row is left completely alone, LLM columns
      and review state included. This is the common case and the one that makes
      re-running free.
    * **changed membership** — the naming may no longer describe the group, so
      review_status goes back to 'pending' (which re-queues it for Stage 4) but
      display_name and the rest are LEFT IN PLACE. A re-cluster must never make
      the catalog temporarily nameless.
    * **gone** — the group no longer forms. Deleted, and if it was
      human_verified the audit row says so, because that is a person's work
      being dropped and it must not happen silently.

    Human-verified items are never re-queued and never repointed. That is the
    one place this differs from a plain upsert: their membership can drift
    underneath them, which is a known and audited hole rather than a silent one.
    """
    con.register("items_in", items)
    con.register("preps_in", preps)
    con.register("links_in", links)
    try:
        # Deleted groups. Audit the verified ones before they go: a human's
        # naming is being dropped because re-clustering dissolved its group.
        con.execute(
            """
            INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
            SELECT m.merged_food_id, 'group_dissolved', m.display_name, NULL,
                   CASE WHEN m.human_verified THEN 'human' ELSE 'auto' END, m.source_version
            FROM merged_foods m
            LEFT JOIN items_in i USING (merged_food_id)
            WHERE i.merged_food_id IS NULL
            """
        )
        dissolved = con.execute(
            """
            SELECT count(*) FROM merged_foods m LEFT JOIN items_in i USING (merged_food_id)
            WHERE i.merged_food_id IS NULL
            """
        ).fetchone()[0]
        con.execute(
            "DELETE FROM merged_foods WHERE merged_food_id NOT IN "
            "(SELECT merged_food_id FROM items_in)"
        )

        requeued = con.execute(
            """
            SELECT count(*) FROM merged_foods m JOIN items_in i USING (merged_food_id)
            WHERE m.member_key IS DISTINCT FROM i.member_key AND NOT m.human_verified
            """
        ).fetchone()[0]
        con.execute(
            """
            INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
            SELECT m.merged_food_id, 'member_key', m.member_key, i.member_key, 'auto',
                   m.source_version
            FROM merged_foods m JOIN items_in i USING (merged_food_id)
            WHERE m.member_key IS DISTINCT FROM i.member_key AND NOT m.human_verified
            """
        )
        # Membership facts are refreshed on every existing row; review_status
        # only falls back to 'pending' when the membership actually moved.
        con.execute(
            """
            UPDATE merged_foods SET
                member_key = i.member_key,
                n_foods = i.n_foods,
                n_preps = i.n_preps,
                food_category = i.food_category,
                variable_fat = i.variable_fat,
                brand_flagged = i.brand_flagged,
                review_status = CASE
                    WHEN merged_foods.member_key IS DISTINCT FROM i.member_key
                    THEN 'pending' ELSE merged_foods.review_status END,
                updated_at = current_timestamp
            FROM items_in i
            WHERE merged_foods.merged_food_id = i.merged_food_id
              AND NOT merged_foods.human_verified
            """
        )

        created = con.execute(
            """
            SELECT count(*) FROM items_in i LEFT JOIN merged_foods m USING (merged_food_id)
            WHERE m.merged_food_id IS NULL
            """
        ).fetchone()[0]
        con.execute(
            """
            INSERT INTO audit_log (fdc_id, field, old_value, new_value, actor, source_version)
            SELECT i.merged_food_id, 'group_created', NULL, i.member_key, 'auto', NULL
            FROM items_in i LEFT JOIN merged_foods m USING (merged_food_id)
            WHERE m.merged_food_id IS NULL
            """
        )
        cols = ", ".join(items.columns)
        con.execute(
            f"""
            INSERT INTO merged_foods ({cols})
            SELECT {cols} FROM items_in i
            WHERE i.merged_food_id NOT IN (SELECT merged_food_id FROM merged_foods)
            """
        )

        # Preparations are now pure derivation, prep_type included: the label
        # was read off each member's description in Stage 3b-1 and the split
        # itself is what widened it ("grilled" and "baked" landing together
        # become "cooked"), so preps_in carries it. Nothing to carry across
        # from the old rows and nothing an LLM run can lose.
        con.execute("DELETE FROM merged_preps")
        prep_cols = ", ".join(preps.columns)
        con.execute(f"INSERT INTO merged_preps ({prep_cols}) SELECT {prep_cols} FROM preps_in")

        # Every food is in exactly one group, so a plain UPDATE covers the
        # table; no NULL-out pass is needed for foods that left a group.
        relinked = con.execute(
            """
            SELECT count(*) FROM foods f JOIN links_in l USING (fdc_id)
            WHERE f.merged_food_id IS DISTINCT FROM l.merged_food_id
               OR f.prep_id IS DISTINCT FROM l.prep_id
            """
        ).fetchone()[0]
        con.execute(
            """
            UPDATE foods SET merged_food_id = l.merged_food_id, prep_id = l.prep_id,
                             updated_at = current_timestamp
            FROM links_in l
            WHERE foods.fdc_id = l.fdc_id
              AND (foods.merged_food_id IS DISTINCT FROM l.merged_food_id
                   OR foods.prep_id IS DISTINCT FROM l.prep_id)
            """
        )
    finally:
        con.unregister("items_in")
        con.unregister("preps_in")
        con.unregister("links_in")
    return {
        "created": created,
        "requeued": requeued,
        "dissolved": dissolved,
        "relinked": relinked,
        "linked": con.execute(
            "SELECT count(*) FROM foods WHERE merged_food_id IS NOT NULL"
        ).fetchone()[0],
    }


def cluster_items(
    con: duckdb.DuckDBPyConnection, min_size: int = 2, limit: int | None = None
) -> pl.DataFrame:
    """The clustered items, largest first — the master half of the tuning read-out.

    Members are not joined in: :func:`cluster_members` fetches them for the one
    item being looked at, so the list stays one row per item. That is what makes
    ``limit=None`` (LIMIT NULL, i.e. all of them) cheap enough to be the
    default — a truncated list silently hides groups from review.
    """
    return con.execute(
        """
        SELECT m.merged_food_id, m.emoji, m.display_name, m.n_foods, m.n_preps,
               m.variable_fat, m.food_category, m.review_status, m.confidence,
               (SELECT string_agg(p.prep_type, ', ' ORDER BY p.seq)
                  FROM merged_preps p WHERE p.merged_food_id = m.merged_food_id) AS preps
        FROM merged_foods m
        WHERE m.n_foods >= ?
        ORDER BY m.n_foods DESC, m.merged_food_id
        LIMIT ?
        """,
        [min_size, limit],
    ).pl()


def cluster_members(con: duckdb.DuckDBPyConnection, merged_food_id: int) -> pl.DataFrame:
    """The foods one item was built from, grouped by preparation.

    Carries each member's own absolute macros and its ratio: the ratio is what
    decided the item, the absolute macros are what decided the preparation, so
    a member that does not belong shows up as the one sitting away from the
    rest of its column.
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
        SELECT pp.seq, pp.prep_type,
               fd.fdc_id = pp.prep_id AS representative,
               fd.fdc_id, fd.description, fd.data_type, fd.fat_percentage,
               r.protein_g, r.carb_g, r.fat_g,
               round(r.protein_g / r.total, 3) AS p,
               round(r.carb_g / r.total, 3) AS c,
               round(r.fat_g / r.total, 3) AS f
        FROM foods fd
        JOIN merged_preps pp ON pp.prep_id = fd.prep_id
        LEFT JOIN r ON r.fdc_id = fd.fdc_id
        WHERE fd.merged_food_id = ?
        ORDER BY pp.seq, representative DESC, fd.fdc_id
        """,
        [merged_food_id],
    ).pl()


def mark_validation_failed(
    con: duckdb.DuckDBPyConnection, merged_food_id: int, error: str
) -> None:
    """Route a malformed/unvalidatable LLM response to human review."""
    row = con.execute(
        "SELECT human_verified, review_status, source_version FROM merged_foods "
        "WHERE merged_food_id = ?",
        [merged_food_id],
    ).fetchone()
    if row is None or row[0]:
        return
    _audit(con, merged_food_id, "validation_error", row[1], error[:500], "auto", row[2])
    con.execute(
        "UPDATE merged_foods SET review_status = 'needs_review', updated_at = current_timestamp "
        "WHERE merged_food_id = ? AND NOT human_verified",
        [merged_food_id],
    )


# --------------------------------------------------------------------------
# Stage 6: review queue + human writes
# --------------------------------------------------------------------------
def review_queue(con: duckdb.DuckDBPyConnection, limit: int = 500) -> pl.DataFrame:
    """Items awaiting review, least confident first."""
    return con.execute(
        """
        SELECT m.merged_food_id, m.food_category, m.display_name, m.emoji,
               m.keywords, m.n_foods, m.n_preps, m.variable_fat, m.brand_flagged,
               m.confidence,
               (SELECT string_agg(p.prep_type, ', ' ORDER BY p.seq)
                  FROM merged_preps p WHERE p.merged_food_id = m.merged_food_id) AS preps,
               (SELECT f.description FROM foods f
                 WHERE f.fdc_id = m.merged_food_id) AS description
        FROM merged_foods m
        WHERE m.review_status = 'needs_review' AND NOT m.human_verified
        ORDER BY m.confidence ASC NULLS FIRST, m.merged_food_id
        LIMIT ?
        """,
        [limit],
    ).pl()


def apply_human_review(
    con: duckdb.DuckDBPyConnection,
    merged_food_id: int,
    *,
    display_name: str | None = None,
    emoji: str | None = None,
    keywords: str | None = None,
    accept: bool,
) -> bool:
    """Accept (-> verified) or reject an item. Either way the human has spoken:
    human_verified becomes true, so no automated pass ever overwrites it.

    prep_type is deliberately not editable here. It is one field per
    preparation on a nested table, and editing it needs a nested editor for a
    field with no correction history — the review action that matters is
    accepting or rejecting the item as a whole.
    """
    row = con.execute(
        "SELECT display_name, emoji, keywords, review_status, source_version "
        "FROM merged_foods WHERE merged_food_id = ?",
        [merged_food_id],
    ).fetchone()
    if row is None:
        return False
    old_display, old_emoji, old_keywords, old_status, sv = row

    new_status = "verified" if accept else "rejected"
    new_display = display_name if (accept and display_name) else old_display
    new_emoji = emoji if (accept and emoji) else old_emoji
    new_keywords = keywords if (accept and keywords) else old_keywords

    for field, old, new in (
        ("display_name", old_display, new_display),
        ("emoji", old_emoji, new_emoji),
        ("keywords", old_keywords, new_keywords),
        ("review_status", old_status, new_status),
        ("human_verified", False, True),
    ):
        if old != new:
            _audit(con, merged_food_id, field, old, new, "human", sv)

    con.execute(
        """
        UPDATE merged_foods SET
            display_name = ?, emoji = ?, keywords = ?,
            review_status = ?, human_verified = TRUE, updated_at = current_timestamp
        WHERE merged_food_id = ?
        """,
        [new_display, new_emoji, new_keywords, new_status, merged_food_id],
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
    """Pipeline state by item, split by the data_type of the item's default.

    Counted over merged_foods because that is what review_status now describes.
    data_type comes from the item's representative food — an item can span
    several archives, and the representative is the row the app shows.
    """
    return con.execute(
        """
        SELECT f.data_type, m.review_status, count(*) AS n,
               sum(CASE WHEN m.brand_flagged THEN 1 ELSE 0 END) AS brand_flagged,
               sum(m.n_foods) AS foods
        FROM merged_foods m
        LEFT JOIN foods f ON f.fdc_id = m.merged_food_id
        GROUP BY f.data_type, m.review_status
        ORDER BY f.data_type, m.review_status
        """
    ).pl()


def audit_tail(con: duckdb.DuckDBPyConnection, limit: int = 50) -> pl.DataFrame:
    return con.execute(
        "SELECT * FROM audit_log ORDER BY timestamp DESC LIMIT ?", [limit]
    ).pl()
