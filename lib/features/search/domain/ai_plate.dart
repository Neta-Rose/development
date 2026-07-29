/// The rules that decide what lands on the plate.
///
/// Everything in this file is pure: no camera, no network, no database, no
/// providers. That is deliberate — the deduplication contract is the feature's
/// whole reason for existing, and it should be testable without any of them.
///
/// `AiCapture` in `../presentation/ai_providers.dart` is a thin orchestrator over
/// these functions.
library;

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/ai/vision_client.dart';
import '../../../core/ai/vision_models.dart';
import '../../home/data/catalog_repository.dart';
import '../presentation/search_providers.dart';
import 'food_match.dart';
import 'portion.dart';

part 'ai_plate.freezed.dart';

/// Confidence a detection needs before it is admitted to the plate. A guess the
/// detector itself is unsure of costs the user a swipe to remove, so the floor
/// buys more than it loses.
const confidenceFloor = 0.35;

/// Photos per batch. The service enforces the same cap on its side.
const maxShots = 8;

/// Loggable weight bounds. Outside them a reported weight is treated as absent.
const minGrams = 1.0;
const maxGrams = 2000.0;

/// What an item weighs when nothing better is known. Also the per-100 g basis a
/// generated food is stored on, so the two agree by construction.
const defaultGrams = 100.0;

/// Where the camera pane is.
enum AiPhase {
  /// Live preview, nothing in flight.
  live,

  /// A shot was taken and a detection is running.
  analyzing,

  /// A detection came back and its results are on the plate.
  result,

  /// The last detection failed. The plate is untouched and a retry is offered.
  failed,

  /// Camera permission is denied. Only the settings deep link can fix it.
  permissionDenied,
}

/// One captured photo. Plain rather than `@freezed` on purpose: this holds a
/// quarter-megabyte of JPEG, and a generated value `==` would deep-compare those
/// bytes every time the session state is reassigned.
class Shot {
  const Shot(this.number, this.bytes);

  /// 1-based within the batch. The prompt is written in terms of these numbers
  /// ("image 3 is shot 3"), so they are wire-visible, not cosmetic.
  final int number;

  final Uint8List bytes;
}

/// What marks a staged item as having come from the detector.
///
/// A `BatchItem` with a null [AiOrigin] came from search or quick add and is
/// never touched by a detection reply.
@freezed
abstract class AiOrigin with _$AiOrigin {
  const factory AiOrigin({
    required String instanceId,
    @Default(<int>[]) List<int> shots,
  }) = _AiOrigin;
}

/// A detection resolved against the catalog, ready to be merged.
class PlateCandidate {
  const PlateCandidate({
    required this.instanceId,
    required this.food,
    required this.grams,
    required this.shots,
  });

  final String instanceId;

  /// Either a catalog row, or a food the detector supplied whole. `isCustom`
  /// with neither id is the latter, which is the same shape quick add produces
  /// and which `Batch.logAll` already knows how to write.
  final FoodHit food;

  final double grams;
  final List<int> shots;
}

/// Everything one batch of photos knows about itself.
///
/// [editedIds] and [removedIds] live here rather than on the rows because a
/// removed item has no row left to carry a flag, and splitting the two would
/// scatter the re-analysis rules across two places that must agree.
@freezed
abstract class AiSession with _$AiSession {
  const factory AiSession({
    @Default(<Shot>[]) List<Shot> shots,
    @Default(AiPhase.live) AiPhase phase,
    VisionFailure? failure,
    @Default(false) bool torch,

    /// Instance ids whose grams the user set by hand. A later reply must not
    /// overwrite them — the user has seen the food and the detector has not.
    @Default(<String>{}) Set<String> editedIds,

    /// Instance ids the user removed. A later reply must not bring them back.
    @Default(<String>{}) Set<String> removedIds,
  }) = _AiSession;
}

/// Per-100 g values a generated food can be stored with.
///
/// Negatives are clamped, because `custom_foods` carries `>= 0` CHECKs and a
/// negative here is always a model error.
///
/// This is the **opposite** of the catalog path, where `carb_g` is genuinely
/// negative for ten USDA foods (carbohydrate by difference) and clamping would
/// make them unloggable. Never apply this to a catalog vector.
({double kcal, double protein, double carb, double fat}) clampPer100g(
        VisionDetection d) =>
    (
      kcal: d.kcal100g < 0 ? 0 : d.kcal100g,
      protein: d.protein100g < 0 ? 0 : d.protein100g,
      carb: d.carb100g < 0 ? 0 : d.carb100g,
      fat: d.fat100g < 0 ? 0 : d.fat100g,
    );

/// A loggable weight for [reported].
///
/// In range it is taken to the nearest whole gram. Out of range — which includes
/// the service's `0` for "no estimate" — it falls back to the matched food's own
/// serving weight, then to [defaultGrams].
double clampGrams(double reported, {double? servingG}) {
  if (reported >= minGrams && reported <= maxGrams) {
    return reported.roundToDouble();
  }
  if (servingG != null && servingG > 0) return servingG;
  return defaultGrams;
}

/// Turns one detection into something stageable, or drops it.
///
/// [candidates] is the primary FTS pass for the detection's search term.
/// Trigram-fallback hits are excluded upstream: a fuzzy hit is the
/// lower-confidence answer by construction, and admitting it here would let a
/// misspelling reach the threshold on a food the catalog does not carry.
PlateCandidate? resolveDetection(
  VisionDetection detection,
  List<FoodHit> candidates,
) {
  if (detection.confidence < confidenceFloor) return null;

  final name = detection.name.trim();
  if (name.isEmpty) return null;

  final shots = sortedShots(detection.shots);
  final matched = bestMatch(name, candidates);

  if (matched != null) {
    // The catalog row wins outright: it carries the full 50-nutrient vector,
    // where the detector offers four macros.
    return PlateCandidate(
      instanceId: detection.instanceId,
      food: matched,
      grams: clampGrams(detection.grams, servingG: matched.servingG),
      shots: shots,
    );
  }

  final per100g = clampPer100g(detection);
  final emoji = detection.emoji.trim();
  return PlateCandidate(
    instanceId: detection.instanceId,
    food: FoodHit(
      name: name,
      // Custom with neither id: no `custom_foods` row exists yet. The row is
      // written on the way out, the same path quick add takes.
      isCustom: true,
      emoji: emoji.isEmpty ? null : emoji,
      kcal100g: per100g.kcal,
      protein100g: per100g.protein,
      carb100g: per100g.carb,
      fat100g: per100g.fat,
      // Left null so the food reads as per 100 g and logs as bare grams, with
      // `portion_qty`/`portion_label` both NULL.
      servingG: null,
      servingLabel: null,
    ),
    grams: clampGrams(detection.grams),
    shots: shots,
  );
}

/// Merges a reply into the staged list. This is the deduplication step the whole
/// feature turns on.
///
/// In order:
///
/// 1. an item with no [AiOrigin] passes through untouched, in place — search and
///    quick add stage into the same list and must be unaffected;
/// 2. a candidate the user removed during this batch is skipped;
/// 3. a candidate whose id is already staged **rewrites that item where it
///    stands** — shots union, food and emoji refresh, grams follow the candidate
///    unless the user set them by hand;
/// 4. a candidate whose id is not staged is appended;
/// 5. a staged AI item the reply does not mention is left exactly as it is.
///
/// Steps 3 and 5 together make an empty candidate list the identity function,
/// which is why a failed detection cannot damage a plate the user already built.
///
/// Fresh instances are returned throughout and the caller replaces the whole
/// list in one assignment: `Batch` works by `identical`, so nothing downstream
/// may depend on comparing two items by value.
List<BatchItem> mergePlate({
  required List<BatchItem> batch,
  required List<PlateCandidate> candidates,
  required Set<String> editedIds,
  required Set<String> removedIds,
}) {
  final byId = <String, PlateCandidate>{};
  for (final candidate in candidates) {
    if (removedIds.contains(candidate.instanceId)) continue;
    byId[candidate.instanceId] = candidate;
  }

  final consumed = <String>{};
  final out = <BatchItem>[];

  for (final item in batch) {
    final origin = item.ai;
    if (origin == null) {
      out.add(item);
      continue;
    }
    final candidate = byId[origin.instanceId];
    if (candidate == null) {
      out.add(item);
      continue;
    }
    consumed.add(origin.instanceId);
    final grams = editedIds.contains(origin.instanceId)
        ? item.portion.grams
        : candidate.grams;
    out.add(_stage(
      candidate,
      grams: grams,
      shots: mergeShots(origin.shots, candidate.shots),
    ));
  }

  for (final candidate in candidates) {
    if (consumed.contains(candidate.instanceId)) continue;
    final fresh = byId[candidate.instanceId];
    // Skipped when removed, or when an earlier candidate in this same reply
    // already claimed the id.
    if (fresh == null || !identical(fresh, candidate)) continue;
    consumed.add(candidate.instanceId);
    out.add(_stage(candidate, grams: candidate.grams, shots: candidate.shots));
  }

  return out;
}

BatchItem _stage(
  PlateCandidate candidate, {
  required double grams,
  required List<int> shots,
}) =>
    BatchItem(
      candidate.food,
      // Bare grams: an amount the detector estimated is not `qty × label`, and
      // the design's plate row has nowhere to render a quantity anyway.
      Portion(grams: grams, label: '${grams.round()} g'),
      ai: AiOrigin(instanceId: candidate.instanceId, shots: shots),
    );

/// The staged plate as the request describes it, so the detector can reuse ids
/// instead of minting new ones for food it has already been shown.
List<PlateSummary> plateSummaries(List<BatchItem> batch) => [
      for (final item in batch)
        if (item.ai != null)
          (
            instanceId: item.ai!.instanceId,
            name: item.food.name,
            grams: item.portion.grams,
          ),
    ];

/// Deduplicated, ascending shot numbers.
List<int> sortedShots(Iterable<int> shots) {
  final set = shots.toSet().toList()..sort();
  return set;
}

List<int> mergeShots(Iterable<int> a, Iterable<int> b) =>
    sortedShots([...a, ...b]);
