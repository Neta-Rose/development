import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/food_log_repository.dart';
import '../domain/daily_summary.dart';
import '../domain/food_entry.dart';

part 'home_providers.g.dart';

// ponytail: read once per build, no ticking timer; add a periodic refresh when
// the now-marker drifting within a long-lived session matters.
@riverpod
DateTime now(Ref ref) => DateTime.now();

@riverpod
Stream<List<FoodEntry>> todayEntries(Ref ref) =>
    ref.watch(foodLogRepositoryProvider).watchDay(ref.watch(nowProvider));

@riverpod
DailySummary dailySummary(Ref ref) {
  final entries = ref.watch(todayEntriesProvider).value ?? const <FoodEntry>[];
  var kcal = 0, protein = 0, carbs = 0, fat = 0;
  for (final e in entries.where((e) => e.type == EntryType.food)) {
    kcal += e.kcal ?? 0;
    protein += e.protein ?? 0;
    carbs += e.carbs ?? 0;
    fat += e.fat ?? 0;
  }
  return DailySummary(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
}

const anabolicWindowLength = Duration(hours: 3);

class AnabolicWindow {
  const AnabolicWindow({
    required this.title,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// e.g. `▸ ANABOLIC WINDOW · T+0:29 · 2:31 LEFT`
  final String title;

  /// Macros consumed since the workout.
  final int protein;
  final int carbs;
  final int fat;

  // ponytail: fixed post-workout targets from the design; make configurable
  // alongside MacroTargets when profiles exist.
  static const proteinTarget = 40;
  static const carbsTarget = 80;
  static const fatTarget = 10;
}

@riverpod
AnabolicWindow? anabolicWindow(Ref ref) {
  final entries = ref.watch(todayEntriesProvider).value ?? const <FoodEntry>[];
  final now = ref.watch(nowProvider);
  FoodEntry? workout; // entries are sorted asc → last match = latest workout
  for (final e in entries) {
    if (e.type == EntryType.workout &&
        !e.loggedAt.isAfter(now) &&
        now.difference(e.loggedAt) < anabolicWindowLength) {
      workout = e;
    }
  }
  if (workout == null) return null;

  final workoutAt = workout.loggedAt;
  final elapsed = now.difference(workoutAt);
  var protein = 0, carbs = 0, fat = 0;
  for (final e in entries.where(
      (e) => e.type == EntryType.food && !e.loggedAt.isBefore(workoutAt))) {
    protein += e.protein ?? 0;
    carbs += e.carbs ?? 0;
    fat += e.fat ?? 0;
  }
  return AnabolicWindow(
    title: '▸ ANABOLIC WINDOW · T+${_hm(elapsed)} · '
        '${_hm(anabolicWindowLength - elapsed)} LEFT',
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
}

String _hm(Duration d) =>
    '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';

enum HourKind { logged, now, plan }

class TimelineHour {
  const TimelineHour(
    this.hour, {
    this.kind = HourKind.logged,
    this.totals = '',
    this.entries = const [],
  });

  final int hour;
  final HourKind kind;
  final String totals;
  final List<FoodEntry> entries;

  String get label => hour.toString().padLeft(2, '0');
}

// ponytail: meal planning isn't built; these rows are static design
// placeholders until a planning feature exists.
const _plannedMeals = {13: '~700 kcal plan', 19: '~650 kcal plan'};

@riverpod
List<TimelineHour> timeline(Ref ref) {
  final entries = ref.watch(todayEntriesProvider).value ?? const <FoodEntry>[];
  final now = ref.watch(nowProvider);
  return [
    for (var h = 5; h <= 23; h++)
      _hour(h, [for (final e in entries) if (e.loggedAt.hour == h) e], now),
  ];
}

TimelineHour _hour(int h, List<FoodEntry> items, DateTime now) {
  if (items.isNotEmpty) {
    return TimelineHour(h, totals: _hourTotals(items), entries: items);
  }
  if (h == now.hour) return TimelineHour(h, kind: HourKind.now, totals: 'now');
  final plan = _plannedMeals[h];
  if (plan != null) return TimelineHour(h, kind: HourKind.plan, totals: plan);
  return TimelineHour(h);
}

String _hourTotals(List<FoodEntry> items) {
  var kcal = 0, p = 0, c = 0, f = 0, burn = 0;
  for (final e in items) {
    if (e.type == EntryType.workout) {
      burn += e.kcal ?? 0;
    } else {
      kcal += e.kcal ?? 0;
      p += e.protein ?? 0;
      c += e.carbs ?? 0;
      f += e.fat ?? 0;
    }
  }
  if (kcal == 0) return burn > 0 ? '−$burn kcal' : '';
  if (p + c + f == 0) return '$kcal kcal';
  return '$kcal kcal · ${p}P ${c}C ${f}F';
}
