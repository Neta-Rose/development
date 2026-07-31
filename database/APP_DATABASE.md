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
| `foods.sqlite` | USDA catalog, 13,694 foods in 6,809 merged items, FTS prebuilt | 21.7 MB | **no** — replaced wholesale on upgrade |
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
| `prep_type` | TEXT | `raw`, `cooked`, `frozen`, `canned`, `roasted`, … — 42% populated |
| `variable_fat` | INTEGER | 1 for families sold at several fat levels (ground beef, milk). 448 foods |
| `category` | TEXT | USDA category, 197 distinct values. Indexed |
| `data_type` | TEXT | `sr_legacy_food` 7,793 · `survey_fndds_food` 5,432 · `foundation_food` 469 |
| `commonness` | REAL | 0.05–1.0, how likely this is in an ordinary kitchen (eggs ≈ 1) |
| `kcal_100g`, `protein_100g`, `fat_100g`, `carb_100g` | REAL | denormalized copy of the 4 list macros |
| `serving_g`, `serving_label` | REAL, TEXT | default serving = `food_portions` seq 1. 88% populated |
| `merged_food_id` | INTEGER NOT NULL | the **item** this food belongs to. Indexed |
| `prep_id` | INTEGER NOT NULL | the **preparation** this food belongs to; `= food_id` on the one that represents it |

`display_name`, `emoji`, `commonness` and `variable_fat` are denormalized **down** from the
item, and `prep_type` across from the preparation, so every food carries the strings the app
shows — `log_entries` snapshots them per food. Display name is
`coalesce(display_name, description)`.

## `merged_foods` — 6,809 rows, one per food a user recognizes

The catalog holds one row per USDA record, so a user searching for "chicken thigh" used to meet
56 of them and ground beef is nine rows at nine fat levels. This table is the **item**: one row
in the search list. `foods.merged_food_id` points each food at its item.

| column | type | notes |
| --- | --- | --- |
| `merged_food_id` | INTEGER PK | **is** the default preparation's `food_id` — a real, loggable food |
| `display_name` | TEXT | the item's name, e.g. `Chicken thigh`. NULL until Stage 4 runs |
| `emoji` | TEXT | one emoji for the item |
| `prep_type` | TEXT | the **default** preparation's label; what the ranking's cooked-food bonus reads |
| `category` | TEXT | the default member's USDA category |
| `commonness` | REAL | 0.05–1.0, how likely this is in an ordinary kitchen (eggs ≈ 1) |
| `variable_fat` | INTEGER NOT NULL | 1 when the item spans fat levels (ground beef, milk) |
| `n_foods` | INTEGER NOT NULL | member count, 1–62. 2,313 hold more than one |
| `n_preps` | INTEGER NOT NULL | preparations, 1–9. 830 items have more than one |

**Total by construction**: every `foods` row has exactly one item and `sum(n_foods) = 13,694`,
so this join never drops a food.

An item has no nutrition of its own — its macros, portions and nutrients are the `foods` row
where `food_id = merged_food_id`.

The **preparations** behind one item, which is the whole wheel. Each is a real loggable food
with its own macros, and `food_id = prep_id` is what marks the one that represents it:

```sql
SELECT food_id, prep_type, kcal_100g, protein_100g, fat_100g, carb_100g,
       serving_g, serving_label
  FROM foods WHERE merged_food_id = ? AND food_id = prep_id ORDER BY food_id;
```

⚠️ **`prep_type IS NULL` on a preparation is not a missing value** — it is the dry or base form
(`Pasta, dry`, `Oats, dry`, `Rice, white, raw`), and 153 of the 830 multi-preparation items have
one. The app renders it as `plain`, which is the design's own vocabulary.

Two foods are the same item when their descriptions share ingredient tokens **and** their
protein:carb:fat ratio agrees; within an item, preparations split on **absolute** macros, because
cooking drives water off. So raw thigh (19.7 g protein) and cooked thigh (24.8 g) are two
preparations of one item, while grilled, boiled and baked are one preparation called `cooked`.
Reasoning and the measured thresholds are in `generate-sqlite/README.md`.

⚠️ **Log a `foods.food_id`, never a `merged_food_id` as though it were a food.** They are the
same integer, but an item id logs its *default* preparation — right until the user spins the wheel
to another one.

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

## `food_fts` / `food_fts_trgm` — FTS5, contentless, `rowid = merged_food_id`

**One row per item, not per food** — 6,809 rows, and `rowid` is the `merged_food_id`. So a
search returns "chicken thigh" once instead of 56 times with no collapsing to do.

`food_fts(name, prep, aka, members)` with `prefix='2 3'`,
`unicode61 remove_diacritics 2`:

| column | holds |
| --- | --- |
| `name` | the item's `display_name` (its default member's `description` until Stage 4 runs) |
| `prep` | the item's preparation labels, so `poached` finds the egg |
| `aka` | USDA Common Name / Additional Description synonyms + LLM keywords — this is why "hot dog" finds *Frankfurter* |
| `members` | the **deduplicated token set** of every member description |

⚠️ **`members` is a token set, not the descriptions concatenated.** bm25 normalizes by document
length, so concatenating an 18-member group's descriptions would bury it under a single-member
item. Measured over the corpus: 644k chars concatenated against **350k** deduplicated, up to 15×
on the worst groups (1,536 → 105 chars). Safe only because the app builds implicit-AND prefix
queries (`"chicken"* "brea"*`) and never `NEAR()` or a phrase query — the forms that need word
order. Losing term frequency is a bonus: a group saying "chicken" 18 times should not outrank one
saying it once.

`food_fts_trgm(txt)` indexes what the user *sees* — name + preparation labels + synonyms. Member
descriptions and keywords stay out, where they would only add wrong-food noise to a fuzzy match.

**The one query** — pass a prefix expression like `chick* brea*`. Measured 0.4–3 ms:

```sql
SELECT s.rowid AS food_id, coalesce(m.display_name, c.description) AS name, m.emoji,
       c.kcal_100g, c.protein_100g, c.fat_100g, c.carb_100g,
       c.serving_g, c.serving_label, m.n_foods, m.n_preps
  FROM food_fts s
  JOIN merged_foods m ON m.merged_food_id = s.rowid
  JOIN foods c        ON c.food_id        = s.rowid
  LEFT JOIN (SELECT cf.merged_food_id AS mid, count(*) AS n
               FROM log_entries l JOIN foods cf ON cf.food_id = l.food_id
              WHERE l.deleted = 0 AND l.food_id IS NOT NULL AND l.local_date >= ?1
              GROUP BY cf.merged_food_id) r ON r.mid = s.rowid
 WHERE food_fts MATCH ?2
 ORDER BY bm25(food_fts, 10.0, 2.0, 3.0, 1.0) * (1
     + 1.0 * coalesce(m.commonness, 0.4)                -- likely in an ordinary kitchen
     + 0.3 * (m.prep_type IS 'cooked')                  -- you log cooked pasta, not dry
     + 1.5 * min(coalesce(r.n, 0), 3) / 3.0             -- logged lately, saturating
     + 0.6 * (lower(coalesce(m.display_name, c.description)) = lower(?3))
     - 0.3 * (<name||description> LIKE '%restaurant%'   -- institutional / infant variants
           OR <…> LIKE '%school lunch%' OR <…> LIKE '%baby food%'))
 LIMIT ?4;
```

`food_id` is the item's default preparation, so a row is loggable as it stands; `n_preps > 1`
is the cue to offer the picker. Weights are per column: name 10, prep 2, aka 3, members 1.

⚠️ **`bm25()` is legal here because nothing aggregates.** An FTS5 auxiliary function may not be
used in an **aggregating** query — joining is fine, which is why the old flat query worked, but a
`GROUP BY` raises *unable to use function bm25 in the requested context* at runtime. Collapsing
per-food hits needed exactly that `GROUP BY`, which is why the composite score and the collapsed
result set were mutually exclusive before `rowid` became `merged_food_id`. (Older revisions of
this file said a *join* breaks `bm25()`. That was wrong.)

⚠️ **Three ways to break the ranking**, all found the hard way:

1. **bm25 is negative.** A bigger multiplier is a *smaller* number, so `ORDER BY score` stays
   ascending, best first. The multiplier floor is `1 + 1.0*0.05 - 0.3 = 0.75` — it never reaches
   zero, which would flip the sign.
2. **`prep_type IS 'cooked'`, never `= 'cooked'`.** It is NULL on about half of all items; `=`
   yields NULL there, NULL poisons the whole product, and NULL sorts *first*.
3. **Sort before the `LIMIT`.** "Cooked pasta" sits at bm25 ranks 26 and 41–45 of 182, so
   re-ranking an already-limited pool in Dart would never see it.

Multiplicative, not additive, because the bm25 spread is query-dependent — `chicken` spans 0.37,
`chicken brea` spans 2.35. Scaling by bm25 magnitude keeps one set of weights honest across both.

The recency term joins **through** `merged_food_id`, so logging a boiled egg boosts the egg item
however the user later spells the search. The per-food query could not express that.

Numbered placeholders, not bare `?`: bare ones bind in order of appearance in the SQL text
(since / match / term / limit), which is not the order any sane caller passes them.

**Typo fallback** — the same query against `food_fts_trgm` with `bm25(food_fts_trgm)` (one
column, so nothing to weight). Run it only when the primary returns too few rows, and **append**
its hits rather than merging: the two indexes produce non-comparable bm25 magnitudes, so a
trigram hit belongs after every exact one regardless of score.

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
beat "Cooked pasta"). Rank by the composite score in
[`food_fts`](#food_fts--food_fts_trgm--fts5-contentless-rowid--merged_food_id) — that query is
what the app ships (`catalog_repository.dart`), it already returns one row per item, and its
three failure modes are documented there.

Custom foods are merged in Dart, not in SQL: the catalog query is run, then the custom-food hits
are **prepended**. A `UNION ALL` in SQL would work too, and would look like this — a custom food
is always `n_preps = 1`, so both halves are one row per item the user recognizes:

```sql
SELECT NULL AS food_id, id AS custom_food_id, name, emoji, energy_kcal, protein_g,
       serving_g, serving_label, 1 AS n_preps, 1 AS is_custom
  FROM custom_foods
 WHERE deleted = 0 AND (name || ' ' || coalesce(brand, '')) LIKE '%' || ?1 || '%'
 LIMIT 20;
```

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
    multiplier sorts earlier. Sort before the `LIMIT`, and compare `prep_type` with `IS` (it is
    NULL on about half of all items, and a NULL term poisons the product and sorts first).
14. A search row is a **merged item**: `food_id` is its *default* preparation, not necessarily the
    one the user means. Offer the preparation wheel when `n_preps > 1`
    (`WHERE merged_food_id = ? AND food_id = prep_id`).
15. `food_fts.rowid` is `merged_food_id`, **not** `food_id`. Joining it to `foods` still works —
    an item id is a real food id — but it resolves to the default preparation, not to whichever
    member matched.
16. `bm25()` is illegal in an **aggregating** query, not in a joined one. Any `GROUP BY` over an
    FTS match raises *unable to use function bm25 in the requested context*; that is why search
    indexes items directly instead of collapsing foods.
17. `merged_foods.display_name` is **nullable** — it is NULL until the enrichment stage has run
    for that item. Always `coalesce(m.display_name, c.description)`.
