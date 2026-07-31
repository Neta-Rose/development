import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/features/home/data/catalog_repository.dart';
import 'package:healthapp/features/search/domain/portion.dart';
import 'package:healthapp/features/search/presentation/camera_providers.dart';
import 'package:healthapp/features/search/presentation/food_detail_screen.dart';
import 'package:healthapp/features/search/presentation/portion_pad.dart';
import 'package:healthapp/features/search/presentation/scan_stub.dart';
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

/// Opens the search screen on a host that claims a camera, and enters scan mode.
///
/// Nothing else is overridden: scan mode reads no database and no network, and
/// its match comes from `scan_stub.dart`.
Future<void> _enterScanMode(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  _ignoreOverflow();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cameraAvailableProvider.overrideWith((ref) async => true),
        searchResultsProvider.overrideWith((ref) async => const <FoodHit>[]),
      ],
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();

  await tester.tap(find.byKey(scanToggleKey));
  await tester.pump();
}

/// Waits out the stub's arm timer and the card's entrance. Explicit durations
/// throughout: the sweep and the status dot never stop, so `pumpAndSettle` would
/// spin forever.
Future<void> _waitForMatch(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Leaves scan mode, which is what disposes the session. Every scan test ends
/// this way: a session left in its searching state holds a live timer, and the
/// test framework fails the test if one outlives the tree.
Future<void> _leaveScanMode(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.search));
  await tester.pump();
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

  testWidgets('scan mode searches, and offers a way out while it does',
      (tester) async {
    await _enterScanMode(tester);

    expect(find.text('SCANNING'), findsOneWidget);
    expect(find.text('[ LIVE CAMERA FEED ]'), findsOneWidget);
    expect(find.text('center the barcode in the frame'), findsOneWidget);
    expect(find.text('enter code manually'), findsOneWidget);

    // Leaving mid-scan is the case that must not leave the arm timer behind.
    await tester.tap(find.text('search instead'));
    await tester.pump();

    expect(find.text('SCANNING'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('a match arrives, steps its portion, and can be thrown away',
      (tester) async {
    await _enterScanMode(tester);
    await _waitForMatch(tester);

    expect(find.text('MATCH FOUND'), findsOneWidget);
    expect(find.text('confirm the portion below'), findsOneWidget);
    expect(find.text('Whey Isolate, Vanilla'), findsOneWidget);
    expect(find.text('TORRENT NUTRITION'), findsOneWidget);
    // One scoop, at the numbers on the packet — the stub stores them per 100 g
    // and `Portion.scale` brings them back.
    expect(find.text('1 × scoop'), findsOneWidget);
    expect(find.text('30 g'), findsOneWidget);
    expect(find.text('120 kcal', findRichText: true), findsOneWidget);

    // Three scoops.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('+'));
      await tester.pump();
    }
    expect(find.text('3 × scoop'), findsOneWidget);
    expect(find.text('90 g'), findsOneWidget);
    expect(find.text('360 kcal', findRichText: true), findsOneWidget);

    // The stepper holds at both ends.
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('+'));
      await tester.pump();
    }
    expect(find.text('6 × scoop'), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('−'));
      await tester.pump();
    }
    expect(find.text('1 × scoop'), findsOneWidget);

    // The card's × throws this match away and looks for the next product.
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();
    expect(find.text('SCANNING'), findsOneWidget);
    await _waitForMatch(tester);
    expect(find.text('Greek Yogurt 2%'), findsOneWidget);

    await _leaveScanMode(tester);
  });

  testWidgets('scanned products accumulate in the batch', (tester) async {
    await _enterScanMode(tester);
    await _waitForMatch(tester);

    await tester.tap(find.text('add to batch · keep scanning'));
    await tester.pump();

    // Staged like anything else on this screen, and straight back to scanning.
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('1 × scoop'), findsOneWidget);
    expect(find.text('120 kcal', findRichText: true), findsOneWidget);
    expect(find.text('SCANNING'), findsOneWidget);

    // The next product adds to the total rather than replacing it.
    await _waitForMatch(tester);
    await tester.tap(find.text('add to batch · keep scanning'));
    await tester.pump();

    expect(find.byType(Dismissible), findsNWidgets(2));
    expect(find.text('1 × pot'), findsOneWidget);
    expect(find.text('220 kcal', findRichText: true), findsOneWidget);

    await _leaveScanMode(tester);
  });

  test('a scanned product round-trips the numbers on its packet', () {
    // The design's labels: kcal, protein, carbs, fat — per serving, which is the
    // only form a packet states them in.
    const label = {
      'Whey Isolate, Vanilla': [120.0, 27.0, 2.0, 1.0],
      'Greek Yogurt 2%': [100.0, 17.0, 6.0, 3.0],
      'Sourdough Loaf': [120.0, 4.0, 24.0, 1.0],
      'Black Beans, No Salt': [190.0, 12.0, 34.0, 1.0],
    };
    expect(scanProducts.length, label.length);

    for (final product in scanProducts) {
      final food = product.food;
      final serving = portionFor(1, product.serving);
      final want = label[food.name]!;
      expect(serving.grams, food.servingG);
      expect(
        [
          serving.scale(food.kcal100g),
          serving.scale(food.protein100g),
          serving.scale(food.carb100g),
          serving.scale(food.fat100g),
        ],
        [for (final n in want) closeTo(n, 1e-9)],
      );
    }

    // Stored per 100 g like every other nutrient in the app: 120 kcal per 30 g.
    expect(scanProducts.first.food.kcal100g, 400);
  });
}
