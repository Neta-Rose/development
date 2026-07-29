// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_plate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiOrigin {

 String get instanceId; List<int> get shots;
/// Create a copy of AiOrigin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiOriginCopyWith<AiOrigin> get copyWith => _$AiOriginCopyWithImpl<AiOrigin>(this as AiOrigin, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiOrigin&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&const DeepCollectionEquality().equals(other.shots, shots));
}


@override
int get hashCode => Object.hash(runtimeType,instanceId,const DeepCollectionEquality().hash(shots));

@override
String toString() {
  return 'AiOrigin(instanceId: $instanceId, shots: $shots)';
}


}

/// @nodoc
abstract mixin class $AiOriginCopyWith<$Res>  {
  factory $AiOriginCopyWith(AiOrigin value, $Res Function(AiOrigin) _then) = _$AiOriginCopyWithImpl;
@useResult
$Res call({
 String instanceId, List<int> shots
});




}
/// @nodoc
class _$AiOriginCopyWithImpl<$Res>
    implements $AiOriginCopyWith<$Res> {
  _$AiOriginCopyWithImpl(this._self, this._then);

  final AiOrigin _self;
  final $Res Function(AiOrigin) _then;

/// Create a copy of AiOrigin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instanceId = null,Object? shots = null,}) {
  return _then(_self.copyWith(
instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,shots: null == shots ? _self.shots : shots // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [AiOrigin].
extension AiOriginPatterns on AiOrigin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiOrigin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiOrigin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiOrigin value)  $default,){
final _that = this;
switch (_that) {
case _AiOrigin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiOrigin value)?  $default,){
final _that = this;
switch (_that) {
case _AiOrigin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String instanceId,  List<int> shots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiOrigin() when $default != null:
return $default(_that.instanceId,_that.shots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String instanceId,  List<int> shots)  $default,) {final _that = this;
switch (_that) {
case _AiOrigin():
return $default(_that.instanceId,_that.shots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String instanceId,  List<int> shots)?  $default,) {final _that = this;
switch (_that) {
case _AiOrigin() when $default != null:
return $default(_that.instanceId,_that.shots);case _:
  return null;

}
}

}

/// @nodoc


class _AiOrigin implements AiOrigin {
  const _AiOrigin({required this.instanceId, final  List<int> shots = const <int>[]}): _shots = shots;
  

@override final  String instanceId;
 final  List<int> _shots;
@override@JsonKey() List<int> get shots {
  if (_shots is EqualUnmodifiableListView) return _shots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shots);
}


/// Create a copy of AiOrigin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiOriginCopyWith<_AiOrigin> get copyWith => __$AiOriginCopyWithImpl<_AiOrigin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiOrigin&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&const DeepCollectionEquality().equals(other._shots, _shots));
}


@override
int get hashCode => Object.hash(runtimeType,instanceId,const DeepCollectionEquality().hash(_shots));

@override
String toString() {
  return 'AiOrigin(instanceId: $instanceId, shots: $shots)';
}


}

/// @nodoc
abstract mixin class _$AiOriginCopyWith<$Res> implements $AiOriginCopyWith<$Res> {
  factory _$AiOriginCopyWith(_AiOrigin value, $Res Function(_AiOrigin) _then) = __$AiOriginCopyWithImpl;
@override @useResult
$Res call({
 String instanceId, List<int> shots
});




}
/// @nodoc
class __$AiOriginCopyWithImpl<$Res>
    implements _$AiOriginCopyWith<$Res> {
  __$AiOriginCopyWithImpl(this._self, this._then);

  final _AiOrigin _self;
  final $Res Function(_AiOrigin) _then;

/// Create a copy of AiOrigin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instanceId = null,Object? shots = null,}) {
  return _then(_AiOrigin(
instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,shots: null == shots ? _self._shots : shots // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc
mixin _$AiSession {

 List<Shot> get shots; AiPhase get phase; VisionFailure? get failure; bool get torch;/// Instance ids whose grams the user set by hand. A later reply must not
/// overwrite them — the user has seen the food and the detector has not.
 Set<String> get editedIds;/// Instance ids the user removed. A later reply must not bring them back.
 Set<String> get removedIds;
/// Create a copy of AiSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiSessionCopyWith<AiSession> get copyWith => _$AiSessionCopyWithImpl<AiSession>(this as AiSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiSession&&const DeepCollectionEquality().equals(other.shots, shots)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.torch, torch) || other.torch == torch)&&const DeepCollectionEquality().equals(other.editedIds, editedIds)&&const DeepCollectionEquality().equals(other.removedIds, removedIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(shots),phase,failure,torch,const DeepCollectionEquality().hash(editedIds),const DeepCollectionEquality().hash(removedIds));

@override
String toString() {
  return 'AiSession(shots: $shots, phase: $phase, failure: $failure, torch: $torch, editedIds: $editedIds, removedIds: $removedIds)';
}


}

/// @nodoc
abstract mixin class $AiSessionCopyWith<$Res>  {
  factory $AiSessionCopyWith(AiSession value, $Res Function(AiSession) _then) = _$AiSessionCopyWithImpl;
@useResult
$Res call({
 List<Shot> shots, AiPhase phase, VisionFailure? failure, bool torch, Set<String> editedIds, Set<String> removedIds
});




}
/// @nodoc
class _$AiSessionCopyWithImpl<$Res>
    implements $AiSessionCopyWith<$Res> {
  _$AiSessionCopyWithImpl(this._self, this._then);

  final AiSession _self;
  final $Res Function(AiSession) _then;

/// Create a copy of AiSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shots = null,Object? phase = null,Object? failure = freezed,Object? torch = null,Object? editedIds = null,Object? removedIds = null,}) {
  return _then(_self.copyWith(
shots: null == shots ? _self.shots : shots // ignore: cast_nullable_to_non_nullable
as List<Shot>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AiPhase,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as VisionFailure?,torch: null == torch ? _self.torch : torch // ignore: cast_nullable_to_non_nullable
as bool,editedIds: null == editedIds ? _self.editedIds : editedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,removedIds: null == removedIds ? _self.removedIds : removedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AiSession].
extension AiSessionPatterns on AiSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiSession value)  $default,){
final _that = this;
switch (_that) {
case _AiSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiSession value)?  $default,){
final _that = this;
switch (_that) {
case _AiSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Shot> shots,  AiPhase phase,  VisionFailure? failure,  bool torch,  Set<String> editedIds,  Set<String> removedIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiSession() when $default != null:
return $default(_that.shots,_that.phase,_that.failure,_that.torch,_that.editedIds,_that.removedIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Shot> shots,  AiPhase phase,  VisionFailure? failure,  bool torch,  Set<String> editedIds,  Set<String> removedIds)  $default,) {final _that = this;
switch (_that) {
case _AiSession():
return $default(_that.shots,_that.phase,_that.failure,_that.torch,_that.editedIds,_that.removedIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Shot> shots,  AiPhase phase,  VisionFailure? failure,  bool torch,  Set<String> editedIds,  Set<String> removedIds)?  $default,) {final _that = this;
switch (_that) {
case _AiSession() when $default != null:
return $default(_that.shots,_that.phase,_that.failure,_that.torch,_that.editedIds,_that.removedIds);case _:
  return null;

}
}

}

/// @nodoc


class _AiSession implements AiSession {
  const _AiSession({final  List<Shot> shots = const <Shot>[], this.phase = AiPhase.live, this.failure, this.torch = false, final  Set<String> editedIds = const <String>{}, final  Set<String> removedIds = const <String>{}}): _shots = shots,_editedIds = editedIds,_removedIds = removedIds;
  

 final  List<Shot> _shots;
@override@JsonKey() List<Shot> get shots {
  if (_shots is EqualUnmodifiableListView) return _shots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shots);
}

@override@JsonKey() final  AiPhase phase;
@override final  VisionFailure? failure;
@override@JsonKey() final  bool torch;
/// Instance ids whose grams the user set by hand. A later reply must not
/// overwrite them — the user has seen the food and the detector has not.
 final  Set<String> _editedIds;
/// Instance ids whose grams the user set by hand. A later reply must not
/// overwrite them — the user has seen the food and the detector has not.
@override@JsonKey() Set<String> get editedIds {
  if (_editedIds is EqualUnmodifiableSetView) return _editedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_editedIds);
}

/// Instance ids the user removed. A later reply must not bring them back.
 final  Set<String> _removedIds;
/// Instance ids the user removed. A later reply must not bring them back.
@override@JsonKey() Set<String> get removedIds {
  if (_removedIds is EqualUnmodifiableSetView) return _removedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_removedIds);
}


/// Create a copy of AiSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiSessionCopyWith<_AiSession> get copyWith => __$AiSessionCopyWithImpl<_AiSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiSession&&const DeepCollectionEquality().equals(other._shots, _shots)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.torch, torch) || other.torch == torch)&&const DeepCollectionEquality().equals(other._editedIds, _editedIds)&&const DeepCollectionEquality().equals(other._removedIds, _removedIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_shots),phase,failure,torch,const DeepCollectionEquality().hash(_editedIds),const DeepCollectionEquality().hash(_removedIds));

@override
String toString() {
  return 'AiSession(shots: $shots, phase: $phase, failure: $failure, torch: $torch, editedIds: $editedIds, removedIds: $removedIds)';
}


}

/// @nodoc
abstract mixin class _$AiSessionCopyWith<$Res> implements $AiSessionCopyWith<$Res> {
  factory _$AiSessionCopyWith(_AiSession value, $Res Function(_AiSession) _then) = __$AiSessionCopyWithImpl;
@override @useResult
$Res call({
 List<Shot> shots, AiPhase phase, VisionFailure? failure, bool torch, Set<String> editedIds, Set<String> removedIds
});




}
/// @nodoc
class __$AiSessionCopyWithImpl<$Res>
    implements _$AiSessionCopyWith<$Res> {
  __$AiSessionCopyWithImpl(this._self, this._then);

  final _AiSession _self;
  final $Res Function(_AiSession) _then;

/// Create a copy of AiSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shots = null,Object? phase = null,Object? failure = freezed,Object? torch = null,Object? editedIds = null,Object? removedIds = null,}) {
  return _then(_AiSession(
shots: null == shots ? _self._shots : shots // ignore: cast_nullable_to_non_nullable
as List<Shot>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AiPhase,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as VisionFailure?,torch: null == torch ? _self.torch : torch // ignore: cast_nullable_to_non_nullable
as bool,editedIds: null == editedIds ? _self._editedIds : editedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,removedIds: null == removedIds ? _self._removedIds : removedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
