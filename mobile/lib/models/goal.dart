import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

@freezed
abstract class Goal with _$Goal {
  const factory Goal({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'target_amount_cents') required int targetAmountCents,
    @JsonKey(name: 'current_amount_cents') required int currentAmountCents,
    required int priority,
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}
