import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingGoalUpdate {
  const PendingGoalUpdate({
    required this.purchaseId,
    required this.goalId,
    required this.goalName,
    required this.purchaseAmountCents,
    required this.previousTargetCents,
    required this.expectedTargetCents,
    required this.createdAtIso,
  });

  final String purchaseId;
  final String goalId;
  final String goalName;
  final int purchaseAmountCents;
  final int previousTargetCents;
  final int expectedTargetCents;
  final String createdAtIso;

  Map<String, dynamic> toJson() => {
    'purchase_id': purchaseId,
    'goal_id': goalId,
    'goal_name': goalName,
    'purchase_amount_cents': purchaseAmountCents,
    'previous_target_cents': previousTargetCents,
    'expected_target_cents': expectedTargetCents,
    'created_at_iso': createdAtIso,
  };

  factory PendingGoalUpdate.fromJson(Map<String, dynamic> json) {
    return PendingGoalUpdate(
      purchaseId: json['purchase_id'] as String? ?? '',
      goalId: json['goal_id'] as String? ?? '',
      goalName: json['goal_name'] as String? ?? 'Goal',
      purchaseAmountCents: (json['purchase_amount_cents'] as num?)?.toInt() ?? 0,
      previousTargetCents: (json['previous_target_cents'] as num?)?.toInt() ?? 0,
      expectedTargetCents: (json['expected_target_cents'] as num?)?.toInt() ?? 0,
      createdAtIso: json['created_at_iso'] as String? ?? '',
    );
  }
}

class GoalUpdateTracker {
  static const String _storageKey = 'pending_goal_update';

  static Future<void> savePendingUpdate(PendingGoalUpdate update) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(update.toJson()));
  }

  static Future<PendingGoalUpdate?> getPendingUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final update = PendingGoalUpdate.fromJson(decoded);
      if (update.goalId.isEmpty || update.purchaseId.isEmpty) {
        await clearPendingUpdate();
        return null;
      }
      return update;
    } catch (_) {
      await clearPendingUpdate();
      return null;
    }
  }

  static Future<void> clearPendingUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
