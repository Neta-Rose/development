/// Photo → food detection.
///
/// ⚠️ MOCK — the only mocked input in the coach feature. Real on-device food
/// recognition is a phase-2 non-goal, so the *names and confidences* below are
/// fixtures from the coach spec.
///
/// Everything downstream of them is real: each name is resolved against the
/// attached USDA catalog, so the food ids, nutrition vectors, categories,
/// emoji and serving weights sent to the engine are genuine catalog data, not
/// invented numbers. Replacing this class with a real detector changes nothing
/// else — it returns the same `(name, confidence, grams)` triples.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/candidate.dart';
import 'coach_repository.dart';

part 'detection_source.g.dart';

@riverpod
Future<DetectionSource> detectionSource(Ref ref) async =>
    DetectionSource(await ref.watch(coachRepositoryProvider.future));

/// One raw detection, before it is resolved against the food library.
typedef Detection = ({String name, double? confidence, double? grams});

/// The spec's fixture set, chosen to exercise every confidence branch:
/// two high, one mid ("tap to fix"), one that resolves to nothing at all, and
/// one below the 0.5 line that arrives unchecked.
const _shots = <List<Detection>>[
  [
    (name: 'grilled chicken breast', confidence: 0.91, grams: 180),
    (name: 'white rice', confidence: 0.88, grams: 200),
    (name: 'greek salad', confidence: 0.61, grams: null),
  ],
  [
    (name: 'garlic shrimp', confidence: 0.86, grams: 120),
    // Resolves to nothing in the catalog — the unresolved branch, reached
    // honestly rather than forced.
    (name: 'beige dip in a bowl', confidence: null, grams: null),
    (name: 'bread basket', confidence: 0.44, grams: null),
  ],
];

class DetectionSource {
  DetectionSource(this._repo);

  final CoachRepository _repo;
  int _shot = 0;

  /// Detections for the next photo, cycling through the fixture shots so
  /// repeated captures keep producing plausible new items.
  Future<List<Candidate>> detect() async {
    final batch = _shots[_shot++ % _shots.length];
    // Deliberately not parallel: resolution hits the same sqlite connection.
    final out = <Candidate>[];
    for (final d in batch) {
      out.add(Candidate(
        detectedName: d.name,
        confidence: d.confidence,
        amountHintG: d.grams,
        resolved: await _repo.resolve(d.name),
      ));
    }
    return out;
  }
}
