import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connection/connection.dart';

part 'database.g.dart';

/// Bump when `database/foods.sqlite` is replaced. The catalog is read-only and
/// upgraded wholesale, so a new file name is the entire upgrade story.
const catalogVersion = 2;

@DriftDatabase(include: {'log.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.catalogPath});

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

@Riverpod(keepAlive: true)
Future<AppDatabase> appDatabase(Ref ref) async {
  final (executor, catalogPath) = await openDatabase();
  final db = AppDatabase(executor, catalogPath: catalogPath);
  ref.onDispose(db.close);
  return db;
}
