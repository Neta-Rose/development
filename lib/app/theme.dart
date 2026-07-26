import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg = Color(0xFF0C0E0B);
  static const fg = Color(0xFFE6E8DF);
  static const navBg = Color(0xFF12140F);
  static const badgeBg = Color(0xFF222420);
  static const tile = Color(0xFF1A1C17);
  static const field = Color(0xFF14160F);
  static const amber = Color(0xFFE5A44C);
  static const protein = Color(0xFFE5705C);
  static const carbs = Color(0xFF7FBF6A);
  static const fat = Color(0xFFE8C95C);

  static Color dim(double a) => fg.withValues(alpha: a);
}

/// `120 kcal · 30P 5C 2F` in the macro colours — the summary line under a food,
/// wherever one is shown.
Text macroLine(double kcal, double p, double c, double f, {double size = 10}) {
  TextSpan span(String s, Color color) =>
      TextSpan(text: s, style: TextStyle(color: color));
  return Text.rich(
    TextSpan(
      style: TextStyle(fontSize: size, color: AppColors.dim(.5)),
      children: [
        TextSpan(text: '${kcal.round()} kcal · '),
        span('${p.round()}P', AppColors.protein),
        const TextSpan(text: ' '),
        span('${c.round()}C', AppColors.carbs),
        const TextSpan(text: ' '),
        span('${f.round()}F', AppColors.fat),
      ],
    ),
  );
}

final appTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'IBM Plex Mono',
  scaffoldBackgroundColor: AppColors.bg,
);
