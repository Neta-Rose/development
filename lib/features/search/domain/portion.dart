/// The swipe maths of a search result row, kept out of the widget so it can be
/// tested.
///
/// Dragging a row right walks a ladder of gram amounts; dragging up or down
/// multiplies the rung. Dragging its preparation wheel spins that instead.
/// Ported from the design's `ladderFor`/`swSel`/`prepUp`.
library;

/// Multipliers, centred on 1 — index 2 is the resting position.
const _multipliers = [0.5, 0.75, 1.0, 2.0, 3.0, 4.0];

/// Fractions of one serving that make up the ladder below the whole unit.
const _fractions = [0.08, 0.15, 0.25, 0.4, 0.55, 0.75];

/// Horizontal travel before a portion is picked at all, and per rung after.
const _startPx = 18.0;
const _rungPx = 26.0;

/// Vertical travel per multiplier step.
const _multPx = 34.0;

/// Accumulates virtual horizontal displacement for row swiping based on finger
/// drag velocity and acceleration.
///
/// Slow finger travel maintains 1:1 pixel precision, while fast acceleration
/// non-linearly boosts gain up to a 3.5× cap.
class PortionDragTracker {
  double _virtualDx = 0.0;
  double _lastDx = 0.0;
  int _lastTimeMs = 0;
  int _currentStepIndex = 0;

  double get virtualDx => _virtualDx;
  int get currentStepIndex => _currentStepIndex;

  void start(double dx, {int? timestampMs}) {
    _virtualDx = dx;
    _lastDx = dx;
    _lastTimeMs = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    _currentStepIndex = 0;
  }

  void update(double dx, {int? timestampMs}) {
    final nowMs = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final deltaDx = dx - _lastDx;
    final rawDeltaSec = (nowMs - _lastTimeMs) / 1000.0;
    // Floor at 50 ms to ensure synthetic test gesture updates (where no time elapses)
    // evaluate at standard velocity rather than infinite speed.
    final deltaSec = rawDeltaSec < 0.05 ? 0.05 : rawDeltaSec;

    double gain = 1.0;
    final velocityPxPerSec = (deltaDx.abs()) / deltaSec;
    if (velocityPxPerSec > 200.0) {
      final ratio = (velocityPxPerSec - 200.0) / 1000.0;
      gain = (1.0 + 2.5 * ratio * ratio).clamp(1.0, 3.5);
    }

    _virtualDx += deltaDx * gain;
    _lastDx = dx;
    _lastTimeMs = nowMs;

    _updateHysteresis();
  }

  void _updateHysteresis() {
    if (_virtualDx < _startPx) {
      _currentStepIndex = 0;
      return;
    }
    const snapHysteresisPx = 6.0;
    final rawIndex = ((_virtualDx - _startPx) / _rungPx).floor();
    if (rawIndex > _currentStepIndex) {
      final boundary = _startPx + (_currentStepIndex + 1) * _rungPx;
      if (_virtualDx >= boundary + snapHysteresisPx) {
        _currentStepIndex =
            ((_virtualDx - snapHysteresisPx - _startPx) / _rungPx).floor();
      }
    } else if (rawIndex < _currentStepIndex) {
      final boundary = _startPx + _currentStepIndex * _rungPx;
      if (_virtualDx < boundary - snapHysteresisPx) {
        _currentStepIndex =
            ((_virtualDx + snapHysteresisPx - _startPx) / _rungPx).floor();
      }
    }
  }

  void reset() {
    _virtualDx = 0.0;
    _lastDx = 0.0;
    _lastTimeMs = 0;
    _currentStepIndex = 0;
  }
}


/// One rung of the ladder. [whole] marks the food's own serving, the only rung
/// that can be logged as `qty × label` rather than as bare grams.
class PortionStep {
  const PortionStep(this.grams, {this.whole = false});

  final double grams;
  final bool whole;
}

/// Gram rungs for a food whose serving weighs [unitG]: a few round fractions
/// of it, then the whole serving. Rounded to 5 g, strictly increasing, and
/// never empty — a tiny serving collapses to the whole-unit rung alone.
List<PortionStep> portionSteps(double unitG) {
  final unit = unitG > 0 ? unitG : 100.0;
  final out = <PortionStep>[];
  for (final f in _fractions) {
    final g = (f * unit / 5).round() * 5.0;
    if (g < 5) continue;
    if (g < unit && (out.isEmpty || g > out.last.grams)) {
      out.add(PortionStep(g));
    }
  }
  return [...out, PortionStep(unit, whole: true)];
}

/// A picked amount: what to log, and what to show while picking it.
class Portion {
  const Portion({
    required this.grams,
    required this.label,
    this.qty,
    this.portionLabel,
  });

  final double grams;

  /// `2` in `2 × cup`. Null when the amount is bare grams, which is also what
  /// gets stored: `portion_qty`/`portion_label` are both null then.
  final double? qty;
  final String? portionLabel;

  /// What the row shows while the finger is down.
  final String label;

  /// Scales a per-100 g nutrient to this amount.
  double scale(double? per100g) => (per100g ?? 0) * grams / 100;
}

/// The portion for a drag of [dx]/[dy] from the row's start, or null while the
/// drag is still below the threshold.
///
/// [unitG] is the food's serving weight — `serving_g IS NULL` means "no defined
/// serving, treat it as per 100 g", so callers pass 100 with a null [unitLabel]
/// and every rung then reads as plain grams.
Portion? portionForDrag(
  double dx,
  double dy, {
  required double unitG,
  String? unitLabel,
  int? stepIndex,
}) {
  if (dx < _startPx) return null;
  final steps = portionSteps(unitG);
  final idx = stepIndex ?? ((dx - _startPx) ~/ _rungPx);
  final safeIndex = idx.clamp(0, 100000);

  final PortionStep step;
  if (safeIndex < steps.length) {
    step = steps[safeIndex];
  } else {
    final extra = safeIndex - (steps.length - 1);
    final unit = unitG > 0 ? unitG : 100.0;
    final lastGrams = steps.last.grams;
    final stepG = ((unit * 0.25 / 5).round() * 5.0).clamp(10.0, double.infinity);
    final extraGrams = lastGrams + extra * stepG;
    step = PortionStep(extraGrams, whole: false);
  }

  final mult = _multipliers[(2 + (dy / _multPx).round())
      .clamp(0, _multipliers.length - 1)];
  final grams = (step.grams * mult).roundToDouble();

  if (step.whole && unitLabel != null) {
    return Portion(
      grams: grams,
      qty: mult,
      portionLabel: unitLabel,
      label: '${formatQty(mult)} × $unitLabel',
    );
  }
  return Portion(grams: grams, label: '${grams.round()} g');
}

/// One serving — what a plain tap logs, and what the row shows before anyone
/// drags it.
Portion wholeServing(double unitG, String? unitLabel) => Portion(
      grams: unitG,
      qty: unitLabel == null ? null : 1,
      portionLabel: unitLabel,
      label: unitLabel == null ? '${unitG.round()} g' : '1 × $unitLabel',
    );

/// Height of one preparation on the wheel, and so the travel a spin is measured
/// in. The design settles on 0.7 of it per step, which lands the next label
/// under the finger a little before it has been dragged all the way there.
const prepRowPx = 30.0;
const _prepStepPx = prepRowPx * 0.7;

/// How far a drag counts as a tap in disguise.
const _prepTapPx = 5.0;

/// Which preparation a wheel resting on [index] of [count] lands on when a drag
/// of [dy] is released.
///
/// A drag clamps at the ends, but a tap-sized one *wraps*: with no travel to
/// read a direction off, "the next one" is the only thing it can mean, and a
/// wheel that stopped dead on the last preparation would look broken.
int prepForDrag(double dy, int index, int count) => dy.abs() < _prepTapPx
    ? (index + 1) % count
    : (index - (dy / _prepStepPx).round()).clamp(0, count - 1);

/// `2`, not `2.0`; `0.5` stays `0.5`.
String formatQty(double q) =>
    q == q.roundToDouble() ? q.round().toString() : '$q';

/// Grams as the pad shows them: whole above 100 g, one decimal below — and
/// never a bare `.0`.
String formatGrams(double g) =>
    g >= 100 ? '${g.round()}' : formatQty((g * 10).round() / 10);

/// A unit the portion pad can count in.
///
/// [isMeasure] is false for `g`/`oz`: a `portion_label` is a catalog measure of
/// *one*, so a gram conversion logs as bare grams instead.
class PortionUnit {
  const PortionUnit(this.label, this.gramWeight, {this.isMeasure = true});

  final String label;
  final double gramWeight;
  final bool isMeasure;
}

/// Units offered for a food: its own serving, then its catalog portions, then
/// the two gram conversions. Deduplicated by label and never empty.
///
// ponytail: the unit list is whatever the current schema exposes. Re-point this
// one function when the deduplicated portions schema lands.
List<PortionUnit> portionUnits({
  double? servingG,
  String? servingLabel,
  List<({String label, double gramWeight})> catalogPortions = const [],
}) {
  final out = <PortionUnit>[];
  void add(PortionUnit u) {
    if (u.gramWeight > 0 && !out.any((e) => e.label == u.label)) out.add(u);
  }

  if (servingG != null && servingLabel != null) {
    add(PortionUnit(servingLabel, servingG));
  }
  for (final p in catalogPortions) {
    add(PortionUnit(p.label, p.gramWeight));
  }
  add(const PortionUnit('g', 1, isMeasure: false));
  add(const PortionUnit('oz', 28.35, isMeasure: false));
  return out;
}

/// [amount] of [unit] as something loggable.
Portion portionFor(double amount, PortionUnit unit) {
  final grams = amount * unit.gramWeight;
  // A gram conversion logs as bare grams, so it reads as grams too — `4 oz`
  // stages as `113.4 g`.
  if (!unit.isMeasure) {
    return Portion(grams: grams, label: '${formatGrams(grams)} g');
  }
  return Portion(
    grams: grams,
    qty: amount,
    portionLabel: unit.label,
    label: '${formatQty(amount)} × ${unit.label}',
  );
}

/// The pad's amount field: whitespace-separated parts summed, each optionally a
/// fraction. `1 1/2` → 1.5, `150` → 150, anything unparseable → 0.
double parseAmount(String s) => s.trim().split(RegExp(r'\s+')).fold(0.0, (t, p) {
      final slash = p.indexOf('/');
      if (slash < 0) return t + (double.tryParse(p) ?? 0);
      final d = double.tryParse(p.substring(slash + 1)) ?? 0;
      if (d == 0) return t;
      return t + (double.tryParse(p.substring(0, slash)) ?? 0) / d;
    });
