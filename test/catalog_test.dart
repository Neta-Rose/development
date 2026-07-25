import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/core/database/database.dart';
import 'package:healthapp/core/database/nutrients.dart';
import 'package:healthapp/features/home/data/catalog_repository.dart';
import 'package:healthapp/features/home/data/food_log_repository.dart';

/// Runs against the real `database/foods.sqlite`, attached to an in-memory log.
/// These are the paths where a silent mistake is most expensive: the 50-column
/// snapshot SQL, the recipe roll-up, and the trigram fallback.
void main() {
  late AppDatabase db;
  late FoodLogRepository log;
  late CatalogRepository catalog;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(),
        catalogPath: 'database/foods.sqlite');
    log = FoodLogRepository(db);
    catalog = CatalogRepository(db);
    // Force the connection open so beforeOpen runs the ATTACH.
    await db.customSelect('SELECT 1').get();
  });
  tearDown(() => db.close());

  test('nutrient column list matches the catalog and the log', () async {
    Future<Set<String>> cols(String sql) async => (await db.customSelect(sql).get())
        .map((r) => r.read<String>('name'))
        .toSet();

    final catalogCols =
        await cols("SELECT name FROM pragma_table_info('food_nutrition')");
    final logCols =
        await cols("SELECT name FROM pragma_table_xinfo('log_entries')");
    final customCols =
        await cols("SELECT name FROM pragma_table_info('custom_foods')");

    // The whole snapshot approach rests on these three sharing every name.
    for (final c in nutrientColumns) {
      expect(catalogCols, contains(c), reason: '$c missing from catalog');
      expect(logCols, contains(c), reason: '$c missing from log_entries');
      expect(customCols, contains(c), reason: '$c missing from custom_foods');
    }
    expect(nutrientColumns, hasLength(50));
  });

  test('logging a catalog food snapshots its whole per-100g vector', () async {
    // Pick a real food that has both a name and nutrition.
    final pick = (await db.customSelect(
      'SELECT f.food_id, coalesce(f.display_name, f.description) AS name, '
      'n.energy_kcal, n.protein_g, n.sodium_mg FROM catalog.foods f '
      'JOIN catalog.food_nutrition n ON n.food_id = f.food_id '
      'WHERE n.energy_kcal > 0 AND n.protein_g > 0 AND n.sodium_mg > 0 '
      'ORDER BY f.food_id LIMIT 1',
    ).get())
        .single;
    final foodId = pick.read<int>('food_id');
    final kcal100 = pick.read<double>('energy_kcal');

    await log.logCatalogFood(foodId,
        grams: 250, portionQty: 2, portionLabel: 'cup');

    final row = (await db.customSelect('SELECT * FROM log_entries').get()).single;

    expect(row.read<int>('food_id'), foodId);
    expect(row.read<String>('name'), pick.read<String>('name'));
    expect(row.read<double>('grams'), 250);
    expect(row.read<String>('portion_label'), 'cup');
    // Stored per 100 g, not scaled to the logged amount.
    expect(row.read<double>('energy_kcal'), closeTo(kcal100, 1e-9));
    expect(row.readNullable<double>('sodium_mg'),
        closeTo(pick.read<double>('sodium_mg'), 1e-9));
    // local_date is a VIRTUAL generated column — absent from table_info but
    // present in SELECT *.
    expect(row.read<String>('local_date'), hasLength(10));

    // The actual amount is always grams / 100 * column.
    final timeline =
        await db.timelineForDay(row.read<String>('local_date')).get();
    expect(timeline.single.kcal, closeTo(250 / 100 * kcal100, 1e-9));
  });

  test('custom food form input is per serving, storage is per 100 g', () async {
    // A 30 g scoop with 24 g protein is 80 g protein per 100 g.
    final id = await log.saveCustomFood(
      name: 'Whey Isolate',
      brand: 'Acme',
      servingG: 30,
      servingLabel: 'scoop',
      perServing: {'energy_kcal': 120, 'protein_g': 24},
    );

    final row = (await db
            .customSelect('SELECT * FROM custom_foods WHERE id = ?',
                variables: [Variable(id)])
            .get())
        .single;
    expect(row.read<double>('protein_g'), closeTo(80, 1e-9));
    expect(row.read<double>('energy_kcal'), closeTo(400, 1e-9));
    expect(row.read<double>('serving_g'), 30);
    expect(row.read<int>('dirty'), 1);

    // Logging one serving multiplies back to what the user typed.
    await log.logCustomFood(id,
        grams: 30, portionQty: 1, portionLabel: 'scoop');
    final logged = await db.timelineForDay(localDate(DateTime.now())).get();
    expect(logged.single.protein, closeTo(24, 1e-9));
    expect(logged.single.kcal, closeTo(120, 1e-9));

    // Custom foods have no FTS index; a LIKE scan covers name and brand.
    final hits = await catalog.search('Whey');
    expect(hits.first.isCustom, isTrue);
    expect(hits.first.customFoodId, id);
  });

  test('recipe roll-up is the grams-weighted mean of its ingredients',
      () async {
    final ings = await db.customSelect(
      'SELECT food_id, energy_kcal, protein_g FROM catalog.food_nutrition '
      'WHERE energy_kcal > 0 AND protein_g > 0 ORDER BY food_id LIMIT 2',
    ).get();

    await db.customStatement(
        "INSERT INTO custom_foods (id, name) VALUES ('r1', 'Test Recipe')");
    await log.saveRecipe('r1', ingredients: [
      (foodId: ings[0].read<int>('food_id'), customFoodId: null, grams: 100.0),
      (foodId: ings[1].read<int>('food_id'), customFoodId: null, grams: 300.0),
    ], steps: [
      (text: 'Mix', durationS: 60, ingredientSeqs: [1, 2]),
    ]);

    final recipe = (await db.customSelect(
            "SELECT * FROM custom_foods WHERE id = 'r1'").get())
        .single;

    final expected = (ings[0].read<double>('energy_kcal') * 100 +
            ings[1].read<double>('energy_kcal') * 300) /
        400;
    expect(recipe.read<double>('energy_kcal'), closeTo(expected, 1e-9));
    // serving_g becomes the batch weight.
    expect(recipe.read<double>('serving_g'), 400);
    // A recipe is a custom_foods row that has steps/ingredients.
    expect(recipe.read<int>('dirty'), 1);

    // Logging the recipe snapshots the rolled-up vector.
    await log.logCustomFood('r1', grams: 400);
    final logged = (await db
            .customSelect("SELECT * FROM log_entries WHERE custom_food_id = 'r1'")
            .get())
        .single;
    expect(logged.read<double>('energy_kcal'), closeTo(expected, 1e-9));
    expect(logged.read<String>('name'), 'Test Recipe');
  });

  test('search finds foods, and survives a typo via the trigram fallback',
      () async {
    final direct = await catalog.search('chicken breast');
    expect(direct, isNotEmpty);
    expect(direct.first.name.toLowerCase(), contains('chicken'));

    expect(CatalogRepository.prefixQuery('chicken bre'), '"chicken"* "bre"*');

    // One transposition breaks every trigram spanning it, so matching the
    // misspelling directly returns nothing — the OR-ed 3-gram split is what
    // turns the index into a shared-trigram scorer and recovers it.
    expect(CatalogRepository.trigramQuery('chikcen'),
        '"chi" OR "hik" OR "ikc" OR "kce" OR "cen"');

    // Ranking is by shared trigrams, so recovery needs enough of them to
    // outweigh coincidental overlap: a bare 7-letter typo is genuinely
    // ambiguous ("cen" alone pulls in concentrate/center), a realistic query
    // is not.
    // Matched on the stem, not the whole word: ranking by commonness surfaces
    // plain "Strawberries" ahead of "Strawberry juice", which is the better
    // answer but does not contain the singular.
    for (final (typo, want) in [
      ('chikcen breast', 'chicken'),
      ('stawberry', 'strawberr'),
      ('yoghurt', 'yogurt'),
    ]) {
      final hits = await catalog.search(typo);
      expect(hits.first.name.toLowerCase(), contains(want),
          reason: '$typo should recover $want');
    }
  });

  test('ranking prefers the common food over the incidental one', () async {
    final hits = await catalog.search('pasta');
    int rankOf(String name) =>
        hits.indexWhere((h) => h.name.toLowerCase().contains(name));

    // bm25 alone put "Spinach pasta" first: every hit scores within 0.2 of
    // every other, so the winner was document-length noise. Commonness is the
    // signal that separates them.
    expect(rankOf('cooked pasta'), isNonNegative);
    expect(rankOf('cooked pasta'), lessThan(rankOf('spinach pasta')));
  });

  test('an exact whole-name match outranks longer names containing it',
      () async {
    // Otherwise "rice" leads with Brown rice sesame cakes.
    final hits = await catalog.search('rice');
    expect(hits.first.name.toLowerCase(), 'rice');
  });

  test('logging a food lifts it up the results for the same query', () async {
    final before = await catalog.search('pasta');
    // The worst-ranked hit, so any movement is unambiguously the recency term
    // and not a tie being broken differently.
    final victim = before.last;
    expect(victim.isCustom, isFalse);

    for (var i = 0; i < 3; i++) {
      await log.logCatalogFood(victim.foodId!, grams: 100);
    }

    final after = await catalog.search('pasta');
    expect(after.indexWhere((h) => h.foodId == victim.foodId),
        lessThan(before.length - 1),
        reason: '${victim.name} was logged 3x and should have moved up');
  });

  test('recents come back as search hits, per 100 g and per one portion',
      () async {
    final pick = (await db.customSelect(
      'SELECT f.food_id, coalesce(f.display_name, f.description) AS name, '
      'n.energy_kcal, n.protein_g FROM catalog.foods f '
      'JOIN catalog.food_nutrition n ON n.food_id = f.food_id '
      'WHERE n.energy_kcal > 0 ORDER BY f.food_id LIMIT 1',
    ).get())
        .single;
    final foodId = pick.read<int>('food_id');

    // Two cups, logged twice — one grouped hit, not two rows.
    await log.logCatalogFood(foodId,
        grams: 316, portionQty: 2, portionLabel: 'cup');
    await log.logCatalogFood(foodId,
        grams: 316, portionQty: 2, portionLabel: 'cup');

    final hit = (await log.recent()).single;
    expect(hit.foodId, foodId);
    expect(hit.isCustom, isFalse);
    expect(hit.name, pick.read<String>('name'));
    // Nutrients stay per 100 g, exactly as the catalog states them.
    expect(hit.kcal100g, closeTo(pick.read<double>('energy_kcal'), 1e-9));
    expect(hit.protein100g, closeTo(pick.read<double>('protein_g'), 1e-9));
    // A portion label is a measure of *one*, so 2 × cup comes back as one cup.
    expect(hit.servingG, closeTo(158, 1e-9));
    expect(hit.servingLabel, 'cup');
  });

  test('portions are bare units and foods without them degrade to empty',
      () async {
    final withPortions = (await db.customSelect(
      'SELECT food_id FROM catalog.food_portions LIMIT 1',
    ).get())
        .single
        .read<int>('food_id');
    expect(await catalog.portions(withPortions), isNotEmpty);

    final without = (await db.customSelect(
      'SELECT f.food_id FROM catalog.foods f WHERE NOT EXISTS '
      '(SELECT 1 FROM catalog.food_portions p WHERE p.food_id = f.food_id) '
      'LIMIT 1',
    ).get())
        .single
        .read<int>('food_id');
    expect(await catalog.portions(without), isEmpty);
  });

  test('negative carb_g foods stay loggable', () async {
    // 10 catalog foods have a legitimately negative carbohydrate-by-difference.
    // Validating logged nutrients as >= 0 would make them unloggable.
    final negative = await db.customSelect(
      'SELECT food_id FROM catalog.food_nutrition WHERE carb_g < 0 LIMIT 1',
    ).get();
    expect(negative, isNotEmpty, reason: 'expected negative carb_g in catalog');

    await log.logCatalogFood(negative.single.read<int>('food_id'), grams: 100);
    final row = (await db.customSelect('SELECT * FROM log_entries').get()).single;
    expect(row.read<double>('carb_g'), lessThan(0));
  });
}
