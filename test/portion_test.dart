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

    // Past the end it stays on the last rung rather than running off.
    expect(at(2000, 0).grams, 166);

    // Up doubles, down quarters off the resting multiplier.
    expect(at(18 + 6 * 26, -34).label, '2 × breast');
    expect(at(18 + 6 * 26, -34).grams, 332);
    expect(at(18 + 6 * 26, 34).qty, 0.75);
    expect(at(18 + 6 * 26, 34).grams, 125); // 166 × 0.75, rounded
    expect(at(18 + 6 * 26, -2000).qty, 4); // clamped to the top multiplier
    expect(at(18 + 6 * 26, 2000).qty, 0.5); // and the bottom
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
}
