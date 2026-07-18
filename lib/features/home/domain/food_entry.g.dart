// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FoodEntry _$FoodEntryFromJson(Map<String, dynamic> json) => _FoodEntry(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  type: $enumDecode(_$EntryTypeEnumMap, json['type']),
  kcal: (json['kcal'] as num?)?.toInt(),
  protein: (json['protein'] as num?)?.toInt(),
  carbs: (json['carbs'] as num?)?.toInt(),
  fat: (json['fat'] as num?)?.toInt(),
  serving: json['serving'] as String?,
  meta: json['meta'] as String?,
  loggedAt: DateTime.parse(json['logged_at'] as String),
);

Map<String, dynamic> _$FoodEntryToJson(_FoodEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'type': _$EntryTypeEnumMap[instance.type]!,
      'kcal': instance.kcal,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
      'serving': instance.serving,
      'meta': instance.meta,
      'logged_at': instance.loggedAt.toIso8601String(),
    };

const _$EntryTypeEnumMap = {
  EntryType.food: 'food',
  EntryType.workout: 'workout',
};
