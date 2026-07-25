import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/app/app.dart';
import 'package:healthapp/core/database/database.dart';
import 'package:healthapp/features/home/data/food_log_repository.dart';
import 'package:healthapp/features/home/presentation/home_providers.dart';

/// Seeds log entries directly, with literal per-100 g values, so the widget
/// test needs no catalog attached.
Future<void> seed(AppDatabase db, DateTime day) async {
  final d = localDate(day);
  Future<void> add(String name, String emoji, String hm, double grams,
          double kcal, double p, double f, double c) =>
      db.into(db.logEntries).insert(LogEntriesCompanion.insert(
            id: Value(name),
            foodId: const Value(1),
            loggedAt: '${d}T$hm',
            grams: grams,
            name: name,
            emoji: Value(emoji),
            energyKcal: Value(kcal),
            proteinG: Value(p),
            fatG: Value(f),
            carbG: Value(c),
          ));

  // 100 g each, so the per-100 g values are also the logged amounts.
  await add('Black Coffee', '☕', '06:00', 100, 5, 0, 0, 0);
  await add('Oats', '🥣', '07:00', 100, 303, 11, 5, 54);
  await add('Whole Milk', '🥛', '07:15', 100, 212, 14, 8, 20);
  await add('Whey Isolate', '🥤', '07:30', 100, 120, 27, 1, 2);
}

void main() {
  testWidgets('home screen renders the logged timeline', (tester) async {
    // Tall viewport so the lazy timeline builds through the 09 now-row
    // without scrolling.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day, 9, 29);
    await tester.runAsync(() => seed(db, now));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          nowProvider.overrideWith((ref) => now),
        ],
        child: const App(),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 5 + 303 + 212 + 120, each logged at 100 g.
    expect(find.textContaining('640', findRichText: true), findsOneWidget);
    expect(find.text('KCAL'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);
    expect(find.text('now'), findsOneWidget);

    // Drift's stream teardown schedules a zero-duration timer; unmount the
    // tree and pump so it fires inside the test body.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
