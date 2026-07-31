import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../home/data/catalog_repository.dart';
import '../domain/portion.dart';
import 'search_providers.dart';

Color _dim(double a) => AppColors.dim(a);

/// Types an exact amount of one food, in whichever unit that food comes in.
///
/// Takes the place of the search field so the OS keyboard retracts — the pad is
/// the keyboard while it is open. It only produces a [Portion]; staging and
/// logging stay with the caller, same as [QuickAdd].
class PortionPad extends ConsumerStatefulWidget {
  const PortionPad({
    super.key,
    required this.food,
    required this.onAdd,
    required this.onClose,
    required this.onLogAll,
    this.initial,
    this.onChanged,
  });

  final FoodHit food;
  final void Function(Portion) onAdd;
  final VoidCallback onClose;
  final VoidCallback onLogAll;

  /// The amount to open on. Null starts at one whole unit — what a fresh row
  /// means — while re-editing a staged amount reopens on that amount.
  final Portion? initial;

  /// Fires whenever the typed amount changes, for a host that mirrors it. The
  /// host must ignore an unchanged amount: it rebuilds this pad, which reports
  /// again.
  final void Function(Portion)? onChanged;

  @override
  ConsumerState<PortionPad> createState() => _PortionPadState();
}

class _PortionPadState extends ConsumerState<PortionPad>
    with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  /// A measured amount reopens in its own unit; bare grams reopen in grams,
  /// which is the one unit every food has.
  late String _amt = switch (widget.initial) {
    null => '1',
    final p when p.portionLabel != null => formatQty(p.qty!),
    final p => formatGrams(p.grams),
  };
  late String? _unit = widget.initial == null
      ? null
      : widget.initial!.portionLabel ?? 'g';

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  /// Capped at the design's seven characters — `1 15/16` is already absurd.
  void _type(String ch) {
    if (_amt.length < 7) setState(() => _amt += ch);
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    // Catalog measures arrive late and are optional: the pad renders at once on
    // the food's own serving and gains chips when the query lands. Only a
    // catalog food has any — the other two offer their own serving and nothing
    // else.
    final catalog = switch (food.ref) {
      CatalogRef(:final id) =>
        ref.watch(foodPortionsProvider(id)).value ?? const [],
      CustomRef() || UnsavedRef() =>
        const <({String label, double gramWeight})>[],
    };
    final units = portionUnits(
      servingG: food.servingG,
      servingLabel: food.servingLabel,
      catalogPortions: catalog,
    );
    final unit = units.firstWhere((u) => u.label == _unit,
        orElse: () => units.first);
    final portion = portionFor(parseAmount(_amt), unit);

    final onChanged = widget.onChanged;
    if (onChanged != null) {
      // After the frame, not during it: the host rebuilds on this, and a
      // parent setState inside a child's build is an error.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onChanged(portion);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        border: Border(top: BorderSide(color: _dim(.1))),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _head(food, portion),
          const SizedBox(height: 9),
          _amount(unit, portion),
          const SizedBox(height: 9),
          _unitRow(units, unit, portion),
          const SizedBox(height: 9),
          _keys(portion),
        ],
      ),
    );
  }

  Widget _head(FoodHit food, Portion portion) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.tile,
            border: Border.all(color: _dim(.09)),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(food.emoji ?? '🍽️', style: const TextStyle(fontSize: 17)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.fg)),
              const SizedBox(height: 3),
              macroLine(
                portion.scale(food.kcal100g),
                portion.scale(food.protein100g),
                portion.scale(food.carb100g),
                portion.scale(food.fat100g),
                size: 9.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: AppColors.badgeBg, shape: BoxShape.circle),
            child: Icon(Icons.close, size: 13, color: _dim(.6)),
          ),
        ),
      ],
    );
  }

  Widget _amount(PortionUnit unit, Portion portion) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: .06),
        border: Border.all(color: AppColors.amber),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // One Expanded for the whole typed group: a loose Flexible per child
          // would reserve flex space it doesn't use and strand the grams
          // readout mid-row instead of at the right edge.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _amt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1,
                      color: AppColors.fg,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FadeTransition(
                  // steps(1): a hard on/off, not a fade.
                  opacity: _blink.drive(CurveTween(curve: const Threshold(.5))),
                  child:
                      Container(width: 2, height: 24, color: AppColors.amber),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(unit.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: _dim(.55))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${formatGrams(portion.grams)} g',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: AppColors.amber,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
              const SizedBox(height: 4),
              Text('${portion.scale(widget.food.kcal100g).round()} kcal',
                  style: TextStyle(fontSize: 9, color: _dim(.4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitRow(List<PortionUnit> units, PortionUnit unit, Portion portion) {
    return Row(
      children: [
        GestureDetector(
          // Converts rather than switches: the grams hold and the number is
          // rewritten, so `4 oz` becomes `113.4 g`.
          onTap: () {
            final next = units[(units.indexOf(unit) + 1) % units.length];
            setState(() {
              _unit = next.label;
              _amt = formatGrams(portion.grams / next.gramWeight);
            });
          },
          child: Container(
            width: 34,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.tile,
              border: Border.all(color: _dim(.14)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.swap_vert, size: 15, color: _dim(.65)),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: units.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) => _chip(units[i], units[i] == unit),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(PortionUnit u, bool on) {
    return GestureDetector(
      // Switching the unit keeps the typed number: `2` cups becomes `2` oz.
      onTap: () => setState(() => _unit = u.label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? AppColors.amber : AppColors.badgeBg,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          u.label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            color: on ? AppColors.bg : _dim(.6),
          ),
        ),
      ),
    );
  }

  Widget _keys(Portion portion) {
    final live = portion.grams > 0;
    Widget row(List<Widget> keys) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: keys[i]),
              ],
            ],
          ),
        );

    return Column(
      children: [
        row([_dig('1'), _dig('2'), _dig('3'), _side(const Text('/'), () => _type('/'))]),
        row([
          _dig('4'),
          _dig('5'),
          _dig('6'),
          _side(const Icon(Icons.space_bar, size: 16), () => _type(' ')),
        ]),
        row([
          _dig('7'),
          _dig('8'),
          _dig('9'),
          _side(const Icon(Icons.backspace_outlined, size: 15), () {
            if (_amt.isNotEmpty) {
              setState(() => _amt = _amt.substring(0, _amt.length - 1));
            }
          }),
        ]),
        row([
          _dig('.'),
          _dig('0'),
          _side(const Text('log all', style: TextStyle(fontSize: 11)), () {
            // The design just commits. Staging first means an amount typed but
            // never added isn't silently dropped.
            if (live) widget.onAdd(portion);
            widget.onLogAll();
          }),
          _cap(
            'add',
            live ? () => widget.onAdd(portion) : null,
            bg: live ? AppColors.amber : _dim(.08),
            fg: live ? AppColors.bg : _dim(.3),
          ),
        ]),
      ],
    );
  }

  Widget _dig(String ch) => _cap(ch, () => _type(ch), size: 17);

  Widget _side(Widget child, VoidCallback onTap) => _cap(null, onTap,
      bg: AppColors.tile, fg: _dim(.6), child: child);

  Widget _cap(
    String? label,
    VoidCallback? onTap, {
    Color? bg,
    Color? fg,
    double size = 14.5,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: bg ?? AppColors.badgeBg,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            color: fg ?? AppColors.fg,
          ),
          child: IconTheme(
            data: IconThemeData(color: fg ?? AppColors.fg),
            child: child ??
                Text(label!,
                    style: TextStyle(
                      fontSize: size,
                      fontWeight:
                          bg == AppColors.amber ? FontWeight.w600 : null,
                      color: fg ?? AppColors.fg,
                    )),
          ),
        ),
      ),
    );
  }
}
