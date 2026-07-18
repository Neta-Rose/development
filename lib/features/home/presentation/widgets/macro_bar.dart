import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Thin progress bar used in the macro header and the anabolic-window card.
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.value,
    required this.target,
    required this.color,
    this.height = 3,
  });

  final int value;
  final int target;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pct = target == 0 ? 0.0 : value / target;
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.dim(.12),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: pct.clamp(.02, 1),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
