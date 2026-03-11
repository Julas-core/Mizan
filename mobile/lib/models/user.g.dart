// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  timeToSavingsGoalDays: (json['timeToSavingsGoalDays'] as num?)?.toInt(),
  email: json['email'] as String?,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'timeToSavingsGoalDays': instance.timeToSavingsGoalDays,
  'email': instance.email,
};

_UserSummary _$UserSummaryFromJson(Map<String, dynamic> json) => _UserSummary(
  unallocatedMoneyCents: (json['unallocated_money_cents'] as num).toInt(),
  totalGoalAllocationCents: (json['total_goal_allocation_cents'] as num)
      .toInt(),
  topGoals: (json['topGoals'] as List<dynamic>)
      .map((e) => Goal.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserSummaryToJson(_UserSummary instance) =>
    <String, dynamic>{
      'unallocated_money_cents': instance.unallocatedMoneyCents,
      'total_goal_allocation_cents': instance.totalGoalAllocationCents,
      'topGoals': instance.topGoals,
    };
