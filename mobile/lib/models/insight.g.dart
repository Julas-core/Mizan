// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Insight _$InsightFromJson(Map<String, dynamic> json) => _Insight(
  mainBehaviorTrend: json['main_behavior_trend'] as String,
  fridayOverspendPercent: (json['friday_overspend_percent'] as num).toInt(),
  impulseWindow: json['impulse_window'] as String,
  topRegretCategory: json['top_regret_category'] as String,
  highRegretRatePercent: (json['high_regret_rate_percent'] as num).toInt(),
  boughtPurchasesCount: (json['bought_purchases_count'] as num).toInt(),
  totalBoughtSpendLast30dCents:
      (json['total_bought_spend_last_30d_cents'] as num).toInt(),
  behavioralScore: (json['behavioral_score'] as num).toInt(),
);

Map<String, dynamic> _$InsightToJson(_Insight instance) => <String, dynamic>{
  'main_behavior_trend': instance.mainBehaviorTrend,
  'friday_overspend_percent': instance.fridayOverspendPercent,
  'impulse_window': instance.impulseWindow,
  'top_regret_category': instance.topRegretCategory,
  'high_regret_rate_percent': instance.highRegretRatePercent,
  'bought_purchases_count': instance.boughtPurchasesCount,
  'total_bought_spend_last_30d_cents': instance.totalBoughtSpendLast30dCents,
  'behavioral_score': instance.behavioralScore,
};
