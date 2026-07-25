import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/features/home/data/catalog_repository.dart';
import 'package:healthapp/features/search/presentation/search_providers.dart';
import 'package:healthapp/features/search/presentation/search_screen.dart';

const _apple = FoodHit(
  name: 'Apple',
  isCustom: false,
  foodId: 1,
  emoji: '🍎',
  kcal100g: 52,
  protein100g: 0,
  fat100g: 0,
  carb100g: 14,
);

void main() {
  testWidgets('removing one of two identical chips keeps the other',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The test font runs taller than IBM Plex Mono and overflows the
    // fixed-height chip strip. Not this test's business; everything else
    // still fails.
    final onError = FlutterError.onError!;
    FlutterError.onError =
        (d) => d.exceptionAsString().contains('overflowed') ? null : onError(d);
    addTearDown(() => FlutterError.onError = onError);

    // Overriding the results skips the database entirely — nothing on this
    // path is logged until the check button.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchResultsProvider.overrideWith((ref) async => [_apple]),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();

    // Tap the result row twice: the same food staged twice.
    await tester.tap(find.text('Apple').last);
    await tester.pump();
    await tester.tap(find.text('Apple').last);
    await tester.pump();
    expect(find.byType(Dismissible), findsNWidgets(2));

    // Swipe the first chip up. The second must survive — with a positional
    // key it inherits the dismissed chip's state and vanishes too.
    await tester.drag(find.byType(Dismissible).first, const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsOneWidget);
    expect(tester.getSize(find.byType(Dismissible)).height, greaterThan(0));
  });
}
