# Implementation Plan: AI Food Logging

## Overview

The order follows the design's dependency shape rather than the document's reading order: the
compile-time config and the wire models first, then the transport, then the **pure layer**
(`food_match.dart`, `ai_plate.dart`) which is testable with no camera, no key and no database, then
the data-layer methods the session notifier calls, then the notifier, and only then the three UI
files. The `SwipeRow` extraction is its own task with `test/search_test.dart` passing unchanged as
its acceptance bar, and it lands before the plate row that consumes it.

Every task names the files it touches with the paths from the design's placement table, cites the
requirements it implements, and ends verifiable: `flutter analyze` clean and a named
`flutter test` target passing. All tests run **from the repo root**, offline, with **no API key** —
`test/catalog_test.dart` already attaches `database/foods.sqlite` by relative path and the new
database-backed tests reuse that harness.

`dart run build_runner build --delete-conflicting-outputs` is called out inside every task that adds
or edits a `@freezed`, `@riverpod` or `@DriftDatabase` source, or `log.drift`. Generated
`*.g.dart` / `*.freezed.dart` files are committed and are never hand-edited.

Two files the design does not assign a path are placed here and flagged in the task that creates
them: `downscaleJpeg` (a top-level function, because `compute` needs one) and the property-test
generators.

## Tasks

- [ ] 1. Dependencies, platform permissions and theme colours

  - [ ] 1.1 Add the four runtime packages and the property-testing dev package
    - Edit `pubspec.yaml`: `camera: ^0.12.0+2`, `image: ^4.9.1`, `http: ^1.6.0`,
      `app_settings: ^8.0.3` under `dependencies`; `kiri_check: ^1.3.1` under `dev_dependencies`
    - Carets, matching every existing entry; the design's resolved-version column is the reference
      if a strict pin is wanted later
    - Run `flutter pub get`. If it reports an Android `minSdk` conflict from `camera` 0.12, raise it
      in `android/app/build.gradle.kts`; otherwise leave `flutter.minSdkVersion` alone
    - Verify: `flutter analyze` clean and `flutter test` still green — nothing imports the new
      packages yet, so this task must not change behaviour
    - _Requirements: 2.5, 3.12, 11.7_

  - [ ] 1.2 Declare the camera permission on both platforms
    - Edit `android/app/src/main/AndroidManifest.xml`: add
      `<uses-permission android:name="android.permission.CAMERA"/>`. `INTERNET` is already declared
    - Edit `ios/Runner/Info.plist`: add `NSCameraUsageDescription` with a one-line reason
    - Do **not** request microphone or photo-library access: no video is recorded and no photo is
      ever read from or written to the library
    - Verify: `flutter analyze` clean (config-only change; no Dart touched)
    - _Requirements: 3.1, 11.7, 12.2_

  - [ ] 1.3 Add the three named colours the AI pane needs
    - Edit `lib/app/theme.dart`, inside `AppColors`: `camBg = Color(0xFF0A0B08)`,
      `merged = Color(0xFF7FBF6A)`, `danger = Color(0xFFE5705C)`
    - `merged` and `danger` repeat the carbs and protein hues under semantic names, so the merge
      badge and the remove affordance do not read as macro colours by accident — keep that as the
      doc comment
    - No widget inlines a hex; every later UI task reads these
    - Verify: `flutter analyze` clean, `flutter test` green
    - _Requirements: 5.6, 9.5_

- [ ] 2. OpenRouter configuration, wire models and the request schema

  - [ ] 2.1 Write the compile-time configuration
    - Create `lib/core/ai/openrouter_config.dart`, structurally mirroring
      `lib/core/supabase/supabase.dart`
    - `openRouterApiKey` from `String.fromEnvironment('OPENROUTER_API_KEY')` defaulting to `''`;
      `openRouterModel` from `OPENROUTER_MODEL` defaulting to `'google/gemini-2.5-flash'`;
      `openRouterEndpoint` as a fixed `https://openrouter.ai/api/v1/chat/completions` `Uri`;
      `openRouterConfigured` as `openRouterApiKey.isNotEmpty`
    - Both values stay `const` — nothing here is ever written to `log.sqlite`
    - Carry the `// ponytail:` note recording the build-time key in the binary and the server-side
      proxy as its upgrade path (D3), plus the web-bundle variant of that ceiling
    - Verify: `flutter analyze` clean
    - _Requirements: 2.1, 2.2, 2.5, 2.7_

  - [ ] 2.2 Write the wire models and the sealed failure type
    - Create `lib/core/ai/vision_models.dart`: `@freezed` `VisionReply` (`items`) and
      `VisionDetection` with the explicit `@JsonKey` snake_case names from the design
      (`instance_id`, `search_term`, `kcal_100g`, `protein_100g`, `carb_100g`, `fat_100g`) and the
      `@Default` values that make an "absent" strict-mode field arrive as `''` or `0`
    - In the same file, the sealed `VisionFailure` with exactly six cases: `VisionNotConfigured`,
      `VisionNoConnection`, `VisionTimeout`, `VisionHttpError(int status)`, `VisionUnreadable`,
      `VisionNoFood`. `VisionHttpError` carries the status code only — no body, no headers, no
      message string, which is what makes a key leak structurally impossible
    - Run `dart run build_runner build --delete-conflicting-outputs` (freezed +
      json_serializable). Commit `vision_models.freezed.dart` and `vision_models.g.dart`; never
      hand-edit them
    - Verify: `flutter analyze` clean
    - _Requirements: 4.3, 7.1, 8.1, 12.5_

  - [ ] 2.3 Write the response schema and the prompt builders
    - Create `lib/core/ai/vision_schema.dart` holding the `json_schema` literal
      (`name: 'plate_detection'`, `strict: true`, `additionalProperties: false`, every one of the
      eleven item fields in `required`, with the field descriptions from the design), the system
      message carrying dedup rules 1–9 verbatim, and a user-text builder
    - The text builder takes the shot count and the current plate summaries and emits, in order:
      the "one plate photographed N times" line, the image-to-shot mapping, which shot is newest,
      then `  <id> | <name> | <grams> g` for every staged item, then the reuse instruction
    - Separated from the client so a prompt change reviews as a diff of one file
    - Verify: `flutter analyze` clean
    - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 7.1, 8.1_

- [ ] 3. Vision client: transport, validation and the single resend

  - [ ] 3.1 Write the transport
    - Create `lib/core/ai/openrouter_client.dart`: one `POST` to `openRouterEndpoint` over an
      injected `http.Client`, `Authorization: Bearer <openRouterApiKey>`,
      `Content-Type: application/json`, body carrying `model`, `temperature: 0`,
      `max_tokens: 2048`, `provider: {require_parameters: true}`, `response_format` and `messages`
    - Message content is one text part **first**, then one `image_url` part per shot as
      `data:image/jpeg;base64,…` in shot order
    - `.timeout(const Duration(seconds: 30))` on the send future → `VisionTimeout`;
      `http.ClientException` / `SocketException` → `VisionNoConnection`; non-2xx →
      `VisionHttpError(status)` with the body discarded
    - Transport only: no food vocabulary, no UI strings, and no request headers attached to any
      returned failure
    - Carry the `// ponytail:` note that the 30 s budget is per attempt, so a schema resend can
      reach 60 s wall clock
    - Verify: `flutter analyze` clean
    - _Requirements: 2.3, 2.4, 2.5, 4.4, 11.1, 11.2, 11.3, 12.4, 12.5_

  - [ ] 3.2 Write the client interface, validation and the resend
    - Create `lib/core/ai/vision_client.dart`: `abstract interface class VisionClient` with
      `detect({required List<Uint8List> shots, required List<PlateSummary> plate})`, the
      `PlateSummary` and `VisionResult` typedefs, and `OpenRouterVisionClient` over an injected
      `http.Client`
    - Short-circuit to `VisionNotConfigured` before building a request when
      `openRouterConfigured` is false, so a programming error cannot send an unauthenticated call
    - Two-stage validation: HTTP body → envelope, then `choices[0].message.content` string →
      `VisionReply`. A `FormatException`, a `TypeError`, or a reply whose every item has an empty
      `instanceId` or an empty trimmed `name` is a validation failure
    - A validation failure resends the **identical** request exactly once, then reports
      `VisionUnreadable`. A network or HTTP failure is never retried
    - Verify: `flutter analyze` clean
    - _Requirements: 2.6, 11.4, 11.5, 12.5_

  - [ ]* 3.3 Build the two-level Vision_Client fake and the reply fixtures
    - Create `test/fixtures/vision_replies.dart`: the four-shot sequence ported from the
      prototype's `SHOTS` table — chicken in shot 1; chicken + tomato + greens in shot 2; oil and
      bread added in shot 3; feta in shot 4 — as both raw JSON strings (for transport tests) and
      decoded `VisionReply`s (for feature tests), with stable instance ids across shots
    - Create `test/fixtures/fake_vision_client.dart`: `FakeVisionClient implements VisionClient`,
      returning a queued `VisionReply` or a chosen `VisionFailure` and recording every
      `(shots, plate)` it was called with. This is the level every merge, match, write and widget
      test uses, overridden through `visionClientProvider`
    - The transport level is `MockClient` from `package:http/testing.dart`, which arrives with
      `http` and needs no fixture file of its own
    - Design assigns `vision_replies.dart` a path but not the fake; it goes beside the fixtures
    - Verify: `flutter test test/fixtures` is not a target — verify by `flutter analyze` clean
    - _Requirements: 4.1, 5.1, 5.2_

  - [ ]* 3.4 Write property test for the request shape
    - File `test/ai_vision_test.dart`, `MockClient` against `OpenRouterVisionClient`
    - **Property 20: A request carries all shots, in order, only when the user asked**
    - **Validates: Requirements 2.5, 4.1, 11.9, 12.1, 12.4**
    - Generate sequences of shutter presses and retries; assert every captured request targets the
      HTTPS OpenRouter endpoint, that content is one leading text part followed by one image part
      per shot in shot order, and that the request count equals presses + retries + resends
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 20: A request carries all shots, in order, only when the user asked`
    - Verify: `flutter test test/ai_vision_test.dart`

  - [ ]* 3.5 Write property test for plate ids reaching the prompt
    - File `test/ai_vision_test.dart`
    - **Property 21: Every staged instance id reaches the request text**
    - **Validates: Requirements 4.2**
    - Generate arbitrary plate summaries; assert the text part contains the instance id, the name
      and the gram amount of every one of them
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 21: Every staged instance id reaches the request text`
    - Verify: `flutter test test/ai_vision_test.dart`

  - [ ]* 3.6 Write property test for the resend accounting
    - File `test/ai_vision_test.dart`
    - **Property 22: A reply that fails validation is sent exactly twice**
    - **Validates: Requirements 11.4, 11.5**
    - Generate malformed bodies (truncated JSON, wrong types, empty `items`, items with blank
      names) and well-formed ones; assert two requests then `VisionUnreadable` for the former,
      exactly one request for the latter
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 22: A reply that fails validation is sent exactly twice`
    - Verify: `flutter test test/ai_vision_test.dart`

  - [ ]* 3.7 Write property test for key containment
    - File `test/ai_vision_test.dart`
    - **Property 23: No failure or error message contains the API key**
    - **Validates: Requirements 2.7, 12.5**
    - Drive every failure path with a distinctive test key so a false negative is impossible;
      assert the string form of every returned `VisionFailure` and of every thrown exception
      excludes it, including when the canned response body echoes the key back
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 23: No failure or error message contains the API key`
    - Verify: `flutter test test/ai_vision_test.dart`

  - [ ]* 3.8 Write the transport example tests
    - File `test/ai_vision_test.dart`, `MockClient`
    - `response_format.json_schema.strict == true` and `required` listing all eleven item fields
      (Req 4.3, 7.1, 8.1); `model` and the bearer header taken from `App_Config` (Req 2.3, 2.4);
      the system message carrying dedup rules 1–4 (Req 5.1, 5.2)
    - Status mapping 400/401/402/429/500/503 → `VisionHttpError` with the body never surfaced
      (Req 11.3); `ClientException` → `VisionNoConnection`; a never-completing handler →
      `VisionTimeout` under `FakeAsync` (Req 4.4); empty key → `VisionNotConfigured` with **zero**
      requests made (Req 2.6)
    - _Requirements: 2.3, 2.4, 2.6, 4.3, 4.4, 5.1, 5.2, 7.1, 8.1, 11.3_
    - Verify: `flutter test test/ai_vision_test.dart`

- [ ] 4. Checkpoint - the network layer stands alone
  - Ensure all tests pass, ask the user if questions arise.
  - `flutter analyze` clean; `flutter test` green. Nothing in `lib/features/` imports `core/ai/`
    yet, so the app must build and behave exactly as before.

- [ ] 5. Plate types, session state and the clamps

  - [ ] 5.1 Write the session and plate types
    - Create `lib/features/search/domain/ai_plate.dart`: `enum AiPhase`, and `@freezed` `Shot`,
      `AiOrigin`, `PlateCandidate`, `AiSession` exactly as the design declares them, plus the
      constants `confidenceFloor = 0.35`, `maxShots = 8`, `minGrams`, `maxGrams`, `defaultGrams`
    - `AiSession` carries `editedIds` and `removedIds` as `Set<String>`; keep the doc comment
      explaining why both live on the session rather than on the row — a removed item has no row
      left to carry a flag, and splitting them would scatter the re-analysis rules
    - Run `dart run build_runner build --delete-conflicting-outputs` (freezed). Commit
      `ai_plate.freezed.dart`
    - Note the deliberate import shape: this file imports `../presentation/search_providers.dart`
      for `BatchItem` while that file imports this one for `AiOrigin`. Dart resolves the library
      cycle; both halves are in the design's placement table
    - Verify: `flutter analyze` clean
    - _Requirements: 3.2, 3.7, 5.9, 5.10, 11.7, 12.1_

  - [ ] 5.2 Give BatchItem an AI origin
    - Edit `lib/features/search/presentation/search_providers.dart`: `BatchItem` gains
      `final AiOrigin? ai` as an optional named constructor parameter, with the doc comment stating
      that null is a search hit or a quick entry and non-null is what routes a generated food
      through insert-or-reuse on the way out
    - No behaviour change: `Batch.add` / `remove` / `replace` still work by `identical`, and every
      existing call site keeps compiling untouched
    - Run `dart run build_runner build --delete-conflicting-outputs` so `search_providers.g.dart`
      stays consistent
    - Verify: `flutter analyze` clean and `flutter test test/search_test.dart` green
    - _Requirements: 1.7, 5.11_

  - [ ] 5.3 Write the two clamps
    - Edit `lib/features/search/domain/ai_plate.dart`: `clampGrams(double reported, {double? servingG})`
      returning the reported amount rounded to a whole gram inside 1–2000, else `servingG`, else
      `100`; `clampPer100g(VisionDetection d)` returning the four per-100 g values with every
      negative raised to `0`
    - Keep the comment recording that this is the **opposite** of the catalog path: a negative
      `carb_g` out of USDA carbohydrate-by-difference must survive untouched, and only
      `custom_foods` carries the non-negative CHECK
    - Verify: `flutter analyze` clean
    - _Requirements: 7.6, 8.2, 8.3, 8.4, 8.5_

  - [ ]* 5.4 Build the property-test harness
    - Create `test/fixtures/generators.dart`: a shared `setUpAll` setting
      `KiriCheck.maxExamples = 100`, plus generators for `VisionDetection` (ids drawn from a small
      alphabet so collisions are common rather than rare, grams spanning well outside 1–2000,
      confidence across 0–1, negative nutrients, empty names and empty emoji), `List<BatchItem>`
      mixing AI and non-AI origins, `PlateCandidate` lists, and food-name pairs built by
      perturbing a shared token pool so `matchScore` sees near-misses rather than unrelated strings
    - The design specifies these generators but assigns no file; this is the one place they live so
      no property test rolls its own
    - Verify: `flutter analyze` clean

  - [ ]* 5.5 Write property test for gram clamping
    - File `test/ai_merge_test.dart`
    - **Property 12: Gram amounts land in a loggable range**
    - **Validates: Requirements 8.2, 8.3, 8.4, 8.5**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 12: Gram amounts land in a loggable range`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 5.6 Write property test for generated nutrient clamping
    - File `test/ai_merge_test.dart`
    - **Property 13: Generated per-100 g values satisfy the custom_foods constraints**
    - **Validates: Requirements 7.6**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 13: Generated per-100 g values satisfy the custom_foods constraints`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 5.7 Write property test for scaled nutrient figures
    - File `test/ai_merge_test.dart`, over `BatchItem`'s `kcal`/`protein`/`carbs`/`fat` getters and
      their sum across a generated plate
    - **Property 14: Every nutrient figure is the per-100 g vector scaled by grams**
    - **Validates: Requirements 8.6, 9.8**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 14: Every nutrient figure is the per-100 g vector scaled by grams`
    - Verify: `flutter test test/ai_merge_test.dart`

- [ ] 6. Catalog matching and detection resolution

  - [ ] 6.1 Write the name-similarity half of the matcher
    - Create `lib/features/search/domain/food_match.dart`: `matchThreshold = 0.6`,
      `normalizeName` (lowercase, non-alphanumerics → single spaces, empty tokens dropped, trailing
      `es`/`s` folded above three characters), `matchScore` as Sørensen–Dice over the two token
      sets, `bestMatch(String name, List<FoodHit> candidates)` returning the highest scorer at or
      above the threshold
    - Strictly-greater comparison inside `bestMatch`, so a tie keeps the SQL rank order — the
      composite score already decided which of two equal-similarity rows is the better food
    - Pure: no SQL, no drift import. Carry the `// ponytail:` note that token Dice is unmeasured,
      that `Olive oil` against `Oil, olive, salad or cooking` scores 0.57 and falls to a generated
      food, and that the upgrade path is scoring against `catalog.foods.aka` and retuning 0.6
      against a corpus of real replies
    - Verify: `flutter analyze` clean
    - _Requirements: 6.2, 6.3, 6.4, 6.5_

  - [ ]* 6.2 Write property test for the similarity metric
    - File `test/ai_match_test.dart`
    - **Property 10: Match_Score is a bounded, symmetric similarity**
    - **Validates: Requirements 6.2**
    - Generated name pairs from the shared token pool; assert `0.0`–`1.0` inclusive, symmetry under
      swap, and exactly `1.0` when the two names normalize to the same token set
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 10: Match_Score is a bounded, symmetric similarity`
    - Verify: `flutter test test/ai_match_test.dart`

  - [ ] 6.3 Write the admission filter and the resolution function
    - Edit `lib/features/search/domain/ai_plate.dart`: a pure
      `PlateCandidate? resolveDetection(VisionDetection d, List<FoodHit> candidates)` that drops a
      detection below `confidenceFloor` or with an empty trimmed name, then either resolves to
      `bestMatch`'s candidate — taking its `food_id`, its coalesced display name and its emoji,
      with `🍽️` for a NULL one — or builds a generated `FoodHit` (`isCustom`, neither id) from the
      detection's own name, `clampPer100g` macros and emoji, with `🍽️` when the emoji is empty
    - Grams come from `clampGrams`, passed the matched row's `servingG` when there is one
    - The design describes this inline in `AiCapture.shoot` step 5; naming it here is what makes
      Property 11 testable with no notifier, no camera and no database, and keeps the notifier the
      thin orchestrator the design asks for
    - Verify: `flutter analyze` clean
    - _Requirements: 4.5, 4.6, 6.3, 6.4, 6.5, 6.7, 6.8, 7.2, 7.4, 7.5, 13.2_

  - [ ]* 6.4 Write property test for the admission filter
    - File `test/ai_merge_test.dart`
    - **Property 6: Only confident, named detections reach the plate**
    - **Validates: Requirements 4.5, 4.6, 7.4**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 6: Only confident, named detections reach the plate`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 6.5 Write property test for the catalog-versus-generated decision
    - File `test/ai_match_test.dart`
    - **Property 11: The threshold alone decides catalog versus generated**
    - **Validates: Requirements 6.3, 6.4, 6.5, 6.7, 6.8, 7.2, 7.5**
    - Generated detections against generated candidate lists; assert resolution happens exactly
      when some candidate scores ≥ 0.6, that the chosen candidate holds the maximum score and the
      item carries its `food_id`, name and emoji, and that otherwise the item is a generated food
      with the detection's own name, its clamped macros and a non-empty emoji
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 11: The threshold alone decides catalog versus generated`
    - Verify: `flutter test test/ai_match_test.dart`

- [ ] 7. Batch deduplication — mergePlate

  - [ ] 7.1 Write mergePlate
    - Edit `lib/features/search/domain/ai_plate.dart`: pure
      `List<BatchItem> mergePlate({required List<BatchItem> batch, required List<PlateCandidate> candidates, required Set<String> editedIds, required Set<String> removedIds})`
      implementing the design's five-step contract in order — non-AI items pass through untouched
      in place; a candidate in `removedIds` is skipped; a candidate matching a staged id rewrites
      that item **in place** with the sorted shot union, refreshed food and emoji, and the
      candidate's grams unless the id is user-edited; an unmatched candidate is appended; a staged
      AI item absent from the reply is left exactly as it is
    - Return fresh `BatchItem` instances and let the caller replace the whole list in one
      assignment — `Batch` operates by `identical`, so nothing may depend on comparing two items
    - Keep the comment recording that steps 3 and 5 together make an empty candidate list the
      identity function, which is why a failed request cannot damage the plate
    - Verify: `flutter analyze` clean
    - _Requirements: 1.7, 5.3, 5.4, 5.5, 5.8, 5.9, 5.10, 11.8_

  - [ ]* 7.2 Write property test for one item per instance id
    - File `test/ai_merge_test.dart`
    - **Property 1: The plate holds exactly one item per instance id**
    - **Validates: Requirements 5.3, 5.4, 5.5, 5.10**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 1: The plate holds exactly one item per instance id`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 7.3 Write property test for merge idempotence
    - File `test/ai_merge_test.dart`
    - **Property 2: Merging is idempotent**
    - **Validates: Requirements 5.3, 5.4, 5.8**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 2: Merging is idempotent`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 7.4 Write property test for untouched items
    - File `test/ai_merge_test.dart`; include the empty-reply case, which is what every failure
      produces
    - **Property 3: Merging preserves what the reply does not mention**
    - **Validates: Requirements 5.8, 11.8**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 3: Merging preserves what the reply does not mention`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 7.5 Write property test for user-edited grams
    - File `test/ai_merge_test.dart`
    - **Property 4: A user-edited gram amount survives every later reply**
    - **Validates: Requirements 5.9, 9.4**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 4: A user-edited gram amount survives every later reply`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 7.6 Write property test for non-AI staged items
    - File `test/ai_merge_test.dart`
    - **Property 5: Items staged by search or quick add are never touched**
    - **Validates: Requirements 1.7**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 5: Items staged by search or quick add are never touched`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 7.7 Write the four-shot walkthrough example
    - File `test/ai_merge_test.dart`, driving `test/fixtures/vision_replies.dart` through
      `resolveDetection` and `mergePlate` shot by shot
    - Assert the plate ends at six items with the chicken carrying `shots [1, 2, 3, 4]` and a
      single row — the exact scenario the `↺ 3` badge and the `shots 1·2·3, counted once` sub-line
      were designed for
    - _Requirements: 5.3, 5.4, 5.5, 5.6_
    - Verify: `flutter test test/ai_merge_test.dart`

- [ ] 8. Checkpoint - the pure layer is complete
  - Ensure all tests pass, ask the user if questions arise.
  - `flutter analyze` clean; `flutter test` green. Every rule that decides what lands on the plate
    is now covered with no camera, no key and no database in the harness.

- [ ] 9. Data layer: primary search, insert-or-reuse and the write path

  - [ ] 9.1 Expose the primary FTS pass
    - Edit `lib/features/home/data/catalog_repository.dart`: add
      `Future<List<FoodHit>> searchPrimary(String input, {int limit = 10})` calling the existing
      `_catalogSearch('food_fts', prefixQuery(term), 'bm25(food_fts, 10.0, 3.0, 1.0)', term, since, limit)`
    - No trigram append and no custom-food prepend: a trigram hit is the lower-confidence answer by
      construction and must not be a match candidate, and a generated food must not be matched by
      similarity against a previous generated food's `custom_foods` row
    - Change nothing about the rank expression — the `prep_type IS 'cooked'`, negative-bm25 and
      sort-before-LIMIT invariants in `APP_DATABASE.md` stay as they are. Catalog stays read-only
    - Verify: `flutter analyze` clean and `flutter test test/catalog_test.dart` green
    - _Requirements: 6.1, 6.6, 6.9_

  - [ ]* 9.2 Write the catalog-attached matcher examples
    - File `test/ai_match_test.dart`, using
      `AppDatabase(NativeDatabase.memory(), catalogPath: 'database/foods.sqlite')`
    - The worked threshold table from the design as four examples (`Cherry tomatoes` 1.00 matched,
      `Grilled chicken thigh`/`Chicken thigh, cooked` 0.67 matched, `Olive oil` 0.57 generated,
      `Sourdough slice` 0.50 generated)
    - One case where `search` would append trigram hits and `searchPrimary` returns primary hits
      only, and one against a real NULL-`emoji` catalog row rendering `🍽️`
    - _Requirements: 6.1, 6.6, 6.8_
    - Verify: `flutter test test/ai_match_test.dart`

  - [ ] 9.3 Add the insert-or-reuse lookup query
    - Edit `lib/core/database/log.drift`: add the named query `customFoodByName` selecting `id`
      from `custom_foods` where `deleted = 0 AND lower(trim(name)) = lower(trim(:name))`, ordered
      by `updated_at DESC LIMIT 1`
    - Log-only, so it belongs here rather than in Dart; single-column, so drift generates
      `Selectable<String>` with no result class and the `InvalidTypeException` gotcha cannot bite
    - No new index: a scan of a few hundred `custom_foods` rows is sub-millisecond, the same
      reasoning `_customSearch` already records
    - Carry the `// ponytail:` note that SQLite's `lower()` is ASCII-only, so a non-ASCII generated
      name could still produce two rows, and that the fix is folding in Dart
    - Run `dart run build_runner build --delete-conflicting-outputs` (drift regenerates
      `lib/core/database/database.g.dart`). Commit it; never hand-edit it
    - Verify: `flutter analyze` clean and `flutter test test/catalog_test.dart` green
    - _Requirements: 7.7, 7.8_

  - [ ] 9.4 Write findOrCreateCustomFood
    - Edit `lib/features/home/data/food_log_repository.dart`: add
      `Future<String> findOrCreateCustomFood({required String name, String? emoji, required Map<String, double> per100g})`
      returning the `customFoodByName` hit when there is one, else delegating to the existing
      `saveCustomFood(name: name.trim(), emoji: emoji, perServing: per100g)`
    - `servingG` and `servingLabel` stay NULL, so `saveCustomFood`'s divisor is 1, the clamped
      per-100 g values land verbatim, and the food logs as bare grams
    - Verify: `flutter analyze` clean and `flutter test test/catalog_test.dart` green
    - _Requirements: 7.7, 7.8_

  - [ ] 9.5 Route AI items through the write path
    - Edit `lib/features/search/presentation/search_providers.dart`: in `Batch.logAll`, the custom
      branch chooses `repo.findOrCreateCustomFood(...)` when `item.ai != null` and keeps the
      existing quick-add `saveCustomFood(...)` shape otherwise, so quick add keeps its documented
      one-row-per-entry ponytail and only the AI path dedupes
    - AI items log as bare grams: `portionQty` and `portionLabel` stay null. Everything else —
      the 50-column `INSERT … SELECT`, `updates: {logEntries}`, `loggedAt`, the `hour` argument,
      the plain-integer `food_id`, no `>= 0` validation on the copied vector — is the existing code
      and must not change
    - Verify: `flutter analyze` clean and `flutter test test/search_test.dart test/catalog_test.dart`
      green
    - _Requirements: 5.11, 7.7, 7.8, 7.9, 8.7, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 11.11_

  - [ ]* 9.6 Write property test for the shape of the written rows
    - File `test/ai_write_test.dart`, catalog attached to an in-memory log, plate constructed
      directly, and `FakeVisionClient` failing **every** detection request so Requirement 11.11
      falls out of the test
    - **Property 15: Every plate item becomes exactly one log row of a fixed shape**
    - **Validates: Requirements 5.11, 7.9, 8.7, 10.1, 10.4, 10.7, 11.11**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 15: Every plate item becomes exactly one log row of a fixed shape`
    - Verify: `flutter test test/ai_write_test.dart`

  - [ ]* 9.7 Write property test for the hour argument
    - File `test/ai_write_test.dart`
    - **Property 16: An hour argument pins logged_at to that hour**
    - **Validates: Requirements 10.5**
    - Hours 0–23; assert `logged_at` characters 11–13 carry the hour, minutes are `00`, and the
      date is the current local date
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 16: An hour argument pins logged_at to that hour`
    - Verify: `flutter test test/ai_write_test.dart`

  - [ ]* 9.8 Write property test for the snapshotted nutrient vector
    - File `test/ai_write_test.dart`, against the real catalog
    - **Property 17: A matched item's nutrient vector equals the catalog's, unadjusted**
    - **Validates: Requirements 10.2, 10.6, 13.2**
    - `kiri_check`, ≥ 100 examples over generated `food_id`s drawn from the attached catalog; tag
      `// Feature: ai-food-logging, Property 17: A matched item's nutrient vector equals the catalog's, unadjusted`
    - Verify: `flutter test test/ai_write_test.dart`

  - [ ]* 9.9 Write property test for generated-food reuse
    - File `test/ai_write_test.dart`
    - **Property 18: Generated foods are inserted once and reused after**
    - **Validates: Requirements 7.7, 7.8**
    - Generate sequences of confirmed plates whose generated names collide under trimming and case
      folding; assert the non-deleted `custom_foods` count equals the distinct folded-name count
      and that every log row for a name references one id
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 18: Generated foods are inserted once and reused after`
    - Verify: `flutter test test/ai_write_test.dart`

  - [ ]* 9.10 Write the write-path example tests
    - File `test/ai_write_test.dart`
    - A catalog food with no `food_nutrition` row writes NULL nutrients (Req 10.3); a known
      negative-`carb_g` food survives the AI path untouched (Req 10.6); a watched day emits without
      a reload after a confirm (Req 10.8); a completed batch leaves the temp documents directory
      holding only the catalog copy — no image bytes anywhere (Req 12.2)
    - _Requirements: 10.3, 10.6, 10.8, 12.2_
    - Verify: `flutter test test/ai_write_test.dart`

- [ ] 10. Capture pipeline, providers and the session notifier

  - [ ] 10.1 Write the downscaler
    - Create `lib/features/search/presentation/ai_providers.dart` with a top-level
      `Uint8List downscaleJpeg(Uint8List bytes)`: decode with `package:image`, `copyResize` only
      when the longest edge exceeds 1024 px, `encodeJpg(quality: 80)`
    - Top-level because `compute` requires it, and in this file because this is the file that calls
      it — the design specifies the behaviour but assigns it no path
    - Verify: `flutter analyze` clean
    - _Requirements: 3.12_

  - [ ]* 10.2 Write the downscaler example tests
    - Create `test/ai_image_test.dart`: landscape, portrait, square and already-under-1024 bitmaps
      through `downscaleJpeg`
    - Assert the longest edge is ≤ 1024, the aspect ratio holds within a pixel, the output decodes
      as JPEG, and a small image is not upscaled. Four examples, not a property — re-encoding 100
      generated images buys nothing and is slow
    - _Requirements: 3.12_
    - Verify: `flutter test test/ai_image_test.dart`

  - [ ] 10.3 Write the availability and client providers
    - Edit `lib/features/search/presentation/ai_providers.dart`: `@riverpod Future<bool> aiAvailable`
      returning false when `openRouterConfigured` is false, else whether `availableCameras()` is
      non-empty, catching `CameraException` and `MissingPluginException` as false so a headless
      test host is a normal negative; `@riverpod VisionClient visionClient` building an
      `http.Client`, disposing it through `ref.onDispose`, and wrapping it in
      `OpenRouterVisionClient`
    - `availableCameras()` is uniform across io and web, so this is a `try`/`catch` around one call
      and **not** a conditional export — `lib/core/database/connection/` stays the only place in
      `lib/` that branches on platform
    - Run `dart run build_runner build --delete-conflicting-outputs` (riverpod). Neither signature
      names a drift-generated type, so both generate cleanly; commit `ai_providers.g.dart`
    - Verify: `flutter analyze` clean
    - _Requirements: 1.2, 1.3, 2.6_

  - [ ] 10.4 Write the AiCapture notifier
    - Edit `lib/features/search/presentation/ai_providers.dart`: `@riverpod class AiCapture` over
      `AiSession` with `shoot`, `retry`, `reset`, `markEdited`, `markRemoved`, `setTorch`
    - `shoot` is the only orchestrator and stays linear: append the shot numbered as the next
      integer from 1 (rejecting a press while analyzing or at `maxShots`), `phase: analyzing`,
      `visionClient.detect`, on failure set `phase: failed` with the failure and **return without
      touching `batchProvider`**, else `resolveDetection` per detection with
      `CatalogRepository.searchPrimary(searchTerm)` run sequentially, `VisionNoFood` when nothing
      survives, `mergePlate` over the current batch written back in one assignment, `phase: result`
    - `retry` resends for the shots already captured; `reset` discards every shot and every
      AI-origin item and returns to `AiPhase.live`; a `CameraException` with `CameraAccessDenied`
      or `CameraAccessDeniedWithoutPrompt` sets `AiPhase.permissionDenied`
    - Shots live in `AiSession.shots` as `Uint8List` for the life of the batch, are captured
      through `takePicture()` → `readAsBytes()` → `compute(downscaleJpeg, …)`, and are released on
      confirm, on reset and on leaving the screen. Nothing is written to the documents directory or
      either database. Carry the `// ponytail:` note about the plugin's temp cache
    - Run `dart run build_runner build --delete-conflicting-outputs` (riverpod)
    - Verify: `flutter analyze` clean and `flutter test test/ai_merge_test.dart` green
    - _Requirements: 3.2, 3.3, 3.5, 3.7, 3.10, 3.11, 3.12, 4.5, 4.6, 4.7, 5.3, 5.4, 5.5, 5.8, 5.9,
      5.10, 10.9, 11.6, 11.7, 11.8, 11.9, 12.1, 12.2, 12.3_

  - [ ]* 10.5 Write property test for shot numbering
    - File `test/ai_merge_test.dart`, driving `AiCapture` with `FakeVisionClient` and synthetic
      bytes — no camera in the harness
    - **Property 7: Shot numbers are 1..n with no gaps and no repeats**
    - **Validates: Requirements 3.2, 3.7**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 7: Shot numbers are 1..n with no gaps and no repeats`
    - Verify: `flutter test test/ai_merge_test.dart`

  - [ ]* 10.6 Write property test for end-of-batch release
    - File `test/ai_write_test.dart`, catalog attached, parameterized over all three end-of-batch
      triggers — confirm, reset, and leaving the screen
    - **Property 19: Ending a batch releases every shot and every AI plate item**
    - **Validates: Requirements 3.10, 10.9, 12.3**
    - The design splits this property's triggers across `ai_merge_test.dart` and
      `ai_write_test.dart`; one property is one property test, so the catalog-attached harness
      covers all three triggers here and subsumes the pure one. Assert no shot remains, no
      AI-origin item remains, the pane is live again, and items staged by search or quick add
      survive a confirm
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 19: Ending a batch releases every shot and every AI plate item`
    - Verify: `flutter test test/ai_write_test.dart`

- [ ] 11. Checkpoint - the feature works headless
  - Ensure all tests pass, ask the user if questions arise.
  - `flutter analyze` clean; `flutter test` green. Detection, matching, merging and writing are all
    reachable through the notifier with a faked client and no UI yet.

- [ ] 12. SwipeRow extraction

  - [ ] 12.1 Lift the drag mechanics out of _ResultRow
    - Create `lib/features/search/presentation/swipe_row.dart` with
      `SwipeRow({required unitG, unitLabel, required onPicked, onRemove, onTap, required builder})`,
      moving the horizontal drag mechanics currently inside `_ResultRow` — including the part worth
      keeping: the recognizer reads **both** axes off `globalPosition`, because its own `delta`
      carries the primary axis only, so a vertical drag still scrolls the list until a horizontal
      one wins the arena
    - `portionForDrag` from `domain/portion.dart` stays the ladder, unchanged. `onRemove` null means
      no left action, which is how the result row keeps its current behaviour
    - Edit `lib/features/search/presentation/search_screen.dart`: re-parent `_ResultRow` onto
      `SwipeRow`, keeping its own painting (amber gradient, left-hand label, portion pill) in the
      `builder` callback. Extraction, not a reimplementation — the recognizer wiring must stay
      identical
    - Acceptance bar: `flutter test test/search_test.dart` passes **unchanged**, including its
      hand-rolled multi-frame `_swipeToStage` helper, which is the only thing that proves the
      recognizer still sees a drag
    - Verify: `flutter analyze` clean and `flutter test test/search_test.dart` green with no edits
      to that file
    - _Requirements: 9.3, 9.4_

- [ ] 13. Camera pane

  - [ ] 13.1 Write AiCapturePane
    - Create `lib/features/search/presentation/ai_capture_pane.dart`: `SizedBox(height: 396)` over
      `AppColors.camBg`, a `Stack` of the design's five layers — `CameraPreview` while live,
      `Image.memory` of the newest shot once one exists, and the centred `[ LIVE CAMERA FEED ]`
      placeholder when no preview frame is available; the torch circle top-right, amber while on;
      the analyzing scrim with the sweep bar, `ANALYZING PLATE`, and the sub-label reading
      `detecting foods and portions` for shot 1 or `comparing with N earlier shot(s)` above it; the
      failure scrim with the copy and a `retry` pill
    - Bottom bar: the `reset stack` pill once a shot exists, the numbered thumbnail strip for the 5
      most recent shots with the newest outlined amber, replaced at 8 shots by
      `shot limit reached — log or reset the stack`; the shutter with a null `onTap` and 45% opacity
      while analyzing or at 8 shots; the confirm pill reading `log <kcal>` in amber when the plate
      is non-empty and `log` disabled with a null `onTap` when it is empty
    - The failure copy is one `switch` over the sealed `VisionFailure`, exhaustive by compiler
      check, with `retry` on every case except `VisionNoFood`. `AiPhase.permissionDenied` renders
      `camera access is off — turn it on in settings` with an `app_settings` deep link
    - The confirm control reads `batchProvider`, not `AiSession.phase`, so a failed detection never
      blocks logging what is already staged. Every colour from `AppColors`
    - Verify: `flutter analyze` clean, `flutter test` green
    - _Requirements: 3.1, 3.4, 3.6, 3.8, 3.9, 3.11, 4.7, 9.9, 9.10, 9.11, 11.1, 11.2, 11.3, 11.4,
      11.5, 11.6, 11.7, 11.10, 13.4_

  - [ ]* 13.2 Write property test for the thumbnail strip
    - File `test/ai_screen_test.dart`, `aiAvailableProvider` forced true and `visionClientProvider`
      faked; no camera exists in the harness, so the placeholder branch is the one under test
    - **Property 8: The thumbnail strip is the last five shots, newest accented**
    - **Validates: Requirements 3.6**
    - `kiri_check`, ≥ 100 examples over shot counts 1–8; tag
      `// Feature: ai-food-logging, Property 8: The thumbnail strip is the last five shots, newest accented`
    - Verify: `flutter test test/ai_screen_test.dart`

  - [ ]* 13.3 Write the failure copy test
    - File `test/ai_screen_test.dart`: an exhaustive `switch` over the sealed `VisionFailure`
      asserting the exact rendered copy for each case, plus the presence of `retry` on all but
      `VisionNoFood`, and the permission-denied copy with its settings control
    - An example test rather than a property: the type is closed, so the switch is complete where a
      hundred random draws would not be
    - _Requirements: 11.1, 11.2, 11.3, 11.5, 11.6, 11.7_
    - Verify: `flutter test test/ai_screen_test.dart`

- [ ] 14. Plate list

  - [ ] 14.1 Write the plate list and its row
    - Create `lib/features/search/presentation/ai_plate_list.dart`: the empty-state copy verbatim
      (`nothing on the plate yet — tap the shutter after each thing you add. shoot as many times as
      you like; repeats are merged, not doubled.`), and `_PlateRow` inside `SwipeRow` laid out as
      the design's `plateRows` — 34 px emoji column, name plus badge, `macroLine`, gram sub-line
    - Badge: `↺ N` in `AppColors.merged` for a shot list above one, `new` in amber for a single
      shot equal to the newest, nothing otherwise. Sub-line: `<grams> g` alone, or
      `<grams> g · shots 1·2·3, counted once` when merged. Every figure is `grams / 100 × per-100 g`
    - Right release rewrites the item's grams through `Batch.replace` and calls
      `markEdited(instanceId, grams)`; left release past the arm threshold removes it and calls
      `markRemoved(instanceId)`, rendering `remove` → `release to remove` in `AppColors.danger`
      once armed at `dx < -46` behind the reversed gradient
    - Carry the `// ponytail:` note recording the omitted preparation wheel, why
      (`catalog.foods.prep_type` is 48% populated with no per-preparation nutrient variants) and
      the merged-foods variant picker as its upgrade path. No per-shot report strip
    - Verify: `flutter analyze` clean, `flutter test` green
    - _Requirements: 5.6, 5.7, 6.8, 7.3, 8.6, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 13.1, 13.3_

  - [ ]* 14.2 Write property test for the plate row
    - File `test/ai_screen_test.dart`, over a generated plate
    - **Property 9: A plate row renders every field, with the badge its shot list implies**
    - **Validates: Requirements 5.6, 5.7, 9.1**
    - `kiri_check`, ≥ 100 examples; tag
      `// Feature: ai-food-logging, Property 9: A plate row renders every field, with the badge its shot list implies`
    - Verify: `flutter test test/ai_screen_test.dart`

- [ ] 15. Screen wiring

  - [ ] 15.1 Add the third mode to the search screen
    - Edit `lib/features/search/presentation/search_screen.dart`: `enum _Mode { search, ai, quick }`
      and the sparkle toggle between search and quick, rendered through the unchanged `_modeButton`
      only when `aiAvailableProvider` resolves true
    - AI mode replaces the results list and the search field with `AiCapturePane` above
      `AiPlateList`; the header totals and the chip strip keep reading `batchProvider`, so they work
      unchanged; switching modes keeps the staged items
    - Chip strip: the empty copy becomes `plate is empty — shoot to detect foods` in AI mode and
      stays as it is otherwise; `Dismissible.onDismissed` routes through one helper that removes the
      `BatchItem` and, when `item.ai != null`, also records the instance id as user-removed. Chip
      labels keep ellipsizing
    - Narrow the existing `// ponytail:` note to Scan alone — that mode still does not exist
    - Verify: `flutter analyze` clean and `flutter test test/search_test.dart` green
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 9.7, 9.8_

  - [ ]* 15.2 Write the screen widget example tests
    - File `test/ai_screen_test.dart`, `aiAvailableProvider` forced true or false and
      `visionClientProvider` faked
    - The toggle renders with a key and hides without one and without a camera (Req 1.1–1.3); the
      body swap and chip strip copy (Req 1.4–1.6); items survive a mode switch (Req 1.7); a shutter
      tap starts a request and is rejected while one is in flight (Req 3.3–3.5); the shot-limit and
      reset copy (Req 3.8, 3.9); a generated food renders in the same layout as a matched row
      (Req 7.3); the empty-plate copy (Req 9.2); a right drag renders a candidate amount with its
      kilocalories and a left drag renders `release to remove` (Req 9.3, 9.5); a chip swiped up
      removes its item (Req 9.7); the confirm control's two labels and its rejected tap when empty
      (Req 9.9–9.11); confirm stays live while a detection is failed (Req 11.10); no preparation
      wheel and no report strip render (Req 13.1, 13.4); and a left-swipe removal both drops the row
      and keeps it off a subsequent reply
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 3.3, 3.4, 3.5, 3.8, 3.9, 3.11, 7.3, 9.2,
      9.3, 9.5, 9.6, 9.7, 9.9, 9.10, 9.11, 11.10, 13.1, 13.4_
    - Verify: `flutter test test/ai_screen_test.dart`

- [ ] 16. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.
  - `flutter analyze` clean; `flutter test` green from the repo root, offline, with no API key.
    Confirm every generated file touched by this change is present and committed
    (`vision_models.freezed.dart`, `vision_models.g.dart`, `ai_plate.freezed.dart`,
    `ai_providers.g.dart`, `search_providers.g.dart`, `database.g.dart`) and that none was
    hand-edited.
  - Hand the user the commands that block rather than running them:
    `flutter run --dart-define=OPENROUTER_API_KEY=... --dart-define=OPENROUTER_MODEL=...` and
    `dart run build_runner watch`.

## Notes

- Sub-tasks marked `*` are test tasks and can be skipped for a faster MVP. Skipping 5.4 skips the
  shared generators, and every other `*` property task with it.
- The pure layer (tasks 5–7) is where the feature's real logic lives and is testable with no
  camera, no key and no database — which is why its property tests land beside it rather than at
  the end.
- Task 12 is a refactor with a regression bar, not a feature: `test/search_test.dart` must pass
  unchanged.
- Requirement 11's failure copy is an exhaustive `switch` over the sealed `VisionFailure`
  (task 13.3), not a property. The type is closed.
- Nothing here runs `flutter run`, `build_runner watch` or `marimo edit`; those block and are
  handed to the user.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["2.1", "2.2"] },
    { "id": 2, "tasks": ["2.3", "3.1"] },
    { "id": 3, "tasks": ["3.2", "5.1", "6.1", "9.1", "9.3", "10.1", "12.1"] },
    { "id": 4, "tasks": ["3.3", "5.2", "5.3", "9.2", "9.4", "10.2", "10.3"] },
    { "id": 5, "tasks": ["5.4", "6.3", "9.5"] },
    { "id": 6, "tasks": ["3.4", "5.5", "6.2", "7.1", "9.6"] },
    { "id": 7, "tasks": ["3.5", "5.6", "6.5", "9.7", "10.4"] },
    { "id": 8, "tasks": ["3.6", "5.7", "9.8", "13.1", "14.1"] },
    { "id": 9, "tasks": ["3.7", "6.4", "9.9", "13.2", "15.1"] },
    { "id": 10, "tasks": ["3.8", "7.2", "9.10", "13.3"] },
    { "id": 11, "tasks": ["7.3", "10.6", "14.2"] },
    { "id": 12, "tasks": ["7.4", "15.2"] },
    { "id": 13, "tasks": ["7.5"] },
    { "id": 14, "tasks": ["7.6"] },
    { "id": 15, "tasks": ["7.7"] },
    { "id": 16, "tasks": ["10.5"] }
  ]
}
```
