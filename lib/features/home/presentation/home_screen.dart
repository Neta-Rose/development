import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/database/database.dart';
import '../domain/daily_summary.dart';
import 'home_providers.dart';
import 'widgets/macro_bar.dart';

Color _dim(double a) => AppColors.dim(a);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailySummaryProvider);
    final hours = ref.watch(timelineProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _header(summary),
          Expanded(child: _timeline(hours)),
          _searchBar(),
          _bottomNav(),
        ],
      ),
    );
  }

  Widget _header(DailySummary s) {
    const targets = MacroTargets.defaults;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: '${s.kcal}',
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.5,
                      height: 1,
                      color: AppColors.fg),
                  children: [
                    TextSpan(
                      text: ' / ${targets.kcal}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _dim(.45)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text('KCAL',
                  style: TextStyle(
                      fontSize: 9, letterSpacing: 1.5, color: _dim(.45))),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Row(
                children: [
                  _counter('PRO', s.protein, targets.protein, AppColors.protein),
                  const SizedBox(width: 14),
                  _counter('CARBS', s.carbs, targets.carbs, AppColors.carbs),
                  const SizedBox(width: 14),
                  _counter('FAT', s.fat, targets.fat, AppColors.fat),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _counter(String label, int v, int t, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$v / ${t}g', style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 9, letterSpacing: 1.5, color: _dim(.45))),
          const SizedBox(height: 5),
          MacroBar(value: v, target: t, color: color, height: 2),
        ],
      ),
    );
  }

  Widget _timeline(List<TimelineHour> hours) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Stack(
        children: [
          Positioned(
              left: 37,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: _dim(.1))),
          ListView(
            padding: EdgeInsets.zero,
            children: [for (final hour in hours) _hourRow(hour)],
          ),
        ],
      ),
    );
  }

  Widget _hourRow(TimelineHour hour) {
    final now = hour.kind == HourKind.now;
    final plan = hour.kind == HourKind.plan;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 7, 20, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: now
                      ? AppColors.amber
                      : plan
                          ? AppColors.bg
                          : AppColors.badgeBg,
                  border: plan ? Border.all(color: _dim(.18)) : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hour.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1,
                    fontWeight: now ? FontWeight.w600 : FontWeight.w400,
                    color: now
                        ? AppColors.bg
                        : plan
                            ? _dim(.4)
                            : AppColors.fg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: AppColors.badgeBg, shape: BoxShape.circle),
                child: Icon(Icons.add, size: 12, color: _dim(.55)),
              ),
              const Spacer(),
              Text(
                hour.totals,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: now ? 1.5 : 0,
                  color: now
                      ? AppColors.amber
                      : plan
                          ? _dim(.3)
                          : _dim(.5),
                ),
              ),
            ],
          ),
          for (final item in hour.entries) _foodCard(item),
        ],
      ),
    );
  }

  Widget _foodCard(TimelineForDayResult item) {
    return Container(
      margin: const EdgeInsets.only(left: 34, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: _dim(.05),
        border: Border.all(color: _dim(.09)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            // 1 of 13,694 catalog foods has no emoji, and custom foods may
            // clear theirs.
            child: Text(item.emoji ?? '🍽️',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.35, color: AppColors.fg)),
                const SizedBox(height: 3),
                if (item.kcal != null)
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 10, color: _dim(.5)),
                      children: [
                        TextSpan(text: '${item.kcal!.round()} kcal · '),
                        TextSpan(
                            text: '${item.protein?.round() ?? 0}P',
                            style: const TextStyle(color: AppColors.protein)),
                        const TextSpan(text: ' '),
                        TextSpan(
                            text: '${item.carb?.round() ?? 0}C',
                            style: const TextStyle(color: AppColors.carbs)),
                        const TextSpan(text: ' '),
                        TextSpan(
                            text: '${item.fat?.round() ?? 0}F',
                            style: const TextStyle(color: AppColors.fat)),
                        TextSpan(text: ' · ${_serving(item)}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Portion labels are measures of *one*, so this renders `qty × label` and
  /// never assumes the label carries a count. Falls back to raw grams, which is
  /// the authoritative amount either way.
  String _serving(TimelineForDayResult item) {
    final qty = item.portionQty;
    final label = item.portionLabel;
    if (qty == null || label == null) return '${item.grams.round()} g';
    final n = qty == qty.roundToDouble() ? qty.round().toString() : '$qty';
    return '$n × $label';
  }

  // Search and bottom nav are static placeholders — their features aren't
  // built yet.
  Widget _searchBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _dim(.04),
        border: Border.all(color: _dim(.22)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 17, color: _dim(.45)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('search foods…',
                style: TextStyle(fontSize: 12.5, color: _dim(.45))),
          ),
          Icon(CupertinoIcons.barcode, size: 18, color: _dim(.45)),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 26),
      decoration: BoxDecoration(
        color: AppColors.navBg,
        border: Border(top: BorderSide(color: _dim(.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.receipt_long_outlined, 'today', active: true),
          _navItem(Icons.bar_chart, 'trends'),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
                color: AppColors.amber, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 20, color: AppColors.bg),
          ),
          _navItem(Icons.auto_awesome_outlined, 'coach'),
          _navItem(Icons.person_outline, 'you'),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool active = false}) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: active ? AppColors.fg : _dim(.4)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: active ? AppColors.fg : _dim(.45))),
        ],
      ),
    );
  }
}
