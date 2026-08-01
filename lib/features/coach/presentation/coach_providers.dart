import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../home/domain/daily_summary.dart';
import '../../home/presentation/home_providers.dart';
import '../data/coach_repository.dart';
import '../data/engine_client.dart';
import '../domain/candidate.dart';
import '../domain/suggest.dart';

part 'coach_providers.g.dart';

/// What the coach header and chips display, and what `user_state` carries.
///
/// [remaining] is **real**: the app's macro targets minus what is actually in
/// `log_entries` today. The engine keeps no consumption log of its own, so this
/// is the field that makes its answers about this user rather than a default
/// one.
class CoachContext {
  const CoachContext({
    required this.remaining,
    required this.remainingMeals,
    required this.mealSlot,
    required this.now,
  });

  final RemainingToday remaining;
  final int remainingMeals;
  final String mealSlot;
  final DateTime now;

  String get clock =>
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';

  UserState toUserState() => UserState(
        remainingToday: remaining,
        remainingMeals: remainingMeals,
        // `preferences.diets` is never sent — see UserState.allergies. The app
        // has no profile table, so allergies stay empty rather than invented.
        allergies: const [],
      );
}

/// Meal slot from the wall clock. Real, and the engine takes it as a free
/// string.
String mealSlotFor(int hour) => switch (hour) {
      < 11 => 'breakfast',
      < 16 => 'lunch',
      < 22 => 'dinner',
      _ => 'snack',
    };

@riverpod
CoachContext coachContext(Ref ref) {
  final now = ref.watch(nowProvider);
  final eaten = ref.watch(dailySummaryProvider);
  const t = MacroTargets.defaults;

  // Clamped at zero: the engine treats 0 as "no budget left", which is a real
  // state and different from omitting the field. Going negative would ask it
  // for a meal that undoes lunch.
  int left(int target, int consumed) =>
      (target - consumed) < 0 ? 0 : target - consumed;

  return CoachContext(
    remaining: RemainingToday(
      kcal: left(t.kcal, eaten.kcal),
      proteinG: left(t.protein, eaten.protein),
      carbsG: left(t.carbs, eaten.carbs),
      fatG: left(t.fat, eaten.fat),
    ),
    // ponytail: derived from the home screen's placeholder plan rows, which are
    // themselves hardcoded. Becomes real when a planning feature exists.
    remainingMeals: _plannedMealsLeft(now.hour),
    mealSlot: mealSlotFor(now.hour),
    now: now,
  );
}

/// ponytail: mirrors `_plannedMeals` in home_providers — the same two static
/// design placeholders. Counts the ones still ahead of now, floored at 1 so a
/// late-evening run still asks for a meal rather than none.
int _plannedMealsLeft(int hour) {
  const plannedHours = [13, 19];
  final left = plannedHours.where((h) => h >= hour).length;
  return left == 0 ? 1 : left;
}

/// Which candidate universe the run draws on. Only [CoachMode.onTheTable] is
/// wired; "cook something" builds the toggle but has no server-side source yet.
@riverpod
class Mode extends _$Mode {
  @override
  CoachMode build() => CoachMode.onTheTable;

  void set(CoachMode m) => state = m;
}

/// The capture tray. Survives navigation between the coach and capture screens,
/// which is why it is not screen-scoped.
@Riverpod(keepAlive: true)
class Tray extends _$Tray {
  @override
  List<Candidate> build() => const [];

  void addAll(List<Candidate> items) => state = [...state, ...items];

  void toggle(int i) => state = [
        for (var j = 0; j < state.length; j++)
          if (j == i) state[j].copyWith(checked: !state[j].checked) else state[j]
      ];

  /// Unchecking is not removal — an unchecked item stays visible so it can be
  /// re-added. This is the explicit removal path.
  void removeAt(int i) => state = [
        for (var j = 0; j < state.length; j++)
          if (j != i) state[j]
      ];

  /// Replaces an unresolved item once search finds it a real food.
  void resolveAt(int i, ResolvedFood food) => state = [
        for (var j = 0; j < state.length; j++)
          if (j == i) state[j].copyWith(resolved: food, checked: true) else state[j]
      ];

  void clear() => state = const [];
}

/// The seven pipeline stages, in the order the engine runs them.
enum Stage {
  context('context assembled'),
  retrieve('candidates retrieved'),
  filter('filtered out'),
  score('scoring signals'),
  compose('composing plates'),
  rerank('ranking and diversifying'),
  explain('writing explanations');

  const Stage(this.label);
  final String label;
}

sealed class CoachState {
  const CoachState();
}

/// Nothing captured yet, or items staged but not run.
class CoachIdle extends CoachState {
  const CoachIdle();
}

class CoachRunning extends CoachState {
  const CoachRunning(this.stage, {this.counts = const {}});

  final Stage stage;

  /// Fills in as the engine reports them — candidate and exclusion counts.
  final Map<Stage, int> counts;
}

class CoachResults extends CoachState {
  const CoachResults(this.response);
  final SuggestResponse response;
}

class CoachError extends CoachState {
  const CoachError(this.message, this.stage);

  final String message;

  /// Which stage was in flight, so the pipeline view can mark it.
  final Stage stage;
}

/// Which suggestion is expanded. Rank 1 by default, only one at a time, and -1
/// for none. Separate from [CoachRun] so expanding a row cannot disturb the
/// results it is expanding.
@Riverpod(keepAlive: true)
class ExpandedRank extends _$ExpandedRank {
  @override
  int build() => 1;

  void toggle(int rank) => state = state == rank ? -1 : rank;
  void reset() => state = 1;
}

@Riverpod(keepAlive: true)
class CoachRun extends _$CoachRun {
  @override
  CoachState build() => const CoachIdle();

  void reset() => state = const CoachIdle();

  Future<void> run() async {
    final ctx = ref.read(coachContextProvider);
    final tray = ref.read(trayProvider);
    final request = buildRequest(
      candidates: tray,
      mode: ref.read(modeProvider),
      userState: ctx.toUserState(),
      mealSlot: ctx.mealSlot,
    );

    // The stages before the call are genuinely done by the time it is sent, so
    // their counts are real rather than animated guesses.
    final sent = request.items.length;
    state = CoachRunning(Stage.context, counts: {Stage.retrieve: sent});

    var stage = Stage.context;
    try {
      // Walk the local stages while the request is in flight. The engine
      // reports per-stage timings but not progress, so the pre-flight steps are
      // paced and the rest resolve when the response lands.
      final pending = ref.read(coachRepositoryProvider.future).then(
          (repo) => repo.suggest(request));

      for (final s in [Stage.context, Stage.retrieve, Stage.filter]) {
        stage = s;
        state = CoachRunning(s, counts: {Stage.retrieve: sent});
        await Future<void>.delayed(const Duration(milliseconds: 90));
      }
      stage = Stage.score;
      state = CoachRunning(stage, counts: {Stage.retrieve: sent});

      final res = await pending;

      final excluded = res.excluded.fold<int>(0, (a, e) => a + e.count);
      for (final s in [Stage.compose, Stage.rerank, Stage.explain]) {
        stage = s;
        state = CoachRunning(s, counts: {
          Stage.retrieve: sent,
          Stage.filter: excluded,
        });
        await Future<void>.delayed(const Duration(milliseconds: 70));
      }

      ref.read(expandedRankProvider.notifier).reset();
      state = CoachResults(res);
    } on EngineException catch (e) {
      state = CoachError(e.message, stage);
    } catch (_) {
      // Never a raw exception string: say what happened and what to do.
      state = CoachError(
          'Could not reach the coach service. Check your connection and try again.',
          stage);
    }
  }
}
