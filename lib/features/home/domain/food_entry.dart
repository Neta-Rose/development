// ignore_for_file: invalid_annotation_target — freezed's documented pattern
// for per-class json_serializable config.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_entry.freezed.dart';
part 'food_entry.g.dart';

enum EntryType { food, workout }

@freezed
abstract class FoodEntry with _$FoodEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory FoodEntry({
    required String id,
    required String name,
    required String icon,
    required EntryType type,

    /// For [EntryType.workout] entries this is the estimated burn.
    int? kcal,
    int? protein,
    int? carbs,
    int? fat,
    String? serving,
    String? meta,
    required DateTime loggedAt,
  }) = _FoodEntry;

  factory FoodEntry.fromJson(Map<String, dynamic> json) =>
      _$FoodEntryFromJson(json);
}
