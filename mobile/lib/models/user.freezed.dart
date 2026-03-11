// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

 String get id; int? get timeToSavingsGoalDays; String? get email;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.timeToSavingsGoalDays, timeToSavingsGoalDays) || other.timeToSavingsGoalDays == timeToSavingsGoalDays)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timeToSavingsGoalDays,email);

@override
String toString() {
  return 'User(id: $id, timeToSavingsGoalDays: $timeToSavingsGoalDays, email: $email)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 String id, int? timeToSavingsGoalDays, String? email
});




}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? timeToSavingsGoalDays = freezed,Object? email = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timeToSavingsGoalDays: freezed == timeToSavingsGoalDays ? _self.timeToSavingsGoalDays : timeToSavingsGoalDays // ignore: cast_nullable_to_non_nullable
as int?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int? timeToSavingsGoalDays,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.timeToSavingsGoalDays,_that.email);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int? timeToSavingsGoalDays,  String? email)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.id,_that.timeToSavingsGoalDays,_that.email);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int? timeToSavingsGoalDays,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.timeToSavingsGoalDays,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({required this.id, this.timeToSavingsGoalDays, this.email});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  String id;
@override final  int? timeToSavingsGoalDays;
@override final  String? email;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.timeToSavingsGoalDays, timeToSavingsGoalDays) || other.timeToSavingsGoalDays == timeToSavingsGoalDays)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timeToSavingsGoalDays,email);

@override
String toString() {
  return 'User(id: $id, timeToSavingsGoalDays: $timeToSavingsGoalDays, email: $email)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 String id, int? timeToSavingsGoalDays, String? email
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? timeToSavingsGoalDays = freezed,Object? email = freezed,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timeToSavingsGoalDays: freezed == timeToSavingsGoalDays ? _self.timeToSavingsGoalDays : timeToSavingsGoalDays // ignore: cast_nullable_to_non_nullable
as int?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UserSummary {

@JsonKey(name: 'unallocated_money_cents') int get unallocatedMoneyCents;@JsonKey(name: 'total_goal_allocation_cents') int get totalGoalAllocationCents; List<Goal> get topGoals;
/// Create a copy of UserSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSummaryCopyWith<UserSummary> get copyWith => _$UserSummaryCopyWithImpl<UserSummary>(this as UserSummary, _$identity);

  /// Serializes this UserSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSummary&&(identical(other.unallocatedMoneyCents, unallocatedMoneyCents) || other.unallocatedMoneyCents == unallocatedMoneyCents)&&(identical(other.totalGoalAllocationCents, totalGoalAllocationCents) || other.totalGoalAllocationCents == totalGoalAllocationCents)&&const DeepCollectionEquality().equals(other.topGoals, topGoals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unallocatedMoneyCents,totalGoalAllocationCents,const DeepCollectionEquality().hash(topGoals));

@override
String toString() {
  return 'UserSummary(unallocatedMoneyCents: $unallocatedMoneyCents, totalGoalAllocationCents: $totalGoalAllocationCents, topGoals: $topGoals)';
}


}

/// @nodoc
abstract mixin class $UserSummaryCopyWith<$Res>  {
  factory $UserSummaryCopyWith(UserSummary value, $Res Function(UserSummary) _then) = _$UserSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'unallocated_money_cents') int unallocatedMoneyCents,@JsonKey(name: 'total_goal_allocation_cents') int totalGoalAllocationCents, List<Goal> topGoals
});




}
/// @nodoc
class _$UserSummaryCopyWithImpl<$Res>
    implements $UserSummaryCopyWith<$Res> {
  _$UserSummaryCopyWithImpl(this._self, this._then);

  final UserSummary _self;
  final $Res Function(UserSummary) _then;

/// Create a copy of UserSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unallocatedMoneyCents = null,Object? totalGoalAllocationCents = null,Object? topGoals = null,}) {
  return _then(_self.copyWith(
unallocatedMoneyCents: null == unallocatedMoneyCents ? _self.unallocatedMoneyCents : unallocatedMoneyCents // ignore: cast_nullable_to_non_nullable
as int,totalGoalAllocationCents: null == totalGoalAllocationCents ? _self.totalGoalAllocationCents : totalGoalAllocationCents // ignore: cast_nullable_to_non_nullable
as int,topGoals: null == topGoals ? _self.topGoals : topGoals // ignore: cast_nullable_to_non_nullable
as List<Goal>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSummary].
extension UserSummaryPatterns on UserSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSummary value)  $default,){
final _that = this;
switch (_that) {
case _UserSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSummary value)?  $default,){
final _that = this;
switch (_that) {
case _UserSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'unallocated_money_cents')  int unallocatedMoneyCents, @JsonKey(name: 'total_goal_allocation_cents')  int totalGoalAllocationCents,  List<Goal> topGoals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSummary() when $default != null:
return $default(_that.unallocatedMoneyCents,_that.totalGoalAllocationCents,_that.topGoals);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'unallocated_money_cents')  int unallocatedMoneyCents, @JsonKey(name: 'total_goal_allocation_cents')  int totalGoalAllocationCents,  List<Goal> topGoals)  $default,) {final _that = this;
switch (_that) {
case _UserSummary():
return $default(_that.unallocatedMoneyCents,_that.totalGoalAllocationCents,_that.topGoals);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'unallocated_money_cents')  int unallocatedMoneyCents, @JsonKey(name: 'total_goal_allocation_cents')  int totalGoalAllocationCents,  List<Goal> topGoals)?  $default,) {final _that = this;
switch (_that) {
case _UserSummary() when $default != null:
return $default(_that.unallocatedMoneyCents,_that.totalGoalAllocationCents,_that.topGoals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSummary implements UserSummary {
  const _UserSummary({@JsonKey(name: 'unallocated_money_cents') required this.unallocatedMoneyCents, @JsonKey(name: 'total_goal_allocation_cents') required this.totalGoalAllocationCents, required final  List<Goal> topGoals}): _topGoals = topGoals;
  factory _UserSummary.fromJson(Map<String, dynamic> json) => _$UserSummaryFromJson(json);

@override@JsonKey(name: 'unallocated_money_cents') final  int unallocatedMoneyCents;
@override@JsonKey(name: 'total_goal_allocation_cents') final  int totalGoalAllocationCents;
 final  List<Goal> _topGoals;
@override List<Goal> get topGoals {
  if (_topGoals is EqualUnmodifiableListView) return _topGoals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topGoals);
}


/// Create a copy of UserSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSummaryCopyWith<_UserSummary> get copyWith => __$UserSummaryCopyWithImpl<_UserSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSummary&&(identical(other.unallocatedMoneyCents, unallocatedMoneyCents) || other.unallocatedMoneyCents == unallocatedMoneyCents)&&(identical(other.totalGoalAllocationCents, totalGoalAllocationCents) || other.totalGoalAllocationCents == totalGoalAllocationCents)&&const DeepCollectionEquality().equals(other._topGoals, _topGoals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,unallocatedMoneyCents,totalGoalAllocationCents,const DeepCollectionEquality().hash(_topGoals));

@override
String toString() {
  return 'UserSummary(unallocatedMoneyCents: $unallocatedMoneyCents, totalGoalAllocationCents: $totalGoalAllocationCents, topGoals: $topGoals)';
}


}

/// @nodoc
abstract mixin class _$UserSummaryCopyWith<$Res> implements $UserSummaryCopyWith<$Res> {
  factory _$UserSummaryCopyWith(_UserSummary value, $Res Function(_UserSummary) _then) = __$UserSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'unallocated_money_cents') int unallocatedMoneyCents,@JsonKey(name: 'total_goal_allocation_cents') int totalGoalAllocationCents, List<Goal> topGoals
});




}
/// @nodoc
class __$UserSummaryCopyWithImpl<$Res>
    implements _$UserSummaryCopyWith<$Res> {
  __$UserSummaryCopyWithImpl(this._self, this._then);

  final _UserSummary _self;
  final $Res Function(_UserSummary) _then;

/// Create a copy of UserSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unallocatedMoneyCents = null,Object? totalGoalAllocationCents = null,Object? topGoals = null,}) {
  return _then(_UserSummary(
unallocatedMoneyCents: null == unallocatedMoneyCents ? _self.unallocatedMoneyCents : unallocatedMoneyCents // ignore: cast_nullable_to_non_nullable
as int,totalGoalAllocationCents: null == totalGoalAllocationCents ? _self.totalGoalAllocationCents : totalGoalAllocationCents // ignore: cast_nullable_to_non_nullable
as int,topGoals: null == topGoals ? _self._topGoals : topGoals // ignore: cast_nullable_to_non_nullable
as List<Goal>,
  ));
}


}

// dart format on
