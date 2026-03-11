// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Insight {

@JsonKey(name: 'main_behavior_trend') String get mainBehaviorTrend;@JsonKey(name: 'friday_overspend_percent') int get fridayOverspendPercent;@JsonKey(name: 'impulse_window') String get impulseWindow;@JsonKey(name: 'top_regret_category') String get topRegretCategory;@JsonKey(name: 'high_regret_rate_percent') int get highRegretRatePercent;@JsonKey(name: 'bought_purchases_count') int get boughtPurchasesCount;@JsonKey(name: 'total_bought_spend_last_30d_cents') int get totalBoughtSpendLast30dCents;@JsonKey(name: 'behavioral_score') int get behavioralScore;
/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightCopyWith<Insight> get copyWith => _$InsightCopyWithImpl<Insight>(this as Insight, _$identity);

  /// Serializes this Insight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Insight&&(identical(other.mainBehaviorTrend, mainBehaviorTrend) || other.mainBehaviorTrend == mainBehaviorTrend)&&(identical(other.fridayOverspendPercent, fridayOverspendPercent) || other.fridayOverspendPercent == fridayOverspendPercent)&&(identical(other.impulseWindow, impulseWindow) || other.impulseWindow == impulseWindow)&&(identical(other.topRegretCategory, topRegretCategory) || other.topRegretCategory == topRegretCategory)&&(identical(other.highRegretRatePercent, highRegretRatePercent) || other.highRegretRatePercent == highRegretRatePercent)&&(identical(other.boughtPurchasesCount, boughtPurchasesCount) || other.boughtPurchasesCount == boughtPurchasesCount)&&(identical(other.totalBoughtSpendLast30dCents, totalBoughtSpendLast30dCents) || other.totalBoughtSpendLast30dCents == totalBoughtSpendLast30dCents)&&(identical(other.behavioralScore, behavioralScore) || other.behavioralScore == behavioralScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mainBehaviorTrend,fridayOverspendPercent,impulseWindow,topRegretCategory,highRegretRatePercent,boughtPurchasesCount,totalBoughtSpendLast30dCents,behavioralScore);

@override
String toString() {
  return 'Insight(mainBehaviorTrend: $mainBehaviorTrend, fridayOverspendPercent: $fridayOverspendPercent, impulseWindow: $impulseWindow, topRegretCategory: $topRegretCategory, highRegretRatePercent: $highRegretRatePercent, boughtPurchasesCount: $boughtPurchasesCount, totalBoughtSpendLast30dCents: $totalBoughtSpendLast30dCents, behavioralScore: $behavioralScore)';
}


}

/// @nodoc
abstract mixin class $InsightCopyWith<$Res>  {
  factory $InsightCopyWith(Insight value, $Res Function(Insight) _then) = _$InsightCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'main_behavior_trend') String mainBehaviorTrend,@JsonKey(name: 'friday_overspend_percent') int fridayOverspendPercent,@JsonKey(name: 'impulse_window') String impulseWindow,@JsonKey(name: 'top_regret_category') String topRegretCategory,@JsonKey(name: 'high_regret_rate_percent') int highRegretRatePercent,@JsonKey(name: 'bought_purchases_count') int boughtPurchasesCount,@JsonKey(name: 'total_bought_spend_last_30d_cents') int totalBoughtSpendLast30dCents,@JsonKey(name: 'behavioral_score') int behavioralScore
});




}
/// @nodoc
class _$InsightCopyWithImpl<$Res>
    implements $InsightCopyWith<$Res> {
  _$InsightCopyWithImpl(this._self, this._then);

  final Insight _self;
  final $Res Function(Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mainBehaviorTrend = null,Object? fridayOverspendPercent = null,Object? impulseWindow = null,Object? topRegretCategory = null,Object? highRegretRatePercent = null,Object? boughtPurchasesCount = null,Object? totalBoughtSpendLast30dCents = null,Object? behavioralScore = null,}) {
  return _then(_self.copyWith(
mainBehaviorTrend: null == mainBehaviorTrend ? _self.mainBehaviorTrend : mainBehaviorTrend // ignore: cast_nullable_to_non_nullable
as String,fridayOverspendPercent: null == fridayOverspendPercent ? _self.fridayOverspendPercent : fridayOverspendPercent // ignore: cast_nullable_to_non_nullable
as int,impulseWindow: null == impulseWindow ? _self.impulseWindow : impulseWindow // ignore: cast_nullable_to_non_nullable
as String,topRegretCategory: null == topRegretCategory ? _self.topRegretCategory : topRegretCategory // ignore: cast_nullable_to_non_nullable
as String,highRegretRatePercent: null == highRegretRatePercent ? _self.highRegretRatePercent : highRegretRatePercent // ignore: cast_nullable_to_non_nullable
as int,boughtPurchasesCount: null == boughtPurchasesCount ? _self.boughtPurchasesCount : boughtPurchasesCount // ignore: cast_nullable_to_non_nullable
as int,totalBoughtSpendLast30dCents: null == totalBoughtSpendLast30dCents ? _self.totalBoughtSpendLast30dCents : totalBoughtSpendLast30dCents // ignore: cast_nullable_to_non_nullable
as int,behavioralScore: null == behavioralScore ? _self.behavioralScore : behavioralScore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Insight].
extension InsightPatterns on Insight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Insight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Insight value)  $default,){
final _that = this;
switch (_that) {
case _Insight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Insight value)?  $default,){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'main_behavior_trend')  String mainBehaviorTrend, @JsonKey(name: 'friday_overspend_percent')  int fridayOverspendPercent, @JsonKey(name: 'impulse_window')  String impulseWindow, @JsonKey(name: 'top_regret_category')  String topRegretCategory, @JsonKey(name: 'high_regret_rate_percent')  int highRegretRatePercent, @JsonKey(name: 'bought_purchases_count')  int boughtPurchasesCount, @JsonKey(name: 'total_bought_spend_last_30d_cents')  int totalBoughtSpendLast30dCents, @JsonKey(name: 'behavioral_score')  int behavioralScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.mainBehaviorTrend,_that.fridayOverspendPercent,_that.impulseWindow,_that.topRegretCategory,_that.highRegretRatePercent,_that.boughtPurchasesCount,_that.totalBoughtSpendLast30dCents,_that.behavioralScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'main_behavior_trend')  String mainBehaviorTrend, @JsonKey(name: 'friday_overspend_percent')  int fridayOverspendPercent, @JsonKey(name: 'impulse_window')  String impulseWindow, @JsonKey(name: 'top_regret_category')  String topRegretCategory, @JsonKey(name: 'high_regret_rate_percent')  int highRegretRatePercent, @JsonKey(name: 'bought_purchases_count')  int boughtPurchasesCount, @JsonKey(name: 'total_bought_spend_last_30d_cents')  int totalBoughtSpendLast30dCents, @JsonKey(name: 'behavioral_score')  int behavioralScore)  $default,) {final _that = this;
switch (_that) {
case _Insight():
return $default(_that.mainBehaviorTrend,_that.fridayOverspendPercent,_that.impulseWindow,_that.topRegretCategory,_that.highRegretRatePercent,_that.boughtPurchasesCount,_that.totalBoughtSpendLast30dCents,_that.behavioralScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'main_behavior_trend')  String mainBehaviorTrend, @JsonKey(name: 'friday_overspend_percent')  int fridayOverspendPercent, @JsonKey(name: 'impulse_window')  String impulseWindow, @JsonKey(name: 'top_regret_category')  String topRegretCategory, @JsonKey(name: 'high_regret_rate_percent')  int highRegretRatePercent, @JsonKey(name: 'bought_purchases_count')  int boughtPurchasesCount, @JsonKey(name: 'total_bought_spend_last_30d_cents')  int totalBoughtSpendLast30dCents, @JsonKey(name: 'behavioral_score')  int behavioralScore)?  $default,) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.mainBehaviorTrend,_that.fridayOverspendPercent,_that.impulseWindow,_that.topRegretCategory,_that.highRegretRatePercent,_that.boughtPurchasesCount,_that.totalBoughtSpendLast30dCents,_that.behavioralScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Insight implements Insight {
  const _Insight({@JsonKey(name: 'main_behavior_trend') required this.mainBehaviorTrend, @JsonKey(name: 'friday_overspend_percent') required this.fridayOverspendPercent, @JsonKey(name: 'impulse_window') required this.impulseWindow, @JsonKey(name: 'top_regret_category') required this.topRegretCategory, @JsonKey(name: 'high_regret_rate_percent') required this.highRegretRatePercent, @JsonKey(name: 'bought_purchases_count') required this.boughtPurchasesCount, @JsonKey(name: 'total_bought_spend_last_30d_cents') required this.totalBoughtSpendLast30dCents, @JsonKey(name: 'behavioral_score') required this.behavioralScore});
  factory _Insight.fromJson(Map<String, dynamic> json) => _$InsightFromJson(json);

@override@JsonKey(name: 'main_behavior_trend') final  String mainBehaviorTrend;
@override@JsonKey(name: 'friday_overspend_percent') final  int fridayOverspendPercent;
@override@JsonKey(name: 'impulse_window') final  String impulseWindow;
@override@JsonKey(name: 'top_regret_category') final  String topRegretCategory;
@override@JsonKey(name: 'high_regret_rate_percent') final  int highRegretRatePercent;
@override@JsonKey(name: 'bought_purchases_count') final  int boughtPurchasesCount;
@override@JsonKey(name: 'total_bought_spend_last_30d_cents') final  int totalBoughtSpendLast30dCents;
@override@JsonKey(name: 'behavioral_score') final  int behavioralScore;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightCopyWith<_Insight> get copyWith => __$InsightCopyWithImpl<_Insight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InsightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Insight&&(identical(other.mainBehaviorTrend, mainBehaviorTrend) || other.mainBehaviorTrend == mainBehaviorTrend)&&(identical(other.fridayOverspendPercent, fridayOverspendPercent) || other.fridayOverspendPercent == fridayOverspendPercent)&&(identical(other.impulseWindow, impulseWindow) || other.impulseWindow == impulseWindow)&&(identical(other.topRegretCategory, topRegretCategory) || other.topRegretCategory == topRegretCategory)&&(identical(other.highRegretRatePercent, highRegretRatePercent) || other.highRegretRatePercent == highRegretRatePercent)&&(identical(other.boughtPurchasesCount, boughtPurchasesCount) || other.boughtPurchasesCount == boughtPurchasesCount)&&(identical(other.totalBoughtSpendLast30dCents, totalBoughtSpendLast30dCents) || other.totalBoughtSpendLast30dCents == totalBoughtSpendLast30dCents)&&(identical(other.behavioralScore, behavioralScore) || other.behavioralScore == behavioralScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mainBehaviorTrend,fridayOverspendPercent,impulseWindow,topRegretCategory,highRegretRatePercent,boughtPurchasesCount,totalBoughtSpendLast30dCents,behavioralScore);

@override
String toString() {
  return 'Insight(mainBehaviorTrend: $mainBehaviorTrend, fridayOverspendPercent: $fridayOverspendPercent, impulseWindow: $impulseWindow, topRegretCategory: $topRegretCategory, highRegretRatePercent: $highRegretRatePercent, boughtPurchasesCount: $boughtPurchasesCount, totalBoughtSpendLast30dCents: $totalBoughtSpendLast30dCents, behavioralScore: $behavioralScore)';
}


}

/// @nodoc
abstract mixin class _$InsightCopyWith<$Res> implements $InsightCopyWith<$Res> {
  factory _$InsightCopyWith(_Insight value, $Res Function(_Insight) _then) = __$InsightCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'main_behavior_trend') String mainBehaviorTrend,@JsonKey(name: 'friday_overspend_percent') int fridayOverspendPercent,@JsonKey(name: 'impulse_window') String impulseWindow,@JsonKey(name: 'top_regret_category') String topRegretCategory,@JsonKey(name: 'high_regret_rate_percent') int highRegretRatePercent,@JsonKey(name: 'bought_purchases_count') int boughtPurchasesCount,@JsonKey(name: 'total_bought_spend_last_30d_cents') int totalBoughtSpendLast30dCents,@JsonKey(name: 'behavioral_score') int behavioralScore
});




}
/// @nodoc
class __$InsightCopyWithImpl<$Res>
    implements _$InsightCopyWith<$Res> {
  __$InsightCopyWithImpl(this._self, this._then);

  final _Insight _self;
  final $Res Function(_Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mainBehaviorTrend = null,Object? fridayOverspendPercent = null,Object? impulseWindow = null,Object? topRegretCategory = null,Object? highRegretRatePercent = null,Object? boughtPurchasesCount = null,Object? totalBoughtSpendLast30dCents = null,Object? behavioralScore = null,}) {
  return _then(_Insight(
mainBehaviorTrend: null == mainBehaviorTrend ? _self.mainBehaviorTrend : mainBehaviorTrend // ignore: cast_nullable_to_non_nullable
as String,fridayOverspendPercent: null == fridayOverspendPercent ? _self.fridayOverspendPercent : fridayOverspendPercent // ignore: cast_nullable_to_non_nullable
as int,impulseWindow: null == impulseWindow ? _self.impulseWindow : impulseWindow // ignore: cast_nullable_to_non_nullable
as String,topRegretCategory: null == topRegretCategory ? _self.topRegretCategory : topRegretCategory // ignore: cast_nullable_to_non_nullable
as String,highRegretRatePercent: null == highRegretRatePercent ? _self.highRegretRatePercent : highRegretRatePercent // ignore: cast_nullable_to_non_nullable
as int,boughtPurchasesCount: null == boughtPurchasesCount ? _self.boughtPurchasesCount : boughtPurchasesCount // ignore: cast_nullable_to_non_nullable
as int,totalBoughtSpendLast30dCents: null == totalBoughtSpendLast30dCents ? _self.totalBoughtSpendLast30dCents : totalBoughtSpendLast30dCents // ignore: cast_nullable_to_non_nullable
as int,behavioralScore: null == behavioralScore ? _self.behavioralScore : behavioralScore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
