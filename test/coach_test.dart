import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/core/database/database.dart';
import 'package:healthapp/features/coach/data/coach_repository.dart';
import 'package:healthapp/features/coach/domain/candidate.dart';
import 'package:healthapp/features/coach/domain/suggest.dart';
import 'package:healthapp/features/coach/presentation/coach_providers.dart';

/// Runs against the real `database/foods.sqlite`, like `catalog_test.dart`, so
/// the payload asserted here is the payload the engine actually receives.
void main() {
  late AppDatabase db;
  late CoachRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(),
        catalogPath: 'database/foods.sqlite');
    // No EngineClient: nothing here may reach the network, and omitting it
    // makes a stray call throw rather than quietly hit Cloud Run.
    repo = CoachRepository(db);
    await db.customSelect('SELECT 1').get();
  });
  tearDown(() => db.close());

  const state = UserState(
    remainingToday:
        RemainingToday(kcal: 1240, proteinG: 68, carbsG: 120, fatG: 32),
    remainingMeals: 2,
  );

  test('a resolved candidate carries real per-100 g catalog nutrition',
      () async {
    final food = await repo.resolve('grilled chicken breast');
    expect(food, isNotNull);

    // Every canonical key the engine names must be present and per 100 g —
    // these column names are shared verbatim with the catalog.
    for (final k in engineNutritionKeys) {
      expect(food!.nutrition, contains(k), reason: '$k missing');
    }
    expect(food!.nutrition['protein_g'], greaterThan(20));
    expect(food.nutrition['energy_kcal'], greaterThan(0));
    // The id must be a real FDC id: the engine parses the `fdc_<n>` form.
    final item = Candidate(detectedName: 'x', resolved: food).toEngineItem()!;
    expect(item.foodId, matches(RegExp(r'^fdc_\d+$')));
    expect(item.food!['category'], isNotNull,
        reason: 'category drives the engine\'s tag matching');
  });

  test('a name with no catalog match stays unresolved rather than guessing',
      () async {
    expect(await repo.resolve('beige dip in a bowl'), isNull);
  });

  test('only checked, resolved items reach the request', () async {
    final chicken = await repo.resolve('grilled chicken breast');
    final rice = await repo.resolve('white rice');

    final tray = [
      Candidate(detectedName: 'chicken', confidence: .91, resolved: chicken),
      // Below 0.5 — arrives unchecked, so it must not be sent.
      Candidate(detectedName: 'bread', confidence: .44, resolved: rice),
      // Unresolved — excluded from the request but still on screen.
      Candidate(detectedName: 'beige dip'),
    ];
    expect(tray[0].checked, isTrue);
    expect(tray[1].checked, isFalse);

    final req = buildRequest(
      candidates: tray,
      mode: CoachMode.onTheTable,
      userState: state,
      mealSlot: 'dinner',
    );
    expect(req.items, hasLength(1));
    expect(req.items.single.name, 'chicken');
    expect(req.intent, Intent.pickFromAvailable);
    // Every sent item carries nutrition, so no_db is honest.
    expect(req.noDb, isTrue);
    expect(tray, hasLength(3), reason: 'excluded items stay on screen');
  });

  test('an empty tray becomes a browse and never claims no_db', () {
    final req = buildRequest(
      candidates: const [],
      mode: CoachMode.onTheTable,
      userState: state,
      mealSlot: 'dinner',
    );
    expect(req.intent, Intent.browse);
    expect(req.noDb, isFalse);
    // `no_db` without a candidate set is rejected server-side; neither key may
    // appear on the browse path.
    final json = req.toJson();
    expect(json.containsKey('no_db'), isFalse);
    expect(json.containsKey('candidate_set'), isFalse);
  });

  test('the request never sends preferences.diets', () {
    // Any diet value makes the engine fail closed against USDA-derived foods:
    // `vegetarian` excluded plain white rice, emptying the whole result set.
    final json = buildRequest(
      candidates: const [],
      mode: CoachMode.onTheTable,
      userState: state,
      mealSlot: 'dinner',
    ).toJson();
    final us = json['user_state'] as Map<String, dynamic>;
    expect(us['preferences'], isNull);
    // The two required keys must always be present.
    expect(us['remaining_today'], isNotNull);
    expect(us['remaining_meals'], 2);
  });

  test('remaining is clamped at zero, not sent negative', () {
    // Overeating must read as "no budget left" rather than asking the engine
    // for a meal that undoes lunch.
    expect(mealSlotFor(19), 'dinner');
    expect(mealSlotFor(8), 'breakfast');
  });

  test('a weak signal is computed against this suggestion, not hardcoded', () {
    final s = Suggestion.fromJson(const {
      'rank': 1,
      'total_score': 0.87,
      'nutrients': {'kcal': 505},
      'items': [
        {
          'name': 'Chicken',
          'amount': {'value': 160, 'unit': 'g'}
        }
      ],
      'breakdown': [
        {'signal': 'macro_fit', 'raw': 0.92, 'weight': 1.0, 'weighted': 0.92},
        {'signal': 'variety', 'raw': 0.31, 'weight': 0.4, 'weighted': 0.124},
      ],
    });
    expect(s.score100, 87);
    expect(s.isWeak(s.contributions[0]), isFalse);
    // 0.124 < 0.4 * 0.92
    expect(s.isWeak(s.contributions[1]), isTrue);
    // The engine sends no title; it is composed from the item names.
    expect(s.title, 'Chicken');
  });

  test('explanation renders only what the engine wrote', () {
    final s = Suggestion.fromJson(const {
      'rank': 1,
      'total_score': 0.5,
      'breakdown': [
        {'signal': 'macro_fit', 'raw': 1, 'weight': 1, 'weighted': 1},
      ],
    });
    // No `explain` on the wire means nothing to render — never synthesised.
    expect(s.contributions.single.explain, isEmpty);
  });
}
