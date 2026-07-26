import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import 'food_log_repository.dart';

part 'catalog_repository.g.dart';

@riverpod
Future<CatalogRepository> catalogRepository(Ref ref) async =>
    CatalogRepository(await ref.watch(appDatabaseProvider.future));

/// One search hit, from either the catalog or the user's own foods.
///
/// A hit read out of the database has exactly one of [foodId]/[customFoodId],
/// mirroring the `log_entries` CHECK. A quick entry typed on the search screen
/// is the third case: `isCustom` with **neither** id, meaning "no `custom_foods`
/// row yet". `Batch.logAll` creates the row on its way out.
class FoodHit {
  const FoodHit({
    required this.name,
    required this.isCustom,
    this.foodId,
    this.customFoodId,
    this.emoji,
    this.kcal100g,
    this.protein100g,
    this.fat100g,
    this.carb100g,
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
  final double? fat100g;
  final double? carb100g;

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

  /// How far back a log entry still counts as "recently logged" for ranking.
  /// Wider than [FoodLogRepository.recent]'s 14 days: a food eaten every few
  /// weeks should still be boosted, even if it is off the recents list.
  static const recencyDays = 90;

  /// Catalog ∪ the user's own foods in one result set. A cross-database VIEW is
  /// illegal in SQLite, so this stays inline.
  ///
  /// Falls back to the trigram index only when the primary search comes up
  /// short, since it is the slower and fuzzier of the two.
  Future<List<FoodHit>> search(String input, {int limit = 30}) async {
    final term = input.trim();
    if (term.isEmpty) return const [];

    final since =
        localDate(DateTime.now().subtract(const Duration(days: recencyDays)));

    var hits = await _catalogSearch(
      'food_fts',
      prefixQuery(term),
      'bm25(food_fts, 10.0, 3.0, 1.0)',
      term,
      since,
      limit,
    );
    if (hits.length < 5) {
      final fuzzy = await _catalogSearch(
        'food_fts_trgm',
        trigramQuery(term),
        'bm25(food_fts_trgm)',
        term,
        since,
        limit,
      );
      // Appended, never interleaved: the two passes score against different
      // indexes, so their bm25 magnitudes are not comparable. A trigram hit is
      // strictly the lower-confidence answer, so it belongs after every exact
      // one regardless of score.
      final seen = hits.map((h) => h.foodId).toSet();
      hits = [...hits, ...fuzzy.where((h) => !seen.contains(h.foodId))];
    }

    return [...await _customSearch(term, since), ...hits];
  }

  // The join to catalog.foods always resolves: food_fts is contentless with
  // rowid = food_id. Only the recency join is LEFT — most foods were never
  // logged.
  //
  // Ranking is a composite score, not raw bm25. For a one-word query bm25
  // barely discriminates (every "pasta" hit scores between -8.95 and -8.78),
  // so the winner would otherwise be document-length noise.
  //
  // Three things make this expression work, and each is easy to break:
  //
  //  * bm25 is always *negative* in FTS5, so a bigger multiplier is a smaller
  //    number and `ORDER BY score` stays ascending, best-first. The multiplier
  //    floor is 1 + 1.0*0.05 - 0.3 = 0.75, so it can never reach zero and
  //    invert the ordering.
  //  * It is multiplicative, not additive, because the bm25 spread depends on
  //    the query ("chicken" spans 0.37, "chicken brea" spans 2.35). Scaling by
  //    bm25 magnitude keeps one set of weights honest across both.
  //  * `prep_type IS 'cooked'` must use IS, not =. prep_type is 52% NULL, and
  //    `= 'cooked'` yields NULL there, which poisons the whole product and
  //    sorts those rows *first*.
  //
  // The sort must also happen before the LIMIT, which is why it lives in SQL:
  // "Cooked pasta" sits at bm25 ranks 26 and 41-45 of 182, so re-ranking an
  // already-limited pool in Dart would never see it.
  //
  // ponytail: recency is frequency-only, saturating at 3 logs, with no decay
  // inside the window. Add a `last_at` decay term if a stale one-off starts
  // outranking a better match.
  Future<List<FoodHit>> _catalogSearch(String table, String match, String rank,
      String term, String since, int limit) async {
    if (match.isEmpty) return const [];
    final rows = await _db.customSelect(
      'SELECT f.food_id, coalesce(f.display_name, f.description) AS name, '
      'f.emoji, f.kcal_100g, f.protein_100g, f.fat_100g, f.carb_100g, '
      'f.serving_g, f.serving_label '
      'FROM $table s '
      'JOIN catalog.foods f ON f.food_id = s.rowid '
      'LEFT JOIN (SELECT food_id, count(*) AS n FROM log_entries '
      '            WHERE deleted = 0 AND food_id IS NOT NULL '
      '              AND local_date >= ?1 '
      '            GROUP BY food_id) r ON r.food_id = f.food_id '
      'WHERE $table MATCH ?2 '
      'ORDER BY $rank * (1 '
      // How likely this food is in an ordinary kitchen at all.
      '  + 1.0 * coalesce(f.commonness, 0.4) '
      // Commonness measures pantry presence, not what you log: dry pasta
      // scores 1.0 but nobody eats it dry.
      "  + 0.3 * (f.prep_type IS 'cooked') "
      // Recently logged, saturating so a daily staple can't run away with it.
      '  + 1.5 * min(coalesce(r.n, 0), 3) / 3.0 '
      // "rice" should find Rice, not Brown rice sesame cakes.
      '  + 0.6 * (lower(coalesce(f.display_name, f.description)) = lower(?3)) '
      // Institutional and infant variants of an otherwise ordinary food.
      "  - 0.3 * (lower(coalesce(f.display_name, '') || ' ' || f.description) "
      "             LIKE '%restaurant%' "
      "        OR lower(coalesce(f.display_name, '') || ' ' || f.description) "
      "             LIKE '%school lunch%' "
      "        OR lower(coalesce(f.display_name, '') || ' ' || f.description) "
      "             LIKE '%baby food%') "
      ') LIMIT ?4',
      // Numbered, not bare `?`: bare placeholders bind in order of appearance
      // in the SQL text, which here is since/match/term/limit — not the order
      // the signature reads in. Numbering makes a reorder harmless.
      variables: [
        Variable(since),
        Variable(match),
        Variable(term),
        Variable(limit),
      ],
      readsFrom: {_db.logEntries},
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
          fat100g: r.readNullable<double>('fat_100g'),
          carb100g: r.readNullable<double>('carb_100g'),
          servingG: r.readNullable<double>('serving_g'),
          servingLabel: r.readNullable<String>('serving_label'),
        ),
    ];
  }

  /// Custom foods have no FTS index and need none — a LIKE scan over a few
  /// hundred rows is sub-millisecond. With no bm25 to rank by, "most logged,
  /// then most recent" is the only relevance signal available, and it is the
  /// right one for a food you typed in yourself.
  Future<List<FoodHit>> _customSearch(String term, String since) async {
    final rows = await _db.customSelect(
      "SELECT c.id, c.name, c.emoji, c.energy_kcal, c.protein_g, c.fat_g, "
      "c.carb_g, c.serving_g, c.serving_label "
      "FROM custom_foods c "
      "LEFT JOIN (SELECT custom_food_id, count(*) AS n, "
      "                  max(logged_at) AS last_at FROM log_entries "
      "            WHERE deleted = 0 AND custom_food_id IS NOT NULL "
      "              AND local_date >= ?1 "
      "            GROUP BY custom_food_id) r ON r.custom_food_id = c.id "
      "WHERE c.deleted = 0 "
      "AND (c.name || ' ' || coalesce(c.brand, '')) LIKE '%' || ?2 || '%' "
      "ORDER BY coalesce(r.n, 0) DESC, r.last_at DESC, c.name LIMIT 20",
      variables: [Variable(since), Variable(term)],
      readsFrom: {_db.customFoods, _db.logEntries},
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
          fat100g: r.readNullable<double>('fat_g'),
          carb100g: r.readNullable<double>('carb_g'),
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
