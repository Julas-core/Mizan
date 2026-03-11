// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Goal _$GoalFromJson(Map<String, dynamic> json) => _Goal(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  targetAmountCents: (json['target_amount_cents'] as num).toInt(),
  currentAmountCents: (json['current_amount_cents'] as num).toInt(),
  priority: (json['priority'] as num).toInt(),
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$GoalToJson(_Goal instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'target_amount_cents': instance.targetAmountCents,
  'current_amount_cents': instance.currentAmountCents,
  'priority': instance.priority,
  'image_url': instance.imageUrl,
};
