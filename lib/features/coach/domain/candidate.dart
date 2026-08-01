/// A food the user has in front of them, and the request-building rules that
/// turn a tray of them into one engine call.
library;

import 'suggest.dart';

/// A real catalog row, carrying the per-100 g vector the engine needs.
class ResolvedFood {
  const ResolvedFood({
    required this.foodId,
    required this.name,
    required this.nutrition,
    this.category,
    this.emoji,
    this.prepType,
    this.servingG,
    this.servingLabel,
  });

  final int foodId;
  final String name;

  /// Per-100 g, keyed exactly as the engine names them. The catalog's column
  /// names are already identical, so this is a copy, not a translation.
  final Map<String, double> nutrition;
  final String? category, emoji, prepType, servingLabel;
  final double? servingG;

  Map<String, dynamic> toEnginePayload() => {
        'food_id': foodId,
        'display_name': name,
        // Recommended by the engine: a food with no category is not excluded by
        // category-based constraints even when it should be.
        if (category != null) 'category': category,
        if (emoji != null) 'emoji': emoji,
        if (prepType != null) 'prep_type': prepType,
        if (servingG != null) 'serving_g': servingG,
        if (servingLabel != null) 'serving_label': servingLabel,
        'nutrition': nutrition,
      };
}

/// One item in the capture tray.
///
/// [resolved] being null is the *unresolved* case, deliberately distinct from
/// low confidence: the detector saw something the food library has no match
/// for. It is reported, never replaced with a guess.
class Candidate {
  Candidate({
    required this.detectedName,
    this.confidence,
    this.amountHintG,
    this.resolved,
    bool? checked,
    // Confidence drives the default: below 0.5 arrives unchecked, and an
    // unresolved item can never be sent at all.
  }) : checked = checked ?? (resolved != null && (confidence ?? 1) >= 0.5);

  /// What the detector called it — kept verbatim, and what search pre-fills.
  final String detectedName;
  final double? confidence;
  final double? amountHintG;
  final ResolvedFood? resolved;
  final bool checked;

  bool get isUnresolved => resolved == null;
  String get emoji => resolved?.emoji ?? '🍽️';
  String get displayName => resolved?.name ?? detectedName;

  /// Grams this represents: the detector's hint, else the food's own serving,
  /// else the per-100 g default.
  double get grams => amountHintG ?? resolved?.servingG ?? 100;

  Candidate copyWith({bool? checked, ResolvedFood? resolved}) => Candidate(
        detectedName: detectedName,
        confidence: confidence,
        amountHintG: amountHintG,
        resolved: resolved ?? this.resolved,
        checked: checked ?? this.checked,
      );

  /// The engine payload, or null when unresolved.
  CandidateItem? toEngineItem() {
    final food = resolved;
    if (food == null) return null;
    return CandidateItem(
      name: detectedName,
      foodId: 'fdc_${food.foodId}',
      confidence: confidence,
      amountHintG: amountHintG,
      food: food.toEnginePayload(),
    );
  }
}

/// Which candidate universe the run draws on.
enum CoachMode { onTheTable, cookSomething }

/// The one place request rules live, rather than scattered through the UI.
///
///  1. `pick_from_available` when the mode is "on the table" *and* something is
///     checked; `browse` when the tray is empty — an empty set is a valid
///     request, which is why the CTA is never disabled.
///  2. `no_db` only when *every* sent item carries a usable inline payload.
///     A partial set would come back unsupported rather than scored.
///  3. `no_db` without a candidate set is rejected server-side, so the browse
///     path sends neither.
///  4. Only **checked** items are sent. Unchecked and unresolved items stay on
///     screen but never reach the engine.
SuggestRequest buildRequest({
  required List<Candidate> candidates,
  required CoachMode mode,
  required UserState userState,
  required String mealSlot,
  int nSuggestions = 3,
}) {
  final items = [
    for (final c in candidates)
      if (c.checked && !c.isUnresolved) c.toEngineItem()!,
  ];
  return SuggestRequest(
    intent: switch (mode) {
      CoachMode.cookSomething => Intent.prepare,
      CoachMode.onTheTable when items.isEmpty => Intent.browse,
      CoachMode.onTheTable => Intent.pickFromAvailable,
    },
    mealSlot: mealSlot,
    userState: userState,
    items: items,
    nSuggestions: nSuggestions,
  );
}
