import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';

part 'catalog_repository.g.dart';

@riverpod
Future<CatalogRepository> catalogRepository(Ref ref) async =>
    CatalogRepository(await ref.watch(appDatabaseProvider.future));

/// One search hit, from either the catalog or the user's own foods.
class FoodHit {
  const FoodHit({
    required this.name,
    required this.isCustom,
    this.foodId,
    this.customFoodId,
    this.emoji,
    this.kcal100g,
    this.protein100g,
    this.servingG,
    this.servingLabel,
  });

  final String name;
  final bool isCustom;
  final int? foodId;
  final String? customFoodId;
  final String? emoji;
  final double? kcal100g;
  final double? protein100g;

  /// Null means "no defined serving — treat it as per 100 g", not "unknown".
  final double? servingG;
  final String? servingLabel;
}

/// Read-only access to the attached USDA catalog. Every query is local; the
/// catalog file is never written to and never referenced by a foreign key.
class CatalogRepository {
  CatalogRepository(this._db);

  final AppDatabase _db;

  /// FTS5 prefix expression: `chicken bre` → `"chicken"* "bre"*`.
  /// Each token is quoted so punctuation can't be read as FTS operator syntax.
  static String prefixQuery(String input) => input
      .split(RegExp(r'\s+'))
      .map((t) => t.replaceAll('"', '').trim())
      .where((t) => t.isNotEmpty)
      .map((t) => '"$t"*')
      .join(' ');

  /// Trigram fallback expression. Matching a misspelling directly against a
  /// trigram index finds *nothing* — one transposition breaks every trigram
  /// spanning it — so the query is split into OR-ed 3-grams, turning the index
  /// into a shared-trigram scorer. `chikcen` then still reaches Chicken.
  static String trigramQuery(String input) {
    final s = input.toLowerCase();
    final grams = <String>{};
    for (var i = 0; i + 3 <= s.length; i++) {
      final g = s.substring(i, i + 3);
      if (g.trim().length == 3) grams.add(g);
    }
    return grams.map((g) => '"$g"').join(' OR ');
  }

  /// Catalog ∪ the user's own foods in one result set. A cross-database VIEW is
  /// illegal in SQLite, so this stays inline.
  ///
  /// Falls back to the trigram index only when the primary search comes up
  /// short, since it is the slower and fuzzier of the two.
  Future<List<FoodHit>> search(String input, {int limit = 30}) async {
    final term = input.trim();
    if (term.isEmpty) return const [];

    var hits = await _catalogSearch(
      'food_fts',
      prefixQuery(term),
      'bm25(food_fts, 10.0, 3.0, 1.0)',
      limit,
    );
    if (hits.length < 5) {
      final fuzzy = await _catalogSearch(
        'food_fts_trgm',
        trigramQuery(term),
        'bm25(food_fts_trgm)',
        limit,
      );
      final seen = hits.map((h) => h.foodId).toSet();
      hits = [...hits, ...fuzzy.where((h) => !seen.contains(h.foodId))];
    }

    return [...await _customSearch(term), ...hits];
  }

  // LEFT JOIN nothing here: food_fts is contentless with rowid = food_id, so
  // the join to foods always resolves.
  Future<List<FoodHit>> _catalogSearch(
      String table, String match, String rank, int limit) async {
    if (match.isEmpty) return const [];
    final rows = await _db.customSelect(
      'SELECT f.food_id, coalesce(f.display_name, f.description) AS name, '
      'f.emoji, f.kcal_100g, f.protein_100g, f.serving_g, f.serving_label '
      'FROM $table s JOIN catalog.foods f ON f.food_id = s.rowid '
      'WHERE $table MATCH ? ORDER BY $rank LIMIT ?',
      variables: [Variable(match), Variable(limit)],
    ).get();
    return [
      for (final r in rows)
        FoodHit(
          isCustom: false,
          foodId: r.read<int>('food_id'),
          name: r.read<String>('name'),
          emoji: r.readNullable<String>('emoji'),
          kcal100g: r.readNullable<double>('kcal_100g'),
          protein100g: r.readNullable<double>('protein_100g'),
          servingG: r.readNullable<double>('serving_g'),
          servingLabel: r.readNullable<String>('serving_label'),
        ),
    ];
  }

  /// Custom foods have no FTS index and need none — a LIKE scan over a few
  /// hundred rows is sub-millisecond.
  Future<List<FoodHit>> _customSearch(String term) async {
    final rows = await _db.customSelect(
      "SELECT id, name, emoji, energy_kcal, protein_g, serving_g, serving_label "
      "FROM custom_foods WHERE deleted = 0 "
      "AND (name || ' ' || coalesce(brand, '')) LIKE '%' || ? || '%' LIMIT 20",
      variables: [Variable(term)],
      readsFrom: {_db.customFoods},
    ).get();
    return [
      for (final r in rows)
        FoodHit(
          isCustom: true,
          customFoodId: r.read<String>('id'),
          name: r.read<String>('name'),
          emoji: r.readNullable<String>('emoji'),
          kcal100g: r.readNullable<double>('energy_kcal'),
          protein100g: r.readNullable<double>('protein_g'),
          servingG: r.readNullable<double>('serving_g'),
          servingLabel: r.readNullable<String>('serving_label'),
        ),
    ];
  }

  /// Portions for a catalog food. Every portion is a measure of *one*, so the
  /// label is a bare unit and the caller renders `qty × label`.
  ///
  /// `seq` is deliberately not returned: it is renumbered on every catalog
  /// rebuild and must never be persisted. Snapshot the label instead.
  Future<List<({String label, double gramWeight})>> portions(int foodId) async {
    final rows = await _db.customSelect(
      'SELECT label, gram_weight FROM catalog.food_portions '
      'WHERE food_id = ? ORDER BY seq',
      variables: [Variable(foodId)],
    ).get();
    return [
      for (final r in rows)
        (label: r.read<String>('label'), gramWeight: r.read<double>('gram_weight'))
    ];
  }

  /// The long tail, for an "all nutrients" expander. Disjoint from the wide
  /// `food_nutrition` columns by construction — a nutrient is one or the other,
  /// never both.
  Future<List<({String name, String unit, double amount})>> allNutrients(
      int foodId) async {
    final rows = await _db.customSelect(
      'SELECT n.name, n.unit, fn.amount FROM catalog.food_nutrients fn '
      'JOIN catalog.nutrients n USING (nutrient_id) '
      'WHERE fn.food_id = ? ORDER BY n.sort_order',
      variables: [Variable(foodId)],
    ).get();
    return [
      for (final r in rows)
        (
          name: r.read<String>('name'),
          unit: r.read<String>('unit'),
          amount: r.read<double>('amount'),
        )
    ];
  }

  /// "What goes with this", PMI-scored from real FNDDS recipes.
  ///
  /// Sparse on purpose: only 1,320 of 13,694 foods have any pairs at all, so
  /// callers must degrade gracefully to showing nothing.
  Future<List<({int foodId, String name, double score})>> pairs(int foodId,
      {int limit = 10}) async {
    final rows = await _db.customSelect(
      'SELECT p.pair_food_id, coalesce(f.display_name, f.description) AS name, '
      'p.score FROM catalog.food_pairs p '
      'JOIN catalog.foods f ON f.food_id = p.pair_food_id '
      'WHERE p.food_id = ? ORDER BY p.score DESC LIMIT ?',
      variables: [Variable(foodId), Variable(limit)],
    ).get();
    return [
      for (final r in rows)
        (
          foodId: r.read<int>('pair_food_id'),
          name: r.read<String>('name'),
          score: r.read<double>('score'),
        )
    ];
  }
}
