import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../data/detection_source.dart';
import '../domain/candidate.dart';
import 'coach_providers.dart';
import 'widgets/coach_bits.dart';

Color _dim(double a) => AppColors.dim(a);

/// Screen 2: shoot, review and edit in one place.
///
/// The camera is never dismissed to edit. At the peek position it is
/// full-bleed; expanded, it compresses to a live strip at the top with its own
/// mini shutter. Another photo is always one tap away from either position.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  static const _peek = 0.30;
  static const _editing = 0.78;

  final _sheet = DraggableScrollableController();
  CameraController? _camera;
  bool _cameraFailed = false;
  int _photos = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw CameraException('none', 'no cameras');
      final c = CameraController(cams.first, ResolutionPreset.medium,
          enableAudio: false);
      await c.initialize();
      if (!mounted) return;
      setState(() => _camera = c);
    } catch (_) {
      // A device or emulator without a usable camera must still be able to
      // build a tray by hand, so this degrades to a well rather than an error.
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _sheet.dispose();
    super.dispose();
  }

  void _animateTo(double size) => _sheet.animateTo(size,
      duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);

  /// Takes a shot and folds its detections into the tray.
  ///
  /// The sheet deliberately does **not** expand on a normal capture — shooting
  /// four photos in a row must not fight the user. The one exception is an item
  /// that failed to resolve: that is the only case where something must be
  /// fixed before running, so surfacing it immediately saves a wasted trip.
  Future<void> _shoot() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _camera?.takePicture();
    } catch (_) {
      // A failed shutter should not cost the detections; carry on.
    }
    final source = await ref.read(detectionSourceProvider.future);
    final found = await source.detect();
    if (!mounted) return;
    ref.read(trayProvider.notifier).addAll(found);
    setState(() {
      _photos++;
      _busy = false;
    });
    if (found.any((c) => c.isUnresolved)) _animateTo(_editing);
  }

  @override
  Widget build(BuildContext context) {
    final tray = ref.watch(trayProvider);
    return Scaffold(
      backgroundColor: AppColors.cameraBg,
      body: Stack(
        children: [
          Positioned.fill(child: _preview()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _topBar()),
          ),
          DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize: _peek,
            minChildSize: _peek,
            maxChildSize: _editing,
            snap: true,
            snapSizes: const [_peek, _editing],
            builder: (context, scrollController) =>
                _Sheet(
              scrollController: scrollController,
              tray: tray,
              photos: _photos,
              sheetController: _sheet,
              onExpand: () => _animateTo(_editing),
              onCollapse: () => _animateTo(_peek),
              onShoot: _shoot,
              cameraPreview: _camera == null ? null : CameraPreview(_camera!),
            ),
          ),
          // The main shutter sits above the sheet at the peek position.
          AnimatedBuilder(
            animation: _sheet,
            builder: (context, _) {
              final size = _sheet.isAttached ? _sheet.size : _peek;
              final t = ((size - _peek) / (_editing - _peek)).clamp(0.0, 1.0);
              if (t > 0.25) return const SizedBox.shrink();
              return Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).size.height * size + 18,
                child: Opacity(
                  opacity: 1 - t * 4,
                  child: Center(child: _Shutter(size: 68, onTap: _shoot)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final cam = _camera;
    if (cam != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: cam.value.previewSize?.height ?? 1080,
          height: cam.value.previewSize?.width ?? 1920,
          child: CameraPreview(cam),
        ),
      );
    }
    return ColoredBox(
      color: AppColors.cameraBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_cameraFailed ? Icons.no_photography_outlined : Icons.camera_alt_outlined,
                size: 28, color: _dim(.28)),
            const SizedBox(height: 10),
            Text(
              _cameraFailed
                  ? 'no camera here — add items by search'
                  : 'starting camera…',
              style: TextStyle(fontSize: 11, color: _dim(.35)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: AppColors.badgeBg, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 15, color: AppColors.fg),
              ),
            ),
          ],
        ),
      );
}

/// The 68px amber ring, and its 46px sibling on the compressed strip.
class _Shutter extends StatelessWidget {
  const _Shutter({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.amber, width: size * .06),
          ),
          child: Center(
            child: Container(
              width: size * .74,
              height: size * .74,
              decoration: const BoxDecoration(
                  color: AppColors.amber, shape: BoxShape.circle),
            ),
          ),
        ),
      );
}

class _Sheet extends ConsumerWidget {
  const _Sheet({
    required this.scrollController,
    required this.tray,
    required this.photos,
    required this.sheetController,
    required this.onExpand,
    required this.onCollapse,
    required this.onShoot,
    required this.cameraPreview,
  });

  final ScrollController scrollController;
  final List<Candidate> tray;
  final int photos;
  final DraggableScrollableController sheetController;
  final VoidCallback onExpand, onCollapse, onShoot;
  final Widget? cameraPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: sheetController,
      builder: (context, _) {
        final size =
            sheetController.isAttached ? sheetController.size : 0.30;
        final expanded = size > 0.5;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: _dim(.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Live strip: the camera keeps running while the list is edited.
              if (expanded && cameraPreview != null)
                _CameraStrip(preview: cameraPreview!, onShoot: onShoot),
              _label(context),
              Expanded(
                child: expanded
                    ? _EditList(
                        scrollController: scrollController, tray: tray)
                    : _peekTray(),
              ),
              // Outside the scrollable, so it stays pinned in both positions
              // instead of vanishing exactly when the list gets long.
              _Cta(tray: tray),
            ],
          ),
        );
      },
    );
  }

  Widget _label(BuildContext context) {
    final expanded =
        (sheetController.isAttached ? sheetController.size : 0.30) > 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The count animates; the sheet does not move.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              '${tray.length} ITEM${tray.length == 1 ? '' : 'S'} · '
              '$photos PHOTO${photos == 1 ? '' : 'S'}',
              key: ValueKey('${tray.length}-$photos'),
              style: TextStyle(
                  fontSize: 10, letterSpacing: 1.5, color: _dim(.45)),
            ),
          ),
          GestureDetector(
            onTap: expanded ? onCollapse : onExpand,
            child: Text(expanded ? 'CAMERA ▼' : 'EDIT LIST ▲',
                style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _peekTray() {
    if (tray.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('nothing yet — take a photo',
            style: TextStyle(fontSize: 10, color: _dim(.3))),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tray.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) => TrayTile(candidate: tray[i]),
    );
  }
}

/// The 132px live strip shown while editing. Still a running preview — leaving
/// the camera is never required to fix the list.
class _CameraStrip extends StatelessWidget {
  const _CameraStrip({required this.preview, required this.onShoot});

  final Widget preview;
  final VoidCallback onShoot;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SizedBox(
          height: 132,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FittedBox(fit: BoxFit.cover, child: preview),
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(child: _Shutter(size: 46, onTap: onShoot)),
              ),
            ],
          ),
        ),
      );
}

class _EditList extends ConsumerWidget {
  const _EditList({required this.scrollController, required this.tray});

  final ScrollController scrollController;
  final List<Candidate> tray;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: tray.length + 1,
      itemBuilder: (context, i) {
        if (i == tray.length) {
          return GestureDetector(
            onTap: () => openCoachSearch(context, ref),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Row(children: [
                Icon(Icons.add, size: 15, color: AppColors.amber),
                const SizedBox(width: 10),
                const Text('Search your library',
                    style: TextStyle(fontSize: 12, color: AppColors.amber)),
              ]),
            ),
          );
        }
        return _Row(candidate: tray[i], index: i);
      },
    );
  }
}

/// One detected item: emoji, name, portion or status, confidence bar, control.
class _Row extends ConsumerWidget {
  const _Row({required this.candidate, required this.index});

  final Candidate candidate;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = candidate;
    final conf = c.confidence;

    // Confidence drives the default state, and the raw value is always shown —
    // it is never hidden behind a threshold.
    final (barColor, showBar) = switch (c) {
      _ when c.isUnresolved => (Colors.transparent, false),
      _ when (conf ?? 1) >= 0.80 => (AppColors.carbs, true),
      _ when (conf ?? 1) >= 0.50 => (AppColors.amber, true),
      _ => (_dim(.30), true),
    };

    return Dismissible(
      key: ValueKey('${c.detectedName}-$index'),
      direction: DismissDirection.startToEnd,
      // Matches the timeline's swipe-to-remove.
      resizeDuration: null,
      background: Container(
        padding: const EdgeInsets.only(left: 16),
        alignment: Alignment.centerLeft,
        color: AppColors.protein.withValues(alpha: .18),
        child: const Icon(Icons.delete_outline,
            size: 17, color: AppColors.protein),
      ),
      onDismissed: (_) => ref.read(trayProvider.notifier).removeAt(index),
      child: Container(
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: _dim(.07)))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(c.emoji,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: c.displayName,
                      style:
                          const TextStyle(fontSize: 12.5, color: AppColors.fg),
                      children: [
                        if (!c.isUnresolved &&
                            (conf ?? 1) >= 0.50 &&
                            (conf ?? 1) < 0.80)
                          const TextSpan(
                              text: ' · tap to fix',
                              style: TextStyle(color: AppColors.amber)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    // Unresolved is a different failure from low confidence and
                    // must read differently: no bar, and an honest subtitle
                    // rather than a substituted guess.
                    c.isUnresolved
                        ? 'not in your library — search for it'
                        : '${c.grams.round()} g',
                    style: TextStyle(fontSize: 10, color: _dim(.45)),
                  ),
                  if (showBar) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      SizedBox(
                        width: 62,
                        child: MacroBarLike(value: conf ?? 0, color: barColor),
                      ),
                      const SizedBox(width: 8),
                      Text((conf ?? 0).toStringAsFixed(2),
                          style: TextStyle(fontSize: 9, color: _dim(.45))),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (c.isUnresolved)
              GestureDetector(
                onTap: () => openCoachSearch(context, ref,
                    prefill: c.detectedName, replaceIndex: index),
                child: Icon(Icons.search, size: 18, color: AppColors.amber),
              )
            else
              GestureDetector(
                onTap: () => ref.read(trayProvider.notifier).toggle(index),
                child: Icon(
                  c.checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 19,
                  color: c.checked ? AppColors.amber : _dim(.35),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A 3px confidence track. Same shape as the app's [MacroBar] but takes a 0–1
/// value directly rather than value/target.
class MacroBarLike extends StatelessWidget {
  const MacroBarLike({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 3,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColors.dim(.12),
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.02, 1),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
}

class _Cta extends ConsumerWidget {
  const _Cta({required this.tray});

  final List<Candidate> tray;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendable = tray.where((c) => c.checked && !c.isUnresolved).length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: GestureDetector(
          onTap: () {
            ref.read(coachRunProvider.notifier).run();
            Navigator.of(context).pop();
          },
          child: Opacity(
            opacity: sendable == 0 ? .45 : 1,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                sendable == 0
                    ? 'ASK THE COACH'
                    : 'ASK THE COACH · $sendable',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AppColors.bg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
