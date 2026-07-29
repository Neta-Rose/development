// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether this device has a camera at all.
///
/// Asked by every mode that points one at something — barcode scan needs nothing
/// but this, AI logging needs a service behind it as well. Either way a mode with
/// no camera renders without its toggle rather than with a button that always
/// fails.
///
/// `availableCameras()` is uniform across io and web, so this is one call in a
/// `try` and **not** a conditional export — `lib/core/database/connection/` stays
/// the only platform-branching code in `lib/`.

@ProviderFor(cameraAvailable)
final cameraAvailableProvider = CameraAvailableProvider._();

/// Whether this device has a camera at all.
///
/// Asked by every mode that points one at something — barcode scan needs nothing
/// but this, AI logging needs a service behind it as well. Either way a mode with
/// no camera renders without its toggle rather than with a button that always
/// fails.
///
/// `availableCameras()` is uniform across io and web, so this is one call in a
/// `try` and **not** a conditional export — `lib/core/database/connection/` stays
/// the only platform-branching code in `lib/`.

final class CameraAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether this device has a camera at all.
  ///
  /// Asked by every mode that points one at something — barcode scan needs nothing
  /// but this, AI logging needs a service behind it as well. Either way a mode with
  /// no camera renders without its toggle rather than with a button that always
  /// fails.
  ///
  /// `availableCameras()` is uniform across io and web, so this is one call in a
  /// `try` and **not** a conditional export — `lib/core/database/connection/` stays
  /// the only platform-branching code in `lib/`.
  CameraAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return cameraAvailable(ref);
  }
}

String _$cameraAvailableHash() => r'ff6ff34d52752252c4b8fc3b22531a9aaf1c13bc';
