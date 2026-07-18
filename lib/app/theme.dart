import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg = Color(0xFF0C0E0B);
  static const fg = Color(0xFFE6E8DF);
  static const navBg = Color(0xFF12140F);
  static const badgeBg = Color(0xFF222420);
  static const amber = Color(0xFFE5A44C);
  static const protein = Color(0xFFE5705C);
  static const carbs = Color(0xFF7FBF6A);
  static const fat = Color(0xFFE8C95C);

  static Color dim(double a) => fg.withValues(alpha: a);
}

final appTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'IBM Plex Mono',
  scaffoldBackgroundColor: AppColors.bg,
);
