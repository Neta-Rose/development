/// Small shared pieces of the coach UI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../search/domain/picked_food.dart';
import '../../data/coach_repository.dart';
import '../../domain/candidate.dart';
import '../../domain/suggest.dart';
import '../coach_providers.dart';

Color _dim(double a) => AppColors.dim(a);

/// `1240` -> `1,240`. The header number is the one place the app shows a
/// thousands separator, so this stays local rather than becoming a dependency.
String formatThousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// P/C/F, in that order, always coloured, always adjacent, never worded.
class MacroTriple extends StatelessWidget {
  const MacroTriple({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.size = 11,
  });

  final double protein, carbs, fat;
  final double size;

  @override
  Widget build(BuildContext context) {
    TextSpan s(String t, Color c) =>
        TextSpan(text: t, style: TextStyle(color: c));
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: size, color: _dim(.5)),
        children: [
          s('${protein.round()}P', AppColors.protein),
          const TextSpan(text: ' '),
          s('${carbs.round()}C', AppColors.carbs),
          const TextSpan(text: ' '),
          s('${fat.round()}F', AppColors.fat),
        ],
      ),
    );
  }
}

/// Read-only proof of one field the engine actually receives.
class ContextChip extends StatelessWidget {
  const ContextChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.badgeBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, color: _dim(.75))),
      );
}

/// A 44px tray tile with its portion pill.
class TrayTile extends StatelessWidget {
  const TrayTile({super.key, required this.candidate, this.size = 44});

  final Candidate candidate;
  final double size;

  /// The pill's content, in one place.
  ///
  /// Open question from the spec, deliberately left switchable: a confident
  /// item shows grams while a shaky one shows its confidence, so the same pill
  /// carries two meanings. The alternative is always showing grams and letting
  /// the amber border carry uncertainty alone — that is this function returning
  /// `'${grams}g'` unconditionally.
  static String pillText(Candidate c) {
    if (c.isUnresolved) return '?';
    final conf = c.confidence;
    if (conf != null && conf < 0.8) return conf.toStringAsFixed(2);
    return '${c.grams.round()}g';
  }

  @override
  Widget build(BuildContext context) {
    final uncertain =
        candidate.isUnresolved || (candidate.confidence ?? 1) < 0.8;
    return Opacity(
      opacity: candidate.checked ? 1 : .35,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.tile,
                border: Border.all(
                    color: uncertain ? AppColors.amber : _dim(.09)),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(candidate.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
            Transform.translate(
              offset: const Offset(0, -8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  border: Border.all(color: _dim(.18)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(pillText(candidate),
                    style: const TextStyle(fontSize: 8, color: AppColors.fg)),
              ),
            ),
            Text(
              candidate.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8.5, color: _dim(.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed empty well. Flutter has no dashed border, so it is painted.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({required this.color, this.radius = 12});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    // Walk the outline, drawing 5px on / 4px off.
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, (d + 5).clamp(0, metric.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color;
}

/// The footer: what was held back, whether the answer was degraded, and the
/// debugging channel.
class ResultsFooter extends StatelessWidget {
  const ResultsFooter({super.key, required this.response});

  final SuggestResponse response;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (response.degraded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 13, color: AppColors.amber),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    response.degradedReason.isEmpty
                        ? 'Answered on partial scoring — the time budget ran out.'
                        : response.degradedReason,
                    style: const TextStyle(
                        fontSize: 10, height: 1.45, color: AppColors.amber),
                  ),
                ),
              ],
            ),
          ),
        // Constraints are hard, and the user is told. Rendered whenever the
        // engine reports anything held back.
        if (response.excluded.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.filter_alt_outlined, size: 13, color: _dim(.45)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  response.excluded
                      .map((e) => '${e.count} ${e.reason}')
                      .join(' · '),
                  style: TextStyle(fontSize: 10, height: 1.45, color: _dim(.45)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        // Kept through MVP: this is the debugging channel, and the hook for
        // replaying a run through the engine's /v1/explain endpoint.
        Text(
          '${response.shortRulebook} · ${response.contextSnapshotId} · '
          '${response.totalMs} ms',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: _dim(.28)),
        ),
      ],
    );
  }
}

/// Opens the app's existing food search and folds whatever comes back into the
/// coach tray.
///
/// The search screen is reused rather than reimplemented: it is pushed in pick
/// mode, where the check button pops with the staged batch instead of writing
/// it to the diary. See `PickedFood` in the search feature.
///
/// [replaceIndex] resolves an unresolved tray row in place instead of appending.
Future<void> openCoachSearch(
  BuildContext context,
  WidgetRef ref, {
  String? prefill,
  int? replaceIndex,
}) async {
  final picked = await context.push<List<PickedFood>>(
    Uri(path: '/coach/search', queryParameters: {
      if (prefill != null && prefill.isNotEmpty) 'q': prefill,
    }).toString(),
  );
  if (picked == null || picked.isEmpty) return;

  final repo = await ref.read(coachRepositoryProvider.future);
  final tray = ref.read(trayProvider.notifier);

  for (final p in picked) {
    // Re-read the full per-100 g vector: a search hit carries only the four
    // list macros, and the engine wants all eight canonical keys.
    final food = p.foodId == null ? null : await repo.resolveById(p.foodId!);
    if (replaceIndex != null && food != null) {
      tray.resolveAt(replaceIndex, food);
      continue;
    }
    tray.addAll([
      Candidate(
        detectedName: p.name,
        // Hand-picked, so there is no detection uncertainty to report.
        amountHintG: p.grams,
        resolved: food,
      )
    ]);
  }
}
