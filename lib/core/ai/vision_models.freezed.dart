// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vision_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VisionDetection {

/// Identifies one physical item across every shot of the batch. This is the
/// entire deduplication mechanism: the plate merges a detection into the row
/// already carrying this id, and appends a row only when the id is new.
@JsonKey(name: 'instance_id') String get instanceId; String get name;/// Generic food name for the catalog lookup: no brand, quantity or
/// preparation.
@JsonKey(name: 'search_term') String get searchTerm;/// Estimated edible weight. `0` means "no usable estimate" — a weight the
/// service could not get from the model — and the caller falls back to the
/// matched food's serving weight.
 double get grams; double get confidence;/// Ascending shot numbers this item appears in. More than one is what
/// renders as `↺ N` and `shots 1·2·3, counted once`.
 List<int> get shots; String get emoji;/// Per-100 g fallback nutrition, used only when no catalog row matches.
@JsonKey(name: 'kcal_100g') double get kcal100g;@JsonKey(name: 'protein_100g') double get protein100g;@JsonKey(name: 'carb_100g') double get carb100g;@JsonKey(name: 'fat_100g') double get fat100g;
/// Create a copy of VisionDetection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisionDetectionCopyWith<VisionDetection> get copyWith => _$VisionDetectionCopyWithImpl<VisionDetection>(this as VisionDetection, _$identity);

  /// Serializes this VisionDetection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisionDetection&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.searchTerm, searchTerm) || other.searchTerm == searchTerm)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other.shots, shots)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.kcal100g, kcal100g) || other.kcal100g == kcal100g)&&(identical(other.protein100g, protein100g) || other.protein100g == protein100g)&&(identical(other.carb100g, carb100g) || other.carb100g == carb100g)&&(identical(other.fat100g, fat100g) || other.fat100g == fat100g));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instanceId,name,searchTerm,grams,confidence,const DeepCollectionEquality().hash(shots),emoji,kcal100g,protein100g,carb100g,fat100g);

@override
String toString() {
  return 'VisionDetection(instanceId: $instanceId, name: $name, searchTerm: $searchTerm, grams: $grams, confidence: $confidence, shots: $shots, emoji: $emoji, kcal100g: $kcal100g, protein100g: $protein100g, carb100g: $carb100g, fat100g: $fat100g)';
}


}

/// @nodoc
abstract mixin class $VisionDetectionCopyWith<$Res>  {
  factory $VisionDetectionCopyWith(VisionDetection value, $Res Function(VisionDetection) _then) = _$VisionDetectionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'instance_id') String instanceId, String name,@JsonKey(name: 'search_term') String searchTerm, double grams, double confidence, List<int> shots, String emoji,@JsonKey(name: 'kcal_100g') double kcal100g,@JsonKey(name: 'protein_100g') double protein100g,@JsonKey(name: 'carb_100g') double carb100g,@JsonKey(name: 'fat_100g') double fat100g
});




}
/// @nodoc
class _$VisionDetectionCopyWithImpl<$Res>
    implements $VisionDetectionCopyWith<$Res> {
  _$VisionDetectionCopyWithImpl(this._self, this._then);

  final VisionDetection _self;
  final $Res Function(VisionDetection) _then;

/// Create a copy of VisionDetection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instanceId = null,Object? name = null,Object? searchTerm = null,Object? grams = null,Object? confidence = null,Object? shots = null,Object? emoji = null,Object? kcal100g = null,Object? protein100g = null,Object? carb100g = null,Object? fat100g = null,}) {
  return _then(_self.copyWith(
instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,searchTerm: null == searchTerm ? _self.searchTerm : searchTerm // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,shots: null == shots ? _self.shots : shots // ignore: cast_nullable_to_non_nullable
as List<int>,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,kcal100g: null == kcal100g ? _self.kcal100g : kcal100g // ignore: cast_nullable_to_non_nullable
as double,protein100g: null == protein100g ? _self.protein100g : protein100g // ignore: cast_nullable_to_non_nullable
as double,carb100g: null == carb100g ? _self.carb100g : carb100g // ignore: cast_nullable_to_non_nullable
as double,fat100g: null == fat100g ? _self.fat100g : fat100g // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [VisionDetection].
extension VisionDetectionPatterns on VisionDetection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisionDetection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisionDetection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisionDetection value)  $default,){
final _that = this;
switch (_that) {
case _VisionDetection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisionDetection value)?  $default,){
final _that = this;
switch (_that) {
case _VisionDetection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'instance_id')  String instanceId,  String name, @JsonKey(name: 'search_term')  String searchTerm,  double grams,  double confidence,  List<int> shots,  String emoji, @JsonKey(name: 'kcal_100g')  double kcal100g, @JsonKey(name: 'protein_100g')  double protein100g, @JsonKey(name: 'carb_100g')  double carb100g, @JsonKey(name: 'fat_100g')  double fat100g)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisionDetection() when $default != null:
return $default(_that.instanceId,_that.name,_that.searchTerm,_that.grams,_that.confidence,_that.shots,_that.emoji,_that.kcal100g,_that.protein100g,_that.carb100g,_that.fat100g);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'instance_id')  String instanceId,  String name, @JsonKey(name: 'search_term')  String searchTerm,  double grams,  double confidence,  List<int> shots,  String emoji, @JsonKey(name: 'kcal_100g')  double kcal100g, @JsonKey(name: 'protein_100g')  double protein100g, @JsonKey(name: 'carb_100g')  double carb100g, @JsonKey(name: 'fat_100g')  double fat100g)  $default,) {final _that = this;
switch (_that) {
case _VisionDetection():
return $default(_that.instanceId,_that.name,_that.searchTerm,_that.grams,_that.confidence,_that.shots,_that.emoji,_that.kcal100g,_that.protein100g,_that.carb100g,_that.fat100g);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'instance_id')  String instanceId,  String name, @JsonKey(name: 'search_term')  String searchTerm,  double grams,  double confidence,  List<int> shots,  String emoji, @JsonKey(name: 'kcal_100g')  double kcal100g, @JsonKey(name: 'protein_100g')  double protein100g, @JsonKey(name: 'carb_100g')  double carb100g, @JsonKey(name: 'fat_100g')  double fat100g)?  $default,) {final _that = this;
switch (_that) {
case _VisionDetection() when $default != null:
return $default(_that.instanceId,_that.name,_that.searchTerm,_that.grams,_that.confidence,_that.shots,_that.emoji,_that.kcal100g,_that.protein100g,_that.carb100g,_that.fat100g);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisionDetection implements VisionDetection {
  const _VisionDetection({@JsonKey(name: 'instance_id') this.instanceId = '', this.name = '', @JsonKey(name: 'search_term') this.searchTerm = '', this.grams = 0.0, this.confidence = 0.0, final  List<int> shots = const <int>[], this.emoji = '', @JsonKey(name: 'kcal_100g') this.kcal100g = 0.0, @JsonKey(name: 'protein_100g') this.protein100g = 0.0, @JsonKey(name: 'carb_100g') this.carb100g = 0.0, @JsonKey(name: 'fat_100g') this.fat100g = 0.0}): _shots = shots;
  factory _VisionDetection.fromJson(Map<String, dynamic> json) => _$VisionDetectionFromJson(json);

/// Identifies one physical item across every shot of the batch. This is the
/// entire deduplication mechanism: the plate merges a detection into the row
/// already carrying this id, and appends a row only when the id is new.
@override@JsonKey(name: 'instance_id') final  String instanceId;
@override@JsonKey() final  String name;
/// Generic food name for the catalog lookup: no brand, quantity or
/// preparation.
@override@JsonKey(name: 'search_term') final  String searchTerm;
/// Estimated edible weight. `0` means "no usable estimate" — a weight the
/// service could not get from the model — and the caller falls back to the
/// matched food's serving weight.
@override@JsonKey() final  double grams;
@override@JsonKey() final  double confidence;
/// Ascending shot numbers this item appears in. More than one is what
/// renders as `↺ N` and `shots 1·2·3, counted once`.
 final  List<int> _shots;
/// Ascending shot numbers this item appears in. More than one is what
/// renders as `↺ N` and `shots 1·2·3, counted once`.
@override@JsonKey() List<int> get shots {
  if (_shots is EqualUnmodifiableListView) return _shots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shots);
}

@override@JsonKey() final  String emoji;
/// Per-100 g fallback nutrition, used only when no catalog row matches.
@override@JsonKey(name: 'kcal_100g') final  double kcal100g;
@override@JsonKey(name: 'protein_100g') final  double protein100g;
@override@JsonKey(name: 'carb_100g') final  double carb100g;
@override@JsonKey(name: 'fat_100g') final  double fat100g;

/// Create a copy of VisionDetection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisionDetectionCopyWith<_VisionDetection> get copyWith => __$VisionDetectionCopyWithImpl<_VisionDetection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisionDetectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisionDetection&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.searchTerm, searchTerm) || other.searchTerm == searchTerm)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other._shots, _shots)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.kcal100g, kcal100g) || other.kcal100g == kcal100g)&&(identical(other.protein100g, protein100g) || other.protein100g == protein100g)&&(identical(other.carb100g, carb100g) || other.carb100g == carb100g)&&(identical(other.fat100g, fat100g) || other.fat100g == fat100g));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instanceId,name,searchTerm,grams,confidence,const DeepCollectionEquality().hash(_shots),emoji,kcal100g,protein100g,carb100g,fat100g);

@override
String toString() {
  return 'VisionDetection(instanceId: $instanceId, name: $name, searchTerm: $searchTerm, grams: $grams, confidence: $confidence, shots: $shots, emoji: $emoji, kcal100g: $kcal100g, protein100g: $protein100g, carb100g: $carb100g, fat100g: $fat100g)';
}


}

/// @nodoc
abstract mixin class _$VisionDetectionCopyWith<$Res> implements $VisionDetectionCopyWith<$Res> {
  factory _$VisionDetectionCopyWith(_VisionDetection value, $Res Function(_VisionDetection) _then) = __$VisionDetectionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'instance_id') String instanceId, String name,@JsonKey(name: 'search_term') String searchTerm, double grams, double confidence, List<int> shots, String emoji,@JsonKey(name: 'kcal_100g') double kcal100g,@JsonKey(name: 'protein_100g') double protein100g,@JsonKey(name: 'carb_100g') double carb100g,@JsonKey(name: 'fat_100g') double fat100g
});




}
/// @nodoc
class __$VisionDetectionCopyWithImpl<$Res>
    implements _$VisionDetectionCopyWith<$Res> {
  __$VisionDetectionCopyWithImpl(this._self, this._then);

  final _VisionDetection _self;
  final $Res Function(_VisionDetection) _then;

/// Create a copy of VisionDetection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instanceId = null,Object? name = null,Object? searchTerm = null,Object? grams = null,Object? confidence = null,Object? shots = null,Object? emoji = null,Object? kcal100g = null,Object? protein100g = null,Object? carb100g = null,Object? fat100g = null,}) {
  return _then(_VisionDetection(
instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,searchTerm: null == searchTerm ? _self.searchTerm : searchTerm // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,shots: null == shots ? _self._shots : shots // ignore: cast_nullable_to_non_nullable
as List<int>,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,kcal100g: null == kcal100g ? _self.kcal100g : kcal100g // ignore: cast_nullable_to_non_nullable
as double,protein100g: null == protein100g ? _self.protein100g : protein100g // ignore: cast_nullable_to_non_nullable
as double,carb100g: null == carb100g ? _self.carb100g : carb100g // ignore: cast_nullable_to_non_nullable
as double,fat100g: null == fat100g ? _self.fat100g : fat100g // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$VisionReply {

 String get model; List<VisionDetection> get items;
/// Create a copy of VisionReply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisionReplyCopyWith<VisionReply> get copyWith => _$VisionReplyCopyWithImpl<VisionReply>(this as VisionReply, _$identity);

  /// Serializes this VisionReply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisionReply&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,model,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'VisionReply(model: $model, items: $items)';
}


}

/// @nodoc
abstract mixin class $VisionReplyCopyWith<$Res>  {
  factory $VisionReplyCopyWith(VisionReply value, $Res Function(VisionReply) _then) = _$VisionReplyCopyWithImpl;
@useResult
$Res call({
 String model, List<VisionDetection> items
});




}
/// @nodoc
class _$VisionReplyCopyWithImpl<$Res>
    implements $VisionReplyCopyWith<$Res> {
  _$VisionReplyCopyWithImpl(this._self, this._then);

  final VisionReply _self;
  final $Res Function(VisionReply) _then;

/// Create a copy of VisionReply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? model = null,Object? items = null,}) {
  return _then(_self.copyWith(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<VisionDetection>,
  ));
}

}


/// Adds pattern-matching-related methods to [VisionReply].
extension VisionReplyPatterns on VisionReply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisionReply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisionReply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisionReply value)  $default,){
final _that = this;
switch (_that) {
case _VisionReply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisionReply value)?  $default,){
final _that = this;
switch (_that) {
case _VisionReply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String model,  List<VisionDetection> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisionReply() when $default != null:
return $default(_that.model,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String model,  List<VisionDetection> items)  $default,) {final _that = this;
switch (_that) {
case _VisionReply():
return $default(_that.model,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String model,  List<VisionDetection> items)?  $default,) {final _that = this;
switch (_that) {
case _VisionReply() when $default != null:
return $default(_that.model,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VisionReply implements VisionReply {
  const _VisionReply({this.model = '', final  List<VisionDetection> items = const <VisionDetection>[]}): _items = items;
  factory _VisionReply.fromJson(Map<String, dynamic> json) => _$VisionReplyFromJson(json);

@override@JsonKey() final  String model;
 final  List<VisionDetection> _items;
@override@JsonKey() List<VisionDetection> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of VisionReply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisionReplyCopyWith<_VisionReply> get copyWith => __$VisionReplyCopyWithImpl<_VisionReply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VisionReplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisionReply&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,model,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'VisionReply(model: $model, items: $items)';
}


}

/// @nodoc
abstract mixin class _$VisionReplyCopyWith<$Res> implements $VisionReplyCopyWith<$Res> {
  factory _$VisionReplyCopyWith(_VisionReply value, $Res Function(_VisionReply) _then) = __$VisionReplyCopyWithImpl;
@override @useResult
$Res call({
 String model, List<VisionDetection> items
});




}
/// @nodoc
class __$VisionReplyCopyWithImpl<$Res>
    implements _$VisionReplyCopyWith<$Res> {
  __$VisionReplyCopyWithImpl(this._self, this._then);

  final _VisionReply _self;
  final $Res Function(_VisionReply) _then;

/// Create a copy of VisionReply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? model = null,Object? items = null,}) {
  return _then(_VisionReply(
model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<VisionDetection>,
  ));
}


}

// dart format on
