// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Purchase {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'item_name') String get itemName;@JsonKey(name: 'price_cents') int get priceCents; String get category; String get status;// 'PENDING', 'APPROVED', 'ABANDONED', 'COMPLETED'
@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'ai_evaluation') PurchaseEvaluation? get aiEvaluation;
/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseCopyWith<Purchase> get copyWith => _$PurchaseCopyWithImpl<Purchase>(this as Purchase, _$identity);

  /// Serializes this Purchase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Purchase&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.aiEvaluation, aiEvaluation) || other.aiEvaluation == aiEvaluation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,itemName,priceCents,category,status,createdAt,aiEvaluation);

@override
String toString() {
  return 'Purchase(id: $id, userId: $userId, itemName: $itemName, priceCents: $priceCents, category: $category, status: $status, createdAt: $createdAt, aiEvaluation: $aiEvaluation)';
}


}

/// @nodoc
abstract mixin class $PurchaseCopyWith<$Res>  {
  factory $PurchaseCopyWith(Purchase value, $Res Function(Purchase) _then) = _$PurchaseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'item_name') String itemName,@JsonKey(name: 'price_cents') int priceCents, String category, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'ai_evaluation') PurchaseEvaluation? aiEvaluation
});


$PurchaseEvaluationCopyWith<$Res>? get aiEvaluation;

}
/// @nodoc
class _$PurchaseCopyWithImpl<$Res>
    implements $PurchaseCopyWith<$Res> {
  _$PurchaseCopyWithImpl(this._self, this._then);

  final Purchase _self;
  final $Res Function(Purchase) _then;

/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? itemName = null,Object? priceCents = null,Object? category = null,Object? status = null,Object? createdAt = null,Object? aiEvaluation = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,itemName: null == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,aiEvaluation: freezed == aiEvaluation ? _self.aiEvaluation : aiEvaluation // ignore: cast_nullable_to_non_nullable
as PurchaseEvaluation?,
  ));
}
/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseEvaluationCopyWith<$Res>? get aiEvaluation {
    if (_self.aiEvaluation == null) {
    return null;
  }

  return $PurchaseEvaluationCopyWith<$Res>(_self.aiEvaluation!, (value) {
    return _then(_self.copyWith(aiEvaluation: value));
  });
}
}


/// Adds pattern-matching-related methods to [Purchase].
extension PurchasePatterns on Purchase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Purchase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Purchase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Purchase value)  $default,){
final _that = this;
switch (_that) {
case _Purchase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Purchase value)?  $default,){
final _that = this;
switch (_that) {
case _Purchase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'item_name')  String itemName, @JsonKey(name: 'price_cents')  int priceCents,  String category,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'ai_evaluation')  PurchaseEvaluation? aiEvaluation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Purchase() when $default != null:
return $default(_that.id,_that.userId,_that.itemName,_that.priceCents,_that.category,_that.status,_that.createdAt,_that.aiEvaluation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'item_name')  String itemName, @JsonKey(name: 'price_cents')  int priceCents,  String category,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'ai_evaluation')  PurchaseEvaluation? aiEvaluation)  $default,) {final _that = this;
switch (_that) {
case _Purchase():
return $default(_that.id,_that.userId,_that.itemName,_that.priceCents,_that.category,_that.status,_that.createdAt,_that.aiEvaluation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'item_name')  String itemName, @JsonKey(name: 'price_cents')  int priceCents,  String category,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'ai_evaluation')  PurchaseEvaluation? aiEvaluation)?  $default,) {final _that = this;
switch (_that) {
case _Purchase() when $default != null:
return $default(_that.id,_that.userId,_that.itemName,_that.priceCents,_that.category,_that.status,_that.createdAt,_that.aiEvaluation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Purchase implements Purchase {
  const _Purchase({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'item_name') required this.itemName, @JsonKey(name: 'price_cents') required this.priceCents, required this.category, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'ai_evaluation') this.aiEvaluation});
  factory _Purchase.fromJson(Map<String, dynamic> json) => _$PurchaseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'item_name') final  String itemName;
@override@JsonKey(name: 'price_cents') final  int priceCents;
@override final  String category;
@override final  String status;
// 'PENDING', 'APPROVED', 'ABANDONED', 'COMPLETED'
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'ai_evaluation') final  PurchaseEvaluation? aiEvaluation;

/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseCopyWith<_Purchase> get copyWith => __$PurchaseCopyWithImpl<_Purchase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Purchase&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.priceCents, priceCents) || other.priceCents == priceCents)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.aiEvaluation, aiEvaluation) || other.aiEvaluation == aiEvaluation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,itemName,priceCents,category,status,createdAt,aiEvaluation);

@override
String toString() {
  return 'Purchase(id: $id, userId: $userId, itemName: $itemName, priceCents: $priceCents, category: $category, status: $status, createdAt: $createdAt, aiEvaluation: $aiEvaluation)';
}


}

/// @nodoc
abstract mixin class _$PurchaseCopyWith<$Res> implements $PurchaseCopyWith<$Res> {
  factory _$PurchaseCopyWith(_Purchase value, $Res Function(_Purchase) _then) = __$PurchaseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'item_name') String itemName,@JsonKey(name: 'price_cents') int priceCents, String category, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'ai_evaluation') PurchaseEvaluation? aiEvaluation
});


@override $PurchaseEvaluationCopyWith<$Res>? get aiEvaluation;

}
/// @nodoc
class __$PurchaseCopyWithImpl<$Res>
    implements _$PurchaseCopyWith<$Res> {
  __$PurchaseCopyWithImpl(this._self, this._then);

  final _Purchase _self;
  final $Res Function(_Purchase) _then;

/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? itemName = null,Object? priceCents = null,Object? category = null,Object? status = null,Object? createdAt = null,Object? aiEvaluation = freezed,}) {
  return _then(_Purchase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,itemName: null == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String,priceCents: null == priceCents ? _self.priceCents : priceCents // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,aiEvaluation: freezed == aiEvaluation ? _self.aiEvaluation : aiEvaluation // ignore: cast_nullable_to_non_nullable
as PurchaseEvaluation?,
  ));
}

/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseEvaluationCopyWith<$Res>? get aiEvaluation {
    if (_self.aiEvaluation == null) {
    return null;
  }

  return $PurchaseEvaluationCopyWith<$Res>(_self.aiEvaluation!, (value) {
    return _then(_self.copyWith(aiEvaluation: value));
  });
}
}


/// @nodoc
mixin _$PurchaseEvaluation {

 String get verdict;// 'APPROVE', 'DENY', 'DELAY'
 String get reason; List<String> get alternatives;@JsonKey(name: 'goal_impact_days') int get goalImpactDays;@JsonKey(name: 'delayed_gratification_suggestion_days') int? get delayedGratificationSuggestionDays;
/// Create a copy of PurchaseEvaluation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseEvaluationCopyWith<PurchaseEvaluation> get copyWith => _$PurchaseEvaluationCopyWithImpl<PurchaseEvaluation>(this as PurchaseEvaluation, _$identity);

  /// Serializes this PurchaseEvaluation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseEvaluation&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.alternatives, alternatives)&&(identical(other.goalImpactDays, goalImpactDays) || other.goalImpactDays == goalImpactDays)&&(identical(other.delayedGratificationSuggestionDays, delayedGratificationSuggestionDays) || other.delayedGratificationSuggestionDays == delayedGratificationSuggestionDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verdict,reason,const DeepCollectionEquality().hash(alternatives),goalImpactDays,delayedGratificationSuggestionDays);

@override
String toString() {
  return 'PurchaseEvaluation(verdict: $verdict, reason: $reason, alternatives: $alternatives, goalImpactDays: $goalImpactDays, delayedGratificationSuggestionDays: $delayedGratificationSuggestionDays)';
}


}

/// @nodoc
abstract mixin class $PurchaseEvaluationCopyWith<$Res>  {
  factory $PurchaseEvaluationCopyWith(PurchaseEvaluation value, $Res Function(PurchaseEvaluation) _then) = _$PurchaseEvaluationCopyWithImpl;
@useResult
$Res call({
 String verdict, String reason, List<String> alternatives,@JsonKey(name: 'goal_impact_days') int goalImpactDays,@JsonKey(name: 'delayed_gratification_suggestion_days') int? delayedGratificationSuggestionDays
});




}
/// @nodoc
class _$PurchaseEvaluationCopyWithImpl<$Res>
    implements $PurchaseEvaluationCopyWith<$Res> {
  _$PurchaseEvaluationCopyWithImpl(this._self, this._then);

  final PurchaseEvaluation _self;
  final $Res Function(PurchaseEvaluation) _then;

/// Create a copy of PurchaseEvaluation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verdict = null,Object? reason = null,Object? alternatives = null,Object? goalImpactDays = null,Object? delayedGratificationSuggestionDays = freezed,}) {
  return _then(_self.copyWith(
verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<String>,goalImpactDays: null == goalImpactDays ? _self.goalImpactDays : goalImpactDays // ignore: cast_nullable_to_non_nullable
as int,delayedGratificationSuggestionDays: freezed == delayedGratificationSuggestionDays ? _self.delayedGratificationSuggestionDays : delayedGratificationSuggestionDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseEvaluation].
extension PurchaseEvaluationPatterns on PurchaseEvaluation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseEvaluation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseEvaluation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseEvaluation value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseEvaluation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseEvaluation value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseEvaluation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String verdict,  String reason,  List<String> alternatives, @JsonKey(name: 'goal_impact_days')  int goalImpactDays, @JsonKey(name: 'delayed_gratification_suggestion_days')  int? delayedGratificationSuggestionDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseEvaluation() when $default != null:
return $default(_that.verdict,_that.reason,_that.alternatives,_that.goalImpactDays,_that.delayedGratificationSuggestionDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String verdict,  String reason,  List<String> alternatives, @JsonKey(name: 'goal_impact_days')  int goalImpactDays, @JsonKey(name: 'delayed_gratification_suggestion_days')  int? delayedGratificationSuggestionDays)  $default,) {final _that = this;
switch (_that) {
case _PurchaseEvaluation():
return $default(_that.verdict,_that.reason,_that.alternatives,_that.goalImpactDays,_that.delayedGratificationSuggestionDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String verdict,  String reason,  List<String> alternatives, @JsonKey(name: 'goal_impact_days')  int goalImpactDays, @JsonKey(name: 'delayed_gratification_suggestion_days')  int? delayedGratificationSuggestionDays)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseEvaluation() when $default != null:
return $default(_that.verdict,_that.reason,_that.alternatives,_that.goalImpactDays,_that.delayedGratificationSuggestionDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseEvaluation implements PurchaseEvaluation {
  const _PurchaseEvaluation({required this.verdict, required this.reason, required final  List<String> alternatives, @JsonKey(name: 'goal_impact_days') required this.goalImpactDays, @JsonKey(name: 'delayed_gratification_suggestion_days') this.delayedGratificationSuggestionDays}): _alternatives = alternatives;
  factory _PurchaseEvaluation.fromJson(Map<String, dynamic> json) => _$PurchaseEvaluationFromJson(json);

@override final  String verdict;
// 'APPROVE', 'DENY', 'DELAY'
@override final  String reason;
 final  List<String> _alternatives;
@override List<String> get alternatives {
  if (_alternatives is EqualUnmodifiableListView) return _alternatives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alternatives);
}

@override@JsonKey(name: 'goal_impact_days') final  int goalImpactDays;
@override@JsonKey(name: 'delayed_gratification_suggestion_days') final  int? delayedGratificationSuggestionDays;

/// Create a copy of PurchaseEvaluation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseEvaluationCopyWith<_PurchaseEvaluation> get copyWith => __$PurchaseEvaluationCopyWithImpl<_PurchaseEvaluation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseEvaluationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseEvaluation&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._alternatives, _alternatives)&&(identical(other.goalImpactDays, goalImpactDays) || other.goalImpactDays == goalImpactDays)&&(identical(other.delayedGratificationSuggestionDays, delayedGratificationSuggestionDays) || other.delayedGratificationSuggestionDays == delayedGratificationSuggestionDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verdict,reason,const DeepCollectionEquality().hash(_alternatives),goalImpactDays,delayedGratificationSuggestionDays);

@override
String toString() {
  return 'PurchaseEvaluation(verdict: $verdict, reason: $reason, alternatives: $alternatives, goalImpactDays: $goalImpactDays, delayedGratificationSuggestionDays: $delayedGratificationSuggestionDays)';
}


}

/// @nodoc
abstract mixin class _$PurchaseEvaluationCopyWith<$Res> implements $PurchaseEvaluationCopyWith<$Res> {
  factory _$PurchaseEvaluationCopyWith(_PurchaseEvaluation value, $Res Function(_PurchaseEvaluation) _then) = __$PurchaseEvaluationCopyWithImpl;
@override @useResult
$Res call({
 String verdict, String reason, List<String> alternatives,@JsonKey(name: 'goal_impact_days') int goalImpactDays,@JsonKey(name: 'delayed_gratification_suggestion_days') int? delayedGratificationSuggestionDays
});




}
/// @nodoc
class __$PurchaseEvaluationCopyWithImpl<$Res>
    implements _$PurchaseEvaluationCopyWith<$Res> {
  __$PurchaseEvaluationCopyWithImpl(this._self, this._then);

  final _PurchaseEvaluation _self;
  final $Res Function(_PurchaseEvaluation) _then;

/// Create a copy of PurchaseEvaluation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verdict = null,Object? reason = null,Object? alternatives = null,Object? goalImpactDays = null,Object? delayedGratificationSuggestionDays = freezed,}) {
  return _then(_PurchaseEvaluation(
verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,alternatives: null == alternatives ? _self._alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<String>,goalImpactDays: null == goalImpactDays ? _self.goalImpactDays : goalImpactDays // ignore: cast_nullable_to_non_nullable
as int,delayedGratificationSuggestionDays: freezed == delayedGratificationSuggestionDays ? _self.delayedGratificationSuggestionDays : delayedGratificationSuggestionDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
