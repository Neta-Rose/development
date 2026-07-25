import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqlite3/wasm.dart';

import '../database.dart' show catalogVersion;

/// The browser has no filesystem, so both databases live in one IndexedDB
/// backed VFS — sqlite can only `ATTACH` a file it reaches through its own VFS.
/// Anything written elsewhere (OPFS, a worker's private VFS) is invisible to it.
///
/// ponytail: no drift worker, so sqlite runs on the main isolate. The queries
/// here are FTS lookups and single-row writes. If one ever drops a frame, move
/// to OPFS + a worker — which then needs COOP/COEP headers on the server and a
/// way to seed the catalog inside the worker's VFS.
Future<(QueryExecutor, String?)> openDatabase() async {
  final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fs = await IndexedDbFileSystem.open(dbName: 'healthapp');
  sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

  const catalog = '/catalog_v$catalogVersion.sqlite';
  if (fs.xAccess(catalog, 0) == 0) {
    final bytes = await rootBundle.load('database/foods.sqlite');
    final file = fs
        .xOpen(
          Sqlite3Filename(catalog),
          SqlFlag.SQLITE_OPEN_CREATE | SqlFlag.SQLITE_OPEN_READWRITE,
        )
        .file;
    file.xWrite(bytes.buffer.asUint8List(), 0);
    file.xClose();
    for (var old = 1; old < catalogVersion; old++) {
      fs.xDelete('/catalog_v$old.sqlite', 0);
    }
    await fs.flush();
  }

  // `fileSystem` makes every write durable in IndexedDB before it completes.
  return (
    WasmDatabase(sqlite3: sqlite3, path: '/healthapp.db', fileSystem: fs),
    catalog,
  );
}
