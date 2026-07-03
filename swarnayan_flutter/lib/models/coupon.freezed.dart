// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coupon.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Coupon _$CouponFromJson(Map<String, dynamic> json) {
  return _Coupon.fromJson(json);
}

/// @nodoc
mixin _$Coupon {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get discountType =>
      throw _privateConstructorUsedError; // PERCENTAGE, FIXED
  double get discountValue => throw _privateConstructorUsedError;
  double get minBillAmount => throw _privateConstructorUsedError;
  double get maxDiscount => throw _privateConstructorUsedError;
  DateTime get expiryDate => throw _privateConstructorUsedError;
  DateTime? get startsAt => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  int? get usageLimit => throw _privateConstructorUsedError;
  int get usedCount => throw _privateConstructorUsedError;

  /// Serializes this Coupon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CouponCopyWith<Coupon> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CouponCopyWith<$Res> {
  factory $CouponCopyWith(Coupon value, $Res Function(Coupon) then) =
      _$CouponCopyWithImpl<$Res, Coupon>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String code,
    String discountType,
    double discountValue,
    double minBillAmount,
    double maxDiscount,
    DateTime expiryDate,
    DateTime? startsAt,
    bool isActive,
    int? usageLimit,
    int usedCount,
  });
}

/// @nodoc
class _$CouponCopyWithImpl<$Res, $Val extends Coupon>
    implements $CouponCopyWith<$Res> {
  _$CouponCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? code = null,
    Object? discountType = null,
    Object? discountValue = null,
    Object? minBillAmount = null,
    Object? maxDiscount = null,
    Object? expiryDate = null,
    Object? startsAt = freezed,
    Object? isActive = null,
    Object? usageLimit = freezed,
    Object? usedCount = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            discountType: null == discountType
                ? _value.discountType
                : discountType // ignore: cast_nullable_to_non_nullable
                      as String,
            discountValue: null == discountValue
                ? _value.discountValue
                : discountValue // ignore: cast_nullable_to_non_nullable
                      as double,
            minBillAmount: null == minBillAmount
                ? _value.minBillAmount
                : minBillAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            maxDiscount: null == maxDiscount
                ? _value.maxDiscount
                : maxDiscount // ignore: cast_nullable_to_non_nullable
                      as double,
            expiryDate: null == expiryDate
                ? _value.expiryDate
                : expiryDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            startsAt: freezed == startsAt
                ? _value.startsAt
                : startsAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            usageLimit: freezed == usageLimit
                ? _value.usageLimit
                : usageLimit // ignore: cast_nullable_to_non_nullable
                      as int?,
            usedCount: null == usedCount
                ? _value.usedCount
                : usedCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CouponImplCopyWith<$Res> implements $CouponCopyWith<$Res> {
  factory _$$CouponImplCopyWith(
    _$CouponImpl value,
    $Res Function(_$CouponImpl) then,
  ) = __$$CouponImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String code,
    String discountType,
    double discountValue,
    double minBillAmount,
    double maxDiscount,
    DateTime expiryDate,
    DateTime? startsAt,
    bool isActive,
    int? usageLimit,
    int usedCount,
  });
}

/// @nodoc
class __$$CouponImplCopyWithImpl<$Res>
    extends _$CouponCopyWithImpl<$Res, _$CouponImpl>
    implements _$$CouponImplCopyWith<$Res> {
  __$$CouponImplCopyWithImpl(
    _$CouponImpl _value,
    $Res Function(_$CouponImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? code = null,
    Object? discountType = null,
    Object? discountValue = null,
    Object? minBillAmount = null,
    Object? maxDiscount = null,
    Object? expiryDate = null,
    Object? startsAt = freezed,
    Object? isActive = null,
    Object? usageLimit = freezed,
    Object? usedCount = null,
  }) {
    return _then(
      _$CouponImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        discountType: null == discountType
            ? _value.discountType
            : discountType // ignore: cast_nullable_to_non_nullable
                  as String,
        discountValue: null == discountValue
            ? _value.discountValue
            : discountValue // ignore: cast_nullable_to_non_nullable
                  as double,
        minBillAmount: null == minBillAmount
            ? _value.minBillAmount
            : minBillAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        maxDiscount: null == maxDiscount
            ? _value.maxDiscount
            : maxDiscount // ignore: cast_nullable_to_non_nullable
                  as double,
        expiryDate: null == expiryDate
            ? _value.expiryDate
            : expiryDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        startsAt: freezed == startsAt
            ? _value.startsAt
            : startsAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        usageLimit: freezed == usageLimit
            ? _value.usageLimit
            : usageLimit // ignore: cast_nullable_to_non_nullable
                  as int?,
        usedCount: null == usedCount
            ? _value.usedCount
            : usedCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CouponImpl implements _Coupon {
  const _$CouponImpl({
    @JsonKey(name: '_id') this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minBillAmount = 0.0,
    this.maxDiscount = 0.0,
    required this.expiryDate,
    this.startsAt,
    this.isActive = true,
    this.usageLimit,
    this.usedCount = 0,
  });

  factory _$CouponImpl.fromJson(Map<String, dynamic> json) =>
      _$$CouponImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final String code;
  @override
  final String discountType;
  // PERCENTAGE, FIXED
  @override
  final double discountValue;
  @override
  @JsonKey()
  final double minBillAmount;
  @override
  @JsonKey()
  final double maxDiscount;
  @override
  final DateTime expiryDate;
  @override
  final DateTime? startsAt;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final int? usageLimit;
  @override
  @JsonKey()
  final int usedCount;

  @override
  String toString() {
    return 'Coupon(id: $id, code: $code, discountType: $discountType, discountValue: $discountValue, minBillAmount: $minBillAmount, maxDiscount: $maxDiscount, expiryDate: $expiryDate, startsAt: $startsAt, isActive: $isActive, usageLimit: $usageLimit, usedCount: $usedCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CouponImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.discountValue, discountValue) ||
                other.discountValue == discountValue) &&
            (identical(other.minBillAmount, minBillAmount) ||
                other.minBillAmount == minBillAmount) &&
            (identical(other.maxDiscount, maxDiscount) ||
                other.maxDiscount == maxDiscount) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.startsAt, startsAt) ||
                other.startsAt == startsAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.usageLimit, usageLimit) ||
                other.usageLimit == usageLimit) &&
            (identical(other.usedCount, usedCount) ||
                other.usedCount == usedCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    code,
    discountType,
    discountValue,
    minBillAmount,
    maxDiscount,
    expiryDate,
    startsAt,
    isActive,
    usageLimit,
    usedCount,
  );

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CouponImplCopyWith<_$CouponImpl> get copyWith =>
      __$$CouponImplCopyWithImpl<_$CouponImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CouponImplToJson(this);
  }
}

abstract class _Coupon implements Coupon {
  const factory _Coupon({
    @JsonKey(name: '_id') final String? id,
    required final String code,
    required final String discountType,
    required final double discountValue,
    final double minBillAmount,
    final double maxDiscount,
    required final DateTime expiryDate,
    final DateTime? startsAt,
    final bool isActive,
    final int? usageLimit,
    final int usedCount,
  }) = _$CouponImpl;

  factory _Coupon.fromJson(Map<String, dynamic> json) = _$CouponImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  String get code;
  @override
  String get discountType; // PERCENTAGE, FIXED
  @override
  double get discountValue;
  @override
  double get minBillAmount;
  @override
  double get maxDiscount;
  @override
  DateTime get expiryDate;
  @override
  DateTime? get startsAt;
  @override
  bool get isActive;
  @override
  int? get usageLimit;
  @override
  int get usedCount;

  /// Create a copy of Coupon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CouponImplCopyWith<_$CouponImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
