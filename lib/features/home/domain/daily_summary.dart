import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_summary.freezed.dart';

@freezed
abstract class DailySummary with _$DailySummary {
  const factory DailySummary({
    @Default(0) int kcal,
    @Default(0) int protein,
    @Default(0) int carbs,
    @Default(0) int fat,
  }) = _DailySummary;
}

class MacroTargets {
  const MacroTargets({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  // ponytail: hardcoded targets; move to a profile/settings table when one exists
  static const defaults =
      MacroTargets(kcal: 2850, protein: 180, carbs: 320, fat: 75);
}
