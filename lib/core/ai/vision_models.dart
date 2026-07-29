import 'package:freezed_annotation/freezed_annotation.dart';

part 'vision_models.freezed.dart';
part 'vision_models.g.dart';

/// One distinct physical food item, as the plate-detect service reports it.
///
/// The field names are the service's wire names, which are in turn the names in
/// the model's response schema. Keeping one vocabulary end to end is what stops
/// the schema, the Go normaliser and this class from drifting into three
/// slightly different shapes.
///
/// The `@Default`s exist for robustness against a service older or newer than
/// this build, not because the schema allows omissions — it marks every field
/// required. A field that does arrive missing lands as `''` or `0`, which
/// `resolveDetection` then rejects or clamps rather than propagating.
@freezed
abstract class VisionDetection with _$VisionDetection {
  const factory VisionDetection({
    /// Identifies one physical item across every shot of the batch. This is the
    /// entire deduplication mechanism: the plate merges a detection into the row
    /// already carrying this id, and appends a row only when the id is new.
    @JsonKey(name: 'instance_id') @Default('') String instanceId,
    @Default('') String name,

    /// Generic food name for the catalog lookup: no brand, quantity or
    /// preparation.
    @JsonKey(name: 'search_term') @Default('') String searchTerm,

    /// Estimated edible weight. `0` means "no usable estimate" — a weight the
    /// service could not get from the model — and the caller falls back to the
    /// matched food's serving weight.
    @Default(0.0) double grams,
    @Default(0.0) double confidence,

    /// Ascending shot numbers this item appears in. More than one is what
    /// renders as `↺ N` and `shots 1·2·3, counted once`.
    @Default(<int>[]) List<int> shots,
    @Default('') String emoji,

    /// Per-100 g fallback nutrition, used only when no catalog row matches.
    @JsonKey(name: 'kcal_100g') @Default(0.0) double kcal100g,
    @JsonKey(name: 'protein_100g') @Default(0.0) double protein100g,
    @JsonKey(name: 'carb_100g') @Default(0.0) double carb100g,
    @JsonKey(name: 'fat_100g') @Default(0.0) double fat100g,
  }) = _VisionDetection;

  factory VisionDetection.fromJson(Map<String, dynamic> json) =>
      _$VisionDetectionFromJson(json);
}

/// A whole reply: the plate as the detector sees it after deduplication.
@freezed
abstract class VisionReply with _$VisionReply {
  const factory VisionReply({
    @Default('') String model,
    @Default(<VisionDetection>[]) List<VisionDetection> items,
  }) = _VisionReply;

  factory VisionReply.fromJson(Map<String, dynamic> json) =>
      _$VisionReplyFromJson(json);
}

/// Why a detection did not produce a plate.
///
/// Sealed, so the camera pane's copy is an exhaustive switch the compiler
/// checks: a new failure mode cannot be added without the UI being made to say
/// something about it.
///
/// No case carries a message, a body or a header. That is not tidiness — a
/// failure value that structurally cannot hold an upstream body structurally
/// cannot leak a credential through a log line.
sealed class VisionFailure {
  const VisionFailure();
}

/// No `PLATE_API_URL` in this build, or the service has no OpenRouter key.
final class VisionNotConfigured extends VisionFailure {
  const VisionNotConfigured();
}

/// The service, or the network to it, could not be reached.
final class VisionNoConnection extends VisionFailure {
  const VisionNoConnection();
}

final class VisionTimeout extends VisionFailure {
  const VisionTimeout();
}

/// A non-success status. [status] is the *upstream* model-provider status when
/// the service knew one, so `detection failed · 429` is renderable.
final class VisionHttpError extends VisionFailure {
  const VisionHttpError(this.status);

  final int status;
}

/// Two replies in a row that the service could not read as a plate.
final class VisionUnreadable extends VisionFailure {
  const VisionUnreadable();
}

/// A valid, empty answer: nothing edible in these shots.
final class VisionNoFood extends VisionFailure {
  const VisionNoFood();
}
