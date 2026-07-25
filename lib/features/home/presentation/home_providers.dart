import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../data/food_log_repository.dart';
import '../domain/daily_summary.dart';

part 'home_providers.g.dart';

// ponytail: read once per build, no ticking timer; add a periodic refresh when
// the now-marker drifting within a long-lived session matters.
@riverpod
DateTime now(Ref ref) => DateTime.now();

/// The timeline query already returns `grams / 100.0 * <nutrient>`, so nothing
/// downstream needs to know about the per-100 g convention.
///
/// Hand-written rather than `@riverpod`: riverpod_generator cannot resolve
/// types that drift emits into a `part` file, and fails with
/// InvalidTypeException on any signature naming one. Providers whose *return*
/// type is ordinary (below) generate fine even when their bodies use these.
final todayEntriesProvider =
    StreamProvider.autoDispose<List<TimelineForDayResult>>((ref) async* {
  final repo = await ref.watch(foodLogRepositoryProvider.future);
  yield* repo.watchDay(ref.watch(nowProvider));
});

@riverpod
DailySummary dailySummary(Ref ref) {
  final entries =
      ref.watch(todayEntriesProvider).value ?? const <TimelineForDayResult>[];
  var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
  for (final e in entries) {
    kcal += e.kcal ?? 0;
    protein += e.protein ?? 0;
    carbs += e.carb ?? 0;
    fat += e.fat ?? 0;
  }
  // Rounded at the boundary so the UI keeps its int API.
  return DailySummary(
    kcal: kcal.round(),
    protein: protein.round(),
    carbs: carbs.round(),
    fat: fat.round(),
  );
}

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
  final List<TimelineForDayResult> entries;

  String get label => hour.toString().padLeft(2, '0');
}

// ponytail: meal planning isn't built; these rows are static design
// placeholders until a planning feature exists.
const _plannedMeals = {13: '~700 kcal plan', 19: '~650 kcal plan'};

@riverpod
List<TimelineHour> timeline(Ref ref) {
  final entries =
      ref.watch(todayEntriesProvider).value ?? const <TimelineForDayResult>[];
  final now = ref.watch(nowProvider);
  return [
    for (var h = 5; h <= 23; h++)
      _hour(h, [for (final e in entries) if (hourOf(e) == h) e], now),
  ];
}

/// `logged_at` is `YYYY-MM-DDTHH:MM` local wall clock — the hour is characters
/// 11..13, so no parsing and no timezone is in play.
int hourOf(TimelineForDayResult e) => int.parse(e.loggedAt.substring(11, 13));

TimelineHour _hour(int h, List<TimelineForDayResult> items, DateTime now) {
  if (items.isNotEmpty) {
    return TimelineHour(h, totals: _hourTotals(items), entries: items);
  }
  if (h == now.hour) return TimelineHour(h, kind: HourKind.now, totals: 'now');
  final plan = _plannedMeals[h];
  if (plan != null) return TimelineHour(h, kind: HourKind.plan, totals: plan);
  return TimelineHour(h);
}

String _hourTotals(List<TimelineForDayResult> items) {
  var kcal = 0.0, p = 0.0, c = 0.0, f = 0.0;
  for (final e in items) {
    kcal += e.kcal ?? 0;
    p += e.protein ?? 0;
    c += e.carb ?? 0;
    f += e.fat ?? 0;
  }
  if (kcal == 0) return '';
  if (p + c + f == 0) return '${kcal.round()} kcal';
  return '${kcal.round()} kcal · ${p.round()}P ${c.round()}C ${f.round()}F';
}
