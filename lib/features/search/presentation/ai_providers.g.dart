// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether AI logging can be offered at all.
///
/// Two independent reasons it cannot be: no service configured in this build, or
/// no camera on this device. Either way the header renders without the toggle
/// rather than with a button that always fails.

@ProviderFor(aiAvailable)
final aiAvailableProvider = AiAvailableProvider._();

/// Whether AI logging can be offered at all.
///
/// Two independent reasons it cannot be: no service configured in this build, or
/// no camera on this device. Either way the header renders without the toggle
/// rather than with a button that always fails.

final class AiAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether AI logging can be offered at all.
  ///
  /// Two independent reasons it cannot be: no service configured in this build, or
  /// no camera on this device. Either way the header renders without the toggle
  /// rather than with a button that always fails.
  AiAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return aiAvailable(ref);
  }
}

String _$aiAvailableHash() => r'cf354716098cb19e7e9276ce45a64488352c6b2b';

/// The initialised rear camera.
///
/// Auto-disposed, which is what releases the hardware when the user leaves the
/// search screen or switches away from AI mode.

@ProviderFor(aiCamera)
final aiCameraProvider = AiCameraProvider._();

/// The initialised rear camera.
///
/// Auto-disposed, which is what releases the hardware when the user leaves the
/// search screen or switches away from AI mode.

final class AiCameraProvider
    extends
        $FunctionalProvider<AsyncValue<AiCamera>, AiCamera, FutureOr<AiCamera>>
    with $FutureModifier<AiCamera>, $FutureProvider<AiCamera> {
  /// The initialised rear camera.
  ///
  /// Auto-disposed, which is what releases the hardware when the user leaves the
  /// search screen or switches away from AI mode.
  AiCameraProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiCameraProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiCameraHash();

  @$internal
  @override
  $FutureProviderElement<AiCamera> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AiCamera> create(Ref ref) {
    return aiCamera(ref);
  }
}

String _$aiCameraHash() => r'780b91169ba8db7add2b1c2ecd279856454a1bd0';

/// The detection port. Overridden in tests with a fake, which is what lets every
/// test above this line run with no network and no credentials.

@ProviderFor(visionClient)
final visionClientProvider = VisionClientProvider._();

/// The detection port. Overridden in tests with a fake, which is what lets every
/// test above this line run with no network and no credentials.

final class VisionClientProvider
    extends $FunctionalProvider<VisionClient, VisionClient, VisionClient>
    with $Provider<VisionClient> {
  /// The detection port. Overridden in tests with a fake, which is what lets every
  /// test above this line run with no network and no credentials.
  VisionClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visionClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visionClientHash();

  @$internal
  @override
  $ProviderElement<VisionClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VisionClient create(Ref ref) {
    return visionClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisionClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisionClient>(value),
    );
  }
}

String _$visionClientHash() => r'b915afa88d02a42c3e053f320ae7b4a90ae91973';

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

@ProviderFor(AiCapture)
final aiCaptureProvider = AiCaptureProvider._();

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
final class AiCaptureProvider extends $NotifierProvider<AiCapture, AiSession> {
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
  AiCaptureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiCaptureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiCaptureHash();

  @$internal
  @override
  AiCapture create() => AiCapture();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiSession>(value),
    );
  }
}

String _$aiCaptureHash() => r'a81b4b160d52fdbf8e6c691d4b164abbb3439286';

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

abstract class _$AiCapture extends $Notifier<AiSession> {
  AiSession build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AiSession, AiSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiSession, AiSession>,
              AiSession,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
