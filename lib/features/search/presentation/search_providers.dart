import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../home/data/catalog_repository.dart';
import '../../home/data/food_log_repository.dart';
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

/// One picked amount of one food, staged but not yet logged.
class BatchItem {
  const BatchItem(this.food, this.portion);

  final FoodHit food;
  final Portion portion;

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
      // A hit out of the database has exactly one of the two ids; a quick entry
      // has neither until the row below is written.
      if (food.isCustom) {
        // Saved here rather than when the chip was staged: nothing else on the
        // search screen writes before the check button, and a chip swiped off
        // the strip would otherwise leave an orphan custom_foods row.
        //
        // ponytail: every quick add writes its own row, so the same off-menu
        // food typed twice is two rows. `recent()` surfaces yesterday's, which
        // is cheaper than retyping — dedupe by name if that stops holding.
        final id = food.customFoodId ??
            await repo.saveCustomFood(
              name: food.name,
              emoji: food.emoji,
              // A quick entry is one nominal 100 g serving, so saveCustomFood's
              // divisor is 1 and the typed numbers land verbatim as per 100 g.
              servingG: 100,
              servingLabel: 'serving',
              perServing: {
                'energy_kcal': food.kcal100g ?? 0,
                'protein_g': food.protein100g ?? 0,
                'fat_g': food.fat100g ?? 0,
                'carb_g': food.carb100g ?? 0,
              },
            );
        await repo.logCustomFood(id,
            grams: p.grams,
            portionQty: p.qty,
            portionLabel: p.portionLabel,
            at: at);
      } else {
        await repo.logCatalogFood(food.foodId!,
            grams: p.grams,
            portionQty: p.qty,
            portionLabel: p.portionLabel,
            at: at);
      }
    }
    state = const [];
  }
}
