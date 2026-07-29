# Requirements Document

## Introduction

AI Food Logging is the third mode of the existing search screen (`Ai`, the sparkle toggle in the
design's header row beside `Scan`, `Search` and `Quick`). The user points the camera at a plate,
taps the shutter once per thing added to it, and a vision model returns the foods and their
estimated gram weights. Detections accumulate onto a **plate** the user can correct before
anything reaches the log.

The defining behaviour is **batch-level deduplication**: every photo taken between entering the
mode and confirming forms one batch, and one physical food item produces exactly one log entry no
matter how many photos it appears in. The chicken breast that shows up in shots 1, 2 and 3 is one
entry, not three. The design already carries the vocabulary for this — the plate row's badge reads
`↺ 3` and its sub-line reads `shots 1·2·3, counted once`, and the empty-plate copy promises
"repeats are merged, not doubled".

This is the first genuinely network-dependent path in an app that is otherwise offline-first, so
request failure, timeout, absent configuration and malformed model output are first-class
requirements rather than afterthoughts. Every write still lands in local SQLite through the
existing `Batch` → `FoodLogRepository` path; the network is only consulted between the shutter and
the plate.

### Source material

- **Design**: `designs/Food logging app design-handoff/food-logging-app-design/project/Food Search.dc.html`,
  `aiMode` branch (markup around the `<sc-if value="{{ aiMode }}">` block) and the
  `// ---- AI logging (stacking mode) ----` section of its script.
- **Data layer**: `database/APP_DATABASE.md`, `lib/core/database/nutrients.dart`,
  `lib/features/home/data/{catalog_repository,food_log_repository}.dart`,
  `lib/features/search/presentation/{search_providers,quick_add}.dart`.
- **Remote API**: OpenRouter exposes an OpenAI-compatible `/api/v1/chat/completions` endpoint that
  accepts multi-part message content, where an image part carries either a URL or a base64 data URL,
  and several images may be sent as separate entries in one content array
  ([OpenRouter image inputs](https://openrouter.ai/docs/guides/overview/multimodal/image-understanding)).
  Schema-constrained replies are requested through the same endpoint's structured-output support
  ([OpenRouter structured outputs](https://openrouter.ai/docs/guides/features/structured-outputs)).
  Content was rephrased for compliance with licensing restrictions.

### Decisions taken by default

The user asked for defaults on every open question. Each default below is recorded so it is
reviewable, and each is reflected in at least one acceptance criterion.

| # | Question | Default taken |
| --- | --- | --- |
| D1 | Where does the mode live? | A third mode on the existing search screen, staging into the existing `Batch`, so one code path writes the log. The `// ponytail:` note in `search_screen.dart` that omits the Scan and AI toggles is lifted for AI only. |
| D2 | How is OpenRouter configured? | `--dart-define=OPENROUTER_API_KEY=…` and `--dart-define=OPENROUTER_MODEL=…`, read with `String.fromEnvironment`, mirroring `supabaseUrl`/`supabaseAnonKey`. Model id defaults to `google/gemini-2.5-flash`; an empty key means "AI logging disabled", a normal state. |
| D3 | Key in the client binary? | Accepted for now and marked as a deliberate ceiling: a build-time key ships inside the binary and any user can extract it. The upgrade path is a server-side proxy holding the key. Recorded as `// ponytail:` in the implementation, not solved here. |
| D4 | One request per shot, or the whole batch each time? | The whole batch. Every shutter press sends all photos of the current batch in one request, and the reply is the authoritative plate. Deduplication is then performed by the model, as required, instead of by app-side name matching. Extra token cost is accepted. |
| D5 | Request timeout | 30 seconds. |
| D6 | Offline detection | No pre-flight connectivity probe. The request is attempted and a failure is surfaced as a failure. |
| D7 | Malformed model output | One automatic retry, then the shot fails like a network error. The plate is left untouched. |
| D8 | What is "no good catalog match"? | Top hit from the **primary** FTS pass only (trigram hits are explicitly the lower-confidence answer), and a normalized name-similarity of at least `0.6`. bm25 magnitudes are query-dependent and not comparable across queries, so the threshold is computed in Dart over the returned names rather than read off the SQL score. |
| D9 | Where does a generated food live? | A `custom_foods` row written at confirm time through `FoodLogRepository.saveCustomFood`, the same path quick add uses. `serving_g`/`serving_label` stay NULL, so the food reads as per 100 g and logs as bare grams. |
| D10 | Same generated food detected in a later session? | Reused by trimmed, case-insensitive name match against non-deleted `custom_foods`, rather than writing a second row. This deliberately differs from quick add, whose `// ponytail:` accepts one row per entry. |
| D11 | Two separate items of one food type | Two plate rows, one per physical item. The design's row renders grams with no quantity field, so a single row with "×2" has nowhere to show itself. |
| D12 | Detection confidence | Returned by the model and used as a floor (`0.35`) for admitting an item to the plate. Not rendered — the rendered design uses the badge slot for `↺ N`/`new`, not for a confidence figure. |
| D13 | Photo cap per batch | 8. The design's thumbnail strip already slides over the last 5. |
| D14 | Image size sent | Longest edge downscaled to 1024 px, JPEG quality 80. |
| D15 | Photo retention | In memory for the life of the batch only. Never written to the app's documents directory, never logged. |
| D16 | Chip labels | The chip strip reuses the existing chip widget, so a long name ellipsizes rather than using the prototype's hand-written `short` name, which has no catalog equivalent. |
| D17 | Per-shot report strip | Omitted. Its values exist in the prototype's script (`reportNew`, `reportDup`) but no markup renders them; the rendered design conveys merge feedback through the per-row badge and shots sub-line. |
| D18 | Preparation wheel | Out of scope by explicit instruction. See Requirement 13. |

## Glossary

- **AI_Logging_Mode**: The third mode of the search screen, reached by the sparkle toggle in the
  header. Owns the camera pane and the plate list.
- **Detection_Batch**: All photos captured since AI_Logging_Mode was entered or since the plate was
  last reset or confirmed. The unit over which deduplication applies.
- **Shot**: One photo captured by one shutter press, numbered from 1 within the Detection_Batch.
- **Plate**: The ordered set of Plate_Items currently staged for the Detection_Batch. Held in the
  search screen's existing staging list, so the header totals, chip strip and confirm button work
  unchanged.
- **Plate_Item**: One physical food item the user is about to log: an instance identifier, a display
  name, an emoji, a per-100 g nutrient source, a gram amount, and the list of Shot numbers the item
  was seen in.
- **Instance_Id**: A short identifier the Vision_Model assigns to one physical food item and reuses
  for that same item across every Shot of the Detection_Batch.
- **Vision_Model**: The multimodal model invoked through OpenRouter, named by the configured model
  id.
- **Vision_Client**: The app component that builds the OpenRouter request, sends it, and validates
  the reply against the response schema.
- **Detection**: One entry of a Vision_Model reply: Instance_Id, food name, catalog search term,
  estimated grams, detection confidence, Shot numbers, and the generated-food fields.
- **Catalog_Matcher**: The component that resolves a Detection's name to a `catalog.foods` row, or
  reports that no row clears the match threshold.
- **Match_Score**: A number in `0.0`–`1.0` measuring similarity between a Detection's food name and
  a candidate catalog row's display name.
- **Generated_Food**: A food the Vision_Model supplies whole — name, per-100 g macros and emoji —
  used when the Catalog_Matcher finds no row clearing the match threshold.
- **Food_Log_Writer**: The existing `FoodLogRepository` write path, which snapshots the whole 50
  nutrient columns into `log_entries` inside SQL.
- **App_Config**: The compile-time configuration read through `String.fromEnvironment`.
- **Catalog**: The read-only USDA database attached as `catalog`.

## Requirements

### Requirement 1: Enter AI logging mode

**User Story:** As someone logging a meal, I want to reach photo logging from the same screen I
already search on, so that photo logging, search and quick add share one staging area and one
confirm button.

#### Acceptance Criteria

1. WHERE the App_Config OpenRouter API key is a non-empty string, THE AI_Logging_Mode toggle SHALL
   render in the search screen header between the search toggle and the quick add toggle.
2. WHERE the App_Config OpenRouter API key is an empty string, THE search screen SHALL render the
   header without the AI_Logging_Mode toggle.
3. WHERE the running platform exposes no camera, THE search screen SHALL render the header without
   the AI_Logging_Mode toggle.
4. WHEN the user taps the AI_Logging_Mode toggle, THE search screen SHALL replace the results list
   and the search field with the camera pane and the plate list.
5. WHILE AI_Logging_Mode is active, THE search screen SHALL render the chip strip populated from the
   Plate.
6. WHILE AI_Logging_Mode is active AND the Plate holds no Plate_Item, THE chip strip SHALL render
   the text `plate is empty — shoot to detect foods`.
7. WHEN the user switches from AI_Logging_Mode to another mode, THE search screen SHALL keep the
   staged Plate_Items in the staging list.

### Requirement 2: Configure the OpenRouter model and credentials

**User Story:** As the developer of this app, I want the vision model id and API key supplied the
same way Supabase credentials already are, so that swapping models is a build flag and a missing
key is a normal state rather than a crash.

#### Acceptance Criteria

1. THE App_Config SHALL read the OpenRouter API key from the `OPENROUTER_API_KEY` compile-time
   environment value, defaulting to an empty string.
2. THE App_Config SHALL read the Vision_Model id from the `OPENROUTER_MODEL` compile-time
   environment value, defaulting to `google/gemini-2.5-flash`.
3. THE Vision_Client SHALL send the configured Vision_Model id as the `model` field of every
   OpenRouter request.
4. THE Vision_Client SHALL send the configured OpenRouter API key as a bearer token in the
   `Authorization` header of every OpenRouter request.
5. THE Vision_Client SHALL send every request to `https://openrouter.ai/api/v1/chat/completions`
   over HTTPS.
6. IF the App_Config OpenRouter API key is an empty string, THEN THE Vision_Client SHALL report
   `not configured` to the caller as its complete response to a detection request.
7. THE App_Config SHALL expose the OpenRouter API key and the Vision_Model id as compile-time
   constants only, so both stay out of `log.sqlite`.

### Requirement 3: Capture a multi-shot batch

**User Story:** As someone assembling a plate, I want to shoot after each thing I add, so that the
detector sees items that a single photo would hide behind others.

#### Acceptance Criteria

1. WHILE AI_Logging_Mode is active AND no Shot has been captured, THE camera pane SHALL render the
   live camera preview with the placeholder text `[ LIVE CAMERA FEED ]` when no preview frame is
   available.
2. WHEN the user taps the shutter, THE AI_Logging_Mode SHALL capture one Shot numbered as the next
   integer within the Detection_Batch, starting at 1.
3. WHEN a Shot is captured, THE AI_Logging_Mode SHALL start a detection request for the
   Detection_Batch.
4. WHILE a detection request is in flight, THE camera pane SHALL render the captured frame of the
   newest Shot under a scrim, the label `ANALYZING PLATE`, and a sub-label reading
   `detecting foods and portions` for Shot 1 or `comparing with N earlier shot(s)` for Shot numbers
   above 1, where N is the Shot number minus 1.
5. WHILE a detection request is in flight, THE shutter SHALL reject taps.
6. WHILE the Detection_Batch holds at least one Shot, THE camera pane SHALL render one numbered
   thumbnail per Shot for the 5 most recent Shots, with the newest thumbnail outlined in the accent
   colour.
7. WHILE the Detection_Batch holds 8 Shots, THE shutter SHALL reject taps.
8. WHILE the Detection_Batch holds 8 Shots, THE camera pane SHALL render the text
   `shot limit reached — log or reset the stack`.
9. WHILE the Detection_Batch holds at least one Shot, THE camera pane SHALL render the
   `reset stack` control.
10. WHEN the user taps `reset stack`, THE AI_Logging_Mode SHALL discard every Shot and every
    Plate_Item of the Detection_Batch and return the camera pane to the live preview.
11. WHEN the user taps the torch control, THE AI_Logging_Mode SHALL toggle the camera torch and
    render the control in the accent colour while the torch is on.
12. THE AI_Logging_Mode SHALL downscale each captured Shot so its longest edge is at most 1024
    pixels and encode the Shot as JPEG at quality 80 before including the Shot in a request.

### Requirement 4: Detect foods in the batch

**User Story:** As someone logging by photo, I want the detector to read the whole batch at once,
so that its answer accounts for every photo rather than each photo in isolation.

#### Acceptance Criteria

1. WHEN a detection request starts, THE Vision_Client SHALL send every Shot of the Detection_Batch
   in one request as separate image entries of one message content array, ordered by Shot number.
2. WHEN a detection request starts AND the Plate holds at least one Plate_Item, THE Vision_Client
   SHALL include the Instance_Id, name and gram amount of every current Plate_Item in the request
   text.
3. THE Vision_Client SHALL request a schema-constrained reply in which every Detection carries an
   Instance_Id, a food name, a catalog search term, an estimated gram amount, a detection
   confidence in `0.0`–`1.0`, the list of Shot numbers the item appears in, and the Generated_Food
   fields of Requirement 7.
4. THE Vision_Client SHALL abort a detection request that has not completed within 30 seconds and
   report `timeout` to the caller.
5. WHEN the Vision_Client receives a reply that satisfies the response schema, THE AI_Logging_Mode
   SHALL apply every Detection whose confidence is at least `0.35` to the Plate.
6. WHEN the Vision_Client receives a reply that satisfies the response schema, THE AI_Logging_Mode
   SHALL discard every Detection whose confidence is below `0.35`.
7. WHEN a detection request completes, THE camera pane SHALL remove the analyzing scrim and render
   the captured frame of the newest Shot.

### Requirement 5: Deduplicate within the batch

**User Story:** As someone who shoots the same plate four times while building it, I want each
thing I ate counted once, so that the log matches the meal instead of the number of photos.

#### Acceptance Criteria

1. THE Vision_Client SHALL instruct the Vision_Model to assign one Instance_Id per physical food
   item, to reuse an Instance_Id for the same physical item across every Shot the item appears in,
   and to assign distinct Instance_Ids to separate physical items of the same food type.
2. THE Vision_Client SHALL instruct the Vision_Model to reuse the Instance_Id supplied for a
   current Plate_Item when a Detection refers to that same physical item.
3. WHEN a Detection carries an Instance_Id equal to that of a current Plate_Item, THE
   AI_Logging_Mode SHALL add the Detection's Shot numbers to that Plate_Item's Shot list.
4. WHEN a Detection carries an Instance_Id equal to that of a current Plate_Item, THE
   AI_Logging_Mode SHALL keep the count of Plate_Items on the Plate unchanged.
5. WHEN a Detection carries an Instance_Id matching no current Plate_Item, THE AI_Logging_Mode SHALL
   append one new Plate_Item for that Detection.
6. WHILE a Plate_Item's Shot list holds more than one Shot number, THE plate row SHALL render the
   badge `↺ N`, where N is the count of Shot numbers, and the sub-line
   `<grams> g · shots <numbers joined by ·>, counted once`.
7. WHILE a Plate_Item's Shot list holds exactly one Shot number equal to the newest Shot number,
   THE plate row SHALL render the badge `new`.
8. WHEN a detection request completes AND a current Plate_Item's Instance_Id appears in no
   Detection of that reply, THE AI_Logging_Mode SHALL keep that Plate_Item on the Plate with its
   Shot list unchanged.
9. WHEN a detection request completes, THE AI_Logging_Mode SHALL keep the user-entered gram amount
   of every Plate_Item the user marked as user-edited during the Detection_Batch.
10. WHEN a detection request completes AND a Detection carries the Instance_Id of a Plate_Item the
    user marked as user-removed during the Detection_Batch, THE AI_Logging_Mode SHALL leave that
    Instance_Id off the Plate.
11. WHEN the user confirms the Plate, THE Food_Log_Writer SHALL write exactly one `log_entries` row
    per Plate_Item.

### Requirement 6: Match a detected food to the catalog

**User Story:** As someone logging by photo, I want detections resolved to real USDA rows where a
real row fits, so that my log carries the full nutrient vector rather than four macros.

#### Acceptance Criteria

1. WHEN a Detection is applied to the Plate, THE Catalog_Matcher SHALL search the Catalog for the
   Detection's catalog search term using the existing composite-ranked primary FTS query.
2. THE Catalog_Matcher SHALL compute a Match_Score between the Detection's food name and the
   display name of each candidate returned by the primary FTS query.
3. WHERE the highest Match_Score among the candidates is at least `0.6`, THE Catalog_Matcher SHALL
   resolve the Detection to the candidate holding that Match_Score.
4. WHERE the highest Match_Score among the candidates is below `0.6`, THE Catalog_Matcher SHALL
   report that no catalog row matches the Detection.
5. WHERE the primary FTS query returns no candidate, THE Catalog_Matcher SHALL report that no
   catalog row matches the Detection.
6. THE Catalog_Matcher SHALL exclude trigram-fallback hits from Match_Score candidacy.
7. WHEN the Catalog_Matcher resolves a Detection to a catalog row, THE Plate_Item SHALL take the
   catalog row's `food_id`, its `coalesce(display_name, description)` as the display name, and its
   `emoji` as the emoji.
8. IF a resolved catalog row carries a NULL `emoji`, THEN THE plate row SHALL render the emoji
   `🍽️`.
9. THE Catalog_Matcher SHALL treat the Catalog as read-only for every query.

### Requirement 7: Fall back to a model-generated food

**User Story:** As someone eating something the USDA catalog does not carry, I want the detector to
supply a named food with macros and an icon, so that the item still reaches my log instead of being
dropped or forced onto a wrong row.

#### Acceptance Criteria

1. THE Vision_Client SHALL request a display name, a per-100 g energy value in kilocalories,
   per-100 g protein, carbohydrate and fat values in grams, and one emoji for every Detection.
2. WHEN the Catalog_Matcher reports that no catalog row matches a Detection, THE AI_Logging_Mode
   SHALL create the Plate_Item as a Generated_Food carrying the Detection's supplied name, per-100 g
   macros and emoji.
3. WHILE a Plate_Item is a Generated_Food, THE plate row SHALL render the Generated_Food's name,
   emoji and macros in the same layout as a catalog-matched row.
4. IF a Generated_Food's supplied name is empty after trimming whitespace, THEN THE AI_Logging_Mode
   SHALL discard that Detection.
5. IF a Generated_Food's supplied emoji is absent, THEN THE AI_Logging_Mode SHALL use the emoji
   `🍽️` for that Plate_Item.
6. THE AI_Logging_Mode SHALL clamp every Generated_Food per-100 g nutrient value below `0` to `0`,
   so the values satisfy the `custom_foods` non-negative CHECK constraints.
7. WHEN the user confirms the Plate AND a Plate_Item is a Generated_Food AND no non-deleted
   `custom_foods` row has a name equal to the Generated_Food's name ignoring case and surrounding
   whitespace, THE Food_Log_Writer SHALL insert one `custom_foods` row holding the Generated_Food's
   name, emoji and per-100 g macros, with `serving_g` and `serving_label` NULL.
8. WHEN the user confirms the Plate AND a Plate_Item is a Generated_Food AND a non-deleted
   `custom_foods` row has a name equal to the Generated_Food's name ignoring case and surrounding
   whitespace, THE Food_Log_Writer SHALL log against that existing row's id.
9. WHEN the Food_Log_Writer logs a Generated_Food, THE Food_Log_Writer SHALL set the
   `log_entries.custom_food_id` column and leave `log_entries.food_id` NULL.

### Requirement 8: Estimate the amount eaten

**User Story:** As someone logging by photo, I want a gram estimate per item, so that the plate
totals mean something before I start correcting them.

#### Acceptance Criteria

1. THE Vision_Client SHALL request an estimated gram amount for every Detection.
2. WHERE a Detection's estimated gram amount is between `1` and `2000` inclusive, THE Plate_Item
   SHALL take that gram amount rounded to the nearest whole gram.
3. WHERE a Detection's estimated gram amount is outside `1` to `2000` inclusive AND the Detection
   resolved to a catalog row whose `serving_g` holds a value, THE Plate_Item SHALL take that
   `serving_g` value as its gram amount.
4. WHERE a Detection's estimated gram amount is outside `1` to `2000` inclusive AND the Detection
   resolved to a catalog row whose `serving_g` is NULL, THE Plate_Item SHALL take `100` grams as its
   gram amount.
5. WHERE a Detection's estimated gram amount is outside `1` to `2000` inclusive AND the Detection is
   a Generated_Food, THE Plate_Item SHALL take `100` grams as its gram amount.
6. THE plate row SHALL render every nutrient figure as the Plate_Item's gram amount divided by
   `100` multiplied by the corresponding per-100 g value.
7. THE AI_Logging_Mode SHALL log every Plate_Item as bare grams, leaving `log_entries.portion_qty`
   and `log_entries.portion_label` NULL.

### Requirement 9: Review and correct the plate

**User Story:** As someone who knows what is on the plate better than the detector does, I want to
fix amounts and drop mistakes before anything is written, so that a wrong detection costs a swipe
rather than an edit to my history.

#### Acceptance Criteria

1. WHILE AI_Logging_Mode is active, THE plate list SHALL render one row per Plate_Item, each row
   carrying the emoji, the display name, the merge badge, the kilocalorie and protein, carbohydrate
   and fat figures, and the gram sub-line.
2. WHILE the Plate holds no Plate_Item, THE plate list SHALL render the text
   `nothing on the plate yet — tap the shutter after each thing you add. shoot as many times as you
   like; repeats are merged, not doubled.`
3. WHEN the user drags a plate row to the right, THE plate row SHALL render a candidate gram amount
   drawn from the existing portion ladder together with the kilocalories that amount yields.
4. WHEN the user releases a plate row drag that selected a candidate gram amount, THE
   AI_Logging_Mode SHALL set that Plate_Item's gram amount to the candidate amount and mark that
   Plate_Item as user-edited for the Detection_Batch.
5. WHEN the user drags a plate row left far enough to arm removal, THE plate row SHALL render the
   text `release to remove`.
6. WHEN the user releases a plate row drag that armed removal, THE AI_Logging_Mode SHALL remove that
   Plate_Item from the Plate and mark its Instance_Id as user-removed for the Detection_Batch.
7. WHEN the user swipes a chip upward in the chip strip, THE AI_Logging_Mode SHALL remove the
   corresponding Plate_Item from the Plate and mark its Instance_Id as user-removed for the
   Detection_Batch.
8. WHILE AI_Logging_Mode is active, THE search screen header SHALL render the summed kilocalories,
   protein, carbohydrate and fat of every Plate_Item.
9. WHILE the Plate holds at least one Plate_Item, THE camera pane SHALL render the confirm control
   labelled `log <summed kilocalories>` in the accent colour.
10. WHILE the Plate holds no Plate_Item, THE camera pane SHALL render the confirm control labelled
    `log` in the disabled colour.
11. WHILE the Plate holds no Plate_Item, THE confirm control SHALL reject taps.

### Requirement 10: Write the plate to the log

**User Story:** As someone who just confirmed a plate, I want the entries to look exactly like
entries made by search, so that the timeline, day totals and every nutrient average read from one
shape of row.

#### Acceptance Criteria

1. WHEN the user taps either the camera pane confirm control or the header confirm control, THE
   Food_Log_Writer SHALL write every Plate_Item to `log_entries` in the local database.
2. WHEN the Food_Log_Writer logs a catalog-matched Plate_Item, THE Food_Log_Writer SHALL copy all 50
   per-100 g nutrient columns from `catalog.food_nutrition` into the `log_entries` row inside one
   SQL statement.
3. WHEN the Food_Log_Writer logs a catalog-matched Plate_Item whose catalog food has no
   `food_nutrition` row, THE Food_Log_Writer SHALL write the `log_entries` row with NULL nutrient
   values.
4. THE Food_Log_Writer SHALL write `log_entries.logged_at` as a local wall-clock string in
   `YYYY-MM-DDTHH:MM` form.
5. WHERE the search screen was opened with an hour argument, THE Food_Log_Writer SHALL write
   `log_entries.logged_at` at that hour of the current local date with minutes `00`.
6. THE Food_Log_Writer SHALL accept negative values in the copied nutrient columns of a
   catalog-matched Plate_Item, so that USDA carbohydrate-by-difference foods remain loggable.
7. THE Food_Log_Writer SHALL write `log_entries.food_id` as a plain integer snapshot of the Catalog
   id, so an entry stays readable after a catalog upgrade replaces the row it came from.
8. THE Food_Log_Writer SHALL declare `log_entries` as an updated table on every insert, so that the
   timeline stream refreshes without a reload.
9. WHEN the Food_Log_Writer finishes writing the Plate, THE AI_Logging_Mode SHALL discard every Shot
   and every Plate_Item of the Detection_Batch.

### Requirement 11: Survive network and model failures

**User Story:** As someone using an offline-first app on a patchy connection, I want a failed
detection to cost me the shot and nothing else, so that a dead network never loses the plate I
already built.

#### Acceptance Criteria

1. IF a detection request fails to reach OpenRouter, THEN THE camera pane SHALL render the text
   `no connection — detection needs the network` together with a `retry` control.
2. IF a detection request exceeds the 30-second limit, THEN THE camera pane SHALL render the text
   `detection timed out` together with a `retry` control.
3. IF OpenRouter answers a detection request with a non-success HTTP status, THEN THE camera pane
   SHALL render the text `detection failed · <status code>` together with a `retry` control.
4. IF a detection reply fails validation against the response schema, THEN THE Vision_Client SHALL
   resend the request once.
5. IF a detection reply fails validation against the response schema on the resent request, THEN THE
   camera pane SHALL render the text `could not read the detector's answer` together with a `retry`
   control.
6. IF a detection reply carries no Detection whose confidence is at least `0.35`, THEN THE camera
   pane SHALL render the text `no food found in this shot`.
7. IF camera permission is denied, THEN THE camera pane SHALL render the text
   `camera access is off — turn it on in settings` together with a control that opens the platform
   settings screen.
8. WHEN a detection request ends in any failure of criteria 1 through 6, THE AI_Logging_Mode SHALL
   keep every Plate_Item of the Detection_Batch on the Plate with its gram amount and Shot list
   unchanged.
9. WHEN the user taps a `retry` control, THE Vision_Client SHALL resend the detection request for
   the current Detection_Batch using the Shots already captured.
10. WHILE a detection request is in a failed state AND the Plate holds at least one Plate_Item, THE
    confirm control SHALL accept taps.
11. THE AI_Logging_Mode SHALL read and write every Plate_Item and `log_entries` row through the local
    database, so that confirming a Plate completes with no network access.

### Requirement 12: Handle photos as transient data

**User Story:** As someone photographing my own meals, I want the photos used and then dropped, so
that logging a meal does not build a photo archive on my phone or off it.

#### Acceptance Criteria

1. THE AI_Logging_Mode SHALL retain every captured Shot for the life of the Detection_Batch, so a
   later shutter press can resend the whole batch.
2. THE AI_Logging_Mode SHALL confine every captured Shot to process memory, keeping Shots out of the
   application documents directory and out of both SQLite databases.
3. WHEN the Detection_Batch ends by confirmation, by reset, or by leaving the search screen, THE
   AI_Logging_Mode SHALL release every captured Shot held in memory.
4. THE Vision_Client SHALL transmit captured Shots only to the OpenRouter endpoint of Requirement
   2.5 and only while a detection request the user started is in flight.
5. THE Vision_Client SHALL exclude the OpenRouter API key from every log message and every error
   message it produces.

### Requirement 13: Deferred scope

**User Story:** As the owner of this codebase, I want the preparation wheel recorded as a deliberate
deferral rather than an oversight, so that the next person reading the design knows it was skipped
on purpose and why.

#### Acceptance Criteria

1. THE plate row SHALL render without the design's preparation selection wheel, because
   `catalog.foods.prep_type` is 48% populated and carries no per-preparation nutrient variants for
   the wheel to switch between.
2. THE Plate_Item SHALL take the nutrient vector of the catalog row the Catalog_Matcher resolved,
   with no preparation adjustment applied.
3. THE implementation SHALL carry a `// ponytail:` note on the plate row recording the preparation
   wheel as the deferred upgrade path.
4. THE plate row SHALL render without the prototype's per-shot report strip, because no markup in
   the design renders that strip's values.
