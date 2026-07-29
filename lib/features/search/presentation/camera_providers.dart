import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_providers.g.dart';

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
@riverpod
Future<bool> cameraAvailable(Ref ref) async {
  try {
    return (await availableCameras()).isNotEmpty;
  } on CameraException {
    return false;
  } on MissingPluginException {
    // A headless test host has no camera plugin at all. A normal negative.
    return false;
  }
}
