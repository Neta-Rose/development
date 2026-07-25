import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../home/data/catalog_repository.dart';
import '../domain/portion.dart';
import 'search_providers.dart';

Color _dim(double a) => AppColors.dim(a);

/// A food's own serving weight. `serving_g IS NULL` means "no defined serving —
/// treat it as per 100 g", which is why the label goes null with it.
double _unitG(FoodHit f) => f.servingG ?? 100;
String? _unitLabel(FoodHit f) => f.servingG == null ? null : f.servingLabel;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batch = ref.watch(batchProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final results = ref.watch(searchResultsProvider);
    final hits = results.value ?? const <FoodHit>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _header(batch),
          _chipStrip(batch),
          Expanded(child: _results(hits, query, loading: results.isLoading)),
          SafeArea(top: false, child: _searchField(query)),
        ],
      ),
    );
  }

  // ponytail: the design's scan / AI-plate / quick-add mode toggles live here,
  // left out until those modes exist rather than rendered as dead buttons.
  Widget _header(List<BatchItem> batch) {
    double sum(double Function(BatchItem) f) =>
        batch.fold(0.0, (a, b) => a + f(b));
    final staged = batch.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 64, 14, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: AppColors.badgeBg, shape: BoxShape.circle),
              child: Icon(Icons.close, size: 15, color: AppColors.fg),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: '${sum((b) => b.kcal).round()}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        height: 1,
                        color: AppColors.fg),
                    children: [
                      TextSpan(
                        text: ' kcal',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: _dim(.45)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _macros(
                  sum((b) => b.protein),
                  sum((b) => b.carbs),
                  sum((b) => b.fat),
                  size: 10,
                ),
              ],
            ),
          ),
          Opacity(
            opacity: staged ? 1 : .3,
            child: GestureDetector(
              onTap: staged ? _logBatch : null,
              child: Container(
                width: 44,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, size: 18, color: AppColors.bg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logBatch() async {
    await ref.read(batchProvider.notifier).logAll();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _macros(double p, double c, double f, {required double size}) {
    TextSpan span(String s, Color color) =>
        TextSpan(text: s, style: TextStyle(color: color));
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: size, color: _dim(.5)),
        children: [
          span('${p.round()}P', AppColors.protein),
          const TextSpan(text: ' '),
          span('${c.round()}C', AppColors.carbs),
          const TextSpan(text: ' '),
          span('${f.round()}F', AppColors.fat),
        ],
      ),
    );
  }

  Widget _chipStrip(List<BatchItem> batch) {
    return Container(
      // Tall enough for the tallest chip: 46 tile + the pill overlapping it,
      // the name and the macro line.
      height: batch.isEmpty ? 34 : 112,
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: _dim(.08)))),
      alignment: Alignment.centerLeft,
      child: batch.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('batch is empty — tap or swipe items to add',
                  style: TextStyle(fontSize: 10, color: _dim(.3))),
            )
          : _chips(batch),
    );
  }

  Widget _chips(List<BatchItem> batch) {
    return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      itemCount: batch.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, i) => _chip(batch[i], i),
    );
  }

  Widget _chip(BatchItem item, int i) {
    // Dismissible gives the design's swipe-up-to-remove — including the drag
    // threshold — for free.
    return Dismissible(
      key: ValueKey('$i-${item.food.name}'),
      direction: DismissDirection.up,
      onDismissed: (_) => ref.read(batchProvider.notifier).removeAt(i),
      background: const SizedBox.shrink(),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.tile,
                border: Border.all(color: _dim(.09)),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(item.food.emoji ?? '🍽️',
                  style: const TextStyle(fontSize: 22)),
            ),
            Transform.translate(
              offset: const Offset(0, -13),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  border: Border.all(color: _dim(.18)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.portion.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.fg),
                ),
              ),
            ),
            Text(
              item.food.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.5, color: _dim(.6)),
            ),
            const SizedBox(height: 2),
            _macros(item.protein, item.carbs, item.fat, size: 8),
          ],
        ),
      ),
    );
  }

  Widget _results(List<FoodHit> hits, String query, {required bool loading}) {
    if (hits.isEmpty && !loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Text(
          query.isEmpty
              ? 'nothing logged yet — search to add something'
              : 'no match — try fewer letters',
          style: TextStyle(fontSize: 11, color: _dim(.4)),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: hits.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  query.isEmpty ? 'RECENT' : 'RESULTS · ${hits.length}',
                  style: TextStyle(
                      fontSize: 9.5, letterSpacing: 1.5, color: _dim(.45)),
                ),
                Text('swipe → for portion',
                    style: TextStyle(fontSize: 9, color: _dim(.28))),
              ],
            ),
          );
        }
        final food = hits[i - 1];
        return _ResultRow(
          food: food,
          onAdd: (portion) =>
              ref.read(batchProvider.notifier).add(BatchItem(food, portion)),
        );
      },
    );
  }

  Widget _searchField(String query) {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _dim(.05),
        border: Border.all(color: AppColors.amber),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 17, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.amber,
              cursorWidth: 2,
              style: const TextStyle(fontSize: 13, color: AppColors.fg),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'search foods…',
                hintStyle: TextStyle(fontSize: 13, color: _dim(.35)),
              ),
              onChanged: ref.read(searchQueryProvider.notifier).set,
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).set('');
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: AppColors.badgeBg, shape: BoxShape.circle),
                child: Icon(Icons.close, size: 10, color: _dim(.6)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A search hit. Dragging it right picks a portion, dragging up or down while
/// held multiplies it; a tap adds one serving.
///
/// The horizontal recognizer reads both axes off `globalPosition` — its own
/// `delta` carries the primary axis only — so a vertical drag still scrolls the
/// list until a horizontal one wins the arena.
class _ResultRow extends StatefulWidget {
  const _ResultRow({required this.food, required this.onAdd});

  final FoodHit food;
  final void Function(Portion) onAdd;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  Offset _start = Offset.zero;
  Offset _delta = Offset.zero;

  Portion? get _picked => portionForDrag(
        _delta.dx,
        _delta.dy,
        unitG: _unitG(widget.food),
        unitLabel: _unitLabel(widget.food),
      );

  void _reset() => setState(() => _delta = Offset.zero);

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final picked = _picked;
    // Before a drag the row reads as one serving, which is also what a tap adds.
    final shown = picked ?? wholeServing(_unitG(food), _unitLabel(food));
    final shift = _delta.dx > 0 ? (18 + _delta.dx * .35).clamp(0.0, 92.0) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onAdd(shown),
      onHorizontalDragStart: (d) => setState(() {
        _start = d.globalPosition;
        _delta = Offset.zero;
      }),
      onHorizontalDragUpdate: (d) =>
          setState(() => _delta = d.globalPosition - _start),
      onHorizontalDragEnd: (_) {
        if (picked != null) widget.onAdd(picked);
        _reset();
      },
      onHorizontalDragCancel: _reset,
      child: Container(
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: _dim(.07)))),
        child: Stack(
          children: [
            if (picked != null)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: _delta.dx.clamp(0.0, 340.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.amber.withValues(alpha: .3),
                      AppColors.amber.withValues(alpha: .03),
                    ]),
                  ),
                ),
              ),
            if (picked != null)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: shift,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(picked.label,
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            color: AppColors.amber)),
                    Text('${picked.scale(food.kcal100g).round()} kcal',
                        maxLines: 1,
                        style: const TextStyle(
                            fontSize: 8.5, color: AppColors.amber)),
                  ],
                ),
              ),
            Transform.translate(
              offset: Offset(shift, 0),
              child: _content(food, shown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(FoodHit food, Portion shown) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(food.emoji ?? '🍽️',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: const TextStyle(fontSize: 13, color: AppColors.fg)),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 10, color: _dim(.5)),
                    children: [
                      TextSpan(
                          text: '${shown.scale(food.kcal100g).round()} kcal · '),
                      TextSpan(
                          text: '${shown.scale(food.protein100g).round()}P',
                          style: const TextStyle(color: AppColors.protein)),
                      const TextSpan(text: ' '),
                      TextSpan(
                          text: '${shown.scale(food.carb100g).round()}C',
                          style: const TextStyle(color: AppColors.carbs)),
                      const TextSpan(text: ' '),
                      TextSpan(
                          text: '${shown.scale(food.fat100g).round()}F',
                          style: const TextStyle(color: AppColors.fat)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(_serving(food),
                    style: TextStyle(fontSize: 10, color: _dim(.35))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Portion labels are measures of *one*, so this reads `1 × label (n g)`.
  String _serving(FoodHit food) {
    final label = _unitLabel(food);
    final g = _unitG(food).round();
    return label == null ? '$g g' : '1 × $label ($g g)';
  }
}
