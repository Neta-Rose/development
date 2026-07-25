import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../../../core/database/nutrients.dart';
import 'catalog_repository.dart';

part 'food_log_repository.g.dart';

@riverpod
Future<FoodLogRepository> foodLogRepository(Ref ref) async =>
    FoodLogRepository(await ref.watch(appDatabaseProvider.future));

/// `logged_at` is a local wall clock string, `YYYY-MM-DDTHH:MM` — not UTC, and
/// not a timestamp. Days are compared as text against the generated
/// `local_date` column.
String localDate(DateTime d) => d.toIso8601String().substring(0, 10);
String loggedAt(DateTime d) => d.toIso8601String().substring(0, 16);

class FoodLogRepository {
  FoodLogRepository(this._db);

  final AppDatabase _db;

  Stream<List<TimelineForDayResult>> watchDay(DateTime day) =>
      _db.timelineForDay(localDate(day)).watch();

  /// Shaped as [FoodHit] so the search screen renders recents and search hits
  /// with one row type. No join: `log_entries` snapshots the per-100 g vector,
  /// the same convention the catalog columns use.
  Future<List<FoodHit>> recent({int days = 14}) async {
    final rows = await _db
        .recentlyLogged(localDate(DateTime.now().subtract(Duration(days: days))))
        .get();
    return [
      for (final r in rows)
        FoodHit(
          name: r.name,
          isCustom: r.customFoodId != null,
          foodId: r.foodId,
          customFoodId: r.customFoodId,
          emoji: r.emoji,
          kcal100g: r.energyKcal,
          protein100g: r.proteinG,
          fat100g: r.fatG,
          carb100g: r.carbG,
          servingG: r.servingG,
          servingLabel: r.portionLabel,
        ),
    ];
  }

  /// Logs a catalog food, snapshotting its whole nutrient vector so history is
  /// immune to a later catalog upgrade.
  Future<void> logCatalogFood(
    int foodId, {
    required double grams,
    double? portionQty,
    String? portionLabel,
    DateTime? at,
  }) =>
      _insertLog(
          logCatalogFoodSql, Variable(foodId), grams, portionQty, portionLabel, at);

  /// Logs a custom food or a recipe — both are `custom_foods` rows.
  Future<void> logCustomFood(
    String customFoodId, {
    required double grams,
    double? portionQty,
    String? portionLabel,
    DateTime? at,
  }) =>
      _insertLog(logCustomFoodSql, Variable(customFoodId), grams, portionQty,
          portionLabel, at);

  // customInsert, not customStatement: only the former tells drift's stream
  // layer that log_entries changed, so the timeline refreshes without a reload.
  Future<void> _insertLog(String sql, Variable id, double grams, double? qty,
          String? label, DateTime? at) =>
      _db.customInsert(
        sql,
        variables: [
          Variable(loggedAt(at ?? DateTime.now())),
          Variable(grams),
          Variable(qty),
          Variable(label),
          id,
        ],
        updates: {_db.logEntries},
      );

  /// Soft delete — the timeline's partial index excludes tombstones for free,
  /// and a custom food referenced by history can't be hard-deleted anyway.
  Future<void> deleteEntry(String id) =>
      (_db.update(_db.logEntries)..where((t) => t.id.equals(id)))
          .write(const LogEntriesCompanion(deleted: Value(1)));

  /// Editing quantity rewrites `grams` alone — the snapshotted per-100 g
  /// vector is unchanged.
  Future<void> setGrams(String id, double grams) =>
      (_db.update(_db.logEntries)..where((t) => t.id.equals(id)))
          .write(LogEntriesCompanion(grams: Value(grams)));

  /// Saves a custom food. [perServing] holds nutrient columns as the user typed
  /// them on a per-serving form; storage is per 100 g. Returns the new id.
  Future<String> saveCustomFood({
    required String name,
    String? brand,
    String? barcode,
    String? emoji,
    double? servingG,
    String? servingLabel,
    Map<String, double> perServing = const {},
  }) async {
    final divisor = (servingG ?? 100) / 100;
    final cols = perServing.keys.where(nutrientColumns.contains).toList();
    final rows = await _db.customSelect(
      'INSERT INTO custom_foods (name, brand, barcode, emoji, serving_g, '
      'serving_label${cols.map((c) => ', $c').join()}) '
      'VALUES (?, ?, ?, ?, ?, ?${', ?' * cols.length}) RETURNING id',
      variables: [
        Variable(name),
        Variable(brand),
        Variable(barcode),
        Variable(emoji),
        Variable(servingG),
        Variable(servingLabel),
        for (final c in cols) Variable(perServing[c]! / divisor),
      ],
    ).get();
    _db.markTablesUpdated({_db.customFoods});
    return rows.single.read<String>('id');
  }

  /// Writes a recipe's ingredients and steps, re-rolls its nutrient vector from
  /// them, and stamps the parent row.
  ///
  /// One transaction, because renumbering `seq` has to rewrite the
  /// `recipe_step_ingredients` links pointing at it in the same breath — the
  /// composite FKs default to `ON UPDATE NO ACTION` and reject a renumbering
  /// that would leave a link dangling.
  Future<void> saveRecipe(
    String recipeId, {
    required List<({int? foodId, String? customFoodId, double grams})>
        ingredients,
    List<({String text, int? durationS, List<int> ingredientSeqs})> steps =
        const [],
  }) =>
      _db.transaction(() async {
        // The children have no sync columns of their own — they push as part of
        // the parent custom_foods row, so replacing the whole set is the unit.
        for (final t in ['recipe_step_ingredients', 'recipe_steps',
            'recipe_ingredients']) {
          await _db
              .customStatement('DELETE FROM $t WHERE recipe_id = ?', [recipeId]);
        }

        for (var i = 0; i < ingredients.length; i++) {
          final ing = ingredients[i];
          await _db.into(_db.recipeIngredients).insert(
                RecipeIngredientsCompanion.insert(
                  recipeId: recipeId,
                  seq: i + 1,
                  foodId: Value(ing.foodId),
                  customFoodId: Value(ing.customFoodId),
                  grams: ing.grams,
                ),
              );
        }
        for (var s = 0; s < steps.length; s++) {
          final step = steps[s];
          await _db.into(_db.recipeSteps).insert(RecipeStepsCompanion.insert(
                recipeId: recipeId,
                seq: s + 1,
                // SQL column is `text`; the Dart getter is renamed in log.drift
                // to dodge the Table.text() collision.
                stepText: step.text,
                durationS: Value(step.durationS),
              ));
          for (final ingSeq in step.ingredientSeqs) {
            await _db.into(_db.recipeStepIngredients).insert(
                  RecipeStepIngredientsCompanion.insert(
                    recipeId: recipeId,
                    stepSeq: s + 1,
                    ingredientSeq: ingSeq,
                  ),
                );
          }
        }

        await _db.customUpdate(recipeRollupSql,
            variables: [Variable(recipeId), Variable(recipeId)],
            updates: {_db.customFoods});
        // Editing only a step's text changes no nutrition, so nothing above
        // would touch custom_foods and the edit would never sync. Stamp it.
        await _db.customUpdate(
          "UPDATE custom_foods SET updated_at = strftime('%s','now'), "
          'dirty = 1 WHERE id = ?',
          variables: [Variable(recipeId)],
          updates: {_db.customFoods},
        );
      });

  /// Re-rolls every recipe using [customFoodId] as an ingredient, found via
  /// `ix_ingredient_of`. One level only — a nested recipe contributes its own
  /// stored columns, so this never recurses.
  Future<void> reRollParents(String customFoodId) async {
    final parents = await _db.customSelect(
      'SELECT DISTINCT recipe_id FROM recipe_ingredients '
      'WHERE custom_food_id = ?',
      variables: [Variable(customFoodId)],
      readsFrom: {_db.recipeIngredients},
    ).get();
    for (final row in parents) {
      final id = row.read<String>('recipe_id');
      await _db.customUpdate(recipeRollupSql,
          variables: [Variable(id), Variable(id)], updates: {_db.customFoods});
    }
  }
}
