import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/app/app.dart';
import 'package:healthapp/core/database/database.dart';
import 'package:healthapp/features/home/data/food_log_repository.dart';
import 'package:healthapp/features/home/presentation/home_providers.dart';

void main() {
  testWidgets('home screen renders the seeded timeline', (tester) async {
    // Tall viewport so the lazy timeline builds through the 09 now-row
    // without scrolling.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = DateTime.now();
    // 9:29, after the 8:00 seeded workout → now-marker on 09, window active.
    final now = DateTime(today.year, today.month, today.day, 9, 29);
    await tester.runAsync(() => FoodLogRepository(db, null).seedDebugData(now));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          nowProvider.overrideWith((ref) => now),
        ],
        child: const App(),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Header: 5 + 303 + 212 + 120 kcal from the seed.
    expect(find.textContaining('640', findRichText: true), findsOneWidget);
    expect(find.text('KCAL'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);
    expect(find.textContaining('ANABOLIC WINDOW'), findsOneWidget);
    expect(find.text('now'), findsOneWidget);

    // Drift's stream teardown schedules a zero-duration timer; unmount the
    // tree and pump so it fires inside the test body.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
