import 'package:flutter_test/flutter_test.dart';
import 'package:healthapp/features/search/domain/portion.dart';

/// The swipe ladder is the one piece of real logic on the search screen: it
/// decides what gets written to `grams`.
void main() {
  test('the ladder climbs in 5 g rungs and ends on the whole serving', () {
    final steps = portionSteps(166); // 1 duck breast
    expect(steps.map((s) => s.grams), [15, 25, 40, 65, 90, 125, 166]);
    expect(steps.last.whole, isTrue);
    expect(steps.take(steps.length - 1).every((s) => !s.whole), isTrue);

    for (var i = 1; i < steps.length; i++) {
      expect(steps[i].grams, greaterThan(steps[i - 1].grams));
    }
  });

  test('a small serving drops the rungs that would collide or round to zero',
      () {
    // 8% of a 30 g scoop is under 5 g, and 40% rounds onto the same rung as 25%.
    final steps = portionSteps(30);
    expect(steps.map((s) => s.grams), [5, 10, 15, 25, 30]);
    expect(steps.last.whole, isTrue);
  });

  test('a serving too small for any fraction still offers itself', () {
    final steps = portionSteps(4);
    expect(steps.single.grams, 4);
    expect(steps.single.whole, isTrue);
  });

  test('nothing is picked until the drag passes the threshold', () {
    expect(portionForDrag(0, 0, unitG: 166, unitLabel: 'breast'), isNull);
    expect(portionForDrag(17.9, 0, unitG: 166, unitLabel: 'breast'), isNull);
    expect(portionForDrag(18, 0, unitG: 166, unitLabel: 'breast'), isNotNull);
  });

  test('horizontal travel picks the rung, vertical travel multiplies it', () {
    Portion at(double dx, double dy) =>
        portionForDrag(dx, dy, unitG: 166, unitLabel: 'breast')!;

    // First rung, resting multiplier: bare grams, and nothing to log as a unit.
    expect(at(18, 0).grams, 15);
    expect(at(18, 0).label, '15 g');
    expect(at(18, 0).qty, isNull);
    expect(at(18, 0).portionLabel, isNull);

    // Six rungs right is the whole serving, which logs as `qty × label`.
    final whole = at(18 + 6 * 26, 0);
    expect(whole.grams, 166);
    expect(whole.qty, 1);
    expect(whole.portionLabel, 'breast');
    expect(whole.label, '1 × breast');

    // Past the end of whole serving, it continues stepping in bare grams without capping.
    final uncapped = at(18 + 7 * 26, 0);
    expect(uncapped.grams, greaterThan(166));
    expect(uncapped.qty, isNull);
    expect(uncapped.portionLabel, isNull);
    expect(uncapped.label, '${uncapped.grams.round()} g');

    // Down doubles, up quarters off the resting multiplier.
    expect(at(18 + 6 * 26, 34).label, '2 × breast');
    expect(at(18 + 6 * 26, 34).grams, 332);
    expect(at(18 + 6 * 26, -34).qty, 0.75);
    expect(at(18 + 6 * 26, -34).grams, 125); // 166 × 0.75, rounded
    expect(at(18 + 6 * 26, 2000).qty, 4); // clamped to the top multiplier
    expect(at(18 + 6 * 26, -2000).qty, 0.5); // and the bottom
  });

  test('a food with no serving is all grams, never a unit', () {
    // `serving_g IS NULL` means "treat it as per 100 g", so there is no label
    // to log and no rung may claim one.
    final whole = portionForDrag(18 + 6 * 26, 0, unitG: 100)!;
    expect(whole.grams, 100);
    expect(whole.label, '100 g');
    expect(whole.qty, isNull);
    expect(whole.portionLabel, isNull);
  });

  test('one serving is what a tap adds', () {
    expect(wholeServing(166, 'breast').label, '1 × breast');
    expect(wholeServing(166, 'breast').qty, 1);
    expect(wholeServing(100, null).label, '100 g');
    expect(wholeServing(100, null).qty, isNull);
  });

  test('scale turns a per-100 g column into a real amount', () {
    // Every stored nutrient is per 100 g; a missing one counts as zero.
    expect(wholeServing(166, 'breast').scale(204), closeTo(338.64, 1e-9));
    expect(wholeServing(166, 'breast').scale(null), 0);
  });

  test('a flick past a prep step spins the wheel, and stops at the ends', () {
    // Four preparations — raw, boiled, frozen, cooked — resting on the second.
    // Dragging *down* moves the list down, so earlier preparations come up.
    expect(prepForDrag(21, 1, 4), 0);
    expect(prepForDrag(-21, 1, 4), 2);
    expect(prepForDrag(-42, 1, 4), 3);

    // Clamped, not wrapped: a long flick lands on an end and stays there.
    expect(prepForDrag(-500, 1, 4), 3);
    expect(prepForDrag(500, 1, 4), 0);

    // Under half a step is not a spin at all.
    expect(prepForDrag(-10, 1, 4), 1);
    expect(prepForDrag(10, 1, 4), 1);
  });

  test('a tap-sized drag advances one preparation, wrapping', () {
    // The deadzone is a tap in disguise, and a tap is "show me the next one" —
    // so it wraps where a real drag clamps.
    expect(prepForDrag(0, 0, 4), 1);
    expect(prepForDrag(4.9, 2, 4), 3);
    expect(prepForDrag(-4.9, 3, 4), 0);
    // A single-preparation item has nowhere to go, and no wheel to get there.
    expect(prepForDrag(0, 0, 1), 0);
  });

  test('the pad parses whole numbers, decimals and mixed fractions', () {
    expect(parseAmount('150'), 150);
    expect(parseAmount('1.5'), 1.5);
    expect(parseAmount('1/2'), 0.5);
    expect(parseAmount('1 1/2'), 1.5);
    expect(parseAmount(' 2  3/4 '), 2.75);
    // Half-typed and unparseable input reads as zero rather than throwing —
    // it is what the keypad holds between two keystrokes.
    expect(parseAmount(''), 0);
    expect(parseAmount('/'), 0);
    expect(parseAmount('1/'), 0);
    expect(parseAmount('1/0'), 0);
    expect(parseAmount('.'), 0);
  });

  test('a measure logs as qty × label, a gram conversion as bare grams', () {
    const cup = PortionUnit('cup', 158);
    final two = portionFor(2, cup);
    expect(two.grams, 316);
    expect(two.qty, 2);
    expect(two.portionLabel, 'cup');
    expect(two.label, '2 × cup');
    expect(portionFor(1.5, cup).label, '1.5 × cup');

    // `g`/`oz` are conversions, not catalog measures: nothing to snapshot, so
    // they log — and read — as grams.
    final oz = portionFor(4, portionUnits().firstWhere((u) => u.label == 'oz'));
    expect(oz.grams, closeTo(113.4, 1e-9));
    expect(oz.qty, isNull);
    expect(oz.portionLabel, isNull);
    expect(oz.label, '113 g'); // whole above 100 g, a decimal below
    expect(portionFor(1, portionUnits().last).label, '28.4 g');
    expect(portionFor(150, const PortionUnit('g', 1, isMeasure: false)).label,
        '150 g');
  });

  test('the unit list leads with the food\'s own serving and never repeats', () {
    final units = portionUnits(
      servingG: 158,
      servingLabel: 'cup',
      // The catalog repeats the serving as its own portion row, and a zero
      // gram weight would divide by nothing.
      catalogPortions: const [
        (label: 'cup', gramWeight: 158),
        (label: 'tbsp', gramWeight: 9.9),
        (label: 'pinch', gramWeight: 0),
      ],
    );
    expect(units.map((u) => u.label), ['cup', 'tbsp', 'g', 'oz']);
    expect(units.first.gramWeight, 158);

    // A food with no serving still offers the two conversions.
    expect(portionUnits().map((u) => u.label), ['g', 'oz']);
    // A label without a weight behind it is not a unit.
    expect(portionUnits(servingLabel: 'slice').map((u) => u.label), ['g', 'oz']);
  });

  test('PortionDragTracker accelerates virtualDx based on finger velocity', () {
    final tracker = PortionDragTracker();
    tracker.start(0, timestampMs: 0);

    // Slow drag: 100 px over 1 second = 100 px/s (< 200 px/s threshold).
    // Gain should be 1.0, so virtualDx == 100.
    tracker.update(100, timestampMs: 1000);
    expect(tracker.virtualDx, closeTo(100.0, 1e-3));

    // Reset and test fast drag: 500 px over 250 ms = 2000 px/s (> 1200 px/s cap speed).
    // Gain should be capped at 3.5x.
    tracker.start(0, timestampMs: 0);
    tracker.update(500, timestampMs: 250);
    // virtualDx should be 500 * 3.5 = 1750.
    expect(tracker.virtualDx, closeTo(1750.0, 1e-3));

    // Slow step after fast drag: 10 px over 100 ms = 100 px/s.
    // Gain for this step drops back to 1.0x, adding 10 to virtualDx.
    tracker.update(510, timestampMs: 350);
    expect(tracker.virtualDx, closeTo(1760.0, 1e-3));
  });

  test('PortionDragTracker maintains sticky snap hysteresis on step boundaries', () {
    final tracker = PortionDragTracker();
    tracker.start(0, timestampMs: 0);

    // Boundary from step 0 to step 1 is 18 + 1 * 26 = 44.
    // With 6px hysteresis, dragging to 44 should remain at step 0.
    tracker.update(44, timestampMs: 1000);
    expect(tracker.currentStepIndex, 0);

    // Dragging past 44 + 6 = 50 moves to step 1.
    tracker.update(50, timestampMs: 2000);
    expect(tracker.currentStepIndex, 1);

    // Dragging back to 44 (within 44 - 6 = 38 threshold) remains sticky at step 1.
    tracker.update(44, timestampMs: 3000);
    expect(tracker.currentStepIndex, 1);

    // Dropping below 38 drops back to step 0.
    tracker.update(37, timestampMs: 4000);
    expect(tracker.currentStepIndex, 0);
  });
}

