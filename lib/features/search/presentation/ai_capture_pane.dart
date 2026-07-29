import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ai/vision_models.dart';
import '../domain/ai_plate.dart';
import 'ai_providers.dart';
import 'search_providers.dart';

Color _dim(double a) => AppColors.dim(a);

/// The camera half of AI logging: preview, shutter, torch, reset, confirm, and
/// whatever the last detection has to say for itself.
class AiCapturePane extends ConsumerWidget {
  const AiCapturePane({super.key, required this.onLogged});

  /// Runs after the plate has been written. Pops the screen, as the header's
  /// confirm button does.
  final Future<void> Function() onLogged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(aiCaptureProvider);
    final camera = ref.watch(aiCameraProvider);
    final batch = ref.watch(batchProvider);

    return SizedBox(
      // The design's fixed pane height. Fixed rather than an aspect ratio so the
      // plate list below it never moves when the preview arrives.
      height: 396,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.camBg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _feed(session, camera.value),
            _torch(ref, session),
            if (session.phase == AiPhase.analyzing) _analyzing(session),
            if (session.phase == AiPhase.failed && session.failure != null)
              _failure(ref, session.failure!),
            if (session.phase == AiPhase.permissionDenied ||
                camera.value?.status == AiCameraStatus.denied)
              _permissionDenied(),
            _controls(context, ref, session, batch),
          ],
        ),
      ),
    );
  }

  /// The live preview, the frame just captured, or the design's placeholder.
  ///
  /// The captured frame is held only while a detection is in flight. The design
  /// freezes it until the next shutter press, but the copy under an empty plate
  /// tells the user to add food and shoot again, and they cannot aim at a frozen
  /// frame — so the preview comes back as soon as the answer does. The slight
  /// desaturation the design applies to a captured frame is kept.
  Widget _feed(AiSession session, AiCamera? camera) {
    if (session.phase == AiPhase.analyzing && session.shots.isNotEmpty) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(_desaturate85),
        child: Image.memory(
          session.shots.last.bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    final controller = camera?.controller;
    if (controller != null && controller.value.isInitialized) {
      // The preview keeps the sensor's aspect ratio and is cropped to the pane,
      // which is what the design's edge-to-edge feed looks like.
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      );
    }
    return _placeholder();
  }

  /// Stands in for the feed before the camera is up. The diagonal hatch and the
  /// vignette are the design's own mock feed, reused here for the one state that
  /// genuinely has no image.
  Widget _placeholder() => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B1E14), Color(0xFF101207)],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: .9,
                colors: [
                  _dim(.14),
                  const Color(0xFF080907).withValues(alpha: .92),
                ],
              ),
            ),
          ),
          Center(
            child: Text('[ LIVE CAMERA FEED ]',
                style: TextStyle(
                    fontSize: 8.5, letterSpacing: 1.6, color: _dim(.22))),
          ),
        ],
      );

  Widget _torch(WidgetRef ref, AiSession session) => Positioned(
        top: 10,
        right: 14,
        child: GestureDetector(
          onTap: () =>
              ref.read(aiCaptureProvider.notifier).setTorch(!session.torch),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: session.torch
                  ? AppColors.amber
                  : AppColors.bg.withValues(alpha: .72),
              border: Border.all(
                  color: session.torch ? AppColors.amber : _dim(.16)),
            ),
            child: Icon(
              session.torch ? Icons.flashlight_on : Icons.flashlight_off,
              size: 16,
              color: session.torch ? AppColors.bg : _dim(.7),
            ),
          ),
        ),
      );

  Widget _analyzing(AiSession session) {
    final n = session.shots.length;
    return _scrim(
      children: [
        const Text('ANALYZING PLATE',
            style: TextStyle(
                fontSize: 10, letterSpacing: 1.8, color: AppColors.amber)),
        const SizedBox(height: 4),
        Text(
          // Names what the extra shots are *for*, which is the one thing the
          // user cannot see happening.
          n > 1
              ? 'comparing with ${n - 1} earlier shot${n > 2 ? 's' : ''}'
              : 'detecting foods and portions',
          style: TextStyle(fontSize: 9.5, color: _dim(.45)),
        ),
      ],
    );
  }

  /// One exhaustive switch over the sealed failure type, so a new failure mode
  /// cannot be added without deciding what the user is told about it.
  Widget _failure(WidgetRef ref, VisionFailure failure) {
    final (text, retryable) = switch (failure) {
      VisionNoConnection() => ('no connection — detection needs the network', true),
      VisionTimeout() => ('detection timed out', true),
      VisionHttpError(:final status) => ('detection failed · $status', true),
      VisionUnreadable() => ("could not read the detector's answer", true),
      VisionNotConfigured() => ('photo logging is not set up in this build', false),
      // Not a failure of ours: the shots simply had no food in them.
      VisionNoFood() => ('no food found in this shot', false),
    };

    return _scrim(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.fg)),
        ),
        if (retryable) ...[
          const SizedBox(height: 12),
          _pill(
            label: 'retry',
            onTap: () => ref.read(aiCaptureProvider.notifier).retry(),
          ),
        ],
      ],
    );
  }

  Widget _permissionDenied() => _scrim(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text('camera access is off — turn it on in settings',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.fg)),
          ),
          const SizedBox(height: 12),
          _pill(
            label: 'open settings',
            onTap: () => AppSettings.openAppSettings(),
          ),
        ],
      );

  /// The dimmed overlay every in-pane message sits on, with the design's sweep
  /// bar across the top of it.
  Widget _scrim({required List<Widget> children}) => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF080907).withValues(alpha: .5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _SweepBar(),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );

  Widget _controls(
    BuildContext context,
    WidgetRef ref,
    AiSession session,
    List<BatchItem> batch,
  ) {
    final shots = session.shots.length;
    final analyzing = session.phase == AiPhase.analyzing;
    final atLimit = shots >= maxShots;
    final kcal = batch.fold(0.0, (a, b) => a + b.kcal).round();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 88,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF080907).withValues(alpha: 0),
              const Color(0xFF080907).withValues(alpha: .82),
            ],
            stops: const [0, .55],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: atLimit
                      ? Text('shot limit reached — log or reset the stack',
                          style: TextStyle(fontSize: 9.5, color: _dim(.6)))
                      : shots > 0
                          ? _pill(
                              label: 'reset stack',
                              onTap: ref.read(aiCaptureProvider.notifier).reset,
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              _shutter(ref, disabled: analyzing || atLimit),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _confirm(kcal, batch.isNotEmpty),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shutter(WidgetRef ref, {required bool disabled}) {
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: GestureDetector(
        onTap: disabled ? null : ref.read(aiCaptureProvider.notifier).shoot,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _dim(.85), width: 2),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: disabled ? 40 : 48,
              height: disabled ? 40 : 48,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.amber),
            ),
          ),
        ),
      ),
    );
  }

  /// Reads the staged plate, not the phase: a failed detection must never block
  /// logging what is already on the plate.
  Widget _confirm(int kcal, bool enabled) => GestureDetector(
        onTap: enabled ? () => onLogged() : null,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: enabled ? AppColors.amber : AppColors.bg.withValues(alpha: .6),
            border:
                Border.all(color: enabled ? AppColors.amber : _dim(.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check,
                  size: 14, color: enabled ? AppColors.bg : _dim(.35)),
              const SizedBox(width: 6),
              Text(
                enabled ? 'log $kcal' : 'log',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.bg : _dim(.35),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _pill({required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF080907).withValues(alpha: .55),
            border: Border.all(color: _dim(.28)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: _dim(.72))),
        ),
      );
}

/// The design's `saturate(0.85)` on a captured frame, as a colour matrix.
const _desaturate85 = <double>[
  0.8755, 0.1145, 0.0100, 0, 0, //
  0.0255, 0.9645, 0.0100, 0, 0, //
  0.0255, 0.1145, 0.8600, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// The amber line that sweeps the pane while a detection runs. The only moving
/// part of the analyzing state, and the whole reason it does not read as frozen.
class _SweepBar extends StatefulWidget {
  const _SweepBar();

  @override
  State<_SweepBar> createState() => _SweepBarState();
}

class _SweepBarState extends State<_SweepBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Container(
              height: 2,
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
      ),
    );
  }
}
