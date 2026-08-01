import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../home/presentation/widgets/macro_bar.dart';
import '../../domain/suggest.dart';
import 'coach_bits.dart';

Color _dim(double a) => AppColors.dim(a);

/// One ranked plate.
///
/// The score sits in the slot the emoji occupies in the food list — 32px, left
/// aligned — so rank reads where the eye already scans. Rank 1 is marked with a
/// 2px amber left border rather than a card: the app has no card style and
/// introducing one here would break the list rhythm.
class SuggestionRow extends StatelessWidget {
  const SuggestionRow({
    super.key,
    required this.suggestion,
    required this.expanded,
    required this.onTap,
  });

  final Suggestion suggestion;
  final bool expanded;
  final VoidCallback onTap;

  bool get _isTop => suggestion.rank == 1;

  @override
  Widget build(BuildContext context) {
    final n = suggestion.nutrients;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _dim(.07)),
            left: _isTop
                ? const BorderSide(color: AppColors.amber, width: 2)
                : BorderSide.none,
          ),
        ),
        padding: EdgeInsets.fromLTRB(_isTop ? 10 : 0, 12, 0, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${suggestion.score100}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: _isTop ? AppColors.amber : _dim(.75),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.title,
                          style: const TextStyle(
                              fontSize: 13, height: 1.35, color: AppColors.fg)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('${n.kcal.round()} kcal · ',
                            style:
                                TextStyle(fontSize: 11, color: _dim(.5))),
                        MacroTriple(
                            protein: n.proteinG,
                            carbs: n.carbsG,
                            fat: n.fatG,
                            size: 11),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            if (expanded) _Body(suggestion: suggestion),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    // The engine explains itself: these sentences are joined verbatim and the
    // UI never writes a word of them. Empty means nothing renders.
    final explanation = suggestion.contributions
        .map((c) => c.explain.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');

    return Padding(
      // Indented to clear the score column.
      padding: const EdgeInsets.fromLTRB(40, 14, 0, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in suggestion.contributions)
            _SignalBar(contribution: c, weak: suggestion.isWeak(c)),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(explanation,
                style: TextStyle(fontSize: 11, height: 1.55, color: _dim(.75))),
          ],
          const SizedBox(height: 14),
          Row(children: [
            _Action(
              icon: Icons.check,
              filled: true,
              // ponytail: logging a plate into the day is not wired yet.
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _Action(
              icon: Icons.thumb_down_outlined,
              filled: false,
              // ponytail: dismissal is not fed back into ranking yet.
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }
}

/// One signal's contribution: label, track, raw value.
///
/// The fill colour is computed from `weighted` relative to the strongest
/// contribution in this suggestion — never hardcoded per signal, so a signal
/// that matters here and not there renders differently in each.
class _SignalBar extends StatelessWidget {
  const _SignalBar({required this.contribution, required this.weak});

  final Contribution contribution;
  final bool weak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(contribution.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9, letterSpacing: 1.5, color: _dim(.45))),
          ),
          Expanded(
            // The app's own bar, reused: raw is 0–1, so it scales to /100.
            child: MacroBar(
              value: (contribution.raw * 100).round(),
              target: 100,
              color: weak ? _dim(.35) : AppColors.amber,
              height: 3,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(contribution.raw.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: _dim(.45))),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(
      {required this.icon, required this.filled, required this.onTap});

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filled ? AppColors.amber : Colors.transparent,
            border: filled ? null : Border.all(color: _dim(.22)),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 15, color: filled ? AppColors.bg : _dim(.55)),
        ),
      );
}
