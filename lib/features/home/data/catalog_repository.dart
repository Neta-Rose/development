import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import 'food_log_repository.dart';

part 'catalog_repository.g.dart';

@riverpod
Future<CatalogRepository> catalogRepository(Ref ref) async =>
    CatalogRepository(await ref.watch(appDatabaseProvider.future));

/// Which food a hit is, and so which table it lives in. Exactly three cases, so
/// the combinations that a boolean plus two nullable ids could express — and
/// that no consumer knows what to do with — cannot be constructed.
///
/// None of the three carries value equality; see
/// `docs/adr/0001-food-ref-carries-no-equality.md` before adding it.
sealed class FoodRef {
  const FoodRef();
}

/// A food from the read-only USDA catalog.
final class CatalogRef extends FoodRef {
  const CatalogRef(this.id);
  final int id;
}

/// A food the user owns — a `custom_foods` row, recipes included.
final class CustomRef extends FoodRef {
  const CustomRef(this.id);
  final String id;
}

/// No row in either table yet. App-only: the log table rejects it, and
/// `Batch.logAll` materialises it on the way out.
final class UnsavedRef extends FoodRef {
  const UnsavedRef();
}

/// One search hit — catalog food, custom food or unsaved food, so the results
/// list has a single row type. [ref] says which; everything else reads the same
/// whichever it is.
class FoodHit {
  const FoodHit({
    required this.name,
    required this.ref,
    this.emoji,
    this.kcal100g,
    this.protein100g,
    this.fat100g,
    this.carb100g,
    this.servingG,
    this.servingLabel,
    this.prepLabel,
    this.preps = const [],
    this.prepIndex = 0,
  });

  final String name;
  final FoodRef ref;
  final String? emoji;
  final double? kcal100g;
  final double? protein100g;
  final double? fat100g;
  final double? carb100g;

  /// Null means "no defined serving — treat it as per 100 g", not "unknown".
  final double? servingG;
  final String? servingLabel;

  /// This hit's own preparation — `raw`, `boiled`, `plain` — set only when the
  /// item has more than one, since that is the only case where naming it says
  /// anything.
  final String? prepLabel;

  /// Every preparation of this item, each a loggable food in its own right, or
  /// empty for the 88% of items that have exactly one. [prepIndex] is where this
  /// hit sits among them: the item's default preparation, and where the wheel
  /// starts.
  ///
  /// The entries carry no [preps] of their own — the row keeps the hit it was
  /// built from and reads the wheel off that.
  final List<FoodHit> preps;
  final int prepIndex;

  /// The food's own serving weight, with the per-100 g fallback applied. The
  /// label goes null with it: without a gram weight there is no unit to name.
  double get unitG => servingG ?? 100;
  String? get unitLabel => servingG == null ? null : servingLabel;

  /// What to show a human: `Onion · boiled` where the item has preparations,
  /// the bare [name] where it does not.
  ///
  /// Separate from [name] on purpose. `display_name` is denormalised *down*
  /// from the item, so every preparation of Onion is literally called `Onion`
  /// — but [name] is also what `bestMatch` scores an AI detection against, and
  /// `Onion · raw` scores materially worse against `onion` than `Onion` does.
  /// Composing into the field itself would quietly push detections under the
  /// similarity threshold and into generated foods.
  String get displayName => prepLabel == null ? name : '$name · $prepLabel';
}

/// The extras the detail screen shows under the four list macros, per 100 g.
typedef FoodExtras = ({
  double? fiber,
  double? sugar,
  double? satFat,
  double? sodium,
});

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

    // Weights are per FTS column: name, prep, aka, members. `members` is the
    // deduplicated token set of every USDA description in the item, so it is
    // the broadest and least precise signal and is weighted lowest.
    var hits = await _catalogSearch(
      'food_fts',
      prefixQuery(term),
      'bm25(food_fts, 10.0, 2.0, 3.0, 1.0)',
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
      //
      // Both passes query the catalog, so every hit on either side is a catalog
      // food. The pattern states that rather than casting to it.
      final seen = {
        for (final h in hits)
          if (h.ref case CatalogRef(:final id)) id,
      };
      hits = [
        ...hits,
        for (final h in fuzzy)
          if (h.ref case CatalogRef(:final id) when !seen.contains(id)) h,
      ];
    }

    return [...await _customSearch(term, since), ...await _withPreps(hits)];
  }

  /// Attaches every hit's preparations, in one query for the whole page.
  ///
  /// A search row is the item's *default* preparation, and raw onion at 40 kcal
  /// and boiled onion at 44 are different foods with different servings — so the
  /// wheel needs them all, and needs them before the row is built rather than
  /// on demand behind a spin.
  ///
  /// Items with one preparation come back with `preps` empty rather than with a
  /// list of one: an empty list is what "no wheel" means to the row, and a
  /// single-entry one would name a preparation the user has no choice about.
  Future<List<FoodHit>> _withPreps(List<FoodHit> hits) async {
    final ids = [
      for (final h in hits)
        if (h.ref case CatalogRef(:final id)) id,
    ];
    if (ids.isEmpty) return hits;

    // `food_id = prep_id` picks the one food that represents each preparation;
    // the other members of that preparation are the same food at another fat
    // level or from another data set.
    final rows = await _db.customSelect(
      'SELECT merged_food_id, food_id, prep_type, kcal_100g, protein_100g, '
      'fat_100g, carb_100g, serving_g, serving_label FROM catalog.foods '
      'WHERE merged_food_id IN (${List.filled(ids.length, '?').join(',')}) '
      'AND food_id = prep_id ORDER BY merged_food_id, food_id',
      variables: [for (final id in ids) Variable(id)],
    ).get();

    final byItem = <int, List<QueryRow>>{};
    for (final r in rows) {
      (byItem[r.read<int>('merged_food_id')] ??= []).add(r);
    }

    return [
      for (final hit in hits)
        if (hit.ref case CatalogRef(:final id))
          if ((byItem[id]?.length ?? 0) > 1)
            _asPreparations(hit, byItem[id]!, id)
          else if (byItem[id]?.length == 1)
            _withSinglePrepLabel(hit, byItem[id]!.single)
          else
            hit
        else
          hit,
    ];
  }

  FoodHit _withSinglePrepLabel(FoodHit hit, QueryRow row) {
    final prep = row.readNullable<String>('prep_type');
    if (prep == null) return hit;
    return FoodHit(
      name: hit.name,
      ref: hit.ref,
      emoji: hit.emoji,
      kcal100g: hit.kcal100g,
      protein100g: hit.protein100g,
      fat100g: hit.fat100g,
      carb100g: hit.carb100g,
      servingG: hit.servingG,
      servingLabel: hit.servingLabel,
      prepLabel: prep,
    );
  }

  /// [hit] rebuilt as its own preparation, carrying [rows] as the rest.
  ///
  /// Name and emoji come from the item, not the row: they are the same for every
  /// preparation, and `prep_type` is what tells them apart. NULL there is the
  /// dry or base form — `Pasta, dry`, `Rice, white, raw` — which the design
  /// calls `plain`.
  FoodHit _asPreparations(FoodHit hit, List<QueryRow> rows, int defaultId) {
    FoodHit at(QueryRow r, {List<FoodHit> preps = const [], int index = 0}) =>
        FoodHit(
          name: hit.name,
          ref: CatalogRef(r.read<int>('food_id')),
          emoji: hit.emoji,
          kcal100g: r.readNullable<double>('kcal_100g'),
          protein100g: r.readNullable<double>('protein_100g'),
          fat100g: r.readNullable<double>('fat_100g'),
          carb100g: r.readNullable<double>('carb_100g'),
          servingG: r.readNullable<double>('serving_g'),
          servingLabel: r.readNullable<String>('serving_label'),
          prepLabel: r.readNullable<String>('prep_type') ?? 'plain',
          preps: preps,
          prepIndex: index,
        );

    final index = rows.indexWhere((r) => r.read<int>('food_id') == defaultId);
    // An item id is by construction one of its own preparations, so this holds
    // — but a hit with no preparation to rest on would spin from the wrong food.
    if (index < 0) return hit;
    return at(rows[index], preps: [for (final r in rows) at(r)], index: index);
  }

  /// The primary FTS pass alone, for resolving a detected food name.
  ///
  /// No trigram append and no custom-food prepend, and both omissions matter:
  ///
  /// * A trigram hit is the lower-confidence answer by construction, so letting
  ///   one be a match candidate would let a misspelling clear the similarity
  ///   threshold on a food the catalog does not actually carry.
  /// * Matching against `custom_foods` would let one model-generated food be
  ///   matched by similarity against an earlier model-generated food, quietly
  ///   compounding one wrong guess into a permanent one.
  ///
  /// The rank expression is [search]'s, unchanged — including the `members`
  /// column weight, so keep the two in sync.
  Future<List<FoodHit>> searchPrimary(String input, {int limit = 10}) async {
    final term = input.trim();
    if (term.isEmpty) return const [];
    final since =
        localDate(DateTime.now().subtract(const Duration(days: recencyDays)));
    return _catalogSearch(
      'food_fts',
      prefixQuery(term),
      'bm25(food_fts, 10.0, 2.0, 3.0, 1.0)',
      term,
      since,
      limit,
    );
  }

  // One row per merged item, not per USDA record: `rowid` in both FTS tables
  // is `merged_food_id`, so "chicken thigh" returns one result instead of the
  // 56 it used to. Both joins always resolve — the FTS tables are contentless
  // with rowid = merged_food_id, and merged_food_id is itself a real food_id
  // (the item's default preparation, which is the row whose macros are shown
  // and the one logged if the user never opens the variant picker). Only the
  // recency join is LEFT: most foods were never logged.
  //
  // That granularity is also what makes the composite score below legal at
  // all. Collapsing per-food hits needed a GROUP BY, and an FTS5 auxiliary
  // function may not be used in an aggregating query — joining is fine, which
  // is why the old flat query worked, but grouping raises "unable to use
  // function bm25 in the requested context" at runtime. With nothing to
  // collapse, bm25() is an ordinary expression again.
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
  //  * `prep_type IS 'cooked'` must use IS, not =. prep_type is NULL on about
  //    half of all items, and `= 'cooked'` yields NULL there, which poisons the
  //    whole product and sorts those rows *first*.
  //
  // The sort must also happen before the LIMIT, which is why it lives in SQL:
  // "Cooked pasta" sits at bm25 ranks 26 and 41-45 of 182, so re-ranking an
  // already-limited pool in Dart would never see it.
  //
  // The recency term joins *through* merged_food_id, so logging a boiled egg
  // boosts the egg item however the user later spells the search — something
  // the per-food query could not express.
  //
  // ponytail: recency is frequency-only, saturating at 3 logs, with no decay
  // inside the window. Add a `last_at` decay term if a stale one-off starts
  // outranking a better match.
  Future<List<FoodHit>> _catalogSearch(String table, String match, String rank,
      String term, String since, int limit) async {
    if (match.isEmpty) return const [];
    final rows = await _db.customSelect(
      'SELECT s.rowid AS food_id, '
      'coalesce(m.display_name, c.description) AS name, m.emoji, '
      'c.kcal_100g, c.protein_100g, c.fat_100g, c.carb_100g, '
      'c.serving_g, c.serving_label, m.n_preps '
      'FROM $table s '
      'JOIN catalog.merged_foods m ON m.merged_food_id = s.rowid '
      'JOIN catalog.foods c ON c.food_id = s.rowid '
      'LEFT JOIN (SELECT cf.merged_food_id AS mid, count(*) AS n '
      '             FROM log_entries l '
      '             JOIN catalog.foods cf ON cf.food_id = l.food_id '
      '            WHERE l.deleted = 0 AND l.food_id IS NOT NULL '
      '              AND l.local_date >= ?1 '
      '            GROUP BY cf.merged_food_id) r ON r.mid = s.rowid '
      'WHERE $table MATCH ?2 '
      'ORDER BY $rank * (1 '
      // How likely this food is in an ordinary kitchen at all.
      '  + 1.0 * coalesce(m.commonness, 0.4) '
      // Commonness measures pantry presence, not what you log: dry pasta
      // scores 1.0 but nobody eats it dry.
      "  + 0.3 * (m.prep_type IS 'cooked') "
      // Recently logged, saturating so a daily staple can't run away with it.
      '  + 1.5 * min(coalesce(r.n, 0), 3) / 3.0 '
      // "rice" should find Rice, not Brown rice sesame cakes.
      '  + 0.6 * (lower(coalesce(m.display_name, c.description)) = lower(?3)) '
      // Institutional and infant variants of an otherwise ordinary food.
      "  - 0.3 * (lower(coalesce(m.display_name, '') || ' ' || c.description) "
      "             LIKE '%restaurant%' "
      "        OR lower(coalesce(m.display_name, '') || ' ' || c.description) "
      "             LIKE '%school lunch%' "
      "        OR lower(coalesce(m.display_name, '') || ' ' || c.description) "
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
          ref: CatalogRef(r.read<int>('food_id')),
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
          ref: CustomRef(r.read<String>('id')),
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

  /// The handful of extra nutrients the detail screen breaks out, from
  /// whichever table the food is stored in — the two carry name-identical
  /// nutrient columns, so only the table and the key differ.
  ///
  /// Null for an unsaved food, which has no row to read, and for the two catalog
  /// foods with no `food_nutrition` row. Callers show nothing.
  Future<FoodExtras?> extraNutrients(FoodRef food) => switch (food) {
        CatalogRef(:final id) => _extras(
            'catalog.food_nutrition', 'food_id', Variable(id), const {}),
        CustomRef(:final id) =>
          _extras('custom_foods', 'id', Variable(id), {_db.customFoods}),
        UnsavedRef() => Future.value(),
      };

  Future<FoodExtras?> _extras(String table, String keyColumn, Variable key,
      Set<ResultSetImplementation> readsFrom) async {
    final rows = await _db.customSelect(
      'SELECT fiber_g, sugar_g, sat_fat_g, sodium_mg '
      'FROM $table WHERE $keyColumn = ?',
      variables: [key],
      readsFrom: readsFrom,
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (
      fiber: r.readNullable<double>('fiber_g'),
      sugar: r.readNullable<double>('sugar_g'),
      satFat: r.readNullable<double>('sat_fat_g'),
      sodium: r.readNullable<double>('sodium_mg'),
    );
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
