import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/api/api_service.dart';
import '../models/goal.dart';
import '../models/insight.dart';
import '../models/purchase.dart';
import '../models/user.dart';

final apiRepositoryProvider = Provider<ApiRepository>((ref) => ApiRepository());

class ApiRepository {
  Future<UserSummary> getUserSummary() async {
    final data = await ApiService.getUserSummary();
    return UserSummary.fromJson(data);
  }

  Future<String> createUser() async {
    return await ApiService.createUser();
  }

  Future<void> createIncome({
    required int amountCents,
    required String frequency,
    required String nextPaydate,
    required double confidenceScore,
  }) async {
    await ApiService.createIncome(
      amountCents: amountCents,
      frequency: frequency,
      nextPaydate: nextPaydate,
      confidenceScore: confidenceScore,
    );
  }

  Future<void> createExpense({
    required String name,
    required int amountCents,
    required bool isFixed,
    required int? dueDateDay,
  }) async {
    await ApiService.createExpense(
      name: name,
      amountCents: amountCents,
      isFixed: isFixed,
      dueDateDay: dueDateDay,
    );
  }

  Future<void> createGoal({
    required String name,
    required int targetAmountCents,
    required int priorityWeight,
    String? imageUrl,
  }) async {
    await ApiService.createGoal(
      name: name,
      targetAmountCents: targetAmountCents,
      priorityWeight: priorityWeight,
      imageUrl: imageUrl,
    );
  }

  Future<List<Goal>> getGoals() async {
    final data = await ApiService.getGoals();
    return data.map((json) => Goal.fromJson(json)).toList();
  }

  Future<Insight> getHabitsInsights() async {
    final data = await ApiService.getHabitsInsights();
    return Insight.fromJson(data);
  }

  Future<Purchase> evaluatePurchase({
    required String itemName,
    required int priceCents,
    required String category,
    String? idempotencyKey,
  }) async {
    final data = await ApiService.evaluatePurchase(
      itemName: itemName,
      priceCents: priceCents,
      category: category,
      idempotencyKey: idempotencyKey,
    );
    return Purchase.fromJson(data);
  }

  Future<Purchase> getLatestEvaluatedPurchase() async {
    final data = await ApiService.getLatestEvaluatedPurchase();
    return Purchase.fromJson(data);
  }

  Future<Purchase> updatePurchaseStatus({
    required String purchaseId,
    required String status,
    String? spentFromGoalId,
    String? idempotencyKey,
  }) async {
    final data = await ApiService.updatePurchaseStatus(
      purchaseId: purchaseId,
      status: status,
      spentFromGoalId: spentFromGoalId,
      idempotencyKey: idempotencyKey,
    );
    return Purchase.fromJson(data);
  }

  Future<List<Purchase>> getPassedPurchases() async {
    final data = await ApiService.getPassedPurchases();
    return data.map((json) => Purchase.fromJson(json)).toList();
  }

  Future<Purchase> submitReflection({
    required String purchaseId,
    required int windowDays,
    required int regretScore,
    bool? feltFinancialPressure,
    double? actualDaysImpacted,
    String? idempotencyKey,
  }) async {
    final data = await ApiService.submitReflection(
      purchaseId: purchaseId,
      windowDays: windowDays,
      regretScore: regretScore,
      feltFinancialPressure: feltFinancialPressure,
      actualDaysImpacted: actualDaysImpacted,
      idempotencyKey: idempotencyKey,
    );
    return Purchase.fromJson(data);
  }

  Future<Map<String, dynamic>> postDecisionEvent({
    required String eventType,
    String? purchaseId,
    String? verdict,
    String? dominantFactor,
    String? riskLevel,
    String? category,
    String? amountBand,
    String? recommendedAction,
    String? userAction,
    bool? overrodeRecommendation,
    bool? feedbackHelpful,
    Map<String, dynamic>? metadataJson,
    String? idempotencyKey,
  }) async {
    return ApiService.postDecisionEvent(
      eventType: eventType,
      purchaseId: purchaseId,
      verdict: verdict,
      dominantFactor: dominantFactor,
      riskLevel: riskLevel,
      category: category,
      amountBand: amountBand,
      recommendedAction: recommendedAction,
      userAction: userAction,
      overrodeRecommendation: overrodeRecommendation,
      feedbackHelpful: feedbackHelpful,
      metadataJson: metadataJson,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<Map<String, dynamic>> getDecisionQuality({
    int lookbackDays = 30,
    int minSample = 5,
  }) async {
    return ApiService.getDecisionQuality(
      lookbackDays: lookbackDays,
      minSample: minSample,
    );
  }
}
