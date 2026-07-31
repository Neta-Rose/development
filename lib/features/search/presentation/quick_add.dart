import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../home/data/catalog_repository.dart';
import '../domain/portion.dart';

Color _dim(double a) => AppColors.dim(a);

/// Emoji offered by the icon grid, in the design's order.
const _icons = [
  '🍽️', '🍗', '🥩', '🍳', '🥗', '🍚', '🍜', '🥪', '🍕',
  '🍔', '🌮', '🥞', '🧀', '🥜', '🍎', '🍫', '🥤', '☕',
];

/// Digits and one decimal point, capped at the design's five characters.
final _numeric = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  LengthLimitingTextInputFormatter(5),
];

/// Off-database entry: calories, optionally macros, a name and an emoji.
///
/// Stages into the same batch as a search hit, as a [FoodHit] with neither id —
/// `Batch.logAll` writes the `custom_foods` row. The design's bespoke keypad is
/// the system keyboard here, same as the search field.
class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key, required this.onAdd});

  final void Function(FoodHit food, Portion portion) onAdd;

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _name = TextEditingController();

  final _kcalFocus = FocusNode();
  final _proteinFocus = FocusNode();
  final _carbsFocus = FocusNode();
  final _fatFocus = FocusNode();
  final _nameFocus = FocusNode();

  String _emoji = _icons.first;

  late final List<Listenable> _listenables = [
    _kcal, _protein, _carbs, _fat, _name,
    _kcalFocus, _proteinFocus, _carbsFocus, _fatFocus, _nameFocus,
  ];

  /// Every readout on this pane — the auto total, the focused border, the
  /// button's label and its enabled state — is derived, so one listener does.
  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    for (final l in _listenables) {
      l.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    for (final l in _listenables) {
      l.removeListener(_rebuild);
    }
    for (final c in [_kcal, _protein, _carbs, _fat, _name]) {
      c.dispose();
    }
    for (final f in [
      _kcalFocus, _proteinFocus, _carbsFocus, _fatFocus, _nameFocus
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  double _value(TextEditingController c) => double.tryParse(c.text) ?? 0;

  bool get _hasMacros =>
      _protein.text.isNotEmpty || _carbs.text.isNotEmpty || _fat.text.isNotEmpty;

  /// Atwater: 4 kcal per gram of protein and carbohydrate, 9 per gram of fat.
  int get _autoKcal =>
      (_value(_protein) * 4 + _value(_carbs) * 4 + _value(_fat) * 9).round();

  /// What gets logged: the typed calories, or the macro total when left blank.
  int get _kcalEffective =>
      _kcal.text.isEmpty ? _autoKcal : _value(_kcal).round();

  bool get _canAdd => _kcalEffective > 0 || _name.text.trim().isNotEmpty;

  void _add() {
    if (!_canAdd) return;
    final name = _name.text.trim();
    widget.onAdd(
      FoodHit(
        name: name.isEmpty ? 'Quick entry' : name,
        // No custom_foods row yet — logAll creates one from these numbers.
        ref: const UnsavedRef(),
        emoji: _emoji,
        kcal100g: _kcalEffective.toDouble(),
        protein100g: _value(_protein),
        fat100g: _value(_fat),
        carb100g: _value(_carbs),
        servingG: 100,
        servingLabel: 'serving',
      ),
      wholeServing(100, 'serving'),
    );
    for (final c in [_kcal, _protein, _carbs, _fat, _name]) {
      c.clear();
    }
    setState(() => _emoji = _icons.first);
    _kcalFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHead(),
                const SizedBox(height: 10),
                _calories(),
                const SizedBox(height: 8),
                _macros(),
                const SizedBox(height: 8),
                _nameRow(),
                const SizedBox(height: 16),
                _label('ICON'),
                const SizedBox(height: 8),
                _iconGrid(),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SafeArea(top: false, child: _addButton()),
      ],
    );
  }

  Widget _sectionHead() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('QUICK ADD',
            style:
                TextStyle(fontSize: 9.5, letterSpacing: 1.5, color: _dim(.45))),
        Text('off-database · numbers only',
            style: TextStyle(fontSize: 9, color: _dim(.28))),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: _dim(.42)),
      );

  /// The design's field surface: amber border and tint while focused.
  BoxDecoration _boxDecoration(bool focused) => BoxDecoration(
        color: focused ? AppColors.amber.withValues(alpha: .07) : AppColors.field,
        border: Border.all(color: focused ? AppColors.amber : _dim(.1)),
        borderRadius: BorderRadius.circular(11),
      );

  /// A number entry, sized to its own content so the unit suffix sits hard
  /// against the value the way the design has it — `suffixText` would pin it
  /// to the far edge of the box instead.
  ///
  /// ponytail: the width is the monospace advance (IBM Plex Mono is 0.6 em)
  /// times the character count, not a measured one. Swap in a TextPainter if
  /// this ever has to render a proportional font.
  Widget _numberField(
    TextEditingController controller,
    FocusNode focus, {
    required double fontSize,
    required String suffix,
    required double suffixSize,
    String? hintText,
    Color? hintColor,
    bool autofocus = false,
  }) {
    final shown =
        controller.text.isEmpty ? (hintText ?? '0') : controller.text;
    // +3 leaves room for the caret past the last digit.
    final width = shown.length * fontSize * 0.6 + 3;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: width,
          child: TextField(
            controller: controller,
            focusNode: focus,
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: _numeric,
            cursorColor: AppColors.amber,
            cursorWidth: 2,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: fontSize > 24 ? -1 : -0.5,
              height: 1,
              color: AppColors.fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hintText ?? '0',
              hintStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: fontSize > 24 ? -1 : -0.5,
                height: 1,
                color: hintColor ?? _dim(.25),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Text(suffix,
            style: TextStyle(fontSize: suffixSize, color: _dim(.4))),
      ],
    );
  }

  Widget _calories() {
    return GestureDetector(
      onTap: _kcalFocus.requestFocus,
      child: Container(
        decoration: _boxDecoration(_kcalFocus.hasFocus),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('CALORIES'),
                  const SizedBox(height: 5),
                  _numberField(
                    _kcal,
                    _kcalFocus,
                    fontSize: 30,
                    suffix: ' kcal',
                    suffixSize: 11,
                    autofocus: true,
                    // Blank calories read as the macro total, in amber to show
                    // the number is computed rather than typed.
                    hintText: '$_autoKcal',
                    hintColor: _hasMacros
                        ? AppColors.amber.withValues(alpha: .85)
                        : _dim(.25),
                  ),
                ],
              ),
            ),
            if (_hasMacros) _autoChip(),
          ],
        ),
      ),
    );
  }

  Widget _autoChip() {
    final auto = _kcal.text.isEmpty;
    return GestureDetector(
      onTap: () {
        _kcal.clear();
        _proteinFocus.requestFocus();
      },
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: auto ? AppColors.amber.withValues(alpha: .12) : null,
          border: Border.all(color: AppColors.amber.withValues(alpha: .45)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          auto ? '4·4·9 auto' : 'use $_autoKcal',
          style: const TextStyle(
              fontSize: 9.5, letterSpacing: .5, color: AppColors.amber),
        ),
      ),
    );
  }

  Widget _macros() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _macroBox('PROTEIN', AppColors.protein, _protein, _proteinFocus),
        const SizedBox(width: 8),
        _macroBox('CARBS', AppColors.carbs, _carbs, _carbsFocus),
        const SizedBox(width: 8),
        _macroBox('FAT', AppColors.fat, _fat, _fatFocus),
      ],
    );
  }

  Widget _macroBox(String label, Color color, TextEditingController controller,
      FocusNode focus) {
    return Expanded(
      child: GestureDetector(
        onTap: focus.requestFocus,
        child: Container(
          decoration: _boxDecoration(focus.hasFocus),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 8.5, letterSpacing: 1.2, color: color)),
              const SizedBox(height: 7),
              _numberField(
                controller,
                focus,
                fontSize: 20,
                suffix: ' g',
                suffixSize: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameRow() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.tile,
            border: Border.all(color: _dim(.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(_emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _nameFocus.requestFocus,
            child: Container(
              // Matches the emoji tile beside it — the design stretches them
              // to a common height, which a Row in a scroll view can't do.
              height: 52,
              decoration: _boxDecoration(_nameFocus.hasFocus),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('NAME'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _name,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    cursorColor: AppColors.amber,
                    cursorWidth: 2,
                    style:
                        const TextStyle(fontSize: 13.5, color: AppColors.fg),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'tap to name it',
                      hintStyle:
                          TextStyle(fontSize: 13.5, color: _dim(.28)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconGrid() {
    return GridView.count(
      crossAxisCount: 9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 34 / 34,
      children: [
        for (final icon in _icons)
          GestureDetector(
            onTap: () => setState(() => _emoji = icon),
            child: Container(
              decoration: BoxDecoration(
                color: icon == _emoji
                    ? AppColors.amber.withValues(alpha: .16)
                    : AppColors.field,
                border: Border.all(
                    color: icon == _emoji ? AppColors.amber : _dim(.08)),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
      ],
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: _add,
      child: Container(
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _canAdd ? AppColors.amber : _dim(.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add,
                size: 15, color: _canAdd ? AppColors.bg : _dim(.3)),
            const SizedBox(width: 8),
            Text(
              _canAdd
                  ? 'add to batch · $_kcalEffective kcal'
                  : 'enter calories or a name',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _canAdd ? AppColors.bg : _dim(.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
