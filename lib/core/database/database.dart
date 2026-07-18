import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

@DataClassName('FoodEntryRow')
class FoodEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get type => text()(); // EntryType.name: 'food' | 'workout'
  IntColumn get kcal => integer().nullable()();
  IntColumn get protein => integer().nullable()();
  IntColumn get carbs => integer().nullable()();
  IntColumn get fat => integer().nullable()();
  TextColumn get serving => text().nullable()();
  TextColumn get meta => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [FoodEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'healthapp'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
