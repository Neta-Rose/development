/// The seam between the coach UI and the suggestion engine.
///
/// Everything above this line is credential-free: swapping [EngineClient] for a
/// proxy-backed one changes this file and nothing else.
library;

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../../home/data/catalog_repository.dart';
import '../domain/candidate.dart';
import '../domain/suggest.dart';
import 'engine_client.dart';

part 'coach_repository.g.dart';

@riverpod
Future<CoachRepository> coachRepository(Ref ref) async =>
    CoachRepository(await ref.watch(appDatabaseProvider.future), EngineClient());

class CoachRepository {
  CoachRepository(this._db, [this._engine]);

  final AppDatabase _db;

  /// Null in tests that only exercise catalog resolution, so a stray call out
  /// to Cloud Run fails loudly instead of silently succeeding.
  final EngineClient? _engine;

  /// Resolves a name against the real catalog, reusing the app's composite
  /// ranking so "white rice" lands on the food a person means rather than on
  /// the best-scoring bm25 document.
  ///
  /// Returns null when nothing matches — the unresolved case, surfaced as-is
  /// rather than replaced with a near miss.
  Future<ResolvedFood?> resolve(String name) async {
    final match = CatalogRepository.prefixQuery(name);
    if (match.isEmpty) return null;

    // Hand-written because it reads `catalog.*`, which drift cannot typecheck.
    final rows = await _db.customSelect(
      'SELECT f.food_id, coalesce(f.display_name, f.description) AS name, '
      'f.category, f.emoji, f.prep_type, f.serving_g, f.serving_label, '
      '${engineNutritionKeys.map((c) => 'n.$c').join(', ')} '
      'FROM food_fts s '
      'JOIN catalog.foods f ON f.food_id = s.rowid '
      'JOIN catalog.food_nutrition n ON n.food_id = f.food_id '
      'WHERE food_fts MATCH ?1 '
      'ORDER BY bm25(food_fts, 10.0, 3.0, 1.0) * (1 '
      '  + 1.0 * coalesce(f.commonness, 0.4) '
      "  + 0.3 * (f.prep_type IS 'cooked') "
      '  + 0.6 * (lower(coalesce(f.display_name, f.description)) = lower(?2))'
      ') LIMIT 1',
      variables: [Variable(match), Variable(name)],
    ).get();
    return rows.isEmpty ? null : _toFood(rows.single);
  }

  ResolvedFood _toFood(QueryRow r) => ResolvedFood(
        foodId: r.read<int>('food_id'),
        name: r.read<String>('name'),
        category: r.readNullable<String>('category'),
        emoji: r.readNullable<String>('emoji'),
        prepType: r.readNullable<String>('prep_type'),
        servingG: r.readNullable<double>('serving_g'),
        servingLabel: r.readNullable<String>('serving_label'),
        nutrition: {
          for (final k in engineNutritionKeys)
            if (r.readNullable<double>(k) != null) k: r.read<double>(k),
        },
      );

  /// Same payload as [resolve], but for a food the user picked by hand, so the
  /// id is already known and no ranking is involved.
  Future<ResolvedFood?> resolveById(int foodId) async {
    final rows = await _db.customSelect(
      'SELECT f.food_id, coalesce(f.display_name, f.description) AS name, '
      'f.category, f.emoji, f.prep_type, f.serving_g, f.serving_label, '
      '${engineNutritionKeys.map((c) => 'n.$c').join(', ')} '
      'FROM catalog.foods f '
      'JOIN catalog.food_nutrition n ON n.food_id = f.food_id '
      'WHERE f.food_id = ?',
      variables: [Variable(foodId)],
    ).get();
    return rows.isEmpty ? null : _toFood(rows.single);
  }

  Future<SuggestResponse> suggest(SuggestRequest request) {
    final engine = _engine;
    if (engine == null) {
      throw StateError('CoachRepository was built without an EngineClient');
    }
    return engine.suggest(request);
  }
}
