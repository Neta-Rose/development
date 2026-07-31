import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../home/data/catalog_repository.dart';
import '../domain/portion.dart';
import 'scan_providers.dart';
import 'search_providers.dart';

Color _dim(double a) => AppColors.dim(a);

/// The reticle, in the design's numbers. The scrim's cut-out and the brackets are
/// painted from two places and have to agree.
const _reticleW = 264.0;
const _reticleH = 150.0;
const _reticleTop = 52.0;
const _reticleRadius = 14.0;

/// Barcode scan: a viewfinder that finds a packaged product, and the card that
/// stages it.
///
/// No decoder and no camera preview behind it yet — `scan_stub.dart` stands in
/// for both, and the torch and `enter code manually` are rendered inert. What is
/// real is the way out: a match stages a [BatchItem] like any other mode, so the
/// header totals, the chip strip and the check button work unchanged.
class ScanPane extends ConsumerWidget {
  const ScanPane({super.key, required this.onSearchInstead});

  /// Switches the screen back to search mode, which is also what disposes this
  /// pane's session and cancels its timer.
  final VoidCallback onSearchInstead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scanProvider);
    final found = session.phase == ScanPhase.found;

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.camBg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _Hatch()),
          _vignette(),
          _feedLabel(),
          const IgnorePointer(child: CustomPaint(painter: _Scrim())),
          _reticle(found),
          _statusPill(found),
          _torch(ref, session.torch),
          if (!found) _escapePills(),
          if (found)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MatchCard(session: session),
            ),
        ],
      ),
    );
  }

  Widget _vignette() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.32),
            radius: .9,
            stops: const [0, .78],
            colors: [
              _dim(.13),
              const Color(0xFF080907).withValues(alpha: .9),
            ],
          ),
        ),
      );

  /// Says outright that there is no feed. The alternative — an empty black
  /// rectangle — reads as a broken camera.
  Widget _feedLabel() => Positioned(
        left: 0,
        right: 0,
        bottom: 12,
        child: Text('[ LIVE CAMERA FEED ]',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 8.5, letterSpacing: 1.6, color: _dim(.22))),
      );

  Widget _reticle(bool found) => Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.only(top: _reticleTop),
          child: Column(
            children: [
              SizedBox(
                width: _reticleW,
                height: _reticleH,
                child: Stack(
                  // Expanded, so the painter below is asked for the reticle's
                  // size rather than for its own — which is zero.
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _Reticle(found: found)),
                    if (!found) const _Sweep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  found
                      ? 'confirm the portion below'
                      : 'center the barcode in the frame',
                  style: TextStyle(
                    fontSize: 11,
                    color: found
                        ? AppColors.found.withValues(alpha: .85)
                        : _dim(.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statusPill(bool found) => Positioned(
        top: 14,
        left: 16,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: found
                ? AppColors.found.withValues(alpha: .14)
                : AppColors.bg.withValues(alpha: .72),
            border: Border.all(
                color: found
                    ? AppColors.found.withValues(alpha: .45)
                    : _dim(.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (found)
                _dot(AppColors.found)
              else
                _Loop(
                  period: const Duration(milliseconds: 550),
                  builder: (t) => Opacity(
                      opacity: 1 - .75 * t, child: _dot(AppColors.amber)),
                ),
              const SizedBox(width: 7),
              Text(
                found ? 'MATCH FOUND' : 'SCANNING',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.3,
                  color: found ? AppColors.found : _dim(.7),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _dot(Color color) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  /// The AI pane's torch, to the pixel — but with nothing behind it. Reading a
  /// barcode off a dark packet wants a light, and this is where the light will be.
  Widget _torch(WidgetRef ref, bool on) => Positioned(
        top: 10,
        right: 14,
        child: GestureDetector(
          onTap: ref.read(scanProvider.notifier).toggleTorch,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? AppColors.amber : AppColors.bg.withValues(alpha: .72),
              border: Border.all(color: on ? AppColors.amber : _dim(.16)),
            ),
            child: Icon(
              on ? Icons.flashlight_on : Icons.flashlight_off,
              size: 16,
              color: on ? AppColors.bg : _dim(.7),
            ),
          ),
        ),
      );

  Widget _escapePills() => Positioned(
        left: 0,
        right: 0,
        bottom: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // No handler: there is no code entry to open yet. Rendered anyway,
            // because a viewfinder that cannot read the barcode has to offer
            // something, and this is the something the design offers.
            _pill('enter code manually'),
            const SizedBox(width: 8),
            _pill('search instead', onTap: onSearchInstead),
          ],
        ),
      );

  Widget _pill(String label, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.bg.withValues(alpha: .7),
            border: Border.all(color: _dim(.22)),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 10.5, color: _dim(.7))),
        ),
      );
}

/// The product, its amount, and the one button that stages it.
class _MatchCard extends ConsumerStatefulWidget {
  const _MatchCard({required this.session});

  final ScanSession session;

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard>
    with SingleTickerProviderStateMixin {
  /// Slides up on arrival. One-shot: the card is built when the match is, and a
  /// rescan disposes it, so the next match animates in on a fresh controller.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final match = session.match;
    final food = match.food;
    final portion = portionFor(session.qty.toDouble(), match.serving);
    final scan = ref.read(scanProvider.notifier);

    return SlideTransition(
      position: Tween(begin: const Offset(0, 1.05), end: Offset.zero).animate(
        CurvedAnimation(parent: _entrance, curve: const Cubic(.2, .8, .3, 1)),
      ),
      // Clipped rather than given a `borderRadius`: a BoxDecoration will not draw
      // a rounded border with only one of its four sides set.
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.field,
            border: Border(
                top: BorderSide(color: AppColors.amber.withValues(alpha: .5))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _identity(match, scan),
                  _amount(food, portion, scan),
                  _cta(food, portion, scan),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _identity(ScanProduct match, Scan scan) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(match.food.emoji ?? '🍽️',
                style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 8.5, letterSpacing: 1.3, color: _dim(.42))),
                const SizedBox(height: 3),
                Text(match.food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 13.5, color: AppColors.fg)),
                const SizedBox(height: 4),
                Text(match.code,
                    style: TextStyle(fontSize: 9, color: _dim(.32))),
              ],
            ),
          ),
          const SizedBox(width: 11),
          GestureDetector(
            onTap: scan.rescan,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                  color: AppColors.badgeBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.close, size: 11, color: _dim(.6)),
            ),
          ),
        ],
      );

  Widget _amount(FoodHit food, Portion portion, Scan scan) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.only(top: 11),
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: _dim(.08)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(
                  text: '${portion.scale(food.kcal100g).round()}',
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      height: 1,
                      color: AppColors.fg),
                  children: [
                    TextSpan(
                      text: ' kcal',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: _dim(.45)),
                    ),
                  ],
                )),
                const SizedBox(height: 5),
                macros(
                  portion.scale(food.protein100g),
                  portion.scale(food.carb100g),
                  portion.scale(food.fat100g),
                  size: 9.5,
                ),
              ],
            ),
            _stepper(portion, scan),
          ],
        ),
      );

  /// The design pluralises this (`2 scoops`). A portion label is a measure of
  /// *one*, so it reads `2 × scoop` here as it does everywhere else — and
  /// [portionFor] has already written it that way.
  Widget _stepper(Portion portion, Scan scan) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _step('−', () => scan.bumpQty(-1)),
          const SizedBox(width: 9),
          SizedBox(
            width: 78,
            child: Column(
              children: [
                Text(portion.label,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 11, color: AppColors.fg)),
                const SizedBox(height: 2),
                Text('${formatGrams(portion.grams)} g',
                    style: TextStyle(fontSize: 9, color: _dim(.4))),
              ],
            ),
          ),
          const SizedBox(width: 9),
          _step('+', () => scan.bumpQty(1)),
        ],
      );

  Widget _step(String glyph, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _dim(.25)),
          ),
          alignment: Alignment.center,
          child: Text(glyph,
              style: const TextStyle(fontSize: 16, color: AppColors.fg)),
        ),
      );

  /// Stages the match and goes straight back to searching — a shelf holds more
  /// than one thing, and stopping to confirm each one is the slow way to log a
  /// grocery bag.
  Widget _cta(FoodHit food, Portion portion, Scan scan) => GestureDetector(
        onTap: () {
          ref.read(batchProvider.notifier).add(BatchItem(food, portion));
          scan.rescan();
        },
        child: Container(
          margin: const EdgeInsets.only(top: 13),
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 13, color: AppColors.bg),
              SizedBox(width: 8),
              Text('add to batch · keep scanning',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bg)),
            ],
          ),
        ),
      );
}

/// The amber line that travels the reticle while it is searching.
///
/// Local rather than the AI pane's `_SweepBar`, which fades a static line in and
/// out. Same colour, different motion: this one has to look like it is reading
/// something.
class _Sweep extends StatelessWidget {
  const _Sweep();

  @override
  Widget build(BuildContext context) {
    // Inset so the line travels 12 → 138 in a 150 px reticle, as the design's
    // keyframes do.
    return Positioned(
      left: 10,
      right: 10,
      top: 12,
      bottom: 10,
      child: _Loop(
        period: const Duration(milliseconds: 2100),
        builder: (t) => Align(
          alignment: Alignment(0, -1 + 2 * t),
          child: Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(colors: [
                AppColors.amber.withValues(alpha: 0),
                AppColors.amber,
                AppColors.amber.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A number that eases 0 → 1 → 0 forever, for the two things in this pane that
/// never stop moving. One [period] is one direction, as a CSS `alternate` is.
class _Loop extends StatefulWidget {
  const _Loop({required this.period, required this.builder});

  final Duration period;
  final Widget Function(double t) builder;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        builder: (_, _) => widget.builder(_t.value),
      );
}

/// The design's `repeating-linear-gradient(112deg, …)`, standing in for the feed
/// there is no camera behind. Painted rather than faked with a two-stop gradient:
/// a fixed 16 px stripe is not something a fractional [LinearGradient] can hold
/// across a box whose size this pane does not know.
class _Hatch extends CustomPainter {
  const _Hatch();

  /// A CSS gradient angle is measured clockwise from *up*; a canvas rotation is
  /// measured from the x axis.
  static const _angle = (112 - 90) * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF101207));
    final stripe = Paint()..color = const Color(0xFF181B12);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(_angle);
    // Rotated, so the stripes have to start well outside the box to cover it.
    final reach = size.width + size.height;
    for (var x = -reach; x < reach; x += 32) {
      canvas.drawRect(Rect.fromLTWH(x, -reach, 16, reach * 2), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Hatch oldDelegate) => false;
}

/// Everything outside the reticle, dimmed — the design's 2000 px box-shadow.
class _Scrim extends CustomPainter {
  const _Scrim();

  @override
  void paint(Canvas canvas, Size size) {
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          (size.width - _reticleW) / 2, _reticleTop, _reticleW, _reticleH),
      const Radius.circular(_reticleRadius),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(window),
      ),
      Paint()..color = const Color(0xFF080907).withValues(alpha: .55),
    );
  }

  @override
  bool shouldRepaint(_Scrim oldDelegate) => false;
}

/// The four corner brackets, and the whole frame once there is a match.
///
/// The brackets are the reticle's own rounded outline, clipped to its corners —
/// which is cheaper than four boxes with one rounded corner and two borders each,
/// something [BoxDecoration] declines to draw.
class _Reticle extends CustomPainter {
  const _Reticle({required this.found});

  final bool found;

  static const _arm = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(_reticleRadius));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    final corners = Path();
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      corners.addRect(
          Rect.fromCenter(center: corner, width: _arm * 2, height: _arm * 2));
    }
    canvas.clipPath(corners);
    canvas.drawRRect(frame, stroke..color = AppColors.amber);
    canvas.restore();

    if (found) canvas.drawRRect(frame, stroke..color = AppColors.found);
  }

  @override
  bool shouldRepaint(_Reticle oldDelegate) => oldDelegate.found != found;
}
