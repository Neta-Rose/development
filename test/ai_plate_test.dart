import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/core/ai/vision_models.dart';
import 'package:healthapp/features/home/data/catalog_repository.dart';
import 'package:healthapp/features/search/domain/ai_plate.dart';
import 'package:healthapp/features/search/domain/food_match.dart';
import 'package:healthapp/features/search/domain/portion.dart';
import 'package:healthapp/features/search/presentation/search_providers.dart';

/// Fixtures ported from the design prototype's four-shot sequence: the chicken
/// thigh is on the plate from shot 1, and the salad, oil, bread and feta arrive
/// as the meal is assembled.
VisionDetection _detection(
  String id,
  String name, {
  double grams = 100,
  double confidence = 0.9,
  List<int> shots = const [1],
  String searchTerm = '',
  String emoji = '🍽️',
  double kcal = 200,
  double protein = 10,
  double carb = 5,
  double fat = 8,
}) =>
    VisionDetection(
      instanceId: id,
      name: name,
      searchTerm: searchTerm.isEmpty ? name : searchTerm,
      grams: grams,
      confidence: confidence,
      shots: shots,
      emoji: emoji,
      kcal100g: kcal,
      protein100g: protein,
      carb100g: carb,
      fat100g: fat,
    );

FoodHit _catalogFood(String name, {int foodId = 1, double? servingG}) => FoodHit(
      name: name,
      isCustom: false,
      foodId: foodId,
      emoji: '🍗',
      kcal100g: 209,
      protein100g: 26,
      fat100g: 11,
      carb100g: 0,
      servingG: servingG,
      servingLabel: servingG == null ? null : 'thigh',
    );

/// Stages a detection the way `AiCapture` does, with no catalog candidates so the
/// generated-food branch is taken.
BatchItem _stage(VisionDetection detection) {
  final candidate = resolveDetection(detection, const [])!;
  return mergePlate(
    batch: const [],
    candidates: [candidate],
    editedIds: const {},
    removedIds: const {},
  ).single;
}

/// A search hit, so the "not touched by a reply" rule has something to prove
/// itself against.
BatchItem get _searchItem => BatchItem(
      const FoodHit(name: 'Banana', isCustom: false, foodId: 99, kcal100g: 89),
      wholeServing(118, 'banana'),
    );

void main() {
  group('batch deduplication', () {
    test('a food in every shot is one row carrying every shot number', () {
      // The scenario the whole feature exists for: four photos of one meal, the
      // chicken thigh visible in all four, one thigh eaten.
      var batch = <BatchItem>[];
      final replies = [
        [_detection('chicken_1', 'Chicken thigh', grams: 140, shots: [1])],
        [
          _detection('chicken_1', 'Chicken thigh', grams: 140, shots: [1, 2]),
          _detection('salad_1', 'Mixed leaf salad', grams: 85, shots: [2]),
        ],
        [
          _detection('chicken_1', 'Chicken thigh', grams: 140, shots: [1, 2, 3]),
          _detection('salad_1', 'Mixed leaf salad', grams: 85, shots: [2, 3]),
          _detection('bread_1', 'Sourdough slice', grams: 50, shots: [3]),
        ],
        [
          _detection('chicken_1', 'Chicken thigh',
              grams: 140, shots: [1, 2, 3, 4]),
          _detection('salad_1', 'Mixed leaf salad', grams: 85, shots: [2, 3, 4]),
          _detection('bread_1', 'Sourdough slice', grams: 50, shots: [3, 4]),
          _detection('feta_1', 'Feta crumble', grams: 30, shots: [4]),
        ],
      ];

      for (final reply in replies) {
        batch = mergePlate(
          batch: batch,
          candidates: [
            for (final d in reply) resolveDetection(d, const [])!,
          ],
          editedIds: const {},
          removedIds: const {},
        );
      }

      expect(batch.length, 4, reason: 'four distinct foods across four shots');

      final ids = batch.map((b) => b.ai!.instanceId).toList();
      expect(ids, ['chicken_1', 'salad_1', 'bread_1', 'feta_1'],
          reason: 'first-seen order, so rows never move under the user');
      expect(ids.toSet().length, ids.length, reason: 'one row per instance id');

      final chicken = batch.first;
      expect(chicken.ai!.shots, [1, 2, 3, 4]);
      expect(chicken.portion.grams, 140,
          reason: 'one thigh, not four thighs stacked up');
      // The badge and sub-line the design writes this state as.
      expect(chicken.ai!.shots.length > 1, isTrue);
    });

    test('re-detecting a staged item rewrites it in place', () {
      final first = _stage(_detection('egg_1', 'Fried egg', grams: 50));

      final merged = mergePlate(
        batch: [first],
        candidates: [
          resolveDetection(
              _detection('egg_1', 'Fried egg', grams: 55, shots: [1, 2]),
              const [])!,
        ],
        editedIds: const {},
        removedIds: const {},
      );

      expect(merged.length, 1);
      expect(merged.single.ai!.shots, [1, 2]);
      expect(merged.single.portion.grams, 55);
    });

    test('two physical items of one food stay two rows', () {
      final merged = mergePlate(
        batch: const [],
        candidates: [
          resolveDetection(_detection('egg_1', 'Fried egg'), const [])!,
          resolveDetection(_detection('egg_2', 'Fried egg'), const [])!,
        ],
        editedIds: const {},
        removedIds: const {},
      );

      expect(merged.length, 2, reason: 'two eggs eaten is two log entries');
    });

    test('merging is idempotent', () {
      final candidates = [
        resolveDetection(_detection('a_1', 'Apple', shots: [1]), const [])!,
        resolveDetection(_detection('b_1', 'Bread', shots: [1]), const [])!,
      ];
      final once = mergePlate(
          batch: const [],
          candidates: candidates,
          editedIds: const {},
          removedIds: const {});
      final twice = mergePlate(
          batch: once,
          candidates: candidates,
          editedIds: const {},
          removedIds: const {});

      expect(twice.length, once.length);
      expect(twice.map((b) => b.ai!.instanceId),
          once.map((b) => b.ai!.instanceId));
      expect(twice.map((b) => b.portion.grams), once.map((b) => b.portion.grams));
    });

    test('an empty reply changes nothing — a failed shot costs only the shot',
        () {
      final batch = [
        _searchItem,
        _stage(_detection('chicken_1', 'Chicken thigh', grams: 140)),
      ];

      final merged = mergePlate(
        batch: batch,
        candidates: const [],
        editedIds: const {},
        removedIds: const {},
      );

      expect(merged, batch, reason: 'identity, item for item');
    });

    test('items the reply does not mention are left alone', () {
      final staged = _stage(_detection('oil_1', 'Olive oil', grams: 10));

      final merged = mergePlate(
        batch: [staged],
        candidates: [
          resolveDetection(_detection('feta_1', 'Feta crumble', shots: [2]),
              const [])!,
        ],
        editedIds: const {},
        removedIds: const {},
      );

      expect(merged.length, 2);
      expect(merged.first, same(staged));
    });

    test('items staged by search or quick add are never touched', () {
      final search = _searchItem;

      final merged = mergePlate(
        batch: [search],
        candidates: [
          // Same food by name, but the detector has no claim on a row the user
          // staged by hand.
          resolveDetection(_detection('banana_1', 'Banana'), const [])!,
        ],
        editedIds: const {},
        removedIds: const {},
      );

      expect(merged.length, 2);
      expect(merged.first, same(search));
      expect(merged.first.ai, isNull);
    });

    test('a gram amount the user set by hand survives every later reply', () {
      final staged = _stage(_detection('rice_1', 'Jasmine rice', grams: 158));
      final corrected = BatchItem(
        staged.food,
        const Portion(grams: 240, label: '240 g'),
        ai: staged.ai,
      );

      final merged = mergePlate(
        batch: [corrected],
        candidates: [
          resolveDetection(
              _detection('rice_1', 'Jasmine rice', grams: 158, shots: [1, 2]),
              const [])!,
        ],
        editedIds: const {'rice_1'},
        removedIds: const {},
      );

      expect(merged.single.portion.grams, 240,
          reason: 'the user has seen the food; the detector has not');
      expect(merged.single.ai!.shots, [1, 2],
          reason: 'the shot list still merges');
    });

    test('an item the user removed does not come back', () {
      final merged = mergePlate(
        batch: const [],
        candidates: [
          resolveDetection(_detection('oil_1', 'Olive oil', shots: [2, 3]),
              const [])!,
        ],
        editedIds: const {},
        removedIds: const {'oil_1'},
      );

      expect(merged, isEmpty);
    });
  });

  group('resolving a detection', () {
    test('a low-confidence or nameless detection is dropped', () {
      expect(resolveDetection(_detection('a', 'Apple', confidence: 0.3), const []),
          isNull);
      expect(resolveDetection(_detection('a', '   '), const []), isNull);
      // Exactly at the floor is admitted.
      expect(
          resolveDetection(
              _detection('a', 'Apple', confidence: confidenceFloor), const []),
          isNotNull);
    });

    test('a close catalog name wins, and brings the catalog row with it', () {
      final candidates = [_catalogFood('Chicken thigh, cooked', foodId: 5)];

      final resolved = resolveDetection(
          _detection('chicken_1', 'Grilled chicken thigh', grams: 140),
          candidates)!;

      expect(resolved.food.foodId, 5);
      expect(resolved.food.isCustom, isFalse,
          reason: 'a catalog row carries the whole 50-nutrient vector');
      expect(resolved.grams, 140);
    });

    test('no close catalog name falls back to the detector\'s own food', () {
      final candidates = [_catalogFood('Sardines, canned in oil', foodId: 7)];

      final resolved = resolveDetection(
        _detection('cake_1', 'Birthday cake', grams: 120, kcal: 380),
        candidates,
      )!;

      expect(resolved.food.isCustom, isTrue);
      expect(resolved.food.foodId, isNull);
      expect(resolved.food.customFoodId, isNull,
          reason: 'no custom_foods row exists yet; logAll writes it');
      expect(resolved.food.name, 'Birthday cake');
      expect(resolved.food.kcal100g, 380);
      expect(resolved.food.servingG, isNull,
          reason: 'null serving reads as per 100 g and logs as bare grams');
    });

    test('a generated food clamps negative macros the CHECKs would reject', () {
      final resolved = resolveDetection(
        _detection('x_1', 'Mystery', kcal: -10, protein: -1, carb: -2, fat: 4),
        const [],
      )!;

      expect(resolved.food.kcal100g, 0);
      expect(resolved.food.protein100g, 0);
      expect(resolved.food.carb100g, 0);
      expect(resolved.food.fat100g, 4);
    });

    test('an implausible weight falls back to the serving, then to 100 g', () {
      // The service sends 0 for "no estimate".
      final matched = resolveDetection(
        _detection('c_1', 'Chicken thigh', grams: 0),
        [_catalogFood('Chicken thigh', servingG: 82)],
      )!;
      expect(matched.grams, 82, reason: "the matched food's own serving");

      final generated =
          resolveDetection(_detection('c_1', 'Mystery', grams: 0), const [])!;
      expect(generated.grams, defaultGrams);

      final absurd = resolveDetection(
          _detection('c_1', 'Mystery', grams: 99999), const [])!;
      expect(absurd.grams, defaultGrams);
    });

    test('an AI item logs as bare grams', () {
      final item = _stage(_detection('a_1', 'Apple', grams: 182));

      expect(item.portion.grams, 182);
      expect(item.portion.qty, isNull);
      expect(item.portion.portionLabel, isNull,
          reason: 'portion_qty and portion_label both stay NULL');
      expect(item.portion.label, '182 g');
    });
  });

  group('name matching', () {
    test('word order and plurals do not matter', () {
      expect(matchScore('Cherry tomatoes', 'Tomatoes, cherry'), 1.0);
      expect(matchScore('Chicken thigh', 'Chicken thighs'), 1.0);
    });

    test('unrelated foods score below the threshold', () {
      expect(matchScore('Chicken thigh', 'Blueberry muffin'),
          lessThan(matchThreshold));
    });

    test('bestMatch picks the highest scorer above the threshold, else nothing',
        () {
      final candidates = [
        _catalogFood('Chicken, broilers or fryers, back, meat only', foodId: 1),
        _catalogFood('Chicken thigh, cooked', foodId: 2),
      ];

      expect(bestMatch('Chicken thigh', candidates)!.foodId, 2);
      expect(bestMatch('Espresso', candidates), isNull);
    });

    test('a tie keeps the order SQL returned', () {
      // The composite rank already knows about commonness, preparation and what
      // this user logs — none of which a name comparison can see.
      final candidates = [
        _catalogFood('Chicken thigh', foodId: 10),
        _catalogFood('Chicken thigh', foodId: 20),
      ];
      expect(bestMatch('Chicken thigh', candidates)!.foodId, 10);
    });

    test('the plate summary describes only AI items', () {
      final batch = [
        _searchItem,
        _stage(_detection('chicken_1', 'Chicken thigh', grams: 140)),
      ];

      final summaries = plateSummaries(batch);

      expect(summaries.length, 1);
      expect(summaries.single.instanceId, 'chicken_1');
      expect(summaries.single.grams, 140);
    });
  });
}
