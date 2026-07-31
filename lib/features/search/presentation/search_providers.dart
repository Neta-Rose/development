import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../home/data/catalog_repository.dart';
import '../../home/data/food_log_repository.dart';
import '../domain/ai_plate.dart';
import '../domain/portion.dart';

part 'search_providers.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Hits for the current query — or, with the box empty, what was logged
/// recently. Both arrive as [FoodHit], so the list has one row type.
@riverpod
Future<List<FoodHit>> searchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) {
    return (await ref.watch(foodLogRepositoryProvider.future)).recent();
  }

  // Debounced: `search` falls back to the slower trigram index whenever the
  // primary search comes up short, which is every half-typed word. A keystroke
  // disposes this provider, so the abandoned delay returns instead of querying.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 150));
  if (cancelled) return const [];

  return (await ref.watch(catalogRepositoryProvider.future)).search(query);
}

/// The measures a catalog food comes in, for the portion pad's unit chips.
/// Catalog-only: custom foods keep their single serving label.
@riverpod
Future<List<({String label, double gramWeight})>> foodPortions(
        Ref ref, int foodId) async =>
    (await ref.watch(catalogRepositoryProvider.future)).portions(foodId);

/// The detail screen's fibre/sugar/sat-fat/sodium, per 100 g.
///
/// Keyed on the food's identity, which compares by identity rather than by value
/// (ADR-0001). Safe here: one detail screen watches it, holding one hit for its
/// lifetime, so the key is a stable instance — and the provider is auto-dispose,
/// so a later visit re-queries either way.
@riverpod
Future<FoodExtras?> foodExtras(Ref ref, FoodRef food) async =>
    (await ref.watch(catalogRepositoryProvider.future)).extraNutrients(food);

/// One picked amount of one food, staged but not yet logged.
class BatchItem {
  const BatchItem(this.food, this.portion, {this.ai});

  final FoodHit food;
  final Portion portion;

  /// Non-null when this item came from the plate detector. Null is a search hit
  /// or a quick entry.
  ///
  /// It carries the instance id a detection reply merges on, and it is what
  /// routes a generated food through insert-or-reuse on the way out instead of
  /// quick add's one-row-per-entry path.
  final AiOrigin? ai;

  double get kcal => portion.scale(food.kcal100g);
  double get protein => portion.scale(food.protein100g);
  double get carbs => portion.scale(food.carb100g);
  double get fat => portion.scale(food.fat100g);
}

/// Foods staged on this screen. Nothing is written until [Batch.logAll]; the
/// batch is screen-scoped, so leaving throws it away.
@riverpod
class Batch extends _$Batch {
  @override
  List<BatchItem> build() => const [];

  void add(BatchItem item) => state = [...state, item];

  /// By identity, not equality — the same food staged twice is two items.
  void remove(BatchItem item) =>
      state = state.where((e) => !identical(e, item)).toList();

  /// Swaps [item] for [next] where it stands, so re-editing a chip's amount
  /// rewrites that chip instead of staging a second one. Same identity rule.
  void replace(BatchItem item, BatchItem next) =>
      state = [for (final e in state) identical(e, item) ? next : e];

  /// Replaces the whole list in one assignment.
  ///
  /// What a detection reply commits: `mergePlate` decides the entire next state
  /// of the plate — which rows merged, which appeared, which the user had already
  /// corrected — and there is no per-item edit that expresses that. Also why
  /// `mergePlate` returns fresh instances: the rules above work by `identical`.
  void replaceAll(List<BatchItem> items) => state = List.unmodifiable(items);

  void clear() => state = const [];

  /// [hour] pins the entries to that hour of today, top of the hour; null logs
  /// at the current time.
  Future<void> logAll({int? hour}) async {
    final repo = await ref.read(foodLogRepositoryProvider.future);
    final now = DateTime.now();
    final at = hour == null ? null : DateTime(now.year, now.month, now.day, hour);
    for (final item in state) {
      final food = item.food;
      final p = item.portion;
      Future<void> logCustom(String id) => repo.logCustomFood(id,
          grams: p.grams,
          portionQty: p.qty,
          portionLabel: p.portionLabel,
          at: at);

      switch (food.ref) {
        case CatalogRef(:final id):
          await repo.logCatalogFood(id,
              grams: p.grams,
              portionQty: p.qty,
              portionLabel: p.portionLabel,
              // Only where the user had a preparation to choose: the entry is a
              // snapshot, and the catalogue calls every preparation of Onion
              // `Onion`. Null everywhere else keeps the catalogue's own name.
              name: food.prepLabel == null ? null : food.displayName,
              at: at);
        case CustomRef(:final id):
          await logCustom(id);
        case UnsavedRef():
          // Written here rather than when the chip was staged: nothing else on
          // the search screen writes before the check button, and a chip swiped
          // off the strip would otherwise leave an orphan custom_foods row.
          //
          // Which write is a question of where the staged food came from, not of
          // what it is — so it stays keyed on the origin the item carries.
          //
          // ponytail: every quick add writes its own row, so the same off-menu
          // food typed twice is two rows. `recent()` surfaces yesterday's, which
          // is cheaper than retyping — dedupe by name if that stops holding.
          final macros = {
            'energy_kcal': food.kcal100g ?? 0,
            'protein_g': food.protein100g ?? 0,
            'fat_g': food.fat100g ?? 0,
            'carb_g': food.carb100g ?? 0,
          };
          await logCustom(item.ai != null
              // A food the detector supplied whole. The *detector* will name it
              // identically every time it sees it, so this path reuses the row
              // instead of accumulating one per meal.
              ? await repo.findOrCreateCustomFood(
                  name: food.name, emoji: food.emoji, per100g: macros)
              : await repo.saveCustomFood(
                  name: food.name,
                  emoji: food.emoji,
                  // A quick entry is one nominal 100 g serving, so
                  // saveCustomFood's divisor is 1 and the typed numbers land
                  // verbatim as per 100 g.
                  servingG: 100,
                  servingLabel: 'serving',
                  perServing: macros,
                ));
      }
    }
    state = const [];
  }
}
