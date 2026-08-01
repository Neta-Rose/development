import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../domain/candidate.dart';
import '../domain/suggest.dart';
import 'coach_providers.dart';
import 'widgets/coach_bits.dart';
import 'widgets/pipeline_view.dart';
import 'widgets/suggestion_row.dart';

Color _dim(double a) => AppColors.dim(a);

/// Screens 1 and 3 of the coach flow: arrival, and the ranked answers.
///
/// Results are not a separate route — a completed run replaces the empty well
/// in place, so the header and its context stay put the whole way through.
class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(coachContextProvider);
    final tray = ref.watch(trayProvider);
    final run = ref.watch(coachRunProvider);
    final hasResults = run is CoachResults;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(ctx: ctx, showRefresh: hasResults),
            Expanded(child: _body(context, ref, run, tray)),
            // The CTA collapses into the header's refresh circle once results
            // exist — a full-width button would scroll away under the list.
            if (!hasResults) _Cta(tray: tray, running: run is CoachRunning),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CoachState run,
      List<Candidate> tray) {
    return switch (run) {
      CoachRunning() => PipelineView(state: run),
      CoachError() => PipelineView(state: run, onRetry: () {
          ref.read(coachRunProvider.notifier).run();
        }),
      CoachResults(:final response) => _Results(response: response),
      CoachIdle() => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          children: [
            if (tray.isEmpty)
              const _EmptyWell()
            else
              _TrayStrip(tray: tray),
            const SizedBox(height: 14),
            const _ModeToggle(),
          ],
        ),
    };
  }
}

// ------------------------------------------------------------------ header

class _Header extends ConsumerWidget {
  const _Header({required this.ctx, required this.showRefresh});

  final CoachContext ctx;
  final bool showRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ctx.remaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: formatThousands(r.kcal),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1,
                      color: AppColors.fg,
                    ),
                    children: [
                      // "left" is never dropped: the home header shows calories
                      // *consumed*, and these two must not be confusable.
                      TextSpan(
                        text: ' kcal left',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: _dim(.45)),
                      ),
                    ],
                  ),
                ),
              ),
              if (showRefresh)
                _RoundButton(
                  size: 38,
                  color: AppColors.amber,
                  icon: Icons.refresh,
                  iconColor: AppColors.bg,
                  onTap: () => ref.read(coachRunProvider.notifier).run(),
                )
              else
                _RoundButton(
                  size: 34,
                  color: AppColors.badgeBg,
                  icon: Icons.tune,
                  iconColor: _dim(.55),
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              MacroTriple(
                  protein: r.proteinG.toDouble(),
                  carbs: r.carbsG.toDouble(),
                  fat: r.fatG.toDouble(),
                  size: 11),
              Text(' · ${ctx.remainingMeals} meal'
                  '${ctx.remainingMeals == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: _dim(.45))),
            ],
          ),
          const SizedBox(height: 10),
          // Only chips backed by a field actually sent to the engine. The
          // design also drew workout and sleep chips; the engine takes both as
          // optional and the app has no source for either, so they are not
          // sent — and a chip that claims otherwise would be a lie about the
          // request.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ContextChip('${ctx.clock} ${ctx.mealSlot}'),
              ContextChip('${formatThousands(r.kcal)} kcal left'),
              ContextChip('${ctx.remainingMeals} meals left'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final double size;
  final Color color, iconColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: size * .45, color: iconColor),
        ),
      );
}

// -------------------------------------------------------------- empty well

class _EmptyWell extends ConsumerWidget {
  const _EmptyWell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomPaint(
      painter: DashedBorderPainter(color: _dim(.18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: Column(
          children: [
            Text('WHAT\'S IN FRONT OF YOU',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 1.5, color: _dim(.45))),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WellButton(
                    label: 'SCAN',
                    icon: Icons.camera_alt_outlined,
                    onTap: () => context.push('/coach/capture')),
                const SizedBox(width: 12),
                _WellButton(
                    label: 'SEARCH',
                    icon: Icons.search,
                    onTap: () => openCoachSearch(context, ref)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WellButton extends StatelessWidget {
  const _WellButton(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.badgeBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.fg),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.fg)),
            ],
          ),
        ),
      );
}

// -------------------------------------------------------------------- tray

class _TrayStrip extends ConsumerWidget {
  const _TrayStrip({required this.tray});

  final List<Candidate> tray;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checked = tray.where((c) => c.checked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$checked OF ${tray.length} SELECTED',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 1.5, color: _dim(.45))),
            GestureDetector(
              onTap: () => context.push('/coach/capture'),
              child: Text('edit ▸',
                  style: TextStyle(fontSize: 10, color: AppColors.amber)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tray.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => TrayTile(candidate: tray[i]),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ toggle

class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    Widget seg(String label, CoachMode m) {
      final on = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(modeProvider.notifier).set(m),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.badgeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    color: on ? AppColors.fg : _dim(.45))),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: _dim(.09)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(children: [
        seg('ON THE TABLE', CoachMode.onTheTable),
        seg('COOK SOMETHING', CoachMode.cookSomething),
      ]),
    );
  }
}

// --------------------------------------------------------------------- CTA

class _Cta extends ConsumerWidget {
  const _Cta({required this.tray, required this.running});

  final List<Candidate> tray;
  final bool running;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendable = tray.where((c) => c.checked && !c.isUnresolved).length;
    // Muted but never disabled: an empty candidate set is a valid request, it
    // just becomes a browse over the whole library.
    final muted = sendable == 0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: running ? null : () => ref.read(coachRunProvider.notifier).run(),
              child: Opacity(
                opacity: muted ? .45 : 1,
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text('ASK THE COACH',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppColors.bg)),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              muted
                  ? "no items — I'll search your whole library"
                  : '$sendable item${sendable == 1 ? '' : 's'} going to the coach',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: _dim(.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- results

class _Results extends ConsumerWidget {
  const _Results({required this.response});

  final SuggestResponse response;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(expandedRankProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RANKED PLATES',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 1.5, color: _dim(.45))),
            Text('tap for why',
                style: TextStyle(fontSize: 9, color: _dim(.28))),
          ],
        ),
        const SizedBox(height: 6),
        if (response.suggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Text(
              'Nothing cleared the filters. The summary below says what was '
              'held back — loosen a constraint or add another item.',
              style: TextStyle(fontSize: 11, height: 1.5, color: _dim(.45)),
            ),
          ),
        for (final s in response.suggestions)
          SuggestionRow(
            suggestion: s,
            expanded: s.rank == expanded,
            // Only one open at a time; tapping the open one closes it.
            onTap: () =>
                ref.read(expandedRankProvider.notifier).toggle(s.rank),
          ),
        const SizedBox(height: 16),
        ResultsFooter(response: response),
      ],
    );
  }
}
