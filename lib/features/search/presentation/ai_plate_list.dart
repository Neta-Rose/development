import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../domain/ai_plate.dart';
import '../domain/portion.dart';
import 'ai_providers.dart';
import 'search_providers.dart';
import 'swipe_row.dart';

Color _dim(double a) => AppColors.dim(a);

/// What the detector found, and what the user does about it.
///
/// Every row is correctable before anything is written: drag right for a
/// different weight, drag left to drop it. Both corrections are also recorded
/// against the instance id, so the next shot's reply does not undo them.
class AiPlateList extends ConsumerWidget {
  const AiPlateList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(batchProvider);
    final session = ref.watch(aiCaptureProvider);
    final plate = [
      for (final item in batch)
        if (item.ai != null) item,
    ];

    if (plate.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Text(
          'nothing on the plate yet — tap the shutter after each thing you add. '
          'shoot as many times as you like; repeats are merged, not doubled.',
          style: TextStyle(fontSize: 11, height: 1.6, color: _dim(.35)),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: plate.length,
      itemBuilder: (context, i) => _PlateRow(
        item: plate[i],
        newestShot: session.shots.length,
      ),
    );
  }
}

/// One detected food.
///
// ponytail: the design puts a preparation wheel on the right of this row too,
// switching the nutrient vector with it. The catalog can feed one now — the
// search row's wheel does exactly that — so what is left out is scope, not
// capability. The upgrade path is to give a detected food the `preps` its
// matched hit already carries and reuse `_PrepWheel`; add it when correcting a
// detection's preparation is worth more than correcting its weight, which is
// the one this row offers today.
class _PlateRow extends ConsumerWidget {
  const _PlateRow({required this.item, required this.newestShot});

  final BatchItem item;

  /// Highest shot number in the batch, which decides what counts as `new`.
  final int newestShot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = item.ai!;
    final food = item.food;
    final grams = item.portion.grams;
    // First seen in the newest shot: the design tints the row and badges it.
    final fresh = origin.shots.length == 1 && origin.shots.first == newestShot;
    final merged = origin.shots.length > 1;

    return SwipeRow(
      // The ladder is built off what the item currently weighs, so a correction
      // starts from where the detector left it rather than from a nominal 100 g.
      unitG: grams > 0 ? grams : defaultGrams,
      kcal100g: food.kcal100g ?? 0,
      onPicked: (picked) {
        ref.read(batchProvider.notifier).replace(
              item,
              BatchItem(
                food,
                Portion(
                    grams: picked.grams, label: '${picked.grams.round()} g'),
                ai: origin,
              ),
            );
        ref.read(aiCaptureProvider.notifier).markEdited(origin.instanceId);
      },
      onRemove: () {
        ref.read(batchProvider.notifier).remove(item);
        ref.read(aiCaptureProvider.notifier).markRemoved(origin.instanceId);
      },
      rowColor: fresh ? AppColors.amber.withValues(alpha: .05) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(food.emoji ?? '🍽️',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.fg)),
                      ),
                      if (merged || fresh) const SizedBox(width: 6),
                      if (merged)
                        _badge('↺ ${origin.shots.length}', AppColors.merged)
                      else if (fresh)
                        _badge('new', AppColors.amber),
                    ],
                  ),
                  const SizedBox(height: 3),
                  macroLine(item.kcal, item.protein, item.carbs, item.fat),
                  const SizedBox(height: 2),
                  Text(
                    _subLine(grams, origin.shots),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: _dim(.35)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `140 g`, or `140 g · shots 1·2·3, counted once` for an item the detector saw
  /// more than once. The second form is the whole feature saying so out loud.
  String _subLine(double grams, List<int> shots) {
    final amount = '${grams.round()} g';
    if (shots.length < 2) return amount;
    return '$amount · shots ${shots.join('·')}, counted once';
  }

  Widget _badge(String label, Color color) => Container(
        height: 15,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .42)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 8.5, color: color)),
      );
}
