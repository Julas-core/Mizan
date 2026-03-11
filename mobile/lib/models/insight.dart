import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight.freezed.dart';
part 'insight.g.dart';

@freezed
class Insight with _$Insight {
  const factory Insight({
    @JsonKey(name: 'main_behavior_trend') required String mainBehaviorTrend,
    @JsonKey(name: 'friday_overspend_percent')
    required int fridayOverspendPercent,
    @JsonKey(name: 'impulse_window') required String impulseWindow,
    @JsonKey(name: 'top_regret_category') required String topRegretCategory,
    @JsonKey(name: 'high_regret_rate_percent')
    required int highRegretRatePercent,
    @JsonKey(name: 'bought_purchases_count') required int boughtPurchasesCount,
    @JsonKey(name: 'total_bought_spend_last_30d_cents')
    required int totalBoughtSpendLast30dCents,
    @JsonKey(name: 'behavioral_score') required int behavioralScore,
  }) = _Insight;

  factory Insight.fromJson(Map<String, dynamic> json) =>
      _$InsightFromJson(json);
}
