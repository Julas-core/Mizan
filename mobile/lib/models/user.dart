import 'package:freezed_annotation/freezed_annotation.dart';

import 'goal.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    int? timeToSavingsGoalDays,
    String? email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserSummary with _$UserSummary {
  const factory UserSummary({
    @JsonKey(name: 'unallocated_money_cents')
    required int unallocatedMoneyCents,
    @JsonKey(name: 'total_goal_allocation_cents')
    required int totalGoalAllocationCents,
    required List<Goal> topGoals,
  }) = _UserSummary;

  factory UserSummary.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryFromJson(json);
}
