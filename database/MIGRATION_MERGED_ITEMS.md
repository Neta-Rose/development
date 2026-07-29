# Migration — search moves to merged items (catalog v3)

Supersedes [`MIGRATION_MERGED_FOODS.md`](MIGRATION_MERGED_FOODS.md), which described the first
grouping attempt. That one was additive and its app-side steps were never taken; this one replaces
it wholesale, so read this file and treat the old one as history.

## What changed and why

The catalog used to ship one search row per USDA record. Grouping was bolted on afterwards
(`merged_foods`, keyed on the protein:carb:fat ratio at a distance of 0.05) and it did not work:
the ratio is invariant to water but **not** to rendering, because fat leaves a cooking meat while
protein concentrates. Raw and roasted chicken thigh sit 0.105 apart — twice the threshold — so no
preparation of any meat could group with its raw form, and the shipped catalog carried **56
separate "thigh" items**.

The pipeline now groups **before** naming, on two tests at once (shared ingredient tokens *and* a
matching macro ratio, at a distance of 0.20), and splits each group into **preparations** by
absolute macros. Then one LLM request names the whole item and labels every preparation.

Result: 13,694 foods → **8,335 items / 10,473 preparations**.

## Nature of the change

**Catalog-only, but not additive.** There is no SQLite migration to run and no user data to
convert — the catalog is replaced wholesale as one file. But columns *moved*, so an app built for
v2 cannot read a v3 file and vice versa. `catalogVersion` is what keeps them apart.

| | v2 | v3 |
| --- | --- | --- |
| `food_fts.rowid` | `food_id` (13,694 rows) | **`merged_food_id`** (8,335 rows) |
| `food_fts` columns | `name, description, aka` | **`name, prep, aka, members`** |
| bm25 weights | `10, 3, 1` | **`10, 2, 3, 1`** |
| `display_name`, `emoji`, `commonness` | on `foods` | **also on `merged_foods`** (the item is the source) |
| `merged_foods` | id, name, emoji, category, variable_fat, n_foods | **+ `prep_type`, `commonness`, `n_preps`**; `display_name` now nullable |
| `foods` | — | **+ `prep_id`** |
| file size | 20.8 MB | ~20 MB |

`foods` keeps `display_name` / `emoji` / `prep_type` / `variable_fat` / `commonness`, denormalized
down from its item and preparation. That is deliberate: `nutrients.dart` snapshots the name and
emoji onto every `log_entries` row, and a logged entry must keep reading the same way whether it
came from the catalog, a custom food or a recipe.

## App-side steps

1. **Bump `catalogVersion` to 3** in `lib/core/database/database.dart`. Done. This is the step
   that must not be forgotten — the version is baked into the on-device copy's filename
   (`catalog_v3.sqlite`), which is what makes an installed app replace its old copy instead of
   running new queries against it.
2. **Swap the search SQL** in `lib/features/home/data/catalog_repository.dart` `_catalogSearch`.
   Done. Two joins instead of one (`merged_foods` for the name/emoji/commonness, `foods` for the
   macros), recency joined *through* `merged_food_id`, and the bm25 weight list grows a column.
3. **Add the variant picker.** Not done — this is the remaining work, and it is what the whole
   change is for. See below.

`FoodHit` needs no change: `foodId` is still a real, loggable `foods.food_id` (the item's default
preparation), so `food_detail_screen`, `portion_pad`, `quick_add` and the log snapshot all keep
working untouched. Add `nPreps` when you build the picker, not before.

No Drift codegen is needed — the catalog tables are not in `@DriftDatabase`, and they must stay
out of it (letting `Migrator.createAll()` see them creates an empty `main.foods` that silently
returns zero rows). Do **not** bump `schemaVersion`; that belongs to `log.sqlite`, which is
untouched.

## The variant picker (remaining work)

A search row is now an item. `n_preps > 1` is the cue to offer the preparations:

```sql
SELECT food_id, prep_type, kcal_100g, protein_100g, fat_100g, carb_100g,
       serving_g, serving_label
  FROM catalog.foods
 WHERE merged_food_id = ? AND food_id = prep_id
 ORDER BY food_id;
```

Each row is a real loggable food with its own macros and portions, so picking one is just
logging a different `food_id`. `ix_foods_merged` covers the lookup.

## Rollback

Ship the previous catalog file *and* revert the two Dart changes together. Neither half works
alone: a v2 file with the v3 query fails on `no such column: m.n_preps`, and a v3 file with the v2
query silently returns items where the app expects foods.

## Verification

Against the exported catalog:

```sql
SELECT count(*) FROM foods;                                    -- 13,694
SELECT count(*) FROM merged_foods;                             -- ~8,335
SELECT sum(n_foods) FROM merged_foods;                         -- 13,694  (totality)
SELECT count(*) FROM foods WHERE merged_food_id IS NULL;       -- 0
SELECT count(*) FROM foods f LEFT JOIN merged_foods m USING (merged_food_id)
 WHERE m.merged_food_id IS NULL;                               -- 0  (no orphans)
SELECT count(*) FROM food_fts;                                 -- = count(merged_foods)
SELECT count(*) FROM merged_foods WHERE display_name IS NULL;  -- 0  (enrichment complete)
SELECT sum(n_preps) FROM merged_foods;                         -- = count of food_id = prep_id
```

In the app: `chicken thigh` → **one** row, not 56; `poached` → the egg item; `chikcen breast` →
the trigram fallback still returns Chicken breast; log an entry and reopen the timeline to
confirm the snapshotted name and macros survive.

⚠️ The Flutter tests in `test/catalog_test.dart` run against the real `database/foods.sqlite`, so
they fail until a v3 catalog is exported. Two of them (`an exact whole-name match outranks longer
names containing it`, `ranking prefers the common food over the incidental one`) additionally
need the enrichment stage to have run — they assert on `display_name` and `commonness`, which are
NULL in an unenriched export.
