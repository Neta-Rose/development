import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/ai/plate_api_config.dart';
import '../../../core/ai/vision_client.dart';
import '../../../core/ai/vision_models.dart';
import '../../home/data/catalog_repository.dart';
import '../domain/ai_plate.dart';
import 'camera_providers.dart';
import 'search_providers.dart';

part 'ai_providers.g.dart';

/// Longest edge of a shot on the wire, and the JPEG quality it is re-encoded at.
///
/// A full-resolution phone photo is several megabytes and buys nothing: the
/// detector is naming foods and estimating portions, not reading fine print, and
/// eight of them go up on every shutter press.
const _maxEdge = 1024;
const _jpegQuality = 80;

/// Shrinks one captured JPEG.
///
/// Top-level because [compute] requires a top-level or static function — decoding
/// and re-encoding a photo on the UI isolate drops frames on the shutter
/// animation, which is exactly the moment the user is looking at it.
///
/// Returns the input untouched when it cannot be decoded, rather than throwing:
/// a shot the detector might still read is better than a failed capture.
Uint8List downscaleJpeg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longest <= _maxEdge
      ? decoded
      : img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? _maxEdge : null,
          height: decoded.height > decoded.width ? _maxEdge : null,
          interpolation: img.Interpolation.average,
        );
  return img.encodeJpg(resized, quality: _jpegQuality);
}

/// Whether AI logging can be offered at all.
///
/// Two independent reasons it cannot be: no service configured in this build, or
/// no camera on this device. Either way the header renders without the toggle
/// rather than with a button that always fails.
@riverpod
Future<bool> aiAvailable(Ref ref) async =>
    plateApiConfigured && await ref.watch(cameraAvailableProvider.future);

/// Why the camera pane has no preview, when it has none.
enum AiCameraStatus { ready, unavailable, denied }

/// The camera, or the reason there isn't one.
class AiCamera {
  const AiCamera(this.status, [this.controller]);

  final AiCameraStatus status;
  final CameraController? controller;
}

/// The initialised rear camera.
///
/// Auto-disposed, which is what releases the hardware when the user leaves the
/// search screen or switches away from AI mode.
@riverpod
Future<AiCamera> aiCamera(Ref ref) async {
  if (!await ref.watch(aiAvailableProvider.future)) {
    return const AiCamera(AiCameraStatus.unavailable);
  }

  late final List<CameraDescription> cameras;
  try {
    cameras = await availableCameras();
  } on CameraException {
    return const AiCamera(AiCameraStatus.unavailable);
  } on MissingPluginException {
    return const AiCamera(AiCameraStatus.unavailable);
  }
  if (cameras.isEmpty) return const AiCamera(AiCameraStatus.unavailable);

  final rear = cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );

  final controller = CameraController(
    rear,
    ResolutionPreset.high,
    // No audio: nothing here records video, and asking for the microphone would
    // put a permission prompt in front of photographing a plate.
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.jpeg,
  );
  ref.onDispose(controller.dispose);

  try {
    await controller.initialize();
  } on CameraException catch (e) {
    if (_isPermissionDenial(e)) return const AiCamera(AiCameraStatus.denied);
    return const AiCamera(AiCameraStatus.unavailable);
  }
  return AiCamera(AiCameraStatus.ready, controller);
}

bool _isPermissionDenial(CameraException e) =>
    e.code == 'CameraAccessDenied' ||
    e.code == 'CameraAccessDeniedWithoutPrompt' ||
    e.code == 'CameraAccessRestricted';

/// The detection port. Overridden in tests with a fake, which is what lets every
/// test above this line run with no network and no credentials.
@riverpod
VisionClient visionClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return PlateApiVisionClient(client);
}

/// Drives one batch of photos.
///
/// The only orchestrator in the feature, and deliberately linear: capture, send,
/// resolve, merge. Every decision it makes is a call into
/// `../domain/ai_plate.dart`, which is pure and testable without any of this.
///
/// The plate itself lives in [batchProvider], not here — so the header totals,
/// the chip strip and the confirm button work unchanged, and one code path writes
/// the log. This notifier owns only what is true of the *batch*: the shots, the
/// phase, and which ids the user has corrected.
@riverpod
class AiCapture extends _$AiCapture {
  @override
  AiSession build() => const AiSession();

  /// Captures the next shot and runs a detection over the whole batch.
  Future<void> shoot() async {
    if (state.phase == AiPhase.analyzing) return;
    if (state.shots.length >= maxShots) return;

    final camera = await ref.read(aiCameraProvider.future);
    if (!ref.mounted) return;
    final controller = camera.controller;
    if (controller == null) {
      state = state.copyWith(
        phase: camera.status == AiCameraStatus.denied
            ? AiPhase.permissionDenied
            : AiPhase.failed,
        failure: camera.status == AiCameraStatus.denied
            ? null
            : const VisionNotConfigured(),
      );
      return;
    }

    final Uint8List bytes;
    try {
      final file = await controller.takePicture();
      final raw = await file.readAsBytes();
      bytes = await compute(downscaleJpeg, raw);
    } on CameraException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: _isPermissionDenial(e) ? AiPhase.permissionDenied : AiPhase.failed,
        failure: _isPermissionDenial(e) ? null : const VisionNoConnection(),
      );
      return;
    }
    if (!ref.mounted) return;

    // Shot numbers are 1..n with no gaps: the prompt is written in terms of them
    // ("image 3 is shot 3"), so they are part of the wire contract.
    final number = state.shots.length + 1;
    state = state.copyWith(
      shots: [...state.shots, Shot(number, bytes)],
      phase: AiPhase.analyzing,
      failure: null,
    );
    await _analyze();
  }

  /// Re-sends the shots already captured. Offered after every failure except
  /// "no food", which a resend would answer identically.
  Future<void> retry() async {
    if (state.phase == AiPhase.analyzing || state.shots.isEmpty) return;
    state = state.copyWith(phase: AiPhase.analyzing, failure: null);
    await _analyze();
  }

  Future<void> _analyze() async {
    final shots = state.shots;

    // The whole batch, every time. Deduplication is the detector's job and it
    // needs every photo to do it — see VisionClient.detect.
    final result = await ref.read(visionClientProvider).detect(
          shots: [for (final shot in shots) shot.bytes],
          plate: plateSummaries(ref.read(batchProvider)),
        );
    if (!ref.mounted) return;

    final failure = result.failure;
    if (failure != null) {
      // The plate is left exactly as it was. A dead network costs the shot and
      // nothing else.
      state = state.copyWith(phase: AiPhase.failed, failure: failure);
      return;
    }

    final catalog = await ref.read(catalogRepositoryProvider.future);
    if (!ref.mounted) return;

    final candidates = <PlateCandidate>[];
    for (final detection in result.reply!.items) {
      final term = detection.searchTerm.trim().isEmpty
          ? detection.name
          : detection.searchTerm;
      // Sequential rather than concurrent: these are local SQLite reads a few
      // milliseconds each, and a handful of them in flight at once on one
      // connection buys nothing.
      final hits = term.trim().isEmpty
          ? const <FoodHit>[]
          : await catalog.searchPrimary(term);
      if (!ref.mounted) return;
      final candidate = resolveDetection(detection, hits);
      if (candidate != null) candidates.add(candidate);
    }

    if (candidates.isEmpty) {
      state = state.copyWith(phase: AiPhase.failed, failure: const VisionNoFood());
      return;
    }

    ref.read(batchProvider.notifier).replaceAll(mergePlate(
          batch: ref.read(batchProvider),
          candidates: candidates,
          editedIds: state.editedIds,
          removedIds: state.removedIds,
        ));
    state = state.copyWith(phase: AiPhase.result, failure: null);
  }

  /// Discards the batch: every shot, every detected item, and every correction.
  /// Items staged by search or quick add survive.
  void reset() {
    ref.read(batchProvider.notifier).replaceAll([
      for (final item in ref.read(batchProvider))
        if (item.ai == null) item,
    ]);
    state = const AiSession();
  }

  /// Records that the user set this item's grams by hand, so a later reply does
  /// not overwrite them.
  void markEdited(String instanceId) =>
      state = state.copyWith(editedIds: {...state.editedIds, instanceId});

  /// Records that the user removed this item, so a later reply does not bring it
  /// back.
  void markRemoved(String instanceId) =>
      state = state.copyWith(removedIds: {...state.removedIds, instanceId});

  Future<void> setTorch(bool on) async {
    final camera = await ref.read(aiCameraProvider.future);
    if (!ref.mounted) return;
    final controller = camera.controller;
    if (controller == null) return;
    try {
      await controller.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } on CameraException {
      // Plenty of devices have no torch. Nothing to say about it beyond leaving
      // the control where it was.
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(torch: on);
  }
}
