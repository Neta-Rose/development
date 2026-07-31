import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../home/data/catalog_repository.dart';
import '../domain/portion.dart';
import 'ai_capture_pane.dart';
import 'ai_plate_list.dart';
import 'ai_providers.dart';
import 'camera_providers.dart';
import 'food_detail_screen.dart';
import 'portion_pad.dart';
import 'quick_add.dart';
import 'scan_pane.dart';
import 'search_providers.dart';

Color _dim(double a) => AppColors.dim(a);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.hour});

  /// Hour of today to log into, from the timeline's `+`. Null logs at now.
  final int? hour;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

/// The design's four header toggles, in the design's order. The mode a fresh
/// screen opens in is [_Mode.search], not the first of these.
enum _Mode { scan, search, ai, quick }

/// Let a test find a toggle without matching on an icon.
const aiToggleKey = Key('ai-mode-toggle');
const scanToggleKey = Key('scan-mode-toggle');

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  _Mode _mode = _Mode.search;

  /// The food whose portion pad is open, if any. The pad *replaces* the search
  /// field rather than sitting over it: dropping the focused field out of the
  /// tree is what retracts the OS keyboard, and its `autofocus` brings the
  /// keyboard back when the pad closes.
  FoodHit? _editing;

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
          Expanded(child: _body(hits, query, results.isLoading)),
        ],
      ),
    );
  }

  Widget _body(List<FoodHit> hits, String query, bool loading) {
    switch (_mode) {
      case _Mode.search:
        return Column(
          children: [
            Expanded(child: _results(hits, query, loading: loading)),
            SafeArea(top: false, child: _bottom(query)),
          ],
        );
      case _Mode.quick:
        return QuickAdd(
          onAdd: (food, portion) =>
              ref.read(batchProvider.notifier).add(BatchItem(food, portion)),
        );
      case _Mode.ai:
        // The camera pane is fixed-height and the plate scrolls under it, which
        // is the design's layout. The pane owns its own confirm control, so a
        // failed detection never hides the way out.
        return Column(
          children: [
            AiCapturePane(onLogged: _logBatch),
            const Expanded(child: AiPlateList()),
          ],
        );
      case _Mode.scan:
        return ScanPane(
          onSearchInstead: () => setState(() => _mode = _Mode.search),
        );
    }
  }

  Widget _header(List<BatchItem> batch) {
    double sum(double Function(BatchItem) f) =>
        batch.fold(0.0, (a, b) => a + f(b));
    final staged = batch.isNotEmpty;
    // Hidden rather than disabled when there is no plate-detect service in this
    // build or no camera on the device: a toggle that always fails is worse than
    // a mode the user never learns about. Scan asks the narrower question — it
    // reads a barcode, so it wants a camera and nothing else.
    final aiAvailable = ref.watch(aiAvailableProvider).value ?? false;
    final cameraAvailable = ref.watch(cameraAvailableProvider).value ?? false;
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
                macros(
                  sum((b) => b.protein),
                  sum((b) => b.carbs),
                  sum((b) => b.fat),
                  size: 10,
                ),
              ],
            ),
          ),
          if (cameraAvailable) ...[
            _modeButton(Icons.qr_code_scanner, _Mode.scan, key: scanToggleKey),
            const SizedBox(width: 8),
          ],
          _modeButton(Icons.search, _Mode.search),
          if (aiAvailable) ...[
            const SizedBox(width: 8),
            _modeButton(Icons.auto_awesome, _Mode.ai, key: aiToggleKey),
          ],
          const SizedBox(width: 8),
          _modeButton(Icons.bolt, _Mode.quick),
          const SizedBox(width: 4),
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

  Widget _modeButton(IconData icon, _Mode mode, {Key? key}) {
    final on = _mode == mode;
    return GestureDetector(
      key: key,
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _mode = mode);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: on ? AppColors.amber : AppColors.badgeBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: on ? AppColors.bg : _dim(.6)),
      ),
    );
  }

  /// The detail screen, opened on a hit or on a chip already staged. Pushed on
  /// the plain navigator rather than routed: a [FoodHit] and a [BatchItem] are
  /// object identities, not something a URL can carry.
  void _openDetail(FoodHit food, {BatchItem? editing}) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          FoodDetailScreen(food: food, editing: editing, hour: widget.hour),
    ));
  }

  Future<void> _logBatch() async {
    await ref.read(batchProvider.notifier).logAll(hour: widget.hour);
    // Releases the batch's photos and its corrections. The provider is
    // auto-disposed on pop as well; this makes the release explicit at the moment
    // the batch is over rather than a side effect of navigation.
    if (mounted) ref.read(aiCaptureProvider.notifier).reset();
    if (mounted) Navigator.of(context).pop();
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
              child: Text(
                  _mode == _Mode.ai
                      ? 'plate is empty — shoot to detect foods'
                      : 'batch is empty — tap or swipe items to add',
                  style: TextStyle(fontSize: 10, color: _dim(.3))),
            )
          : _chips(batch),
    );
  }

  /// Removes a chip. An item the detector staged also has its instance id
  /// recorded, so the next shot's reply does not put it back on the plate the
  /// user just took it off.
  void _removeChip(BatchItem item) {
    ref.read(batchProvider.notifier).remove(item);
    final ai = item.ai;
    if (ai != null) {
      ref.read(aiCaptureProvider.notifier).markRemoved(ai.instanceId);
    }
  }

  Widget _chips(List<BatchItem> batch) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      itemCount: batch.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, i) => _chip(batch[i]),
    );
  }

  Widget _chip(BatchItem item) {
    // Dismissible gives the design's swipe-up-to-remove — including the drag
    // threshold — for free.
    //
    // The key must be the item's own identity: a positional one lets the
    // survivor of two same-named chips inherit the dismissed chip's state and
    // render as already gone.
    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.up,
      onDismissed: (_) => _removeChip(item),
      background: const SizedBox.shrink(),
      child: GestureDetector(
        // Reopens the amount rather than staging a second one — the detail
        // screen replaces this item in place.
        onTap: () => _openDetail(item.food, editing: item),
        behavior: HitTestBehavior.opaque,
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
              item.food.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.5, color: _dim(.6)),
            ),
            const SizedBox(height: 2),
            macros(item.protein, item.carbs, item.fat, size: 8),
          ],
        ),
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
                Text('tap portion pill to edit grams',
                    style: TextStyle(fontSize: 9, color: _dim(.28))),
              ],
            ),
          );
        }
        // The row hands back which food it is on: spinning its preparation
        // wheel swaps the hit under it, and boiled onion is not raw onion.
        return _ResultRow(
          food: hits[i - 1],
          editing: _editing,
          onAdd: (food, portion) =>
              ref.read(batchProvider.notifier).add(BatchItem(food, portion)),
          onOpen: _openDetail,
          onEdit: (food) {
            setState(() => _editing = food);
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  Widget _bottom(String query) {
    final editing = _editing;
    if (editing == null) return _searchField(query);
    return PortionPad(
      // Keyed so switching rows resets the typed amount instead of carrying it.
      key: ObjectKey(editing),
      food: editing,
      onAdd: (portion) {
        ref.read(batchProvider.notifier).add(BatchItem(editing, portion));
        setState(() => _editing = null);
      },
      onClose: () => setState(() => _editing = null),
      onLogAll: _logBatch,
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

/// A search hit. Dragging it right picks a portion and stages it, dragging up
/// or down while held multiplies it; a tap opens the food's detail screen. The
/// portion pill opens the pad in place, for an amount too exact to swipe to
/// but not worth leaving the list for.
///
/// The horizontal recognizer reads both axes off `globalPosition` — its own
/// `delta` carries the primary axis only — so a vertical drag still scrolls the
/// list until a horizontal one wins the arena.
///
/// An item with more than one preparation also carries a wheel. Spinning it
/// replaces the whole food the row stands for — its macros, its serving, its
/// swipe ladder and what a tap opens — because each preparation is its own
/// catalog food.
class _ResultRow extends StatefulWidget {
  const _ResultRow({
    required this.food,
    required this.editing,
    required this.onAdd,
    required this.onOpen,
    required this.onEdit,
  });

  final FoodHit food;

  /// The food the portion pad is open on, so a row that spins while it is *its*
  /// pad can carry it to the new preparation instead of leaving it amounting a
  /// food no longer on screen.
  final FoodHit? editing;
  final void Function(FoodHit, Portion) onAdd;
  final void Function(FoodHit) onOpen;
  final void Function(FoodHit) onEdit;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  Offset _start = Offset.zero;
  Offset _delta = Offset.zero;

  /// Which preparation the wheel rests on. Starts on the item's default, which
  /// is the food the hit itself already describes.
  late int _prep = widget.food.prepIndex;

  /// The food this row currently stands for.
  FoodHit get _food =>
      widget.food.preps.isEmpty ? widget.food : widget.food.preps[_prep];

  Portion? get _picked => portionForDrag(
        _delta.dx,
        _delta.dy,
        unitG: _food.unitG,
        unitLabel: _food.unitLabel,
      );

  void _reset() => setState(() => _delta = Offset.zero);

  @override
  Widget build(BuildContext context) {
    final food = _food;
    final picked = _picked;
    // Before a drag the row reads as one serving, which is also what the
    // detail screen opens on.
    final shown = picked ?? wholeServing(food.unitG, food.unitLabel);
    final shift = _delta.dx > 0 ? (18 + _delta.dx * .35).clamp(0.0, 92.0) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onOpen(food),
      onHorizontalDragStart: (d) => setState(() {
        _start = d.globalPosition;
        _delta = Offset.zero;
      }),
      onHorizontalDragUpdate: (d) =>
          setState(() => _delta = d.globalPosition - _start),
      onHorizontalDragEnd: (_) {
        if (picked != null) widget.onAdd(food, picked);
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
                Text(food.displayName,
                    style: const TextStyle(fontSize: 13, color: AppColors.fg)),
                const SizedBox(height: 3),
                macroLine(
                  shown.scale(food.kcal100g),
                  shown.scale(food.protein100g),
                  shown.scale(food.carb100g),
                  shown.scale(food.fat100g),
                ),
                const SizedBox(height: 6),
                _pill(food),
              ],
            ),
          ),
          if (widget.food.preps.isNotEmpty) ...[
            const SizedBox(width: 10),
            _PrepWheel(
              preps: widget.food.preps,
              index: _prep,
              onPick: (i) {
                final hadPad = identical(widget.editing, _food);
                // The new preparation brings its own serving, so the ladder
                // starts over rather than carrying a half-finished swipe of the
                // old food's grams.
                setState(() {
                  _prep = i;
                  _delta = Offset.zero;
                });
                // Re-keys the pad on the new food, which resets the amount
                // typed into it — the old grams were an amount of the old
                // serving.
                if (hadPad) widget.onEdit(_food);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// The row's default amount, and the way into the pad. Its own detector wins
  /// the arena against the row's, so tapping it doesn't also stage a serving.
  Widget _pill(FoodHit food) {
    return GestureDetector(
      onTap: () => widget.onEdit(food),
      child: Container(
        // Vertical padding rather than a height: a Container with an alignment
        // grows to its constraints, and this one has to hug its text.
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: .12),
          border: Border.all(color: AppColors.amber.withValues(alpha: .45)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(_serving(food),
            style: const TextStyle(fontSize: 9.5, color: AppColors.amber)),
      ),
    );
  }

  /// Portion labels are measures of *one*, so this reads `1 × label (n g)`.
  String _serving(FoodHit food) {
    final label = food.unitLabel;
    final g = food.unitG.round();
    return label == null ? '$g g' : '1 × $label ($g g)';
  }
}

/// The preparation wheel: one label deep, spun by dragging it or tapped for the
/// next one. Shown only where there is a choice to make, which is 830 of the
/// catalogue's 6,809 items.
///
/// Its own recognizer wins the arena against both the list's scroll and the
/// row's swipe, because the innermost one in the tree claims the pointer first.
/// `DragStartBehavior.down` measures from where the finger landed rather than
/// from where the drag was recognised, so the 18 px of touch slop counts towards
/// the spin instead of being spent before it starts.
class _PrepWheel extends StatefulWidget {
  const _PrepWheel({
    required this.preps,
    required this.index,
    required this.onPick,
  });

  final List<FoodHit> preps;
  final int index;
  final void Function(int) onPick;

  @override
  State<_PrepWheel> createState() => _PrepWheelState();
}

class _PrepWheelState extends State<_PrepWheel> {
  double _startY = 0;
  double _dy = 0;
  bool _dragging = false;

  void _end() {
    widget.onPick(prepForDrag(_dy, widget.index, widget.preps.length));
    setState(() {
      _dragging = false;
      _dy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The list may lead the finger by most of a row, but never by a whole one:
    // past that the label being dragged towards would leave the window before it
    // has been chosen.
    final dy = _dy.clamp(-prepRowPx * 0.9, prepRowPx * 0.9);

    return GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      onTap: () =>
          widget.onPick(prepForDrag(0, widget.index, widget.preps.length)),
      onVerticalDragStart: (d) => setState(() {
        _dragging = true;
        _startY = d.globalPosition.dy;
        _dy = 0;
      }),
      onVerticalDragUpdate: (d) =>
          setState(() => _dy = d.globalPosition.dy - _startY),
      onVerticalDragEnd: (_) => _end(),
      onVerticalDragCancel: () => setState(() {
        _dragging = false;
        _dy = 0;
      }),
      child: Container(
        width: 92,
        height: prepRowPx,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: .07),
          border: Border.all(color: AppColors.amber.withValues(alpha: .4)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              // No transition while the finger is down: the list has to track
              // it, not chase it.
              duration:
                  _dragging ? Duration.zero : const Duration(milliseconds: 220),
              curve: const Cubic(0.2, 0.8, 0.3, 1),
              left: 0,
              right: 0,
              top: -widget.index * prepRowPx + dy,
              child: Column(
                children: [
                  for (final (i, prep) in widget.preps.indexed)
                    SizedBox(
                      height: prepRowPx,
                      child: Center(
                        child: Text(
                          prep.prepLabel ?? '',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 0.2,
                            fontWeight: i == widget.index
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                i == widget.index ? AppColors.amber : _dim(.4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 5,
              top: 0,
              bottom: 0,
              child: Icon(Icons.unfold_more,
                  size: 11, color: AppColors.amber.withValues(alpha: .5)),
            ),
          ],
        ),
      ),
    );
  }
}
