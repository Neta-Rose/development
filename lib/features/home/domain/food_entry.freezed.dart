// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FoodEntry {

 String get id; String get name; String get icon; EntryType get type;/// For [EntryType.workout] entries this is the estimated burn.
 int? get kcal; int? get protein; int? get carbs; int? get fat; String? get serving; String? get meta; DateTime get loggedAt;
/// Create a copy of FoodEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodEntryCopyWith<FoodEntry> get copyWith => _$FoodEntryCopyWithImpl<FoodEntry>(this as FoodEntry, _$identity);

  /// Serializes this FoodEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.type, type) || other.type == type)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fat, fat) || other.fat == fat)&&(identical(other.serving, serving) || other.serving == serving)&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,type,kcal,protein,carbs,fat,serving,meta,loggedAt);

@override
String toString() {
  return 'FoodEntry(id: $id, name: $name, icon: $icon, type: $type, kcal: $kcal, protein: $protein, carbs: $carbs, fat: $fat, serving: $serving, meta: $meta, loggedAt: $loggedAt)';
}


}

/// @nodoc
abstract mixin class $FoodEntryCopyWith<$Res>  {
  factory $FoodEntryCopyWith(FoodEntry value, $Res Function(FoodEntry) _then) = _$FoodEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String icon, EntryType type, int? kcal, int? protein, int? carbs, int? fat, String? serving, String? meta, DateTime loggedAt
});




}
/// @nodoc
class _$FoodEntryCopyWithImpl<$Res>
    implements $FoodEntryCopyWith<$Res> {
  _$FoodEntryCopyWithImpl(this._self, this._then);

  final FoodEntry _self;
  final $Res Function(FoodEntry) _then;

/// Create a copy of FoodEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? type = null,Object? kcal = freezed,Object? protein = freezed,Object? carbs = freezed,Object? fat = freezed,Object? serving = freezed,Object? meta = freezed,Object? loggedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EntryType,kcal: freezed == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as int?,protein: freezed == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as int?,carbs: freezed == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as int?,fat: freezed == fat ? _self.fat : fat // ignore: cast_nullable_to_non_nullable
as int?,serving: freezed == serving ? _self.serving : serving // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as String?,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodEntry].
extension FoodEntryPatterns on FoodEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodEntry value)  $default,){
final _that = this;
switch (_that) {
case _FoodEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FoodEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String icon,  EntryType type,  int? kcal,  int? protein,  int? carbs,  int? fat,  String? serving,  String? meta,  DateTime loggedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodEntry() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.type,_that.kcal,_that.protein,_that.carbs,_that.fat,_that.serving,_that.meta,_that.loggedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String icon,  EntryType type,  int? kcal,  int? protein,  int? carbs,  int? fat,  String? serving,  String? meta,  DateTime loggedAt)  $default,) {final _that = this;
switch (_that) {
case _FoodEntry():
return $default(_that.id,_that.name,_that.icon,_that.type,_that.kcal,_that.protein,_that.carbs,_that.fat,_that.serving,_that.meta,_that.loggedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String icon,  EntryType type,  int? kcal,  int? protein,  int? carbs,  int? fat,  String? serving,  String? meta,  DateTime loggedAt)?  $default,) {final _that = this;
switch (_that) {
case _FoodEntry() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.type,_that.kcal,_that.protein,_that.carbs,_that.fat,_that.serving,_that.meta,_that.loggedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _FoodEntry implements FoodEntry {
  const _FoodEntry({required this.id, required this.name, required this.icon, required this.type, this.kcal, this.protein, this.carbs, this.fat, this.serving, this.meta, required this.loggedAt});
  factory _FoodEntry.fromJson(Map<String, dynamic> json) => _$FoodEntryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  EntryType type;
/// For [EntryType.workout] entries this is the estimated burn.
@override final  int? kcal;
@override final  int? protein;
@override final  int? carbs;
@override final  int? fat;
@override final  String? serving;
@override final  String? meta;
@override final  DateTime loggedAt;

/// Create a copy of FoodEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodEntryCopyWith<_FoodEntry> get copyWith => __$FoodEntryCopyWithImpl<_FoodEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FoodEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.type, type) || other.type == type)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fat, fat) || other.fat == fat)&&(identical(other.serving, serving) || other.serving == serving)&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,type,kcal,protein,carbs,fat,serving,meta,loggedAt);

@override
String toString() {
  return 'FoodEntry(id: $id, name: $name, icon: $icon, type: $type, kcal: $kcal, protein: $protein, carbs: $carbs, fat: $fat, serving: $serving, meta: $meta, loggedAt: $loggedAt)';
}


}

/// @nodoc
abstract mixin class _$FoodEntryCopyWith<$Res> implements $FoodEntryCopyWith<$Res> {
  factory _$FoodEntryCopyWith(_FoodEntry value, $Res Function(_FoodEntry) _then) = __$FoodEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, EntryType type, int? kcal, int? protein, int? carbs, int? fat, String? serving, String? meta, DateTime loggedAt
});




}
/// @nodoc
class __$FoodEntryCopyWithImpl<$Res>
    implements _$FoodEntryCopyWith<$Res> {
  __$FoodEntryCopyWithImpl(this._self, this._then);

  final _FoodEntry _self;
  final $Res Function(_FoodEntry) _then;

/// Create a copy of FoodEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? type = null,Object? kcal = freezed,Object? protein = freezed,Object? carbs = freezed,Object? fat = freezed,Object? serving = freezed,Object? meta = freezed,Object? loggedAt = null,}) {
  return _then(_FoodEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EntryType,kcal: freezed == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as int?,protein: freezed == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as int?,carbs: freezed == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as int?,fat: freezed == fat ? _self.fat : fat // ignore: cast_nullable_to_non_nullable
as int?,serving: freezed == serving ? _self.serving : serving // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as String?,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
