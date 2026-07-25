# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`healthapp` — an offline-first Flutter food/nutrition logger. Every read and write hits a local
SQLite database; nothing in the UI path waits on the network. Flutter 3.44 / Dart 3.12, Android + iOS

## Commands

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…  # both optional
flutter analyze
flutter test
flutter test test/catalog_test.dart --plain-name 'recipe roll-up'           # one test
dart run build_runner build --delete-conflicting-outputs                   # or `watch`
shorebird patch android                                                     # code push
```

Codegen produces `*.g.dart` (riverpod, drift, json_serializable) and `*.freezed.dart`. Run
build_runner after touching `log.drift`, any `@riverpod`, `@DriftDatabase`, or `@freezed`.

`test/catalog_test.dart` attaches the real 20 MB `database/foods.sqlite` by **relative path**, so
tests must run from the repo root.

## Architecture

`lib/app/` app shell, go_router routes, dark IBM Plex Mono theme · `lib/core/` database + Supabase
client · `lib/features/<feature>/{data,domain,presentation}`. Riverpod (codegen) everywhere; the
router itself is a provider. Repositories are constructed from the `appDatabaseProvider` future, so
every consumer is async.

`search/` reuses `home/data/` repositories rather than owning its own — `FoodHit` is the single row
type for search results and recents.

### Two databases, one connection

`AppDatabase` opens the writable log as `main` and `ATTACH`es the read-only USDA catalog beside it
(`lib/core/database/database.dart`). Consequences that shape all data code:

- **Drift cannot typecheck an attached database.** Log-only queries are named queries in
  `lib/core/database/log.drift`; anything touching `catalog.*` is a hand-written `customSelect` in a
  repository. A cross-database VIEW is illegal in SQLite, so unions stay inline in Dart.
- The catalog ships as a Flutter asset and is copied to the documents dir by `installCatalog()` —
  Android assets live compressed in the APK with no file path. Bump `catalogVersion` when
  `database/foods.sqlite` is replaced; old copies are deleted on next launch.
- `PRAGMA foreign_keys = ON` and the `ATTACH` both run in `beforeOpen` — they are per-connection, not
  stored in the file.
- Never write to the catalog and never store an FK into it (`log_entries.food_id` is deliberately not
  an FK).

**`database/APP_DATABASE.md` is the schema reference** — full column lists, the query for every
screen, and a gotchas checklist. Read it before writing SQL.

### Invariants that break things silently

- **Every nutrient amount in every table is per 100 g.** A real amount is always
  `grams / 100.0 * <column>`. `serving_g IS NULL` means "treat as per 100 g", not "unknown".
- **Logging snapshots the whole 50-nutrient vector** into `log_entries` (`nutrients.dart` builds the
  SQL from `nutrientColumns`; the vector never becomes a Dart object). So reads need no joins and
  history survives a catalog upgrade. The three tables' nutrient columns must stay name-identical —
  `catalog_test.dart` asserts this.
- **A recipe is just a `custom_foods` row that has `recipe_steps`/`recipe_ingredients`.** Its
  nutrients are rolled up onto its own columns, so reads go one level deep and never recurse.
- **`carb_g` can be negative** (real USDA carb-by-difference). Never validate logged nutrients as
  `>= 0`; the `>= 0` CHECKs belong to `custom_foods` only.
- Portion labels are measures of **one** — render `qty × label`. Never persist a catalog
  `food_portions.seq`; it is renumbered on every rebuild. Snapshot the label instead.
- `logged_at` is a local wall-clock string `YYYY-MM-DDTHH:MM` — not UTC, not a timestamp. The hour is
  `substring(11, 13)`, days compare as text against the generated `local_date`.
- Sync columns (`updated_at` unix **seconds**, `dirty`, `deleted`) plus `AFTER UPDATE` triggers are in
  place, but **push/pull is not implemented yet** — `supabaseClient` is a nullable provider and null
  means "remote sync disabled". Editing only a recipe's step text touches no nutrition, so a recipe
  save must end by stamping `custom_foods.updated_at`/`dirty` explicitly (see `saveRecipe`).

### Toolchain gotchas already hit here

- **riverpod_generator throws `InvalidTypeException` on types drift emits into a `part` file.** Any
  provider whose signature names one (e.g. `TimelineForDayResult`) must be hand-written — see
  `todayEntriesProvider` in `home_providers.dart:22`. Providers with ordinary return types generate
  fine even if their bodies use drift types.
- Use `customInsert`/`customUpdate` with `updates: {...}`, not `customStatement` — only the former
  tells drift's stream layer a table changed, so watchers refresh.
- In `.drift`, `AS <name>` renames only the Dart getter: `text AS stepText` and
  `table_name AS syncTable` dodge collisions with `Table.text()` / `Table.tableName`.
- `local_date` is a VIRTUAL generated column — absent from `PRAGMA table_info` (use `table_xinfo`),
  present in `SELECT *`.
- Trigram search: matching a misspelling directly against `food_fts_trgm` returns nothing. Split the
  query into OR-ed 3-grams (`CatalogRepository.trigramQuery`).

## Conventions

`// ponytail: <ceiling>` marks a deliberate simplification with its upgrade path (hardcoded macro
targets, no ticking clock, placeholder plan rows). Treat them as known, not as bugs to fix in passing.
