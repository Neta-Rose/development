# fdc-enrich

Reproducible, resumable pipeline that turns USDA FoodData Central's generic
foods (**Foundation Foods, SR Legacy, FNDDS/Survey** — no Branded) into a
clean, LLM-enriched catalog with a human-review loop.

- **Notebook**: [marimo](https://marimo.io) (`notebook.py`) — thin
  orchestration driver + review UI. All real logic is in importable modules
  under `src/`.
- **Storage**: DuckDB at `data/foods.duckdb` — the single source of truth.
  In-memory frames are never authoritative.
- **LLM**: OpenRouter via the OpenAI-compatible client, async with strict
  JSON-schema structured outputs, validated with pydantic.

## Setup

Requires Python 3.11+ and [uv](https://docs.astral.sh/uv/).

```bash
cd fdc-enrich
uv sync
cp .env.example .env    # then paste your OpenRouter key into .env
```

`OPENROUTER_API_KEY` is the only required secret. It is loaded from `.env`
via python-dotenv; nothing is ever hardcoded and `.env` is gitignored.

## Getting the FDC data

Stage 1 discovers the current full-download CSV zips at runtime by scraping
[FDC's download-datasets page](https://fdc.nal.usda.gov/download-datasets)
(archives are re-released periodically, so URLs are not pinned) and
downloads them into `data/raw/`.

If automatic download fails (offline, page layout change), download these
three archives manually from that page and drop them into `data/raw/` —
the loader picks up the newest matching file by name:

- `FoodData_Central_foundation_food_csv_<date>.zip`
- `FoodData_Central_sr_legacy_food_csv_<date>.zip`
- `FoodData_Central_survey_food_csv_<date>.zip`

## Running

```bash
uv run marimo edit notebook.py
```

Then follow the notebook top to bottom. Every expensive or side-effecting
stage is gated behind a run button (marimo reactivity can never auto-fire
API calls):

1. **Ingest** — download/extract archives, normalize into DuckDB
   (`fdc_id`, verbatim `data_type`, category, `description`,
   fat g/100g, `source_version`).
2. **Abbreviation expansion** — deterministic, idempotent whole-token
   expansion (`NFS` → `not further specified`, `w/o` → `without`) applied to
   `description` in place; regex extraction of `fat_percentage` from
   `% lean` / `% fat` / `% milkfat`. Every substitution lands in
   `cleanup_log`. Casing, unicode and whitespace normalization used to live
   here and were removed: measured over the corpus they rewrote 2,100+ rows
   no consumer could perceive, while the casing pass lowercased proper nouns
   and destroyed the brand signal on ~1,000 rows outside `BRAND_TOKENS`.
3. **Brand detection** — SR Legacy rows with brand names in the description
   get `brand_flagged` (brand list + ALL-CAPS heuristic, pure rules).
4. **Sample enrichment (~200 rows)** — run this first; it reports measured
   token cost/latency and projects the full-run cost.
5. **Full enrichment** — async OpenRouter calls, one food item per request,
   paced to `REQUESTS_PER_MINUTE` with `CONCURRENCY` requests in flight and
   tenacity backoff on 429/5xx (honouring `Retry-After`). Malformed output is
   retried once, then routed to `needs_review`. Every row is persisted
   immediately, so the run is safe to interrupt and re-run: completed rows are
   skipped.
6. **Review** — the `needs_review` queue in a marimo table; edit
   `display_name` / `emoji` / `prep_type` / `variable_fat`, then Accept (sets
   `review_status=verified`, `human_verified=true`) or Reject.
   6b. **Merge** — group the rows that are one food in several preparations
   or fat levels (four eggs, nine ground beefs) into `merged_foods`, keyed on
   the protein:carb:fat ratio, which is invariant to water and seasoning but
   not to a macro-bearing addition. 13,694 foods → 10,000 items; 2,192 groups
   hold more than one; largest is `Ground beef` at 29. Clustering is
   complete-linkage *inside a blocking key* — the obvious union-find over
   every close pair takes the transitive closure of a relation that is not
   transitive, and every threshold tried collapsed 8.5k–12.5k foods into one
   blob. Reasoning in `src/merge.py`.
7. **Export** — build the app-shaped `app_*` tables and write
   `../database/foods.sqlite`. See [The app catalog](#the-app-catalog-srcappdbpy).

### Invariants

- **Human-verified lock**: no automated pass ever writes a row where
  `human_verified = true` (enforced in every UPDATE in `src/store.py`).
- **Audit trail**: every write (auto or human) appends to `audit_log`.
- **Provenance**: `fdc_id` + `description` are retained end to end. Stage 2
  rewrites `description` in place, but every substitution is logged to
  `cleanup_log` + `audit_log` and the raw USDA text is always recoverable by
  re-running ingest against `data/raw/`.
- **Routing**: `confidence` covers the whole enrichment — `display_name`,
  `emoji`, `prep_type` and `variable_fat` — and is the model's *least* certain
  field, not an average, because the row publishes or not as a unit.
  `confidence >= 0.80` → `auto_approved`; below, plus all brand-flagged and
  validation-failed rows → `needs_review`. Thresholds in `src/config.py`.
- `fat_percentage` and `data_type` are deterministic (regex / verbatim) —
  never LLM outputs.

## The app catalog (`src/appdb.py`)

The pipeline tables are shaped for enrichment and review; a macro-logging app
needs the opposite. Stage 7 materializes `app_*` tables from them and exports
**`../database/foods.sqlite`** (~22 MB, from a 61 MB DuckDB) — a read-only catalog the
app bundles, with its search indexes already built. Derived and idempotent:
re-run it after any enrichment or review pass. It never writes to the pipeline
tables, so the human-verified lock is not a concern.

| table | shape | what it serves |
| --- | --- | --- |
| `foods` | 13.7k narrow rows, 4 macros denormalized on, `variable_fat`, `merged_food_id` | search list — one read, no join |
| `merged_foods` | 10k Stage 6b groups, `n_foods` + `variable_fat` | one search result per food a user recognizes; the variant picker behind it |
| `food_nutrition` | wide, one REAL per `config.APP_NUTRIENTS` key (~50) | detail page (PK lookup), recommender (indexed scans) |
| `nutrients` + `food_nutrients` | the ~200-nutrient long tail | "all nutrients" expander |
| `food_portions` | 27.4k measures of one, bare-unit labels | logging "2 × cup" instead of grams |
| `food_pairs` | co-occurrence, PMI-scored | meal building |
| `food_fts` / `food_fts_trgm` | FTS5, contentless | search + typo fallback |

Nothing is stored twice: a nutrient is either a `food_nutrition` column or a
`food_nutrients` row, never both. All amounts are per 100 g edible portion.

Only measures of **one** are ingested, so a portion label is a bare unit the
app multiplies (`cup`, `slice`, `container (6 oz)`). USDA states that two ways:
Foundation and SR Legacy set `amount = 1`, while FNDDS leaves `amount` empty
and writes the count into the text (`1 cup`), so both forms are filtered at
ingest and the column itself is dropped. FNDDS also fills `modifier` with a
numeric measure code rather than display text — nulled at ingest, or it would
win the label coalesce and ship `90000` as a serving name.
The old `food_macros` view is gone — it re-scanned all 1M rows of the long
table on every read.

**Search** is two queries (`appdb.search_sql()`). The primary path is an FTS5
prefix match ranked `bm25(food_fts, 10, 3, 1)` over `name` / `description` /
`aka`, where `name` is `coalesce(display_name, description)` — the string the
app displays. Indexing `display_name` as its own weighted column instead
systematically promotes the enriched minority (2.4k of 13.7k rows have one):
measured, it ranked "Ranch dip, yogurt based" above "Yogurt, Greek, plain".
`aka` carries USDA's own Common Name / Additional Description synonyms, which
is what makes "hot dog" find Frankfurter.

Both queries return one row per Stage 6b merged item, ranked by the group's
best-matching variant. Every variant stays indexed — only the result set
collapses, so "poached" still finds the egg group and shows it as "Whole raw
egg". The weights move into `rank MATCH 'bm25(…)'`: an FTS5 auxiliary function
is only legal in a query whose FROM is the FTS table itself, so the moment the
match is joined to `foods`, a `bm25()` call fails outright — in a subquery and
a plain CTE alike. Measured 1–9 ms across all 13.7k foods.

The fallback runs only when the primary returns too few rows. Note that
`MATCH 'chikcen'` against a trigram index finds **nothing** — one transposition
breaks every trigram spanning it. `appdb.trigram_query()` splits the query into
trigrams and ORs them, turning the index into a shared-trigram scorer:
`chikcen breast` → Chicken breast, `stawberry` → Strawberry, `yoghurt` →
Yogurt. Measured 0.2–7 ms across all 13.7k foods.

**The user's log** is a *separate* writable database (`appdb.log_ddl()`),
ATTACH-ed next to the read-only catalog. A catalog upgrade is then "replace one
file", with no user-data migration and no copy-on-first-launch —
`../database/MIGRATION_MERGED_FOODS.md` is what that looks like in practice for the
merge. Eight tables:

| table | holds |
| --- | --- |
| `log_entries` | one row per logged thing, whatever its source |
| `custom_foods` | user-created foods **and** recipes, per 100 g |
| `custom_food_portions` | the user's own units — "1 scoop = 32 g" |
| `recipe_ingredients` | so a recipe stays editable |
| `recipe_steps` | preparation steps, with optional per-step timers |
| `recipe_step_ingredients` | which ingredients a step uses |
| `cook_session` | resume point for an interrupted cook, device-local |
| `sync_state` | the pull cursor, one row per table |

One decision carries the whole schema: **every** nutrient in
`config.APP_NUTRIENTS` is snapshotted onto the entry, per 100 g, not just the
four macros. The hour timeline, a day's totals, and a day/week/month average of
any macro *or* micronutrient are then all the same shape — one range scan over
`ix_log_day`, no join, no `coalesce`, no `UNION` — and the SQL is identical
whether the entry came from the catalog, a hand-entered food or a recipe. It
also keeps history truthful: a USDA revision, an edit to a custom food, or a
deleted custom food cannot change what a past day says. ~1.5 MB/year at 10
entries/day. Only the ~150-nutrient long tail still joins
`catalog.food_nutrients`, absent for custom foods by construction.

Exactly one of `food_id` / `custom_food_id` is set, enforced by a `CHECK`, so
there is no source discriminator to keep in step with the columns it describes.
**A recipe is just a `custom_foods` row that has `recipe_ingredients`** — its
per-100 g nutrition is rolled up when saved, so every reader treats it and a
hand-entered food identically and `log_entries` needs no third case.
`logged_at` is local wall clock, which is what a food log means by "when", and
what lets `local_date` be a generated column instead of a second stored one that
can disagree with it; day ranges are then plain string comparisons with no
timezone math. `grams` is authoritative and `portion_label` is snapshotted
rather than a `portion_seq` kept, because `seq` is renumbered on every export —
a catalog rebuild could otherwise turn a logged "2 × cup" into "2 × tbsp".

**Recipes and cooking mode.** A recipe's per-100 g vector is
`sum(grams * coalesce(catalog.food_nutrition.x, custom_foods.x)) / sum(grams)` over its ingredients,
`LEFT JOIN`-ed across both sources — which is why the catalog's wide table and `custom_foods` carry
the same nutrient column names. Materializing that vector on the recipe is also what stops a *nested*
recipe from recursing: a roll-up reads its children's stored columns, one level deep, so the `CHECK`
only has to block direct self-reference and a longer cycle costs staleness rather than a hang.
`ix_ingredient_of` is the reverse lookup that makes the staleness fixable — it finds the parent
recipes to re-roll when an ingredient changes.

`recipe_steps` is `recipe_ingredients`' shape again, and cooking mode gets its ordering free:
`WITHOUT ROWID` stores rows in primary-key order, so `ORDER BY seq` plans as a bare
`SEARCH ... USING PRIMARY KEY` with no sort. Composite foreign keys tie `recipe_step_ingredients` to
both children, so "this step uses the onions" cannot name a step or an ingredient that does not
exist — and their default `ON UPDATE NO ACTION` *rejects* renumbering a linked ingredient instead of
silently re-pointing the link, so `seq` can serve as identity and display order at once.
`cook_session` is device-local with no exclusion list needed: the pusher drains tables by their
`dirty` column and this one has none. Its composite FK means a resume point always names a real step,
and deleting that step resets the cook instead of resuming into nothing.

**The food-creation screen** writes `custom_foods`, the one table here whose
values a human types, so it is the one carrying `CHECK` constraints: a non-blank
name, `serving_g > 0`, no `serving_label` without a gram weight (nutrition is per
100 g and `log_entries.grams` is NOT NULL, so a food with no weight cannot be
logged at all), non-negative nutrients, and a cheap emoji sanity gate —
`schema.is_emoji` is the real rule for the app to port, since SQLite cannot see
grapheme clusters. The icon defaults to 🍽️, the same fallback the enrichment
prompt uses. Those non-negative guards are on `custom_foods` **only**: 10 real
catalog rows have a negative `carb_g`, because carbohydrate-by-difference dips
below zero for near-zero-carb meats, and guarding the snapshot columns would make
raw pork belly unloggable. The form takes a label's per-serving numbers and the
app divides by `serving_g / 100` to store them, so the basis is always
`coalesce(serving_g, 100)` and no `basis_g` column is needed.

`barcode` is indexed but **not unique** — two devices offline can each save the
same barcode, and a unique index would make the *pull* fail and wedge the sync
loop. `custom_food_portions` is column-for-column `food_portions`, same bare-unit
labels, with seq 1 as the default serving denormalized onto
`custom_foods.serving_g/serving_label` exactly as `app_foods` does it. Custom
foods get **no FTS5 index**: `name LIKE '%x%'` over 500 of them measures 0.111 ms
and a heavy user creates tens, so search merges them into the catalog results as
a `UNION ALL` against `search_sql()`'s primary — which needs no change, because
with the log DB as `main` its unqualified `foods`/`food_fts` fall through to the
ATTACH-ed catalog. A cross-database *view* is illegal in SQLite, so that merge
lives in the app, not in the schema.

**Offline-first** is last-write-wins per row on `updated_at`, which is all a
single-user food log needs: ids are client-generated random hex (two offline
devices cannot collide, and a re-push after a lost ack is an idempotent upsert),
`deleted` tombstones are excluded from the timeline by the partial index itself,
and the pusher drains `WHERE dirty = 1` off a covering partial index. An
`AFTER UPDATE` trigger per table stamps `updated_at` and re-dirties the row, so
"a local edit is always visible to the pusher" is a schema invariant rather than
app discipline — its `WHEN` guard lets the pull path write the server's
`updated_at` without being stamped over. A custom food that history references
cannot be hard-deleted (the FK blocks it); soft-delete it and the tombstone
syncs. No `user_id` on device: one user per device, and the backend takes
identity from the auth token. Needs `PRAGMA foreign_keys = ON` per connection,
and schema changes go through `PRAGMA user_version` — unlike the catalog, which
is replaced wholesale, this file holds the only copy of the user's data.

`food_pairs` comes from real FNDDS recipes: `input_foods.ingredient_code` is an
SR-Legacy NDB number, so 14,153 of 18,584 ingredient rows resolve against
`foods.ndb_number`, giving ~3.5k recipes with two or more catalog ingredients.
Measured "these foods appear in the same meal" data — no LLM pairing pass.
Assembling a meal to a kcal/protein target is app-side search over `food_pairs`
and `food_nutrition`; the schema's job is to make each step one indexed lookup.

## Configuration

Everything tunable — model name (default `tencent/hy3`), request rate,
concurrency, confidence threshold, abbreviation dictionary, brand list,
protected tokens, category gates — lives in `src/config.py`.

**On a paid model the meter is tokens, not requests**, so pacing only buys wall
clock: `REQUESTS_PER_MINUTE = 0` disables it and `CONCURRENCY = 48` is what
governs throughput, putting a full 13.7k-row run in the 10-minute range. (On a
free tier, where OpenRouter meters the *account* at ~20 requests/minute, set
`REQUESTS_PER_MINUTE = 20` instead and expect ~12 hours.)

Cost is dominated by one number: the static instruction block is ~985 tokens
and ~96% of a run's input, because it is re-sent verbatim with every one-item
request. That makes **prompt caching** the only lever worth pulling — the item
payload is 3% of input, so no amount of re-encoding it (TOON, CSV, bare text)
is worth the quality risk of drifting from the JSON few-shot examples.

Caching is therefore measured, not assumed. Every request sets
`usage: {include: true}`, and the sample run reports the cache hit rate,
reasoning tokens, and OpenRouter's own `usage.cost` (post-discount, so it never
goes stale the way the `*_PRICE_PER_M` constants do). Caches are per-provider,
so if the hit rate is poor, pin routing with `PROVIDER_ORDER`. Watch the
reasoning-token count on any reasoning-capable model: if the provider ignores
`reasoning: {enabled: false}`, output cost goes up ~10x.

## Tests

```bash
uv run pytest
```

Covers the deterministic layers (cleanup, brand detection, schema,
store routing/locking) — no network or API key needed.
