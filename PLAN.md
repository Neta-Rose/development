# Homepage implementation + architecture base (healthapp)

## Context

Fresh Flutter template with a static design mock in `lib/home/home_screen.dart` (dark food-log timeline: macro header, anabolic-window card, hourly timeline, search bar, bottom nav — all hardcoded consts). The goal is to implement the homepage against real architecture — Riverpod (codegen), Drift, go_router, Dio, freezed+json_serializable, Supabase — and establish the folder structure and conventions the rest of the app will follow. **Only the homepage.** No food-logging page, no auth UI, no other tabs.

User decisions: **offline-first** (Drift = source of truth, UI reads Drift streams, Supabase syncs in background), **no auth yet** (Supabase init only when `--dart-define` creds present; sync is a no-op otherwise), **@riverpod codegen** style.

## Step 0 — CLAUDE.md (write first, per user request)

`healthapp/CLAUDE.md` covering:
- Commands: `flutter pub get`, `dart run build_runner build -d` (after editing any model/table/provider), `flutter analyze`, `flutter test`, `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- Architecture: offline-first (Drift source of truth → repository syncs Supabase in background; UI never talks to Supabase directly), feature-first folders, codegen Riverpod, freezed domain models with snake_case JSON for Supabase.
- Folder conventions + "how to add a feature" (data/domain/presentation).
- Supabase `food_entries` table SQL snippet for when the backend is provisioned.

## Dependencies

`flutter pub add`: `flutter_riverpod riverpod_annotation go_router dio drift drift_flutter freezed_annotation json_annotation supabase_flutter`
`flutter pub add --dev`: `build_runner riverpod_generator drift_dev freezed json_serializable`

## Folder structure / files

```
lib/
  main.dart                      # bootstrap: init Supabase if creds set, ProviderScope(child: App())
  app/
    app.dart                     # MaterialApp.router (theme, no more `home:`)
    router.dart                  # GoRouter via @riverpod; single route '/' → HomeScreen
    theme.dart                   # AppColors (colors extracted from the mock) + ThemeData
  core/
    database/database.dart       # Drift AppDatabase + FoodEntries table + @Riverpod(keepAlive) provider
    network/dio.dart             # @Riverpod(keepAlive) Dio (BaseOptions, debug LogInterceptor)
    supabase/supabase.dart       # env consts (String.fromEnvironment) + nullable SupabaseClient provider
  features/home/
    domain/food_entry.dart       # freezed FoodEntry + EntryType enum, JSON snake_case
    domain/daily_summary.dart    # freezed DailySummary (kcal/macros consumed) + const MacroTargets
    data/food_log_repository.dart# Drift↔model mapping, watchDay() stream, pullToday() sync, debug seed
    presentation/
      home_screen.dart           # refactored mock, consumes providers (moved from lib/home/)
      home_providers.dart        # todayEntries stream, dailySummary, anabolicWindow, timeline hours
      widgets/macro_bar.dart     # only genuinely reused pieces extracted (bar used in header + window card)
test/widget_test.dart            # replaced: HomeScreen smoke test w/ in-memory Drift override
```

`lib/home/` is deleted (contents move to `features/home/presentation/`).

## Key design points

- **Drift table `FoodEntries`**: `id` (text uuid PK), `name`, `icon` (emoji), `kcal`, `protein`, `carbs`, `fat` (int, null for workouts), `serving` (text?), `meta` (text?), `type` (food|workout enum), `loggedAt` (DateTime), `pendingSync` (bool, default true). Matches the mock's `_Item` fields.
- **FoodEntry freezed model** with `json_serializable` `fieldRename: FieldRename.snake` — the JSON shape is the Supabase wire format; Drift rows are mapped manually in the repository (single mapping point).
- **Repository** (`FoodLogRepository`, @riverpod): `watchDay(DateTime)` → `Stream<List<FoodEntry>>` from Drift; `pullToday()` upserts remote rows into Drift when SupabaseClient is non-null, silently no-ops otherwise (fire-and-forget from provider init). No write API yet — logging isn't in scope.
- **Home providers** derive everything from the entries stream: `DailySummary` (sums vs `MacroTargets` consts — 2850 kcal / 180P 320C 75F from the mock), anabolic window (latest workout entry + 3h window, remaining time), timeline rows (hours 05–23, entries grouped by hour, `now` marker from clock). Planned-meal rows (`~700 kcal plan`) stay a const placeholder list in `home_providers.dart` with a `ponytail:` note — meal planning is a future feature.
- **Debug seed**: when the DB is empty in debug mode, seed the mock's data (coffee/oats/milk/whey/workout at their hours, today's date) so the rendered homepage matches the design.
- **UI**: `HomeScreen` becomes a `ConsumerWidget`; visual code from the mock is kept nearly verbatim but fed from providers instead of consts. Search bar / bottom nav / FAB stay static no-ops (their features aren't in scope). Colors move to `theme.dart` so other screens reuse them.
- **Dio**: configured provider only — Supabase uses its own client; Dio is the stack's client for future external APIs (e.g. food-database search). No consumer yet, by design.
- **Targets** are consts for now (`MacroTargets.defaults`) with a note that they move to a profile/settings table later.

## Verification

1. `dart run build_runner build -d` — codegen clean.
2. `flutter analyze` — zero issues.
3. `flutter test` — HomeScreen smoke test: pump with in-memory Drift DB seeded with mock data, assert header totals ("640"), a food card ("Oats"), and the now-marker render.
4. If a device/emulator is available: `flutter run` and visually compare to the mock.
