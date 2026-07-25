import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

/// Bump when `database/foods.sqlite` is replaced. The catalog is read-only and
/// upgraded wholesale, so a new file name is the entire upgrade story.
const catalogVersion = 1;

@DriftDatabase(include: {'log.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(this.catalogPath) : super(driftDatabase(name: 'healthapp'));

  AppDatabase.forTesting(super.e, {this.catalogPath});

  /// Path to the catalog copy to `ATTACH`, or null to run without it — tests
  /// that only touch the log, and any path where installing the copy failed.
  final String? catalogPath;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (_) async {
          // Both are per-connection, not stored in the file.
          await customStatement('PRAGMA foreign_keys = ON');
          final path = catalogPath;
          if (path != null) {
            await customStatement('ATTACH DATABASE ? AS catalog', [path]);
          }
        },
      );
}

/// Copies the read-only catalog out of the asset bundle so sqlite can `ATTACH`
/// it — on Android assets live compressed inside the APK with no file path.
Future<String> installCatalog() async {
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
  return file.path;
}

@Riverpod(keepAlive: true)
Future<AppDatabase> appDatabase(Ref ref) async {
  final db = AppDatabase(await installCatalog());
  ref.onDispose(db.close);
  return db;
}
