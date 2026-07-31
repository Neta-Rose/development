import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connection/connection.dart';

part 'database.g.dart';

/// Bump when `database/foods.sqlite` is replaced. The catalog is read-only and
/// upgraded wholesale, so a new file name is the entire upgrade story.
///
/// v3 moved search to merged-item granularity: `food_fts.rowid` is now
/// `merged_food_id`, `merged_foods` carries the display name/emoji/commonness,
/// and `foods` gained `prep_id`. An old app against a v3 file would read
/// columns that moved, which is exactly what this constant prevents.
///
/// v4 is the rebuilt catalogue: 6,809 items, LLM keywords folded into the FTS
/// `aka` column, and preparations split so the wheel has rows to spin between.
/// Same schema — but both connections extract to `catalog_v$catalogVersion` and
/// skip the copy if it exists, so without this bump every install already
/// carrying v3 keeps reading the old file forever.
const catalogVersion = 4;

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
