import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/database.dart';
import '../../../core/supabase/supabase.dart';
import '../domain/food_entry.dart';

part 'food_log_repository.g.dart';

@riverpod
FoodLogRepository foodLogRepository(Ref ref) {
  final repo = FoodLogRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseClientProvider),
  );
  if (kDebugMode) {
    unawaited(repo.seedDebugData());
  }
  unawaited(repo.pullToday());
  return repo;
}

class FoodLogRepository {
  FoodLogRepository(this._db, this._supabase);

  final AppDatabase _db;
  final SupabaseClient? _supabase;

  Stream<List<FoodEntry>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final query = _db.select(_db.foodEntries)
      ..where((t) =>
          t.loggedAt.isBiggerOrEqualValue(start) &
          t.loggedAt.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]);
    return query.watch().map((rows) => rows.map(_toModel).toList());
  }

  /// Upserts today's remote rows into Drift. No-op without Supabase creds;
  /// network failures are swallowed — Drift stays the source of truth.
  Future<void> pullToday() async {
    final client = _supabase;
    if (client == null) return;
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    try {
      final rows = await client
          .from('food_entries')
          .select()
          .gte('logged_at', dayStart.toUtc().toIso8601String());
      await _db.batch((b) {
        for (final json in rows) {
          b.insert(
            _db.foodEntries,
            _toRow(FoodEntry.fromJson(json), pendingSync: false),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    } catch (_) {
      // Offline-first: remote pull is best-effort.
    }
  }

  /// Seeds the design mock's data into an empty DB so the debug homepage
  /// matches the design. [at] fixes the day (used by tests).
  Future<void> seedDebugData([DateTime? at]) async {
    final existing = await (_db.select(_db.foodEntries)..limit(1)).get();
    if (existing.isNotEmpty) return;
    final d = at ?? DateTime.now();
    DateTime t(int h, [int m = 0]) => DateTime(d.year, d.month, d.day, h, m);
    final entries = [
      FoodEntry(
          id: 'seed-coffee', name: 'Black Coffee', icon: '☕',
          type: EntryType.food, kcal: 5, protein: 0, carbs: 0, fat: 0,
          serving: '1 cup', loggedAt: t(6)),
      FoodEntry(
          id: 'seed-oats', name: 'Oats', icon: '🥣',
          type: EntryType.food, kcal: 303, protein: 11, carbs: 54, fat: 5,
          serving: '80 g', loggedAt: t(7)),
      FoodEntry(
          id: 'seed-milk', name: 'Whole Milk', icon: '🥛',
          type: EntryType.food, kcal: 212, protein: 14, carbs: 20, fat: 8,
          serving: '400 ml', loggedAt: t(7, 15)),
      FoodEntry(
          id: 'seed-whey', name: 'Whey Isolate', icon: '🥤',
          type: EntryType.food, kcal: 120, protein: 27, carbs: 2, fat: 1,
          serving: '30 g', loggedAt: t(7, 30)),
      FoodEntry(
          id: 'seed-workout', name: 'Push A — 57 min', icon: '🏋️',
          type: EntryType.workout, kcal: 310,
          meta: 'workout detected · gym', loggedAt: t(8)),
    ];
    await _db.batch((b) {
      for (final e in entries) {
        b.insert(_db.foodEntries, _toRow(e, pendingSync: false));
      }
    });
  }

  FoodEntry _toModel(FoodEntryRow r) => FoodEntry(
        id: r.id,
        name: r.name,
        icon: r.icon,
        type: EntryType.values.byName(r.type),
        kcal: r.kcal,
        protein: r.protein,
        carbs: r.carbs,
        fat: r.fat,
        serving: r.serving,
        meta: r.meta,
        loggedAt: r.loggedAt,
      );

  FoodEntryRow _toRow(FoodEntry e, {required bool pendingSync}) => FoodEntryRow(
        id: e.id,
        name: e.name,
        icon: e.icon,
        type: e.type.name,
        kcal: e.kcal,
        protein: e.protein,
        carbs: e.carbs,
        fat: e.fat,
        serving: e.serving,
        meta: e.meta,
        loggedAt: e.loggedAt,
        pendingSync: pendingSync,
      );
}
