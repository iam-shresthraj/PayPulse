// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DailyRate _$DailyRateFromJson(Map<String, dynamic> json) {
  return _DailyRate.fromJson(json);
}

/// @nodoc
mixin _$DailyRate {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double get rateGold22K => throw _privateConstructorUsedError;
  double get rateGold18K => throw _privateConstructorUsedError;
  double get rateSilver => throw _privateConstructorUsedError;
  String? get enteredBy => throw _privateConstructorUsedError;

  /// Serializes this DailyRate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailyRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyRateCopyWith<DailyRate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyRateCopyWith<$Res> {
  factory $DailyRateCopyWith(DailyRate value, $Res Function(DailyRate) then) =
      _$DailyRateCopyWithImpl<$Res, DailyRate>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    DateTime date,
    double rateGold22K,
    double rateGold18K,
    double rateSilver,
    String? enteredBy,
  });
}

/// @nodoc
class _$DailyRateCopyWithImpl<$Res, $Val extends DailyRate>
    implements $DailyRateCopyWith<$Res> {
  _$DailyRateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? date = null,
    Object? rateGold22K = null,
    Object? rateGold18K = null,
    Object? rateSilver = null,
    Object? enteredBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            rateGold22K: null == rateGold22K
                ? _value.rateGold22K
                : rateGold22K // ignore: cast_nullable_to_non_nullable
                      as double,
            rateGold18K: null == rateGold18K
                ? _value.rateGold18K
                : rateGold18K // ignore: cast_nullable_to_non_nullable
                      as double,
            rateSilver: null == rateSilver
                ? _value.rateSilver
                : rateSilver // ignore: cast_nullable_to_non_nullable
                      as double,
            enteredBy: freezed == enteredBy
                ? _value.enteredBy
                : enteredBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DailyRateImplCopyWith<$Res>
    implements $DailyRateCopyWith<$Res> {
  factory _$$DailyRateImplCopyWith(
    _$DailyRateImpl value,
    $Res Function(_$DailyRateImpl) then,
  ) = __$$DailyRateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    DateTime date,
    double rateGold22K,
    double rateGold18K,
    double rateSilver,
    String? enteredBy,
  });
}

/// @nodoc
class __$$DailyRateImplCopyWithImpl<$Res>
    extends _$DailyRateCopyWithImpl<$Res, _$DailyRateImpl>
    implements _$$DailyRateImplCopyWith<$Res> {
  __$$DailyRateImplCopyWithImpl(
    _$DailyRateImpl _value,
    $Res Function(_$DailyRateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DailyRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? date = null,
    Object? rateGold22K = null,
    Object? rateGold18K = null,
    Object? rateSilver = null,
    Object? enteredBy = freezed,
  }) {
    return _then(
      _$DailyRateImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        rateGold22K: null == rateGold22K
            ? _value.rateGold22K
            : rateGold22K // ignore: cast_nullable_to_non_nullable
                  as double,
        rateGold18K: null == rateGold18K
            ? _value.rateGold18K
            : rateGold18K // ignore: cast_nullable_to_non_nullable
                  as double,
        rateSilver: null == rateSilver
            ? _value.rateSilver
            : rateSilver // ignore: cast_nullable_to_non_nullable
                  as double,
        enteredBy: freezed == enteredBy
            ? _value.enteredBy
            : enteredBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyRateImpl implements _DailyRate {
  const _$DailyRateImpl({
    @JsonKey(name: '_id') this.id,
    required this.date,
    required this.rateGold22K,
    required this.rateGold18K,
    required this.rateSilver,
    this.enteredBy,
  });

  factory _$DailyRateImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyRateImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final DateTime date;
  @override
  final double rateGold22K;
  @override
  final double rateGold18K;
  @override
  final double rateSilver;
  @override
  final String? enteredBy;

  @override
  String toString() {
    return 'DailyRate(id: $id, date: $date, rateGold22K: $rateGold22K, rateGold18K: $rateGold18K, rateSilver: $rateSilver, enteredBy: $enteredBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyRateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.rateGold22K, rateGold22K) ||
                other.rateGold22K == rateGold22K) &&
            (identical(other.rateGold18K, rateGold18K) ||
                other.rateGold18K == rateGold18K) &&
            (identical(other.rateSilver, rateSilver) ||
                other.rateSilver == rateSilver) &&
            (identical(other.enteredBy, enteredBy) ||
                other.enteredBy == enteredBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    date,
    rateGold22K,
    rateGold18K,
    rateSilver,
    enteredBy,
  );

  /// Create a copy of DailyRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyRateImplCopyWith<_$DailyRateImpl> get copyWith =>
      __$$DailyRateImplCopyWithImpl<_$DailyRateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyRateImplToJson(this);
  }
}

abstract class _DailyRate implements DailyRate {
  const factory _DailyRate({
    @JsonKey(name: '_id') final String? id,
    required final DateTime date,
    required final double rateGold22K,
    required final double rateGold18K,
    required final double rateSilver,
    final String? enteredBy,
  }) = _$DailyRateImpl;

  factory _DailyRate.fromJson(Map<String, dynamic> json) =
      _$DailyRateImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  DateTime get date;
  @override
  double get rateGold22K;
  @override
  double get rateGold18K;
  @override
  double get rateSilver;
  @override
  String? get enteredBy;

  /// Create a copy of DailyRate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyRateImplCopyWith<_$DailyRateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
