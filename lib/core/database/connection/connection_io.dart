import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../database.dart' show catalogVersion;

/// Opens the writable log and copies the read-only catalog out of the asset
/// bundle so sqlite can `ATTACH` it — on Android assets live compressed inside
/// the APK with no file path.
///
/// Returns the log executor and the path to `ATTACH`.
Future<(QueryExecutor, String?)> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/catalog_v$catalogVersion.sqlite');
  if (!file.existsSync()) {
    final bytes = await rootBundle.load('database/foods.sqlite');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    for (final old in dir.listSync()) {
      if (old is File &&
          old.path != file.path &&
          old.uri.pathSegments.last.startsWith('catalog_v')) {
        old.deleteSync();
      }
    }
  }
  return (driftDatabase(name: 'healthapp'), file.path);
}
