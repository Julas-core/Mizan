import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase.freezed.dart';
part 'purchase.g.dart';

@freezed
abstract class Purchase with _$Purchase {
  const factory Purchase({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'item_name') required String itemName,
    @JsonKey(name: 'price_cents') required int priceCents,
    required String category,
    required String status, // 'PENDING', 'APPROVED', 'ABANDONED', 'COMPLETED'
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'ai_evaluation') PurchaseEvaluation? aiEvaluation,
  }) = _Purchase;

  factory Purchase.fromJson(Map<String, dynamic> json) =>
      _$PurchaseFromJson(json);
}

@freezed
abstract class PurchaseEvaluation with _$PurchaseEvaluation {
  const factory PurchaseEvaluation({
    required String verdict, // 'APPROVE', 'DENY', 'DELAY'
    required String reason,
    required List<String> alternatives,
    @JsonKey(name: 'goal_impact_days') required int goalImpactDays,
    @JsonKey(name: 'delayed_gratification_suggestion_days')
    int? delayedGratificationSuggestionDays,
  }) = _PurchaseEvaluation;

  factory PurchaseEvaluation.fromJson(Map<String, dynamic> json) =>
      _$PurchaseEvaluationFromJson(json);
}
