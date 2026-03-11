// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Purchase _$PurchaseFromJson(Map<String, dynamic> json) => _Purchase(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  itemName: json['item_name'] as String,
  priceCents: (json['price_cents'] as num).toInt(),
  category: json['category'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  aiEvaluation: json['ai_evaluation'] == null
      ? null
      : PurchaseEvaluation.fromJson(
          json['ai_evaluation'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PurchaseToJson(_Purchase instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'item_name': instance.itemName,
  'price_cents': instance.priceCents,
  'category': instance.category,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'ai_evaluation': instance.aiEvaluation,
};

_PurchaseEvaluation _$PurchaseEvaluationFromJson(Map<String, dynamic> json) =>
    _PurchaseEvaluation(
      verdict: json['verdict'] as String,
      reason: json['reason'] as String,
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      goalImpactDays: (json['goal_impact_days'] as num).toInt(),
      delayedGratificationSuggestionDays:
          (json['delayed_gratification_suggestion_days'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PurchaseEvaluationToJson(_PurchaseEvaluation instance) =>
    <String, dynamic>{
      'verdict': instance.verdict,
      'reason': instance.reason,
      'alternatives': instance.alternatives,
      'goal_impact_days': instance.goalImpactDays,
      'delayed_gratification_suggestion_days':
          instance.delayedGratificationSuggestionDays,
    };
