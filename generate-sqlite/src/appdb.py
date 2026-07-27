"""Stage 7 — materialize the mobile-app catalog and export it to SQLite.

The pipeline tables are shaped for enrichment and review; the app needs the
opposite shape. This module builds ``app_*`` tables in DuckDB from them and
writes ``data/foods.sqlite``, a read-only asset the app bundles.

What the re-model buys, per screen:

* **Search list** — one narrow ``app_foods`` row with the four macros
  denormalized onto it, so a result row is a single read with no join. The
  old path (``food_macros``) re-scanned all 1M rows of the long nutrient
  table for every query. Results are collapsed to one row per Stage 6b
  merged item (:func:`_collapse_sql`) so the user sees one egg, not four.
* **Detail page** — one primary-key lookup in the wide ``app_food_nutrition``
  (the ~50 nutrients anyone displays), and a two-column index range scan in
  ``app_food_nutrients`` only if the user expands "all nutrients".
* **Recommender** — "high protein, low kcal" is an indexed scan over
  ``app_food_nutrition`` columns instead of self-joins over an EAV table.
* **Meal building** — ``app_food_pairs``, derived from real FNDDS recipes
  (see :func:`_pairs_sql`), answers "what goes with this" as one range scan.

Everything here is derived and idempotent: drop the app tables and re-run.
Nothing in this module writes to the pipeline tables, so the human-verified
lock is not a concern.
"""
from __future__ import annotations

import sqlite3
from pathlib import Path

import duckdb

from . import config, store

# Build order matters: app_foods reads its denormalized macros back out of
# app_food_nutrition, and app_food_nutrients filters against app_nutrients.
APP_TABLES = (
    "app_foods",
    "app_merged_foods",
    "app_food_nutrition",
    "app_nutrients",
    "app_food_nutrients",
    "app_food_portions",
    "app_food_pairs",
)

# Pipeline-only columns deliberately absent from app_foods: review_status,
# confidence, human_verified, brand_flagged, enriched_by/_reasoning,
# source_version, updated_at, fat_percentage, ndb_number, food_code,
# wweia_category_number, publication/start/end dates, usda_footnote. They are
# bookkeeping the phone has no use for and they are ~40% of the DuckDB file.
#
# One convention for the whole catalog: every nutrient amount is per 100 g of
# edible portion, which is how USDA reports all three ingested data types.
APP_DDL = """
CREATE TABLE foods (
    food_id       INTEGER PRIMARY KEY,
    description   TEXT NOT NULL,
    display_name  TEXT,
    emoji         TEXT,
    prep_type     TEXT,
    variable_fat  INTEGER,
    category      TEXT,
    data_type     TEXT,
    commonness    REAL,
    kcal_100g     REAL,
    protein_100g  REAL,
    fat_100g      REAL,
    carb_100g     REAL,
    serving_g     REAL,
    serving_label TEXT,
    merged_food_id INTEGER NOT NULL
);

-- Stage 6b's grouping: one row per food a user recognizes, with its
-- preparations and fat levels hanging off it as foods.merged_food_id.
-- merged_food_id IS the canonical variant's food_id, so a group id is a real,
-- loggable food and the group's macros, portions and nutrients are just that
-- foods row. Only variable_fat and n_foods are facts about the group rather
-- than about any member; the three display columns are duplicated from the
-- canonical row so the search list renders without a second lookup.
--
-- No FK: nothing else in this file declares one, and the catalog is read-only.
CREATE TABLE merged_foods (
    merged_food_id INTEGER PRIMARY KEY,
    display_name   TEXT NOT NULL,
    emoji          TEXT,
    category       TEXT,
    variable_fat   INTEGER NOT NULL,
    n_foods        INTEGER NOT NULL
);

CREATE TABLE nutrients (
    nutrient_id INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    unit        TEXT,
    sort_order  INTEGER
);

CREATE TABLE food_nutrients (
    food_id     INTEGER NOT NULL,
    nutrient_id INTEGER NOT NULL,
    amount      REAL NOT NULL,
    PRIMARY KEY (food_id, nutrient_id)
) WITHOUT ROWID;

CREATE TABLE food_portions (
    food_id     INTEGER NOT NULL,
    seq         INTEGER NOT NULL,
    label       TEXT NOT NULL,
    gram_weight REAL NOT NULL,
    PRIMARY KEY (food_id, seq)
) WITHOUT ROWID;

CREATE TABLE food_pairs (
    food_id      INTEGER NOT NULL,
    pair_food_id INTEGER NOT NULL,
    n_recipes    INTEGER NOT NULL,
    score        REAL NOT NULL,
    PRIMARY KEY (food_id, pair_food_id)
) WITHOUT ROWID;
"""

# app_food_nutrition's column list is generated from config.APP_NUTRIENTS, so
# it is not spelled out here. Neither are the log tables' — all three share
# _nutrient_cols(), so a new key in config lands in every one of them.
_NUTRITION_DDL = "CREATE TABLE food_nutrition (\n    food_id INTEGER PRIMARY KEY,\n    {}\n);"

# Only the columns the recommender actually sorts and filters on. An index per
# column on a ~50-column table would roughly double the file for queries
# nobody has written yet.
APP_INDEXES = (
    "CREATE INDEX ix_foods_category ON foods(category)",
    # Both merge reads are range scans on this: listing a group's variants, and
    # collapsing a search result set to one row per group.
    "CREATE INDEX ix_foods_merged ON foods(merged_food_id)",
    "CREATE INDEX ix_nut_kcal    ON food_nutrition(energy_kcal)",
    "CREATE INDEX ix_nut_protein ON food_nutrition(protein_g)",
    "CREATE INDEX ix_nut_fat     ON food_nutrition(fat_g)",
    "CREATE INDEX ix_nut_carb    ON food_nutrition(carb_g)",
    "CREATE INDEX ix_nut_fiber   ON food_nutrition(fiber_g)",
    "CREATE INDEX ix_pairs_score ON food_pairs(food_id, score DESC)",
)

# rowid = food_id in both. content='' (contentless) because we only ever want
# rowids and a bm25 score back, never the text — that keeps both indexes small.
#
# food_fts is the primary path: unicode61 tokenizing with prefix indexes for
# as-you-type search, three columns so bm25 can weight a name hit above a hit
# buried in the USDA text. `aka` carries USDA's own Common Name / Additional
# Description synonyms, which is what makes "hot dog" find Frankfurter, plus
# the Stage 4c LLM keywords (ingredients, cuisine, occasion) — same kind of
# text, same weight, so neither the schema nor the queries grow a column for it.
#
# `name` is coalesce(display_name, description) — the string the app displays —
# NOT display_name on its own. Indexing display_name as its own weighted column
# systematically promotes the enriched minority (2.4k of 13.7k foods have one)
# over better matches that simply have not been enriched yet: measured, it put
# "Ranch dip, yogurt based" above "Yogurt, Greek, plain" for `greek yogurt`,
# and "Imitation cheddar cheese" above "Cheese, cheddar". Ranking the string
# that is actually shown removes the bias, and it disappears from the query
# side entirely rather than needing weights tuned around it.
#
# food_fts_trgm is the typo fallback, queried only when the primary path
# returns too few rows. Note that MATCH-ing the misspelling itself against a
# trigram index finds nothing (one transposition breaks every trigram spanning
# it); the caller must split the query into trigrams and OR them, letting bm25
# rank by shared-trigram overlap. See search_sql() for the exact shape.
FTS_DDL = (
    "CREATE VIRTUAL TABLE food_fts USING fts5("
    "name, description, aka, content='', prefix='2 3', "
    "tokenize='unicode61 remove_diacritics 2')",
    "CREATE VIRTUAL TABLE food_fts_trgm USING fts5(txt, content='', tokenize='trigram')",
)

# The schema for the app's own writable database. Not created here — the app
# creates it on first launch — but it belongs next to the catalog it joins
# against, so the two stay in step.
#
# ATTACH-ed alongside the read-only catalog rather than living inside it: a
# catalog upgrade is then "replace one file", with no user-data migration and
# no copy-on-first-launch of a ~25 MB bundle asset. The cost is that food_id
# cannot be a foreign key, which is also why the snapshot columns exist.
#
# Every nutrient in config.APP_NUTRIENTS is snapshotted onto the entry, per
# 100 g, not just the four macros — which buys all three screens at once. The
# hour timeline and any day/week/month nutrient average are one range scan over
# ix_log_day with no join and no coalesce, and the SQL is identical whether the
# entry came from the catalog, a custom food or a recipe. It also keeps history
# truthful: a USDA revision, an edit to a custom food, or a deleted custom food
# cannot change what a past day says. ~1.5 MB/year at 10 entries/day. Only the
# ~150-nutrient long tail still reads catalog.food_nutrients by food_id, absent
# for custom foods by construction.
#
# Exactly one of food_id / custom_food_id is set (CHECK), so there is no source
# discriminator column to keep in step with the two columns it would describe.
#
# A recipe is just a custom_foods row that has recipe_ingredients: its per-100 g
# nutrition is rolled up when saved, so every reader treats a recipe and a
# hand-entered food identically and log_entries needs no third case. A recipe
# keeping its own materialized vector is also what stops a nested recipe (one
# used as another's ingredient) from recursing: a roll-up reads its children's
# stored columns, one level deep. So the CHECK only has to block *direct*
# self-reference — a longer cycle costs staleness, not a hang. ix_ingredient_of
# is the reverse lookup that makes that staleness fixable: it finds the parents
# to re-roll when a custom-food ingredient changes.
#
# The roll-up itself is app-side. Per-100 g of the recipe is
#   sum(grams * coalesce(catalog.food_nutrition.x, custom_foods.x)) / sum(grams)
# LEFT JOIN-ed over both ingredient sources, which is why the two tables carry
# the same nutrient column names.
#
# recipe_steps is recipe_ingredients' shape again, so both children of a recipe
# read the same way, and cooking mode gets its ordering for free: WITHOUT ROWID
# stores rows in primary-key order, so ORDER BY seq needs no sort. Composite FKs
# tie recipe_step_ingredients to both children, so "this step uses the onions"
# cannot point at an ingredient or a step that does not exist.
#
# cook_session is the resume point for an interrupted cook. It is device-local
# and needs no exclusion list to stay that way: the pusher drains tables by
# their `dirty` column, and this one has none. Its composite FK means a session
# can only ever name a step that exists, and deleting that step resets the cook
# rather than resuming into nothing.
#
# ponytail: seq is identity as well as display order in both child tables. That
# is fine because the FK's default ON UPDATE NO ACTION *rejects* renumbering a
# linked ingredient rather than silently re-pointing the link — a reorder has to
# rewrite the link rows in the same transaction. If real drag-reordering is
# wanted, give them a separate `sort` column and leave seq immutable.
#
# ponytail: a recipe save must end with an UPDATE of custom_foods, because
# editing only step *text* changes no nutrition and so would never trip
# tr_custom_touch — the edit would sit there un-synced. One write path (the
# creation screen saves a whole recipe in one transaction) means one place to get
# this right. If steps ever become editable piecemeal, put AFTER
# INSERT/UPDATE/DELETE triggers on each child to touch the parent instead.
#
# custom_foods is what the food-creation screen writes, so unlike every other
# table here its values are typed by a human — hence the CHECKs, which are the
# only validation the schema can carry. The emoji one is a sanity gate, not a
# validator (SQLite cannot see grapheme clusters); schema.is_emoji is the real
# rule for the app to port. serving_label without serving_g is rejected because
# nutrition is per 100 g and log_entries.grams is NOT NULL: a food with no gram
# weight cannot be logged or counted at all.
#
# custom_food_portions is column-for-column catalog.food_portions, so the
# portion picker reads the same either side, with the same conventions — a label
# is a bare unit the app multiplies by quantity ('scoop'), and seq 1 is the
# default serving, denormalized onto serving_g/serving_label exactly as
# app_foods does it. The app writes the portion and that copy together; the
# catalog gets the same invariant for free from its build.
#
# Custom foods get no FTS5 index. `name LIKE '%x%'` over 500 of them measures
# 0.111 ms and a heavy user creates tens, so the virtual table, its triggers and
# its sync story would all be ceremony. Search merges them into the catalog
# results as a UNION ALL against search_sql()'s primary — which needs no change,
# because with the log DB as main its unqualified `foods`/`food_fts` fall
# through to the ATTACH-ed catalog. Note a cross-database VIEW is illegal in
# SQLite, so that merge lives in the app or beside search_sql(), not here.
#
# grams is authoritative; portion_qty/portion_label only record what the user
# picked. The label is snapshotted rather than a portion_seq kept, because
# _portions_sql renumbers seq on every export, so a catalog rebuild could
# silently turn a logged "2 x cup" into "2 x tbsp".
#
# logged_at is local wall clock, which is what a food log means by "when", and
# what makes local_date derivable instead of a second column that can disagree
# with it. Day/week/month stats are then plain string ranges, no timezone math.
#
# Sync is last-write-wins per row on updated_at, which is all a single-user food
# log needs: client-generated random ids (two offline devices cannot collide,
# and a re-push after a lost ack is an idempotent upsert), a `deleted` tombstone
# the timeline index excludes for free, and a `dirty` flag the pusher drains.
# No user_id — one user per device, and the backend takes identity from the auth
# token. Needs PRAGMA foreign_keys = ON per connection for the CASCADE to fire,
# and schema changes go through PRAGMA user_version: unlike the catalog, which
# is replaced wholesale, this file holds the only copy of the user's data.
_LOG_DDL = """
CREATE TABLE IF NOT EXISTS custom_foods (
    id            TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    name          TEXT NOT NULL,
    brand         TEXT,
    barcode       TEXT,
    emoji         TEXT DEFAULT '🍽️',
    variable_fat  INTEGER NOT NULL DEFAULT 0,
    serving_g     REAL,
    serving_label TEXT,
    {guarded},
    updated_at    INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    deleted       INTEGER NOT NULL DEFAULT 0,
    dirty         INTEGER NOT NULL DEFAULT 1,
    CHECK (length(trim(name)) > 0),
    CHECK (serving_g IS NULL OR serving_g > 0),
    CHECK (serving_label IS NULL OR serving_g IS NOT NULL),
    CHECK (emoji IS NULL OR (length(emoji) BETWEEN 1 AND 8 AND unicode(emoji) > 127))
);

CREATE TABLE IF NOT EXISTS custom_food_portions (
    custom_food_id TEXT NOT NULL REFERENCES custom_foods(id) ON DELETE CASCADE,
    seq            INTEGER NOT NULL,
    label          TEXT NOT NULL,
    gram_weight    REAL NOT NULL,
    PRIMARY KEY (custom_food_id, seq),
    CHECK (gram_weight > 0 AND length(trim(label)) > 0)
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS recipe_ingredients (
    recipe_id      TEXT NOT NULL REFERENCES custom_foods(id) ON DELETE CASCADE,
    seq            INTEGER NOT NULL,
    food_id        INTEGER,
    custom_food_id TEXT REFERENCES custom_foods(id),
    grams          REAL NOT NULL,
    PRIMARY KEY (recipe_id, seq),
    CHECK ((food_id IS NULL) <> (custom_food_id IS NULL)),
    CHECK (custom_food_id IS NULL OR custom_food_id <> recipe_id)
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS recipe_steps (
    recipe_id  TEXT NOT NULL REFERENCES custom_foods(id) ON DELETE CASCADE,
    seq        INTEGER NOT NULL,
    text       TEXT NOT NULL,
    duration_s INTEGER,
    PRIMARY KEY (recipe_id, seq),
    CHECK (length(trim(text)) > 0),
    CHECK (duration_s IS NULL OR duration_s > 0)
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS recipe_step_ingredients (
    recipe_id      TEXT NOT NULL,
    step_seq       INTEGER NOT NULL,
    ingredient_seq INTEGER NOT NULL,
    PRIMARY KEY (recipe_id, step_seq, ingredient_seq),
    FOREIGN KEY (recipe_id, step_seq)
        REFERENCES recipe_steps(recipe_id, seq) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id, ingredient_seq)
        REFERENCES recipe_ingredients(recipe_id, seq) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS cook_session (
    recipe_id  TEXT PRIMARY KEY,
    step_seq   INTEGER NOT NULL,
    started_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (recipe_id, step_seq)
        REFERENCES recipe_steps(recipe_id, seq) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS log_entries (
    id             TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    food_id        INTEGER,
    custom_food_id TEXT REFERENCES custom_foods(id),
    logged_at      TEXT NOT NULL,
    local_date     TEXT GENERATED ALWAYS AS (substr(logged_at, 1, 10)) VIRTUAL,
    grams          REAL NOT NULL,
    portion_qty    REAL,
    portion_label  TEXT,
    name           TEXT NOT NULL,
    emoji          TEXT,
    {cols},
    updated_at     INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    deleted        INTEGER NOT NULL DEFAULT 0,
    dirty          INTEGER NOT NULL DEFAULT 1,
    CHECK ((food_id IS NULL) <> (custom_food_id IS NULL))
);

CREATE TABLE IF NOT EXISTS sync_state (
    table_name TEXT PRIMARY KEY,
    cursor     TEXT,
    synced_at  INTEGER
);

CREATE INDEX IF NOT EXISTS ix_log_day
    ON log_entries(local_date, logged_at) WHERE deleted = 0;
CREATE INDEX IF NOT EXISTS ix_log_dirty    ON log_entries(id)  WHERE dirty = 1;
CREATE INDEX IF NOT EXISTS ix_custom_dirty ON custom_foods(id) WHERE dirty = 1;

-- Which recipes use this food? Needed to re-roll a parent recipe's nutrient
-- vector when one of its custom-food ingredients is edited, and to tell the user
-- what references a custom food they are trying to delete.
CREATE INDEX IF NOT EXISTS ix_ingredient_of
    ON recipe_ingredients(custom_food_id) WHERE custom_food_id IS NOT NULL;

-- Deliberately NOT unique: two devices offline can each save the same barcode,
-- and a unique index would make the *pull* fail and wedge the sync loop. A scan
-- resolves to the first hit; the index only keeps that a lookup.
CREATE INDEX IF NOT EXISTS ix_custom_barcode
    ON custom_foods(barcode) WHERE barcode IS NOT NULL AND deleted = 0;

-- Stamping updated_at in the schema rather than in every app UPDATE makes "a
-- local edit is always visible to the pusher" an invariant instead of a
-- discipline. The WHEN guard terminates regardless of PRAGMA recursive_triggers
-- and lets the pull path write the server's updated_at without being stamped
-- over.
CREATE TRIGGER IF NOT EXISTS tr_log_touch AFTER UPDATE ON log_entries
WHEN new.updated_at = old.updated_at BEGIN
    UPDATE log_entries SET updated_at = strftime('%s', 'now'), dirty = 1 WHERE id = new.id;
END;

CREATE TRIGGER IF NOT EXISTS tr_custom_touch AFTER UPDATE ON custom_foods
WHEN new.updated_at = old.updated_at BEGIN
    UPDATE custom_foods SET updated_at = strftime('%s', 'now'), dirty = 1 WHERE id = new.id;
END;
"""


def _nutrient_cols(indent: int = 4, check: bool = False) -> str:
    """The one nutrient column list: one REAL per config.APP_NUTRIENTS key.

    ``check`` adds a non-negative guard per column, for the table a human types
    into. It is deliberately NOT used on the catalog's food_nutrition or on
    log_entries: 10 real catalog rows carry a negative carb_g, because
    carbohydrate-by-difference goes slightly below zero for near-zero-carb meats
    ('Pork, belly, with skin, raw' is -0.705). Guarding the snapshot columns
    would make those foods unloggable. Either way the column *names* come from
    the same config loop, so the tables cannot drift apart.
    """
    guard = " CHECK ({0} IS NULL OR {0} >= 0)" if check else ""
    return (",\n" + " " * indent).join(
        f"{name} REAL" + guard.format(name) for name in config.APP_NUTRIENTS
    )


def nutrition_ddl() -> str:
    """CREATE TABLE for the wide nutrition table, one REAL per APP_NUTRIENTS key."""
    return _NUTRITION_DDL.format(_nutrient_cols())


def log_ddl() -> str:
    """CREATE statements for the app's writable log database — see the comment
    above _LOG_DDL for why it is shaped this way. Idempotent, so the app can
    run it on every launch."""
    return _LOG_DDL.format(cols=_nutrient_cols(), guarded=_nutrient_cols(check=True))


def _collapse_sql(fts: str, weights: str = "") -> str:
    """One search result per Stage 6b merged item, not per USDA row.

    The index still holds every variant, so typing "poached" or "80% lean"
    finds the group; only the result set collapses. A group is ranked by its
    best-matching variant and displayed as its canonical one.

    Three things make this work:

    * The weights are set with ``rank MATCH 'bm25(...)'`` rather than by
      calling ``bm25()`` in the SELECT list. An FTS5 auxiliary function is only
      legal in a query whose FROM is the FTS table itself — the moment the
      match is joined to anything, ``bm25()`` fails with "unable to use
      function bm25 in the requested context", and that is true of a subquery
      and a plain CTE alike. Reading the hidden ``rank`` column instead scores
      inside the subquery and hands out an ordinary number, which the join and
      the GROUP BY can then use. (``WITH … AS MATERIALIZED`` also works and
      scores identically, but needs SQLite 3.35+ for one extra scan.)
    * rank is negative-is-better, so ``min()`` is the best variant and the
      ascending ORDER BY is the same one the flat query used.
    * The ``c.*`` columns are bare under GROUP BY, but they are functionally
      dependent on the group key (the join is ``c.food_id = m.merged_food_id``),
      so SQLite's arbitrary-row rule has exactly one row to pick from.

    ``food_id`` is the canonical variant's — a real, loggable food — so an app
    that ignores n_foods still behaves, it just always logs the canonical
    preparation.
    """
    return f"""
        SELECT c.food_id, coalesce(c.display_name, c.description) AS name, c.emoji,
               c.kcal_100g, c.protein_100g, c.fat_100g, c.carb_100g,
               m.n_foods, m.variable_fat, min(s.rank) AS rank
        FROM (SELECT rowid, rank FROM {fts}
              WHERE {fts} MATCH ?{weights}) s
        JOIN foods v        ON v.food_id = s.rowid
        JOIN merged_foods m ON m.merged_food_id = v.merged_food_id
        JOIN foods c        ON c.food_id = m.merged_food_id
        GROUP BY m.merged_food_id
        ORDER BY rank
        LIMIT ?
    """


def search_sql() -> tuple[str, str]:
    """The two queries the app's search box runs. Returned rather than
    hardcoded in the app so the bm25 weights live next to the index that
    defines the columns they weight.

    Both return one row per merged item — see :func:`_collapse_sql`. The
    variants behind a row are ``SELECT * FROM foods WHERE merged_food_id = ?``.

    Primary: pass an FTS5 prefix expression, e.g. 'chick* brea*'.
    Fallback: run only when the primary returns too few rows; pass the query's
    trigrams OR-ed together, e.g. '"chi" OR "hik" OR "ikc" OR "kce" OR "cen"'.
    """
    return (
        _collapse_sql("food_fts", " AND rank MATCH 'bm25(10.0, 3.0, 1.0)'"),
        _collapse_sql("food_fts_trgm"),  # one column, so default weights are bm25()
    )


def trigram_query(text: str) -> str:
    """Build the OR-ed trigram MATCH expression for the typo fallback.

    A plain MATCH of the misspelling returns nothing, because a transposition
    breaks every trigram that spans it. OR-ing the individual trigrams instead
    turns the index into a shared-trigram scorer, which recovers 'chikcen
    breast' -> chicken breast and 'stawberry' -> strawberry.
    """
    t = text.lower()
    grams = {t[i:i + 3] for i in range(len(t) - 2) if t[i:i + 3].strip()}
    return " OR ".join(f'"{g}"' for g in sorted(grams))


# --------------------------------------------------------------------------
# Build (DuckDB side)
# --------------------------------------------------------------------------
def _aka_cte() -> str:
    """USDA's own shopper-facing synonyms, aggregated per food.

    Same source and same aggregation as store.select_enrichment_candidates —
    a food can carry several values, so it must be aggregated in a CTE rather
    than joined directly or it multiplies rows.
    """
    return """
        SELECT fdc_id,
               string_agg(DISTINCT value, '; ') AS aka
        FROM food_attributes
        WHERE attribute_type IN ('Common Name', 'Additional Description')
          AND coalesce(value, '') <> ''
        GROUP BY fdc_id
    """


def _portion_label_sql() -> str:
    """Human-readable portion label from USDA's three overlapping text columns.

    measure_unit is NULL on almost every row in this corpus and `modifier`
    carries the real unit text ('waffle, square', 'container (6 oz)'), so the
    unit is coalesced across all three and whichever wins is used verbatim.

    Every ingested portion is a measure of one, so the label is a bare unit the
    app multiplies by the logged quantity. FNDDS is the one source that writes
    the count into its text ('1 cup', '1 slice'); that leading '1 ' is stripped
    so its labels read like the others.
    """
    return r"""
        nullif(trim(coalesce(
            nullif(trim(measure_unit), ''),
            nullif(trim(modifier), ''),
            regexp_replace(trim(portion_description), '^1\s+', '')
        )), '')
    """


def _pairs_sql() -> str:
    """Co-occurrence pairs from FNDDS recipes.

    FNDDS survey foods are recipes and input_foods lists their ingredients.
    Those rows carry no fdc link, but ingredient_code is an SR-Legacy NDB
    number, so they resolve against foods.ndb_number — 14,153 of 18,584
    ingredient rows do, giving ~3.5k recipes with two or more catalog
    ingredients. That is measured "these foods appear in the same real meal"
    data, so the meal builder needs no LLM pairing pass.

    Scored by pointwise mutual information rather than raw count, so
    ubiquitous ingredients (salt, water, oil) do not pair with everything.
    Stored in both directions and pruned to the top N per food, so "what goes
    with this" is one index range scan.

    Ranking alone does the pruning; low-PMI pairs are kept with their score
    rather than filtered out here, so the app can pick its own threshold. A
    `score > 0` cut looks equivalent but silently empties the table on a small
    corpus, where every co-occurrence is exactly chance and PMI is 0.
    """
    return f"""
        WITH ingredient AS (
            SELECT DISTINCT i.fdc_id AS recipe_id, f.fdc_id AS food_id
            FROM input_foods i
            JOIN foods f ON f.ndb_number = i.ingredient_code
            WHERE coalesce(i.ingredient_code, '') <> ''
        ),
        n_recipes AS (SELECT count(DISTINCT recipe_id) AS total FROM ingredient),
        freq AS (SELECT food_id, count(*) AS n FROM ingredient GROUP BY food_id),
        pair AS (
            SELECT a.food_id AS food_id, b.food_id AS pair_food_id, count(*) AS n
            FROM ingredient a JOIN ingredient b USING (recipe_id)
            WHERE a.food_id <> b.food_id
            GROUP BY 1, 2
        ),
        scored AS (
            SELECT p.food_id, p.pair_food_id, p.n AS n_recipes,
                   ln((p.n * t.total) / (fa.n * fb.n::DOUBLE)) AS score,
                   row_number() OVER (
                       PARTITION BY p.food_id
                       ORDER BY ln((p.n * t.total) / (fa.n * fb.n::DOUBLE)) DESC, p.n DESC
                   ) AS rn
            FROM pair p
            JOIN freq fa ON fa.food_id = p.food_id
            JOIN freq fb ON fb.food_id = p.pair_food_id
            CROSS JOIN n_recipes t
        )
        SELECT food_id, pair_food_id, n_recipes, score
        FROM scored
        WHERE rn <= {int(config.MAX_PAIRS_PER_FOOD)}
    """


def build(con: duckdb.DuckDBPyConnection) -> dict[str, int]:
    """Materialize the app_* tables from the pipeline tables. Idempotent."""
    kept = ", ".join(str(n) for ids in config.APP_NUTRIENTS.values() for n in ids)

    # Wide nutrition first — app_foods reads its four list macros back out of
    # it, so the denormalized copy can never disagree with the detail page.
    con.execute(
        f"""
        CREATE OR REPLACE TABLE app_food_nutrition AS
        SELECT fdc_id AS food_id, {store.pivot_columns_sql(config.APP_NUTRIENTS)}
        FROM food_nutrients
        WHERE fdc_id IN (SELECT fdc_id FROM foods)
        GROUP BY fdc_id
        """
    )

    # Default serving = the first portion USDA lists. NULL when a food has
    # none, which the app reads as "per 100 g".
    con.execute(
        f"""
        CREATE OR REPLACE TABLE app_food_portions AS
        SELECT fdc_id AS food_id,
               row_number() OVER (PARTITION BY fdc_id ORDER BY seq_num NULLS LAST) AS seq,
               label, gram_weight
        FROM (
            SELECT fdc_id, seq_num, gram_weight, {_portion_label_sql()} AS label
            FROM food_portions
            WHERE gram_weight IS NOT NULL AND gram_weight > 0
        )
        WHERE label IS NOT NULL
        """
    )

    con.execute(
        f"""
        CREATE OR REPLACE TABLE app_foods AS
        SELECT f.fdc_id AS food_id,
               f.description,
               f.display_name,
               f.emoji,
               f.prep_type,
               f.variable_fat,
               f.food_category AS category,
               f.data_type,
               f.commonness,
               n.energy_kcal AS kcal_100g,
               n.protein_g   AS protein_100g,
               n.fat_g       AS fat_100g,
               n.carb_g      AS carb_100g,
               p.gram_weight AS serving_g,
               p.label       AS serving_label,
               coalesce(f.merged_food_id, f.fdc_id) AS merged_food_id
        FROM foods f
        LEFT JOIN app_food_nutrition n ON n.food_id = f.fdc_id
        LEFT JOIN app_food_portions p ON p.food_id = f.fdc_id AND p.seq = 1
        """
    )

    # Stage 6b's groups. Total by construction: a food Stage 6b never placed —
    # or every food, if Stage 6b has not run at all — gets a singleton group
    # here, so the join from foods can never drop a row and the export can
    # never ship a catalog pointing at groups that do not exist. Pairs with the
    # coalesce above, which is the other half of the same guarantee.
    con.execute(
        """
        CREATE OR REPLACE TABLE app_merged_foods AS
        SELECT m.merged_food_id, m.display_name, m.emoji,
               m.food_category AS category, m.variable_fat, m.n_foods
        FROM merged_foods m
        UNION ALL
        SELECT f.fdc_id, coalesce(f.display_name, f.description), f.emoji,
               f.food_category, FALSE, 1
        FROM foods f WHERE f.merged_food_id IS NULL
        """
    )

    # Long tail: everything NOT already a column in app_food_nutrition, so no
    # amount is stored twice. Names and units are deduped into app_nutrients
    # instead of repeating on every one of the rows.
    con.execute(
        f"""
        CREATE OR REPLACE TABLE app_nutrients AS
        SELECT nutrient_id,
               any_value(nutrient_name) AS name,
               any_value(unit_name) AS unit,
               CAST(coalesce(any_value(nutrient_rank), 999999) AS INTEGER) AS sort_order
        FROM food_nutrients
        WHERE nutrient_id NOT IN ({kept}) AND nutrient_name IS NOT NULL
        GROUP BY nutrient_id
        """
    )
    con.execute(
        f"""
        CREATE OR REPLACE TABLE app_food_nutrients AS
        SELECT fdc_id AS food_id, nutrient_id, amount
        FROM food_nutrients
        WHERE nutrient_id NOT IN ({kept})
          AND amount IS NOT NULL
          AND fdc_id IN (SELECT fdc_id FROM foods)
          AND nutrient_id IN (SELECT nutrient_id FROM app_nutrients)
        """
    )

    con.execute(f"CREATE OR REPLACE TABLE app_food_pairs AS {_pairs_sql()}")

    con.execute(
        f"""
        CREATE OR REPLACE TABLE app_food_fts AS
        SELECT f.fdc_id AS food_id,
               coalesce(f.display_name, f.description) AS name,
               f.description,
               -- concat_ws drops the NULL side, so a food with only one of the
               -- two still gets a clean value (and '' when it has neither)
               concat_ws('; ', nullif(a.aka, ''), nullif(f.keywords, '')) AS aka,
               -- trgm is the typo fallback for what the user *sees*; keywords
               -- stay out of it, where they would only add wrong-food noise
               lower(concat_ws(' ', coalesce(f.display_name, f.description),
                               coalesce(a.aka, ''))) AS trgm
        FROM foods f
        LEFT JOIN ({_aka_cte()}) a ON a.fdc_id = f.fdc_id
        """
    )

    return {
        t: con.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
        for t in APP_TABLES + ("app_food_fts",)
    }


# --------------------------------------------------------------------------
# Export (SQLite side)
# --------------------------------------------------------------------------
def export_sqlite(
    con: duckdb.DuckDBPyConnection, path: Path | str = config.SQLITE_PATH
) -> dict[str, int]:
    """Write the app_* tables to a fresh SQLite file with FTS and indexes.

    Two engines, one schema: the DDL above uses only type names both accept,
    so the app's tables are declared once. DuckDB's sqlite extension does the
    bulk copy; the stdlib sqlite3 module does the parts DuckDB cannot express
    (FTS5 virtual tables, WITHOUT ROWID, ANALYZE, VACUUM).
    """
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.unlink(missing_ok=True)
    # A stale -wal/-shm from a previous run would be replayed into the new file.
    for suffix in ("-wal", "-shm"):
        path.with_name(path.name + suffix).unlink(missing_ok=True)

    # Declare the schema first, so the copy inherits these types and primary
    # keys rather than whatever DuckDB would infer.
    with sqlite3.connect(path) as sq:
        sq.executescript(APP_DDL)
        sq.execute(nutrition_ddl())

    con.execute("INSTALL sqlite; LOAD sqlite;")
    con.execute(f"ATTACH '{path}' AS app (TYPE sqlite)")
    try:
        for src in APP_TABLES:
            dest = src.removeprefix("app_")
            # BY NAME, not positional: APP_DDL and the build() SELECT lists are
            # two hand-written column orders, and a positional copy would
            # silently write commonness into kcal_100g the day they drift.
            con.execute(f"INSERT INTO app.{dest} BY NAME SELECT * FROM {src}")
    finally:
        con.execute("DETACH app")

    fts_rows = con.execute(
        "SELECT food_id, name, description, aka, trgm FROM app_food_fts"
    ).fetchall()

    counts: dict[str, int] = {}
    with sqlite3.connect(path) as sq:
        for ddl in FTS_DDL:
            sq.execute(ddl)
        sq.executemany(
            "INSERT INTO food_fts(rowid, name, description, aka) VALUES (?,?,?,?)",
            [(r[0], r[1], r[2], r[3]) for r in fts_rows],
        )
        sq.executemany(
            "INSERT INTO food_fts_trgm(rowid, txt) VALUES (?,?)",
            [(r[0], r[4]) for r in fts_rows],
        )
        for ddl in APP_INDEXES:
            sq.execute(ddl)
        # ANALYZE ships sqlite_stat1 inside the file, so the on-device query
        # planner is right from the first launch instead of after a warm-up.
        sq.execute("ANALYZE")
        for src in APP_TABLES:
            dest = src.removeprefix("app_")
            counts[dest] = sq.execute(f"SELECT count(*) FROM {dest}").fetchone()[0]
    # VACUUM cannot run inside the transaction the context manager opens.
    sq = sqlite3.connect(path)
    sq.execute("VACUUM")
    sq.close()

    counts["_bytes"] = path.stat().st_size
    return counts


def run(
    con: duckdb.DuckDBPyConnection, path: Path | str = config.SQLITE_PATH
) -> dict[str, int]:
    """Build + export in one call — what the notebook's Stage 7 button runs."""
    build(con)
    return export_sqlite(con, path)
