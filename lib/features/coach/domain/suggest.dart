/// Request and response models for the food suggestion engine.
///
/// These mirror the *deployed* contract, which differs from the coach spec's
/// draft in several places — the spec was written against an earlier draft:
///
///  * the score array is `breakdown`, not `contributions`, and its key is
///    `signal`, not `signal_id`
///  * `total_score` is 0–1; the UI renders it ×100
///  * an item's amount is `amount: {value, unit}`, not bare grams
///  * there is **no `title` field** — [Suggestion.title] composes one from the
///    item names, which is a label, not explanation copy
///  * `rulebook_version` is a content hash (`sha256:…`), not a `v14`-style tag
library;

/// Per-100 g nutrition, in the engine's spelling. The eight canonical keys are
/// name-identical to columns in `catalog.food_nutrition`, so mapping a catalog
/// row is a straight rename-free copy — see `CandidateItem.fromCatalog`.
const engineNutritionKeys = <String>[
  'energy_kcal',
  'protein_g',
  'carb_g',
  'fat_g',
  'fiber_g',
  'sugar_g',
  'sat_fat_g',
  'sodium_mg',
];

/// What the engine may be asked for. Only [pickFromAvailable] and [browse] are
/// wired; `prepare` has no candidate source on the server yet.
enum Intent {
  pickFromAvailable('pick_from_available'),
  browse('browse'),
  prepare('prepare');

  const Intent(this.wire);
  final String wire;
}

/// The day's remaining budget. **Required by the engine** — it keeps no
/// consumption log of its own, so without this it cannot compute a meal target.
///
/// Every field here is real: computed from `log_entries` against the app's
/// macro targets. Zero is meaningful and must be sent rather than omitted —
/// "no budget left" is not the same as "field missing".
class RemainingToday {
  const RemainingToday({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
      };
}

/// Everything the engine knows about the user for one call. The engine is
/// stateless — it never looks anything up by `user_id`.
class UserState {
  const UserState({
    required this.remainingToday,
    required this.remainingMeals,
    this.allergies = const [],
  });

  final RemainingToday remainingToday;

  /// Required alongside [remainingToday]: a remaining macro budget is
  /// meaningless without knowing how many meals it still has to cover.
  final int remainingMeals;

  /// Sent when non-empty. Verified safe against catalog foods — an unrelated
  /// allergy does not exclude them.
  ///
  /// `preferences.diets` is deliberately **never sent**. The engine's diet
  /// matching needs certification tags that USDA data does not carry, so it
  /// fails closed: `diets: ['vegetarian']` excluded plain white rice, and any
  /// diet value empties the whole result set. Re-enable only once catalog
  /// foods carry diet tags.
  final List<String> allergies;

  Map<String, dynamic> toJson() => {
        'remaining_today': remainingToday.toJson(),
        'remaining_meals': remainingMeals,
        if (allergies.isNotEmpty) 'preferences': {'allergies': allergies},
      };
}

/// A hard filter. Shape is `field`/`op`/`value` — an unrecognised `op` **fails
/// closed**, silently excluding everything it is tested against, so [name] is
/// left off while debugging: without it the exclusion reason renders as the
/// literal field+op+value and a typo is immediately visible.
class Filter {
  const Filter({required this.field, required this.op, required this.value, this.name});

  final String field;
  final String op;
  final Object value;
  final String? name;

  Map<String, dynamic> toJson() => {
        'field': field,
        'op': op,
        'value': value,
        if (name != null) 'name': name,
      };
}

/// One food offered to the engine, carrying its own nutrition so the engine
/// looks nothing up (`no_db`).
class CandidateItem {
  const CandidateItem({
    required this.name,
    this.foodId,
    this.confidence,
    this.amountHintG,
    this.food,
  });

  final String name;

  /// `fdc_<n>` when it came from the USDA catalog; the engine parses that form.
  final String? foodId;

  /// 0–1 from detection. Compounds with the food's own confidence, and shows up
  /// in the response as the `nutrition_confidence` signal.
  final double? confidence;
  final double? amountHintG;

  /// The inline payload. Required whenever `no_db` is true; an item without it
  /// comes back in `excluded_summary` as unsupported rather than erroring.
  final Map<String, dynamic>? food;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (foodId != null) 'food_id': foodId,
        if (confidence != null) 'confidence': confidence,
        if (amountHintG != null) 'amount_hint_g': amountHintG,
        if (food != null) 'food': food,
      };
}

class SuggestRequest {
  const SuggestRequest({
    required this.intent,
    required this.mealSlot,
    required this.userState,
    this.items = const [],
    this.constraints = const [],
    this.nSuggestions = 3,
    this.explainLevel = 'full',
  });

  final Intent intent;
  final String mealSlot;
  final UserState userState;
  final List<CandidateItem> items;
  final List<Filter> constraints;
  final int nSuggestions;
  final String explainLevel;

  /// True only when every item carries a usable inline payload. A partial set
  /// must not claim `no_db` — those items would come back unsupported.
  bool get noDb =>
      items.isNotEmpty &&
      items.every((i) =>
          i.food != null &&
          (i.food!['nutrition'] as Map?)?.isNotEmpty == true);

  Map<String, dynamic> toJson() => {
        'intent': intent.wire,
        'meal_slot': mealSlot,
        'explain_level': explainLevel,
        'n_suggestions': nSuggestions,
        'user_state': userState.toJson(),
        // `no_db` without a candidate set is rejected server-side; guarding
        // here keeps the browse path from ever sending it.
        if (items.isNotEmpty) ...{
          'no_db': noDb,
          'candidate_set': {
            'source': 'photo_extraction',
            'items': [for (final i in items) i.toJson()],
          },
        },
        if (constraints.isNotEmpty)
          'constraints': [for (final c in constraints) c.toJson()],
      };
}

// ---------------------------------------------------------------- response

class Nutrients {
  const Nutrients({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory Nutrients.fromJson(Map<String, dynamic> j) => Nutrients(
        kcal: (j['kcal'] as num?)?.toDouble() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
      );

  final double kcal, proteinG, carbsG, fatG;
}

class SuggestionItem {
  const SuggestionItem({required this.name, required this.grams});

  factory SuggestionItem.fromJson(Map<String, dynamic> j) => SuggestionItem(
        name: j['name'] as String? ?? '',
        grams: ((j['amount'] as Map?)?['value'] as num?)?.toDouble() ?? 0,
      );

  final String name;
  final double grams;
}

/// One scoring signal's contribution.
class Contribution {
  const Contribution({
    required this.signal,
    required this.raw,
    required this.weight,
    required this.weighted,
    required this.explain,
  });

  factory Contribution.fromJson(Map<String, dynamic> j) => Contribution(
        signal: j['signal'] as String? ?? '',
        raw: (j['raw'] as num?)?.toDouble() ?? 0,
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        weighted: (j['weighted'] as num?)?.toDouble() ?? 0,
        explain: j['explain'] as String? ?? '',
      );

  final String signal;
  final double raw, weight, weighted;

  /// One sentence, straight from the engine. The UI never writes this.
  final String explain;

  /// `rulebook:micro` reads as `MICRO` in the signal column.
  String get label =>
      (signal.contains(':') ? signal.split(':').last : signal).toUpperCase();
}

class Suggestion {
  const Suggestion({
    required this.rank,
    required this.score,
    required this.nutrients,
    required this.items,
    required this.contributions,
  });

  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        // 0–1 on the wire; the UI shows an integer 0–100.
        score: (j['total_score'] as num?)?.toDouble() ?? 0,
        nutrients:
            Nutrients.fromJson((j['nutrients'] as Map?)?.cast<String, dynamic>() ?? {}),
        items: [
          for (final i in (j['items'] as List? ?? []))
            SuggestionItem.fromJson((i as Map).cast<String, dynamic>())
        ],
        contributions: [
          for (final b in (j['breakdown'] as List? ?? []))
            Contribution.fromJson((b as Map).cast<String, dynamic>())
        ],
      );

  final int rank;
  final double score;
  final Nutrients nutrients;
  final List<SuggestionItem> items;
  final List<Contribution> contributions;

  int get score100 => (score * 100).round();

  /// The engine sends no title. Joining the item names is a label, not
  /// explanation copy — the `explain` sentences remain the engine's alone.
  String get title => items.isEmpty
      ? 'Plate'
      : items.map((i) => i.name).join(', ').replaceAllMapped(
          RegExp(r'^(.*),\s([^,]+)$'), (m) => '${m[1]} and ${m[2]}');

  /// A signal is "weak" relative to the strongest contribution in *this*
  /// suggestion — computed, never hardcoded per signal.
  bool isWeak(Contribution c) {
    final max = contributions.fold<double>(0, (a, b) => b.weighted > a ? b.weighted : a);
    return max <= 0 || c.weighted < 0.4 * max;
  }
}

/// One aggregated exclusion. Counts are per request, not per suggestion.
class Excluded {
  const Excluded({required this.reason, required this.count});

  factory Excluded.fromJson(Map<String, dynamic> j) => Excluded(
        reason: j['reason'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );

  final String reason;
  final int count;
}

class SuggestResponse {
  const SuggestResponse({
    required this.suggestions,
    required this.excluded,
    required this.degraded,
    required this.degradedReason,
    required this.rulebookVersion,
    required this.contextSnapshotId,
    required this.totalMs,
  });

  factory SuggestResponse.fromJson(Map<String, dynamic> j) => SuggestResponse(
        suggestions: [
          for (final s in (j['suggestions'] as List? ?? []))
            Suggestion.fromJson((s as Map).cast<String, dynamic>())
        ],
        excluded: [
          for (final e in (j['excluded_summary'] as List? ?? []))
            Excluded.fromJson((e as Map).cast<String, dynamic>())
        ],
        degraded: j['degraded'] as bool? ?? false,
        // Comes back null rather than "" when not degraded.
        degradedReason: j['degraded_reason'] as String? ?? '',
        rulebookVersion: j['rulebook_version'] as String? ?? '',
        contextSnapshotId: j['context_snapshot_id'] as String? ?? '',
        totalMs: ((j['timing_ms'] as Map?)?['total'] as num?)?.toInt() ?? 0,
      );

  final List<Suggestion> suggestions;
  final List<Excluded> excluded;
  final bool degraded;
  final String degradedReason;
  final String rulebookVersion, contextSnapshotId;
  final int totalMs;

  /// `sha256:b80998999570` is too long for the footer; the tail is the part
  /// that actually distinguishes one rulebook from another.
  String get shortRulebook {
    final v = rulebookVersion.replaceFirst('sha256:', '');
    return v.length > 8 ? 'rulebook ${v.substring(0, 8)}' : 'rulebook $v';
  }
}
