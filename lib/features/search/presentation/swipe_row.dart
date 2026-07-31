import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/portion.dart';

Color _dim(double a) => AppColors.dim(a);

/// Leftward distance before removal arms, from the design's `ps.dx < -46`.
const _armAt = -46.0;

/// Width of the revealed remove affordance, and the cap on the row's shift.
const _removeWidth = 84.0;
const _amountWidth = 92.0;

/// A list row that picks an amount when dragged right and removes itself when
/// dragged far enough left.
///
/// Both are one horizontal recognizer, and both readouts are drawn *behind* the
/// row rather than replacing it, so the food stays readable while its amount is
/// being chosen.
///
/// The recognizer reads **both** axes off `globalPosition` because its own
/// `delta` carries the primary axis only — and the vertical component is what
/// multiplies the picked rung. A vertical drag still scrolls the list until a
/// horizontal one wins the arena.
class SwipeRow extends StatefulWidget {
  const SwipeRow({
    super.key,
    required this.unitG,
    this.unitLabel,
    required this.kcal100g,
    required this.onPicked,
    this.onRemove,
    this.rowColor,
    required this.child,
  });

  /// What one serving of this food weighs, which sets the ladder's rungs.
  final double unitG;
  final String? unitLabel;

  /// Energy per 100 g, for the `n kcal` under a candidate amount.
  final double kcal100g;

  /// A completed right-drag that selected an amount.
  final void Function(Portion) onPicked;

  /// A completed left-drag past the arm threshold. Null means the row has no left
  /// action at all.
  final VoidCallback? onRemove;

  /// Painted behind the row. The design tints a row first seen in the newest shot.
  final Color? rowColor;

  final Widget child;

  @override
  State<SwipeRow> createState() => _SwipeRowState();
}

class _SwipeRowState extends State<SwipeRow> {
  Offset _start = Offset.zero;
  Offset _delta = Offset.zero;
  final _dragTracker = PortionDragTracker();

  Portion? get _picked => portionForDrag(
        _dragTracker.virtualDx,
        _delta.dy,
        unitG: widget.unitG,
        unitLabel: widget.unitLabel,
      );

  bool get _removing => widget.onRemove != null && _delta.dx < _armAt;

  void _reset() => setState(() {
        _delta = Offset.zero;
        _dragTracker.reset();
      });

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    final showRemove = widget.onRemove != null && _delta.dx < -8;

    final double shift;
    if (_delta.dx > 0) {
      shift = (18 + _delta.dx * .35).clamp(0.0, _amountWidth);
    } else if (widget.onRemove != null) {
      shift = (_delta.dx * .5).clamp(-_removeWidth, 0.0);
    } else {
      shift = 0;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (d) => setState(() {
        _start = d.globalPosition;
        _delta = Offset.zero;
        _dragTracker.start(0);
      }),
      onHorizontalDragUpdate: (d) => setState(() {
        _delta = d.globalPosition - _start;
        _dragTracker.update(_delta.dx);
      }),
      onHorizontalDragEnd: (_) {
        if (picked != null) {
          widget.onPicked(picked);
        } else if (_removing) {
          widget.onRemove!();
        }
        _reset();
      },
      onHorizontalDragCancel: _reset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.rowColor,
          border: Border(bottom: BorderSide(color: _dim(.07))),
        ),
        child: Stack(
          children: [
            if (picked != null)
              _pickFill()
            else if (showRemove)
              _removeFill(),
            if (picked != null) _pickLabel(picked, shift),
            if (showRemove) _removeLabel(),
            Transform.translate(offset: Offset(shift, 0), child: widget.child),
          ],
        ),
      ),
    );
  }

  Widget _pickFill() => Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: _delta.dx.clamp(0.0, 340.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.amber.withValues(alpha: .3),
              AppColors.amber.withValues(alpha: .03),
            ]),
          ),
        ),
      );

  Widget _removeFill() => Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: (-_delta.dx).clamp(0.0, 340.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // Right to left, so the strongest end sits under the label.
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                AppColors.danger.withValues(alpha: _removing ? .3 : .16),
                AppColors.danger.withValues(alpha: .02),
              ],
            ),
          ),
        ),
      );

  Widget _pickLabel(Portion picked, double shift) => Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: shift,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(picked.label,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: AppColors.amber)),
            Text('${picked.scale(widget.kcal100g).round()} kcal',
                maxLines: 1,
                style: const TextStyle(fontSize: 8.5, color: AppColors.amber)),
          ],
        ),
      );

  Widget _removeLabel() => Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: _removeWidth,
        child: Center(
          child: Text(
            _removing ? 'release to remove' : 'remove',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: .3,
              height: 1.3,
              color: _removing
                  ? AppColors.danger
                  : AppColors.danger.withValues(alpha: .55),
            ),
          ),
        ),
      );
}
