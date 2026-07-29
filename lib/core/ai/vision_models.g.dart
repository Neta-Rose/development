// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vision_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VisionDetection _$VisionDetectionFromJson(Map<String, dynamic> json) =>
    _VisionDetection(
      instanceId: json['instance_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      searchTerm: json['search_term'] as String? ?? '',
      grams: (json['grams'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      shots:
          (json['shots'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      emoji: json['emoji'] as String? ?? '',
      kcal100g: (json['kcal_100g'] as num?)?.toDouble() ?? 0.0,
      protein100g: (json['protein_100g'] as num?)?.toDouble() ?? 0.0,
      carb100g: (json['carb_100g'] as num?)?.toDouble() ?? 0.0,
      fat100g: (json['fat_100g'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$VisionDetectionToJson(_VisionDetection instance) =>
    <String, dynamic>{
      'instance_id': instance.instanceId,
      'name': instance.name,
      'search_term': instance.searchTerm,
      'grams': instance.grams,
      'confidence': instance.confidence,
      'shots': instance.shots,
      'emoji': instance.emoji,
      'kcal_100g': instance.kcal100g,
      'protein_100g': instance.protein100g,
      'carb_100g': instance.carb100g,
      'fat_100g': instance.fat100g,
    };

_VisionReply _$VisionReplyFromJson(Map<String, dynamic> json) => _VisionReply(
  model: json['model'] as String? ?? '',
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => VisionDetection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <VisionDetection>[],
);

Map<String, dynamic> _$VisionReplyToJson(_VisionReply instance) =>
    <String, dynamic>{'model': instance.model, 'items': instance.items};
