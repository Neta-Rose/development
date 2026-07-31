import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../home/data/catalog_repository.dart';
import '../domain/portion.dart';
import 'scan_stub.dart';

part 'scan_providers.g.dart';

/// How long the viewfinder looks before it has an answer.
const _armDelay = Duration(milliseconds: 1900);

/// Quantities the match card's stepper will count to.
const _minQty = 1;
const _maxQty = 6;

enum ScanPhase {
  /// Pointed at nothing yet — the sweep is running.
  searching,

  /// A product is on the card, waiting for a portion and a confirm.
  found,
}

/// A scanned product: an ordinary [FoodHit] plus the three things a packet has
/// that a search hit does not.
class ScanProduct {
  const ScanProduct({
    required this.brand,
    required this.code,
    required this.serving,
    required this.food,
  });

  final String brand;

  /// As printed under the bars, spaced the way the packet spaces it.
  final String code;

  /// The amount printed on the packet. Never absent — naming it is most of what
  /// the barcode is for.
  final PortionUnit serving;

  final FoodHit food;
}

/// What scan mode knows about itself.
///
/// Plain rather than `@freezed`: four scalar fields, one writer and no extra part
/// file — the same trade [ScanProduct] and `Shot` make.
class ScanSession {
  const ScanSession({
    this.phase = ScanPhase.searching,
    this.index = 0,
    this.qty = _minQty,
    this.torch = false,
  });

  final ScanPhase phase;

  /// Which product this scan lands on. Counts up forever and wraps, so the list
  /// cycles rather than running out.
  final int index;

  /// Servings of [match], as the stepper has it. Always within 1..6.
  final int qty;

  final bool torch;

  ScanProduct get match => scanProducts[index % scanProducts.length];

  ScanSession copyWith({ScanPhase? phase, int? index, int? qty, bool? torch}) =>
      ScanSession(
        phase: phase ?? this.phase,
        index: index ?? this.index,
        qty: qty ?? this.qty,
        torch: torch ?? this.torch,
      );
}

/// Barcode scan's own state: which product, how many of it, and the torch.
///
/// Nothing staged lives here — the match card writes a `BatchItem` into
/// `batchProvider` like every other mode, so the header totals, the chip strip
/// and the check button need to know nothing about scanning.
///
/// Auto-disposed, which is what cancels the arm timer when the user switches mode
/// or leaves the screen.
@riverpod
class Scan extends _$Scan {
  Timer? _timer;

  @override
  ScanSession build() {
    ref.onDispose(() => _timer?.cancel());
    _arm();
    return const ScanSession();
  }

  /// Starts looking. Stands in for pointing a decoder at a barcode — see
  /// `scan_stub.dart`.
  void _arm() {
    _timer?.cancel();
    _timer = Timer(
        _armDelay, () => state = state.copyWith(phase: ScanPhase.found));
  }

  /// Throws this match away and looks for the next one. What the card's `×` does,
  /// and what staging one does after it.
  void rescan() {
    state = ScanSession(index: state.index + 1, torch: state.torch);
    _arm();
  }

  void bumpQty(int by) =>
      state = state.copyWith(qty: (state.qty + by).clamp(_minQty, _maxQty));

  /// Inert beyond its own colour: there is no camera behind scan mode to light.
  void toggleTorch() => state = state.copyWith(torch: !state.torch);
}
