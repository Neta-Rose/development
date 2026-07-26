import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../home/data/catalog_repository.dart';
import '../../home/domain/daily_summary.dart';
import '../domain/portion.dart';
import 'portion_pad.dart';
import 'search_providers.dart';

Color _dim(double a) => AppColors.dim(a);

/// One food at one amount — its macros, what it does to the day's targets, and
/// where its calories come from — over the portion pad, so the amount is
/// editable without leaving.
///
/// Reached by tapping a search result or a staged chip. [editing] is that chip:
/// the pad opens on its amount and adding rewrites it in place instead of
/// staging a second copy of the same food.
class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({
    super.key,
    required this.food,
    this.editing,
    this.hour,
  });

  final FoodHit food;
  final BatchItem? editing;

  /// Hour of today the pad's `log all` commits into, carried through from the
  /// search screen. Null logs at now.
  final int? hour;

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  /// Mirrors the pad, so every number above it reacts as the amount is typed.
  late Portion _portion = widget.editing?.portion ??
      wholeServing(widget.food.unitG, widget.food.unitLabel);

  /// Only a real change, or the pad's report would rebuild the pad, which
  /// reports again.
  void _sync(Portion p) {
    if (p.grams == _portion.grams && p.label == _portion.label) return;
    setState(() => _portion = p);
  }

  void _stage(Portion p) {
    final batch = ref.read(batchProvider.notifier);
    final editing = widget.editing;
    final next = BatchItem(widget.food, p);
    if (editing == null) {
      batch.add(next);
    } else {
      batch.replace(editing, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    // Captured while the route is certainly current: `log all` runs after the
    // pad's `onAdd` has already popped this screen.
    final nav = Navigator.of(context);
    final extras = ref
        .watch(foodExtrasProvider(
            foodId: food.foodId, customId: food.customFoodId))
        .value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _header(food),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _hero(food),
                if (widget.editing != null) _remove(),
                _targets(food),
                _energy(food),
                _nutrients(food, extras),
                const SizedBox(height: 14),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: PortionPad(
              food: food,
              initial: _portion,
              onChanged: _sync,
              onAdd: (p) {
                _stage(p);
                nav.pop();
              },
              onClose: nav.pop,
              onLogAll: () async {
                await ref.read(batchProvider.notifier).logAll(hour: widget.hour);
                // Back past the search screen too — the batch is gone.
                nav.popUntil((r) => r.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(FoodHit food) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 60, 14, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: AppColors.badgeBg, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 13, color: AppColors.fg),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(food.emoji ?? '🍽️',
                    style: const TextStyle(fontSize: 17, height: 1)),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 15.5, color: AppColors.fg)),
                ),
              ],
            ),
          ),
          // Balances the back button, so the name stays optically centred.
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  /// Calories big, then each macro's share of them, its grams, and its name.
  Widget _hero(FoodHit food) {
    final p = _portion.scale(food.protein100g);
    final c = _portion.scale(food.carb100g);
    final f = _portion.scale(food.fat100g);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_portion.scale(food.kcal100g).round()}',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -2,
                    height: 0.9,
                    color: AppColors.fg,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                _caption('CALORIES'),
              ],
            ),
          ),
          for (final m in [
            ('PROTEIN', p, AppColors.protein),
            ('FAT', f, AppColors.fat),
            ('CARBS', c, AppColors.carbs),
          ]) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 10,
              child: _macro(m.$1, m.$2, m.$3, _share(m.$1, p, c, f)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _macro(String label, double grams, Color color, int share) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(9)),
          alignment: Alignment.center,
          child: Text('$share%',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.bg,
                fontFeatures: [FontFeature.tabularFigures()],
              )),
        ),
        const SizedBox(height: 9),
        Text(
          grams.toStringAsFixed(1),
          maxLines: 1,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            height: 0.9,
            color: AppColors.fg,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        _caption(label),
      ],
    );
  }

  /// The design's Edit / Duplicate / Delete row, cut to the one action that
  /// isn't already reachable: editing is this screen, and duplicating is
  /// tapping the row again.
  Widget _remove() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: GestureDetector(
        onTap: () {
          ref.read(batchProvider.notifier).remove(widget.editing!);
          Navigator.of(context).pop();
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.tile,
            border: Border.all(color: _dim(.09)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline,
                  size: 15, color: AppColors.protein),
              const SizedBox(width: 7),
              Text('remove from batch',
                  style: TextStyle(fontSize: 10.5, color: _dim(.55))),
            ],
          ),
        ),
      ),
    );
  }

  /// This one amount against the day's whole target — the answer to "can I
  /// afford it", which is why the screen exists at all.
  //
  // ponytail: the targets are the hardcoded MacroTargets.defaults, and they are
  // the *day's*, not what's left of it. Subtract the day's totals once the
  // detail screen is reachable from the timeline.
  Widget _targets(FoodHit food) {
    const goals = MacroTargets.defaults;
    final rings = [
      (
        'CALORIES',
        _portion.scale(food.kcal100g),
        goals.kcal,
        '',
        AppColors.amber
      ),
      (
        'PROTEIN',
        _portion.scale(food.protein100g),
        goals.protein,
        'g',
        AppColors.protein
      ),
      ('FAT', _portion.scale(food.fat100g), goals.fat, 'g', AppColors.fat),
      (
        'CARBS',
        _portion.scale(food.carb100g),
        goals.carbs,
        'g',
        AppColors.carbs
      ),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: _dim(.08)))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _caption('IMPACT ON TARGETS', spacing: 1.5),
              Text('daily goals',
                  style: TextStyle(fontSize: 9, color: _dim(.28))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
          child: Row(
            children: [
              for (var i = 0; i < rings.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ring(rings[i].$1, rings[i].$2, rings[i].$3,
                      rings[i].$4, rings[i].$5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ring(String label, double value, int goal, String unit, Color color) {
    // A negative carb amount is legal (carb by difference) and would draw the
    // arc backwards, so the fraction is clamped rather than the grams.
    final pct = ((value / goal) * 100).clamp(0, 100).round();
    return Column(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.butt,
                  backgroundColor: _dim(.1),
                  color: color,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: pct >= 5 ? AppColors.fg : _dim(.5),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _caption(label, spacing: 0.8, size: 9),
        const SizedBox(height: 8),
        Text(
          '${formatGrams(value)}$unit / $goal$unit',
          maxLines: 1,
          style: TextStyle(
            fontSize: 8.5,
            color: _dim(.28),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  /// Where the calories actually come from — 4·4·9, the same split the macro
  /// percentages above are read off.
  Widget _energy(FoodHit food) {
    final p = _portion.scale(food.protein100g);
    final c = _portion.scale(food.carb100g);
    final f = _portion.scale(food.fat100g);
    final bars = [
      ('protein', p * 4, AppColors.protein, _share('PROTEIN', p, c, f)),
      ('carbs', c * 4, AppColors.carbs, _share('CARBS', p, c, f)),
      ('fat', f * 9, AppColors.fat, _share('FAT', p, c, f)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: _dim(.08)))),
          child: _caption('ENERGY BREAKDOWN', spacing: 1.5),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 8,
                  color: AppColors.tile,
                  child: Row(
                    children: [
                      // Zero-share macros are dropped, not given flex 0: a
                      // flexible child with no flex still takes its own width.
                      for (final b in bars)
                        if (b.$4 > 0)
                          Expanded(flex: b.$4, child: ColoredBox(color: b.$3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (final b in bars)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration:
                              BoxDecoration(color: b.$3, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(b.$1,
                            style: TextStyle(fontSize: 10, color: _dim(.6))),
                        const SizedBox(width: 6),
                        Text(
                          '${b.$2.round()} kcal',
                          style: TextStyle(
                            fontSize: 10,
                            color: _dim(.35),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The rows the four list macros don't cover. [extras] arrives a frame or two
  /// late and is null for a quick entry, so every row past the first is
  /// conditional.
  Widget _nutrients(FoodHit food, FoodExtras? extras) {
    double? at(double? per100g) =>
        per100g == null ? null : _portion.scale(per100g);
    final carb = at(food.carb100g);
    final fiber = at(extras?.fiber);

    final rows = <(String, double?, String, bool)>[
      ('Total carbohydrate', carb, 'g', true),
      ('Dietary fibre', fiber, 'g', false),
      ('Total sugars', at(extras?.sugar), 'g', false),
      // Net carbs need both, and the catalog has foods with one and not the
      // other.
      (
        'Net carbs',
        carb == null || fiber == null ? null : carb - fiber,
        'g',
        true
      ),
      ('Saturated fat', at(extras?.satFat), 'g', false),
      ('Sodium', at(extras?.sodium), 'mg', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: _dim(.08)))),
          child: _caption('NUTRITION', spacing: 1.5),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Column(
            children: [
              for (final r in rows)
                if (r.$2 != null) _nutrientRow(r.$1, r.$2!, r.$3, r.$4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nutrientRow(String name, double value, String unit, bool strong) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: _dim(.05)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(name,
              style: TextStyle(
                  fontSize: 11.5, color: strong ? AppColors.fg : _dim(.55))),
          // The design's dotted leader, as a hairline — Flutter has no dotted
          // border and a custom painter isn't worth 1 px of texture.
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _dim(.1),
            ),
          ),
          Text(
            unit == 'mg'
                ? '${value.round()} mg'
                : '${formatGrams(value)} $unit',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
              color: strong ? AppColors.amber : _dim(.7),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _caption(String text, {double spacing = 1.3, double size = 9.5}) =>
      Text(text,
          maxLines: 1,
          style: TextStyle(
              fontSize: size, letterSpacing: spacing, color: _dim(.45)));

  /// A macro's share of the food's calories, 4·4·9. Negative carbs floor at
  /// zero, and a food with no macros at all reads 0% across.
  int _share(String macro, double p, double c, double f) {
    double kcal(String m) => switch (m) {
          'PROTEIN' => p * 4,
          'CARBS' => c * 4,
          _ => f * 9,
        };
    final total = [
      kcal('PROTEIN'),
      kcal('CARBS'),
      kcal('FAT'),
    ].fold(0.0, (a, b) => a + (b > 0 ? b : 0));
    if (total <= 0) return 0;
    final v = kcal(macro);
    return v <= 0 ? 0 : (v / total * 100).round();
  }
}
