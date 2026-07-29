# Migrating the app to merged foods

> **SUPERSEDED — history only.** This describes the first grouping attempt (macro-ratio dedup at
> `MERGE_DISTANCE = 0.05`, run *after* enrichment). It shipped in the catalog but its app-side
> steps were never taken, and the approach was measured to be wrong: the ratio is not invariant
> to rendering, so raw and cooked meat could never group and the catalog carried 56 separate
> "chicken thigh" items. See [`MIGRATION_MERGED_ITEMS.md`](MIGRATION_MERGED_ITEMS.md) for the
> current shape and the live migration.

The catalog now ships Stage 6b's grouping: **13,694 USDA foods in 10,000 merged items.** A user
searching for "egg" met four rows and ground beef was nine rows at nine fat levels; now each is
one result with its preparations behind it.

This is a **catalog-only, additive change**. There is no SQLite migration to run, no user data to
convert, and nothing in `log.sqlite` moves. The work is entirely in the app's queries.

Schema details live in [`APP_DATABASE.md`](APP_DATABASE.md); this file is the diff and the
sequence.

---

## 1. What changed in `foods.sqlite`

The file is rebuilt, never altered, so this is a description of the new file — not a script to
run. (SQLite would reject that `ADD COLUMN` anyway: `NOT NULL` needs a default.)

```sql
CREATE TABLE foods (
    ...                                   -- every existing column, unchanged
    merged_food_id INTEGER NOT NULL       -- new, last in the table
);
CREATE INDEX ix_foods_merged ON foods(merged_food_id);

-- new table, 10,000 rows
CREATE TABLE merged_foods (
    merged_food_id INTEGER PRIMARY KEY,   -- IS the canonical variant's foods.food_id
    display_name   TEXT NOT NULL,
    emoji          TEXT,
    category       TEXT,
    variable_fat   INTEGER NOT NULL,      -- 1 = group spans fat levels (10 groups)
    n_foods        INTEGER NOT NULL       -- 1..29
);
```

Nothing was removed, renamed, or retyped. File size went 20.8 MB → 21.7 MB.

`merged_food_id` **is** the canonical variant's `food_id` — not a surrogate key. So a group id is
always a real, loggable food, and `merged_foods` needs no macros, portions or nutrients of its
own: they are the `foods` row with that id.

Two invariants the export guarantees, both asserted in `tests/test_appdb.py`:

- every `foods` row has exactly one `merged_foods` row (`sum(n_foods) = count(*) FROM foods`), so
  the join can never drop a food;
- `merged_food_id` is never NULL — a food the grouping could not place is its own group of one.

You can rely on both. There is no "ungrouped" state to code around.

### Why these groups

Two foods are the same item when the same base ingredients drive their macros, which shows up as
the same protein:carb:fat ratio. That ratio is invariant to water (raw and cooked steak land on
one point) and to seasoning (salt-and-pepper tilapia lands on plain tilapia), but *not* to a
macro-bearing addition — so an omelette's oil keeps it a separate item. Fat-level families
(ground beef 70%–97% lean, milk whole–skim) are a deliberate exception and are the groups
flagged `variable_fat`. Full reasoning in `src/merge.py`.

Practical consequence: **a group is a set of preparations of one ingredient, not a category.**
`Ground beef` (29 foods) is the largest; the median multi-food group holds 2.

---

## 2. What does *not* change

| | |
| --- | --- |
| `log.sqlite` schema | untouched — do **not** bump its `user_version` for this |
| existing `log_entries.food_id` values | still name real `foods` rows; history renders identically |
| every pre-merge query | returns exactly what it returned before |
| custom foods, recipes, sync | unaffected |

The catalog is replaced wholesale on upgrade, so there is no `foods.sqlite` migration step at
all — ship the new asset. And because the change is purely additive, **an app that ignores both
new schema objects is still correct**, just un-merged. That is what lets you land the asset and
the UI work in separate releases.

---

## 3. The order to do it in

1. **Ship the new `foods.sqlite` asset** with the old queries. Verify with §7. Nothing changes
   for the user.
2. **Regenerate schema bindings** (§4) and switch search to the collapsed query (§5).
3. **Add the variant picker** to the detail screen (§5).

⚠️ **The most likely way this goes wrong is a stale on-device copy.** If the app copies the
bundled catalog to app-support storage on first launch only, an upgraded install runs new
queries against the old file and every search throws `no such table: merged_foods`. The copy must
be gated on a bundled catalog version, not on file existence.

This app already does that: `catalogVersion` in `lib/core/database/database.dart` is baked into
the copy's *filename* (`catalog_v$catalogVersion.sqlite`), so a bump makes the existence check
miss and the old file is deleted on the next launch — see `lib/core/database/connection/`. The
whole obligation here is **bump that constant whenever Stage 7 runs**; there is no stamp file to
maintain.

---

## 4. Drift specifics

**Add the new column and table to your catalog definitions** — a `foods.drift` file or the Dart
table classes — then `dart run build_runner build --delete-conflicting-outputs`.

```
-- foods.drift, if that is where the catalog lives
CREATE TABLE merged_foods (
    merged_food_id INTEGER NOT NULL PRIMARY KEY,
    display_name   TEXT NOT NULL,
    emoji          TEXT,
    category       TEXT,
    variable_fat   INTEGER NOT NULL,
    n_foods        INTEGER NOT NULL
) AS MergedFood;
```

`variable_fat` and `n_foods` are `NOT NULL`, so they generate as non-nullable `bool`/`int`.
`foods.merged_food_id` is `NOT NULL` too — it goes at the **end** of the column list, matching
the shipped file, or a positional mapping will drift.

Four things to get right:

- **`schemaVersion` belongs to `log.sqlite`, not the catalog.** Drift stores it in the *main*
  database's `user_version`. This change touches only the attached catalog, so **do not bump
  `schemaVersion` and do not write an `onUpgrade` step for it** — there is no ALTER to run on
  device. The new columns arrive with the asset.

- ⚠️ **Never let `Migrator.createAll()` see the catalog tables.** With the catalog attached,
  unqualified `foods` resolves to it only because nothing in the log shadows that name. If
  `createAll()` creates an empty `main.foods` and `main.merged_foods`, every catalog query
  silently starts returning zero rows — with no error, because the tables exist. Keep catalog
  tables out of `@DriftDatabase(tables: …)`, or create only the log's tables explicitly in
  `onCreate`.

- **Attach in `beforeOpen`**, before any query runs:
  `await customStatement("ATTACH DATABASE '${path}' AS catalog")`, and keep
  `await customStatement('PRAGMA foreign_keys = ON')` on every connection.

- **Schema verification will flag the diff** if you use `drift_dev`'s generated schema tests or
  `validateDatabaseSchema()`: the generated schema now has a column and a table the old asset
  lacks. Regenerate the schema dump (`dart run drift_dev schema dump`) *after* the new asset is
  in place, or those tests compare against a file that no longer ships.

---

## 5. Screen by screen

### Search — the one required change

Replace the flat query with the collapsed one from `APP_DATABASE.md`. Every variant is still
indexed, so typing `poached` or `80% lean` still finds the group; only the result set collapses,
and the group is ranked by its best-matching variant.

```dart
Future<List<SearchHit>> search(String prefix, {int limit = 30}) =>
    customSelect(
      '''
      SELECT c.food_id, coalesce(c.display_name, c.description) AS name, c.emoji,
             c.kcal_100g, c.protein_100g, c.fat_100g, c.carb_100g,
             m.n_foods, m.variable_fat, min(s.rank) AS rank
        FROM (SELECT rowid, rank FROM food_fts
               WHERE food_fts MATCH ?1 AND rank MATCH 'bm25(10.0, 3.0, 1.0)') s
        JOIN foods v        ON v.food_id = s.rowid
        JOIN merged_foods m ON m.merged_food_id = v.merged_food_id
        JOIN foods c        ON c.food_id = m.merged_food_id
       GROUP BY m.merged_food_id
       ORDER BY rank
       LIMIT ?2
      ''',
      variables: [Variable.withString(prefix), Variable.withInt(limit)],
    ).map(SearchHit.fromRow).get();
```

This has to be a `customSelect`: it spans the attached database and groups, which Drift's query
builder will not express. There is nothing to add to `readsFrom` — the catalog is read-only, so
no local write can ever invalidate the stream.

⚠️ **Keep the weights in `rank MATCH 'bm25(…)'`.** Porting the old `ORDER BY bm25(food_fts, 10.0,
3.0, 1.0)` into this query fails at runtime with *unable to use function bm25 in the requested
context* — an FTS5 auxiliary function is only legal in a query whose `FROM` is the FTS table
itself, and joining to `foods` breaks that, in a subquery and a plain CTE alike. The hidden
`rank` column produces the identical score as an ordinary number. Lower is better, so `min()`
picks the group's best variant.

The typo fallback gets the same treatment; with one column its default weights already are
`bm25()`, so it needs no `rank MATCH` clause.

### Result row

`n_foods > 1` is the cue that a row hides options — "Ground beef · 29 options". `variable_fat`
tells you what kind: fat levels rather than preparations, so label it "lean %", not "prepared".
Only 10 groups set it; treat it as a nicety, not a branch you must handle.

### Detail — the new picker

```sql
SELECT food_id, coalesce(display_name, description) AS name, prep_type,
       kcal_100g, protein_100g, fat_100g, carb_100g, serving_g, serving_label
  FROM foods WHERE merged_food_id = ? ORDER BY food_id;
```

One index range scan on `ix_foods_merged`. Default the selection to the row whose `food_id`
equals the `merged_food_id` — that is the canonical variant, the one the search row already
showed, so a user who ignores the picker gets what they tapped.

### Logging — unchanged

Still `log_entries.food_id = <a foods.food_id>`, still the variant's own nutrient vector
snapshotted per entry.

⚠️ **Never write a `merged_food_id` into `log_entries` as though it were the user's choice.**
They are the same integer, so nothing will error — you will just have silently logged raw egg
for someone who picked fried.

### History and totals — unchanged

Entries carry their own snapshot, so nothing re-reads the catalog and no past entry changes.

### Recently logged — optional

Grouping by `food_id` shows "Raw egg" and "Boiled egg" as two chips. To show one, partition on
`merged_food_id` instead — and re-log the *most recently used* variant, not the canonical one,
since that is the preparation this user actually eats:

```sql
SELECT food_id, custom_food_id, name, emoji, n, last FROM (
  SELECT l.food_id, l.custom_food_id, l.name, l.emoji,
         count(*)         OVER w AS n,
         max(l.logged_at) OVER w AS last,
         row_number()     OVER (PARTITION BY coalesce(f.merged_food_id, l.custom_food_id)
                                ORDER BY l.logged_at DESC) AS rn
    FROM log_entries l
    LEFT JOIN catalog.foods f ON f.food_id = l.food_id
   WHERE l.deleted = 0 AND l.local_date >= ?
  WINDOW w AS (PARTITION BY coalesce(f.merged_food_id, l.custom_food_id))
) WHERE rn = 1 ORDER BY n DESC, last DESC LIMIT 20;
```

⚠️ The window function is not decoration. The obvious `GROUP BY coalesce(…)` with bare `name`
and `emoji` compiles and looks right, but SQLite only promises bare columns come from the
matching row when `min()`/`max()` is the query's **only** aggregate — `count(*)` alongside it
voids that, and the chip gets an arbitrary variant's name.

Judgement call: re-logging the exact preparation is often what people want, so leaving this
grouped by `food_id` is a defensible choice.

---

## 6. Rollback

Ship the previous `foods.sqlite`. Nothing on device needs undoing — no schema was altered and no
user data was touched.

The reverse pairing is also safe: the **new file with the old app** works, because every added
object is additive and no old query mentions them. Only new-app-with-old-file breaks, which is
the stale-copy case in §3.

---

## 7. Verify before release

Run against the shipped asset. All five must hold:

```sql
SELECT count(*) FROM foods;                                    -- 13,694
SELECT count(*) FROM merged_foods;                             -- 10,000
SELECT count(*) FROM foods WHERE merged_food_id IS NULL;       -- 0
SELECT count(*) FROM foods f                                   -- 0, no orphans
  LEFT JOIN merged_foods m USING (merged_food_id)
 WHERE m.merged_food_id IS NULL;
SELECT sum(n_foods) FROM merged_foods;                         -- 13,694, totality
```

Then in the app, with the real UI:

- search `ground beef` → one *Ground beef* row reading 29 options, not 29 rows;
- search `poached` → the egg group, displayed as *Whole raw egg*;
- open it → 7 preparations, canonical preselected;
- log one, reopen the timeline → the preparation you picked, with its own numbers;
- search a misspelling (`chikcen`) → the trigram fallback still returns rows.
