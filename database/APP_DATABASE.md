# Database reference

The app reads two SQLite files. Open the **log** as `main` and attach the **catalog**:

```sql
-- log.sqlite is main; the catalog is attached beside it
ATTACH DATABASE '<path>/foods.sqlite' AS catalog;
PRAGMA foreign_keys = ON;   -- per connection, NOT stored in the file
```

Attaching this way means unqualified `foods`, `food_nutrition`, `food_fts` etc. resolve to the
catalog automatically (nothing in the log shadows those names), so catalog queries need no prefix.

| file | role | size | writable |
| --- | --- | --- | --- |
| `foods.sqlite` | USDA catalog, 13,694 foods, FTS indexes prebuilt | 20.8 MB | **no** — replaced wholesale on upgrade |
| `log.sqlite` | the user's log, custom foods, recipes | grows | yes — created by the app on first launch |

A catalog upgrade is "replace one file". Never write to it, and never store a foreign key into it:
`log_entries.food_id` is deliberately **not** an FK because the two live in different databases.

## The one convention

**Every nutrient amount in both databases is per 100 g of edible portion.** A real amount is always
`grams / 100.0 * <column>`. This holds for catalog foods, custom foods and recipes alike.

`serving_g IS NULL` means "this food has no defined serving — treat it as per 100 g".

---

# catalog (`foods.sqlite`, read-only)

## `foods` — 13,694 rows, one per USDA food

| column | type | notes |
| --- | --- | --- |
| `food_id` | INTEGER PK | the USDA FDC id |
| `description` | TEXT NOT NULL | raw USDA text, e.g. `Yogurt, Greek, plain, nonfat` |
| `display_name` | TEXT | clean name for UI, e.g. `Nonfat Greek yogurt` — 100% populated |
| `emoji` | TEXT | one emoji; 13,693 of 13,694 have one, so handle NULL |
| `prep_type` | TEXT | `raw`, `cooked`, `frozen`, `canned`, `roasted`, … — 48% populated |
| `variable_fat` | INTEGER | 1 for families sold at several fat levels (ground beef, milk). 448 foods |
| `category` | TEXT | USDA category, 197 distinct values. Indexed |
| `data_type` | TEXT | `sr_legacy_food` 7,793 · `survey_fndds_food` 5,432 · `foundation_food` 469 |
| `commonness` | REAL | 0.05–1.0, how likely this is in an ordinary kitchen (eggs ≈ 1) |
| `kcal_100g`, `protein_100g`, `fat_100g`, `carb_100g` | REAL | denormalized copy of the 4 list macros |
| `serving_g`, `serving_label` | REAL, TEXT | default serving = `food_portions` seq 1. 88% populated |

Display name is `coalesce(display_name, description)`.

## `food_nutrition` — 13,692 rows, wide, PK `food_id`

One REAL column per nutrient, **name carries the unit**. Two foods have no row here — `LEFT JOIN`.

- **macros** `energy_kcal` `protein_g` `fat_g` `carb_g` `fiber_g` `sugar_g` `starch_g` `water_g` `ash_g` `alcohol_g`
- **fats** `sat_fat_g` `mono_fat_g` `poly_fat_g` `trans_fat_g` `cholesterol_mg` `omega3_epa_g` `omega3_dha_g`
- **minerals** `calcium_mg` `iron_mg` `magnesium_mg` `phosphorus_mg` `potassium_mg` `sodium_mg` `zinc_mg` `copper_mg` `manganese_mg` `selenium_ug` `fluoride_ug` `iodine_ug`
- **vitamins** `vitamin_a_rae_ug` `retinol_ug` `carotene_beta_ug` `vitamin_c_mg` `vitamin_d_ug` `vitamin_e_mg` `vitamin_k_ug` `thiamin_mg` `riboflavin_mg` `niacin_mg` `pantothenic_acid_mg` `vitamin_b6_mg` `folate_ug` `folate_dfe_ug` `vitamin_b12_ug` `choline_mg` `biotin_ug`
- **other** `caffeine_mg` `theobromine_mg` `lycopene_ug` `lutein_zeaxanthin_ug`

Indexed for the recommender: `energy_kcal`, `protein_g`, `fat_g`, `carb_g`, `fiber_g`.

## `nutrients` + `food_nutrients` — the long tail

`nutrients(nutrient_id PK, name, unit, sort_order)` — 194 rows.
`food_nutrients(food_id, nutrient_id, amount)` PK both, 469,724 rows.

**Disjoint from `food_nutrition` by construction** — a nutrient is a wide column *or* a long-tail
row, never both. Only read this for an "all nutrients" expander:

```sql
SELECT n.name, n.unit, fn.amount
  FROM food_nutrients fn JOIN nutrients n USING (nutrient_id)
 WHERE fn.food_id = ? ORDER BY n.sort_order;
```

## `food_portions` — 27,404 rows, PK `(food_id, seq)`, WITHOUT ROWID

`label TEXT NOT NULL`, `gram_weight REAL NOT NULL`.

**Every portion is a measure of one**, so the label is a bare unit and the app multiplies:
`cup`, `slice`, `oz`, `container (6 oz)`, `waffle, round (4" dia)`. Render as `qty × label`.
`seq = 1` is the default serving. 1,599 foods have no portions at all.

⚠️ **`seq` is renumbered on every catalog rebuild.** Never persist it. Snapshot the label instead
(which is what `log_entries.portion_label` is for).

## `food_pairs` — 13,717 rows, PK `(food_id, pair_food_id)`

`n_recipes INTEGER`, `score REAL` — PMI-scored co-occurrence mined from real FNDDS recipes, both
directions stored, capped at 25 per food. Indexed `(food_id, score DESC)`.

```sql
SELECT pair_food_id, score FROM food_pairs WHERE food_id = ? ORDER BY score DESC LIMIT 10;
```

⚠️ **Sparse: only 1,320 of 13,694 foods have any pairs**, and they are all `sr_legacy_food` (1,122)
or `foundation_food` (198) — never FNDDS, because pairs come from FNDDS recipes whose ingredient
codes resolve to SR Legacy foods. Design "what goes with this" to degrade gracefully to nothing.

## `food_fts` / `food_fts_trgm` — FTS5, contentless, `rowid = food_id`

`food_fts(name, description, aka)` with `prefix='2 3'`, `unicode61 remove_diacritics 2`.
`aka` holds USDA synonyms plus generated keywords — this is why "hot dog" finds *Frankfurter*.

**Primary search** (pass a prefix expression like `chick* brea*`):

```sql
SELECT f.food_id, coalesce(f.display_name, f.description) AS name, f.emoji,
       f.kcal_100g, f.protein_100g, f.fat_100g, f.carb_100g
  FROM food_fts s JOIN foods f ON f.food_id = s.rowid
 WHERE food_fts MATCH ?
 ORDER BY bm25(food_fts, 10.0, 3.0, 1.0)
 LIMIT ?;
```

**Typo fallback** — run only when the primary returns too few rows, against `food_fts_trgm`:

```sql
SELECT f.food_id, coalesce(f.display_name, f.description) AS name, f.emoji, f.kcal_100g
  FROM food_fts_trgm s JOIN foods f ON f.food_id = s.rowid
 WHERE food_fts_trgm MATCH ? ORDER BY bm25(food_fts_trgm) LIMIT ?;
```

⚠️ `MATCH 'chikcen'` against a trigram index finds **nothing** — one transposition breaks every
trigram spanning it. You must split the query into 3-char grams and OR them:

```
"chi" OR "hik" OR "ikc" OR "kce" OR "cen"     -- lowercase, dedup, drop all-whitespace
```

That turns the index into a shared-trigram scorer and recovers `chikcen breast` → Chicken breast,
`stawberry` → Strawberry, `yoghurt` → Yogurt.

`sqlite_stat1` ships inside the file, so the planner is correct from the first query — do not
`ANALYZE` on device.

---

# log (`log.sqlite`, writable, `user_version = 1`)

Eight tables. All ids are client-generated 128-bit random hex, defaulted in SQL
(`lower(hex(randomblob(16)))`) so two offline devices can never collide.

## `log_entries` — one row per logged thing

| column | type | notes |
| --- | --- | --- |
| `id` | TEXT PK | defaulted random hex |
| `food_id` | INTEGER | catalog `foods.food_id`; no FK (other database) |
| `custom_food_id` | TEXT → `custom_foods(id)` | for a custom food or a recipe |
| `logged_at` | TEXT NOT NULL | **local wall clock**, `YYYY-MM-DDTHH:MM` |
| `local_date` | TEXT GENERATED VIRTUAL | `substr(logged_at, 1, 10)`, indexed |
| `grams` | REAL NOT NULL | authoritative amount |
| `portion_qty`, `portion_label` | REAL, TEXT | what the user picked: `2` × `cup` |
| `name`, `emoji` | TEXT | snapshot, so the timeline needs no join |
| *~50 nutrient columns* | REAL | **per 100 g**, same names as `food_nutrition` |
| `updated_at` | INTEGER NOT NULL | unix **seconds**, the sync clock |
| `deleted`, `dirty` | INTEGER NOT NULL | tombstone / needs-push |

`CHECK ((food_id IS NULL) <> (custom_food_id IS NULL))` — exactly one source, so there is no
discriminator column to keep in step.

**The whole nutrient vector is snapshotted per entry**, not just macros. So every read — timeline,
day totals, a monthly average of selenium — is one index range scan with no join and identical SQL
regardless of source, and history can't be rewritten by a catalog upgrade or by the user editing a
custom food. Editing quantity writes `grams` alone.

⚠️ `local_date` is a VIRTUAL generated column: it is **absent from `PRAGMA table_info`** (use
`table_xinfo`, hidden flag 2) but **present in `SELECT *`**. Schema-introspecting ORMs and codegen
will miss it.

## `custom_foods` — user-created foods **and** recipes

`id` PK · `name` NOT NULL · `brand` · `barcode` · `emoji` (defaults `🍽️`) · `variable_fat` ·
`serving_g` · `serving_label` · *~50 nutrient columns, per 100 g* · `updated_at` · `deleted` · `dirty`

Constraints, because this is the one table a human types into:

```
CHECK (length(trim(name)) > 0)
CHECK (serving_g IS NULL OR serving_g > 0)
CHECK (serving_label IS NULL OR serving_g IS NOT NULL)   -- a label needs a gram weight
CHECK (emoji IS NULL OR (length(emoji) BETWEEN 1 AND 8 AND unicode(emoji) > 127))
CHECK (<each nutrient> IS NULL OR <each nutrient> >= 0)
```

**A recipe is a `custom_foods` row that has `recipe_steps`/`recipe_ingredients`** — nothing else
distinguishes them, and `log_entries` needs no third case. List them apart with
`EXISTS (SELECT 1 FROM recipe_ingredients WHERE recipe_id = custom_foods.id)`.

`ix_custom_barcode` on `barcode` is **not unique** on purpose: two offline devices can save the same
barcode, and a unique index would make the *pull* fail. Scanning resolves to the first hit.

Form input is per serving; storage is per 100 g. Divide by `coalesce(serving_g, 100) / 100` on save
and multiply back to redisplay.

## `custom_food_portions` — the user's own units

`(custom_food_id, seq)` PK, WITHOUT ROWID, `label`, `gram_weight`, cascade on delete.
Column-for-column `food_portions`: bare-unit labels, `seq 1` is the default serving and is
denormalized onto `custom_foods.serving_g/serving_label` — write both together.

## `recipe_ingredients` — `(recipe_id, seq)` PK, WITHOUT ROWID

`food_id` | `custom_food_id` (exactly one, same `CHECK`), `grams` NOT NULL.
`CHECK (custom_food_id IS NULL OR custom_food_id <> recipe_id)` blocks direct self-reference.
`ix_ingredient_of` on `custom_food_id` answers "which recipes use this food".

A recipe's nutrients are rolled up from its ingredients and written to its own columns:

```sql
SELECT sum(i.grams) AS total_g,
       sum(i.grams * coalesce(n.protein_g, cf.protein_g)) / sum(i.grams) AS protein_g,  -- × ~50
  FROM recipe_ingredients i
  LEFT JOIN catalog.food_nutrition n ON n.food_id = i.food_id
  LEFT JOIN custom_foods cf ON cf.id = i.custom_food_id
 WHERE i.recipe_id = ?;
```

Because every recipe stores its own materialized vector, this reads **one level deep and never
recurses** — a nested recipe just contributes its stored columns. So a longer cycle (A uses B, B
uses A) is harmless: it costs staleness, not a hang. When an ingredient changes, re-roll the parents
found via `ix_ingredient_of`.

## `recipe_steps` — `(recipe_id, seq)` PK, WITHOUT ROWID

`text` NOT NULL (non-blank), `duration_s` INTEGER nullable (`> 0`) for a step timer.
`WITHOUT ROWID` stores rows in PK order, so `ORDER BY seq` needs no sort.

## `recipe_step_ingredients` — which ingredients a step uses

`(recipe_id, step_seq, ingredient_seq)` PK, WITHOUT ROWID, composite FKs to **both**
`recipe_steps(recipe_id, seq)` and `recipe_ingredients(recipe_id, seq)`, cascading.

⚠️ `seq` is identity *and* display order in both child tables. The FKs' default
`ON UPDATE NO ACTION` **rejects** renumbering a linked ingredient rather than silently re-pointing
the link — so reordering must rewrite the link rows in the same transaction.

## `cook_session` — resume point for an interrupted cook

`recipe_id` PK, `step_seq` NOT NULL, `started_at` INTEGER. Composite FK to
`recipe_steps(recipe_id, seq)`, so it can only name a real step; deleting that step resets the cook.

**Device-local: it has no `dirty` column, so it is never pushed.** Nothing else is needed to keep it
off the wire.

## `sync_state` — `table_name` PK, `cursor`, `synced_at`

---

# Queries by screen

**Timeline for a day, grouped by hour** — one range scan, no joins:

```sql
SELECT substr(logged_at, 12, 2) AS hour, id, name, emoji,
       grams / 100.0 * energy_kcal AS kcal,
       grams / 100.0 * protein_g   AS protein,
       grams / 100.0 * fat_g       AS fat,
       grams / 100.0 * carb_g      AS carb
  FROM log_entries
 WHERE deleted = 0 AND local_date = ?
 ORDER BY logged_at;
```

**Any nutrient, averaged per day over a range** — same shape for macros and micros:

```sql
SELECT count(DISTINCT local_date) AS days,
       sum(grams / 100.0 * sodium_mg) / count(DISTINCT local_date) AS avg_sodium_mg
  FROM log_entries
 WHERE deleted = 0 AND local_date BETWEEN ? AND ?;
```

For week/month buckets, group on `strftime('%Y-%W', local_date)` / `substr(local_date, 1, 7)`.

⚠️ `sum()` over all-NULL returns **NULL**, not 0. Use `total()` if you want 0.

**Search: catalog + the user's own foods in one result set.**

⚠️ **Do not rank by bare `bm25`.** For a one-word query it barely discriminates: all 182 `pasta`
matches score between −8.95 and −8.78, so the winner is document-length noise ("Spinach pasta"
beat "Cooked pasta"). Rank by a composite score instead:

```sql
SELECT f.food_id, coalesce(f.display_name, f.description) AS name, f.emoji,
       f.kcal_100g, f.protein_100g, f.fat_100g, f.carb_100g, f.serving_g, f.serving_label
  FROM food_fts s
  JOIN foods f ON f.food_id = s.rowid
  LEFT JOIN (SELECT food_id, count(*) AS n FROM log_entries
              WHERE deleted = 0 AND food_id IS NOT NULL AND local_date >= ?1
              GROUP BY food_id) r ON r.food_id = f.food_id
 WHERE food_fts MATCH ?2
 ORDER BY bm25(food_fts, 10.0, 3.0, 1.0) * (1
     + 1.0 * coalesce(f.commonness, 0.4)                -- likely in an ordinary kitchen
     + 0.3 * (f.prep_type IS 'cooked')                  -- you log cooked pasta, not dry
     + 1.5 * min(coalesce(r.n, 0), 3) / 3.0             -- logged lately, saturating
     + 0.6 * (lower(coalesce(f.display_name, f.description)) = lower(?3))
     - 0.3 * (<name||description> LIKE '%restaurant%'   -- institutional / infant variants
           OR <…> LIKE '%school lunch%' OR <…> LIKE '%baby food%'))
 LIMIT ?4;
```

Three ways to break this expression:

1. **bm25 is negative.** A bigger multiplier is a *smaller* number, so `ORDER BY score` stays
   ascending, best-first. The multiplier floor is `1 + 1.0*0.05 − 0.3 = 0.75`, so it can never reach
   zero and flip the ordering — keep it that way if you retune the weights.
2. **`prep_type IS 'cooked'`, never `= 'cooked'`.** `prep_type` is 52% NULL; `=` yields NULL there,
   NULL poisons the whole product, and NULL sorts **first**. Same care for any new column term.
3. **Sort before the `LIMIT`.** "Cooked pasta" sits at bm25 ranks 26 and 41–45 of 182, so re-ranking
   an already-limited result set in Dart cannot see it. That is why the score lives in SQL.

Multiplicative, not additive, because the bm25 spread is query-dependent — `chicken` spans 0.37,
`chicken brea` spans 2.35. Scaling by bm25 magnitude keeps one set of weights honest across both.

The trigram fallback uses the same expression with `bm25(food_fts_trgm)`, but its hits are
**appended after** the exact ones rather than merged: the two indexes produce non-comparable bm25
magnitudes, and a fuzzy hit is always the lower-confidence answer.

Custom foods have **no FTS index** and need none — a `LIKE` scan over 500 of them measures 0.111 ms.
With no bm25 to rank by they order on `count(*) DESC, max(logged_at) DESC` over the same window.
Note a cross-database **VIEW is illegal in SQLite**, so this must stay inline in the app — the
catalog and `log_entries` join fine within one connection, but only as a hand-written statement.

**Recently logged, for re-logging:**

```sql
SELECT food_id, custom_food_id, name, emoji, count(*) AS n, max(logged_at) AS last
  FROM log_entries
 WHERE deleted = 0 AND local_date >= ?
 GROUP BY food_id, custom_food_id
 ORDER BY n DESC, last DESC LIMIT 20;
```

**Cooking mode** — steps with their ingredients, all PK lookups:

```sql
SELECT s.seq, s.text, s.duration_s, i.seq AS ing_seq, i.grams,
       coalesce(f.display_name, f.description, cf.name) AS ingredient
  FROM recipe_steps s
  LEFT JOIN recipe_step_ingredients l ON l.recipe_id = s.recipe_id AND l.step_seq = s.seq
  LEFT JOIN recipe_ingredients i ON i.recipe_id = l.recipe_id AND i.seq = l.ingredient_seq
  LEFT JOIN catalog.foods f ON f.food_id = i.food_id
  LEFT JOIN custom_foods cf ON cf.id = i.custom_food_id
 WHERE s.recipe_id = ? ORDER BY s.seq, i.seq;
```

`LEFT JOIN` throughout so a step with no tagged ingredients still renders.

---

# Sync

Offline-first: **all reads and writes hit the local database.** Nothing in the UI path waits on the
network. Conflict resolution is last-write-wins per row on `updated_at`.

- **Push** — `WHERE dirty = 1` (a partial index, so an empty queue costs nothing). Upsert on the
  client-generated `id`, so a retry after a lost ack is a no-op. On ack:
  `UPDATE … SET dirty = 0 WHERE id = ? AND updated_at = ?` — an edit made mid-flight stays dirty
  instead of being silently dropped.
- **Pull** — `WHERE updated_at > cursor`, then
  `ON CONFLICT(id) DO UPDATE … WHERE excluded.updated_at > log_entries.updated_at`.
- **Deletes** — set `deleted = 1`; the timeline's partial index excludes tombstones for free. Hard
  delete only after the server acks.
- **Sync units** — `custom_food_portions`, `recipe_ingredients`, `recipe_steps` and
  `recipe_step_ingredients` have no sync columns: they push as part of their parent `custom_foods`
  row, and the server replaces the whole child set.
- **No `user_id` on device** — one user per device; the backend takes identity from the auth token.

⚠️ An `AFTER UPDATE` trigger on `log_entries` and `custom_foods` stamps `updated_at` and re-sets
`dirty = 1`. Its `WHEN new.updated_at = old.updated_at` guard means the **pull path must write the
server's `updated_at` explicitly**, or the trigger will overwrite it with local time.

⚠️ Editing only a recipe's step *text* changes no nutrition, so nothing touches `custom_foods` and
the edit would never sync. **A recipe save must end with**
`UPDATE custom_foods SET updated_at = strftime('%s','now'), dirty = 1 WHERE id = ?`.

---

# Gotchas checklist

1. Multiply by `grams / 100.0`. Always. Every stored amount is per 100 g.
2. `serving_g IS NULL` means per 100 g, not "unknown".
3. Portion labels are measures of **one** — render `qty × label`, never assume the label contains a count.
4. Never persist a catalog `food_portions.seq`; it is renumbered on every rebuild.
5. **`carb_g` can be negative** (10 catalog foods, e.g. `Pork, belly, with skin, raw` = −0.705).
   That is real USDA carbohydrate-by-difference. Do not validate logged nutrients as `>= 0`, or
   those foods become unloggable. The `>= 0` checks apply only to `custom_foods`.
6. `LEFT JOIN` the catalog: 2 foods have no `food_nutrition` row, 1,599 have no portions, 1 has no emoji.
7. `local_date` is invisible to `PRAGMA table_info` but present in `SELECT *`.
8. `PRAGMA foreign_keys = ON` on every connection, or the cascades silently do nothing.
9. `sum()` of all NULLs is NULL — `total()` returns 0.
10. Trigram fallback needs the query split into OR-ed 3-grams; matching the misspelling directly returns nothing.
11. A custom food referenced by history cannot be hard-deleted — the FK blocks it. Soft-delete it.
12. `updated_at` is unix **seconds**, not milliseconds.
13. Search ranks on a composite score, not bare `bm25` — which is **negative**, so a larger
    multiplier sorts earlier. Sort before the `LIMIT`, and compare `prep_type` with `IS` (it is 52%
    NULL, and a NULL term poisons the product and sorts first).
