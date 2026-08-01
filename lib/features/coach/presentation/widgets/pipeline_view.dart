import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../coach_providers.dart';

Color _dim(double a) => AppColors.dim(a);

/// The running view, reused verbatim for the error state with the failing
/// stage marked. Shows the seven engine stages and fills counts in as they
/// become known.
class PipelineView extends StatelessWidget {
  const PipelineView({super.key, required this.state, this.onRetry});

  final CoachState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final running = state is CoachRunning ? state as CoachRunning : null;
    final failed = state is CoachError ? state as CoachError : null;
    final current = running?.stage ?? failed!.stage;
    final counts = running?.counts ?? const <Stage, int>{};
    final done = Stage.values.indexOf(current);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Determinate-ish: it tracks stages, which are real, rather than
          // inventing a percentage.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (done + 1) / Stage.values.length,
              minHeight: 2,
              backgroundColor: _dim(.09),
              valueColor: AlwaysStoppedAnimation(
                  failed != null ? AppColors.protein : AppColors.amber),
            ),
          ),
          const SizedBox(height: 18),
          for (final s in Stage.values)
            _StageLine(
              stage: s,
              index: Stage.values.indexOf(s),
              currentIndex: done,
              count: counts[s],
              failed: failed != null && s == current,
            ),
          const SizedBox(height: 16),
          if (failed != null) ...[
            Text(failed.message,
                style: const TextStyle(
                    fontSize: 11, height: 1.5, color: AppColors.fg)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text('TRY AGAIN',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: AppColors.fg)),
              ),
            ),
          ] else
            Text('budget 200 ms',
                style: TextStyle(fontSize: 9, color: _dim(.28))),
        ],
      ),
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine({
    required this.stage,
    required this.index,
    required this.currentIndex,
    required this.count,
    required this.failed,
  });

  final Stage stage;
  final int index, currentIndex;
  final int? count;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentIndex;
    final isCurrent = index == currentIndex;

    final (glyph, color) = switch (true) {
      _ when failed => ('×', AppColors.protein),
      _ when isDone => ('✓', AppColors.carbs),
      _ when isCurrent => ('▸', AppColors.amber),
      _ => ('·', _dim(.28)),
    };

    // Counts belong to the stages that report them, and only once known.
    final label = switch (stage) {
      Stage.retrieve when count != null => '$count candidates retrieved',
      Stage.filter when count != null => '$count filtered out',
      _ => stage.label,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(glyph,
                style: TextStyle(fontSize: 11, color: color)),
          ),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: failed || isCurrent
                    ? AppColors.fg
                    : isDone
                        ? _dim(.55)
                        : _dim(.28),
              )),
        ],
      ),
    );
  }
}
