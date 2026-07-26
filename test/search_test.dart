import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/features/home/data/catalog_repository.dart';
import 'package:healthapp/features/search/presentation/food_detail_screen.dart';
import 'package:healthapp/features/search/presentation/portion_pad.dart';
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

/// The test font runs taller than IBM Plex Mono and overflows the fixed-height
/// chip strip. Not these tests' business; everything else still fails.
void _ignoreOverflow() {
  final onError = FlutterError.onError!;
  FlutterError.onError =
      (d) => d.exceptionAsString().contains('overflowed') ? null : onError(d);
  addTearDown(() => FlutterError.onError = onError);
}

/// Swipes a result row right far enough to stage its first ladder rung.
///
/// Hand-rolled rather than `tester.drag`, which delivers every move inside one
/// frame — the row's recognizer never sees that as a drag at all.
Future<void> _swipeToStage(WidgetTester tester, Finder row) async {
  final gesture = await tester.startGesture(tester.getCenter(row));
  for (var i = 0; i < 2; i++) {
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
}

/// Runs a push or a pop out. The portion pad blinks its cursor forever, so
/// `pumpAndSettle` would never return once the detail screen is up.
Future<void> _settleRoute(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('removing one of two identical chips keeps the other',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    _ignoreOverflow();

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

    // Swipe the result row right twice: the same food staged twice. (A tap
    // opens the detail screen now; the swipe is the stage-it-here path.)
    await _swipeToStage(tester, find.text('Apple').last);
    await _swipeToStage(tester, find.text('Apple').last);
    expect(find.byType(Dismissible), findsNWidgets(2));

    // Swipe the first chip up. The second must survive — with a positional
    // key it inherits the dismissed chip's state and vanishes too.
    await tester.drag(find.byType(Dismissible).first, const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsOneWidget);
    expect(tester.getSize(find.byType(Dismissible)).height, greaterThan(0));
  });

  testWidgets('quick add stages the 4·4·9 total', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    _ignoreOverflow();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchResultsProvider.overrideWith((ref) async => const <FoodHit>[]),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.bolt));
    await tester.pump();

    // Calories left blank, so the button must read the macro total:
    // 30 × 4 + 0 × 4 + 10 × 9 = 210.
    await tester.enterText(find.byType(TextField).at(1), '30');
    await tester.enterText(find.byType(TextField).at(2), '0');
    await tester.enterText(find.byType(TextField).at(3), '10');
    await tester.pump();
    expect(find.text('add to batch · 210 kcal'), findsOneWidget);

    await tester.tap(find.text('add to batch · 210 kcal'));
    await tester.pump();

    // Staged, not logged — nothing on this path touches the database.
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Quick entry'), findsOneWidget);
    expect(find.text('1 × serving'), findsOneWidget);
    // The header total, which is a Text.rich of '210' + ' kcal'.
    expect(find.text('210 kcal', findRichText: true), findsOneWidget);
    expect(find.text('enter calories or a name'), findsOneWidget); // form reset
  });

  testWidgets('the portion pad types an exact amount into the batch',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    _ignoreOverflow();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchResultsProvider.overrideWith((ref) async => [_apple]),
          foodPortionsProvider(1).overrideWith(
              (ref) async => const [(label: 'cup, sliced', gramWeight: 109)]),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();

    // The pill carries the row's default amount and opens the pad.
    await tester.tap(find.text('100 g'));
    await tester.pump();
    expect(find.byType(PortionPad), findsOneWidget);
    // ...in place of the search field, so the OS keyboard is gone.
    expect(find.byType(TextField), findsNothing);

    // The chips arrive with the portions query, one frame behind the pad. The
    // food's own measure leads, so it shows twice: as a chip and as the
    // selected unit beside the amount.
    await tester.pump();
    expect(find.text('cup, sliced'), findsNWidgets(2));

    // Type 150 grams over the default 1. Pump after every key: the amount
    // readout and the keycaps share glyphs, so a stale tree matches twice.
    await tester.tap(find.text('g'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    for (final key in ['1', '5', '0']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    expect(find.text('150 g'), findsOneWidget); // the grams readout
    expect(find.text('78 kcal'), findsOneWidget); // 52/100 g × 150

    await tester.tap(find.text('add'));
    await tester.pump();

    // Staged at the typed amount, and the pad closed behind it.
    expect(find.byType(PortionPad), findsNothing);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget); // now the batch chip
    expect(find.text('78 kcal', findRichText: true), findsOneWidget);

    // Reopened on its default unit — a catalog measure — it logs as
    // `qty × label` instead of bare grams.
    await tester.tap(find.text('100 g'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('add'));
    await tester.pump();
    expect(find.text('1 × cup, sliced'), findsOneWidget);
  });

  testWidgets('editing a staged chip rewrites it instead of staging a second',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    _ignoreOverflow();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchResultsProvider.overrideWith((ref) async => [_apple]),
          foodPortionsProvider(1).overrideWith((ref) async => const []),
          foodExtrasProvider(foodId: 1, customId: null)
              .overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();

    // Stage one by swipe. The ladder's first rung for a 100 g unit is 10 g.
    await _swipeToStage(tester, find.text('Apple').last);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('10 g'), findsOneWidget);

    // Tapping the chip opens the detail screen on *that* amount, not on the
    // food's default one.
    await tester.tap(find.byType(Dismissible));
    await _settleRoute(tester);
    expect(find.byType(FoodDetailScreen), findsOneWidget);

    // Scoped to the pushed screen: the search screen stays in the tree beneath
    // it, so its chip carries the same '10 g' text.
    Finder onDetail(String text) => find.descendant(
        of: find.byType(FoodDetailScreen), matching: find.text(text));

    expect(onDetail('10 g'), findsOneWidget); // the pad's grams readout

    // Retype it as 50 g. Backspace to empty first, so the amount readout never
    // shares a glyph with the keycap being tapped.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    }
    for (final key in ['5', '0']) {
      await tester.tap(find.text(key).last);
      await tester.pump();
    }
    expect(onDetail('50 g'), findsOneWidget);

    // The screen above the pad mirrors it from a post-frame callback, so it
    // lands one frame behind: 52 kcal/100 g × 50 g in the hero.
    await tester.pump();
    expect(onDetail('26'), findsOneWidget);

    await tester.tap(find.text('add'));
    await _settleRoute(tester);

    // One chip still, at the new amount — not a second Apple.
    expect(find.byType(FoodDetailScreen), findsNothing);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('50 g'), findsOneWidget);
  });
}
