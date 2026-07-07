// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Payment _$PaymentFromJson(Map<String, dynamic> json) {
  return _Payment.fromJson(json);
}

/// @nodoc
mixin _$Payment {
  String get method =>
      throw _privateConstructorUsedError; // CASH, CARD, UPI, BANK_TRANSFER
  double get amount => throw _privateConstructorUsedError;

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call({String method, double amount});
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? method = null, Object? amount = null}) {
    return _then(
      _value.copyWith(
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
    _$PaymentImpl value,
    $Res Function(_$PaymentImpl) then,
  ) = __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String method, double amount});
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
    _$PaymentImpl _value,
    $Res Function(_$PaymentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? method = null, Object? amount = null}) {
    return _then(
      _$PaymentImpl(
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentImpl implements _Payment {
  const _$PaymentImpl({required this.method, required this.amount});

  factory _$PaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentImplFromJson(json);

  @override
  final String method;
  // CASH, CARD, UPI, BANK_TRANSFER
  @override
  final double amount;

  @override
  String toString() {
    return 'Payment(method: $method, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, method, amount);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentImplToJson(this);
  }
}

abstract class _Payment implements Payment {
  const factory _Payment({
    required final String method,
    required final double amount,
  }) = _$PaymentImpl;

  factory _Payment.fromJson(Map<String, dynamic> json) = _$PaymentImpl.fromJson;

  @override
  String get method; // CASH, CARD, UPI, BANK_TRANSFER
  @override
  double get amount;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OldGoldAdjustment _$OldGoldAdjustmentFromJson(Map<String, dynamic> json) {
  return _OldGoldAdjustment.fromJson(json);
}

/// @nodoc
mixin _$OldGoldAdjustment {
  double get weight => throw _privateConstructorUsedError;
  String get purity =>
      throw _privateConstructorUsedError; // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
  double get rate => throw _privateConstructorUsedError;
  double get metalValue => throw _privateConstructorUsedError;

  /// Serializes this OldGoldAdjustment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OldGoldAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OldGoldAdjustmentCopyWith<OldGoldAdjustment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OldGoldAdjustmentCopyWith<$Res> {
  factory $OldGoldAdjustmentCopyWith(
    OldGoldAdjustment value,
    $Res Function(OldGoldAdjustment) then,
  ) = _$OldGoldAdjustmentCopyWithImpl<$Res, OldGoldAdjustment>;
  @useResult
  $Res call({double weight, String purity, double rate, double metalValue});
}

/// @nodoc
class _$OldGoldAdjustmentCopyWithImpl<$Res, $Val extends OldGoldAdjustment>
    implements $OldGoldAdjustmentCopyWith<$Res> {
  _$OldGoldAdjustmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OldGoldAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weight = null,
    Object? purity = null,
    Object? rate = null,
    Object? metalValue = null,
  }) {
    return _then(
      _value.copyWith(
            weight: null == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double,
            purity: null == purity
                ? _value.purity
                : purity // ignore: cast_nullable_to_non_nullable
                      as String,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
            metalValue: null == metalValue
                ? _value.metalValue
                : metalValue // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OldGoldAdjustmentImplCopyWith<$Res>
    implements $OldGoldAdjustmentCopyWith<$Res> {
  factory _$$OldGoldAdjustmentImplCopyWith(
    _$OldGoldAdjustmentImpl value,
    $Res Function(_$OldGoldAdjustmentImpl) then,
  ) = __$$OldGoldAdjustmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double weight, String purity, double rate, double metalValue});
}

/// @nodoc
class __$$OldGoldAdjustmentImplCopyWithImpl<$Res>
    extends _$OldGoldAdjustmentCopyWithImpl<$Res, _$OldGoldAdjustmentImpl>
    implements _$$OldGoldAdjustmentImplCopyWith<$Res> {
  __$$OldGoldAdjustmentImplCopyWithImpl(
    _$OldGoldAdjustmentImpl _value,
    $Res Function(_$OldGoldAdjustmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OldGoldAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weight = null,
    Object? purity = null,
    Object? rate = null,
    Object? metalValue = null,
  }) {
    return _then(
      _$OldGoldAdjustmentImpl(
        weight: null == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double,
        purity: null == purity
            ? _value.purity
            : purity // ignore: cast_nullable_to_non_nullable
                  as String,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
        metalValue: null == metalValue
            ? _value.metalValue
            : metalValue // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OldGoldAdjustmentImpl implements _OldGoldAdjustment {
  const _$OldGoldAdjustmentImpl({
    required this.weight,
    required this.purity,
    required this.rate,
    this.metalValue = 0.0,
  });

  factory _$OldGoldAdjustmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$OldGoldAdjustmentImplFromJson(json);

  @override
  final double weight;
  @override
  final String purity;
  // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
  @override
  final double rate;
  @override
  @JsonKey()
  final double metalValue;

  @override
  String toString() {
    return 'OldGoldAdjustment(weight: $weight, purity: $purity, rate: $rate, metalValue: $metalValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OldGoldAdjustmentImpl &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.purity, purity) || other.purity == purity) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.metalValue, metalValue) ||
                other.metalValue == metalValue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, weight, purity, rate, metalValue);

  /// Create a copy of OldGoldAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OldGoldAdjustmentImplCopyWith<_$OldGoldAdjustmentImpl> get copyWith =>
      __$$OldGoldAdjustmentImplCopyWithImpl<_$OldGoldAdjustmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OldGoldAdjustmentImplToJson(this);
  }
}

abstract class _OldGoldAdjustment implements OldGoldAdjustment {
  const factory _OldGoldAdjustment({
    required final double weight,
    required final String purity,
    required final double rate,
    final double metalValue,
  }) = _$OldGoldAdjustmentImpl;

  factory _OldGoldAdjustment.fromJson(Map<String, dynamic> json) =
      _$OldGoldAdjustmentImpl.fromJson;

  @override
  double get weight;
  @override
  String get purity; // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
  @override
  double get rate;
  @override
  double get metalValue;

  /// Create a copy of OldGoldAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OldGoldAdjustmentImplCopyWith<_$OldGoldAdjustmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) {
  return _InvoiceItem.fromJson(json);
}

/// @nodoc
mixin _$InvoiceItem {
  String get productId => throw _privateConstructorUsedError;
  String get productName => throw _privateConstructorUsedError;
  String? get huidNumber => throw _privateConstructorUsedError;
  String get hsnCode => throw _privateConstructorUsedError;
  String get category =>
      throw _privateConstructorUsedError; // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
  String get purity => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  double get grossWeight => throw _privateConstructorUsedError;
  double get netWeight => throw _privateConstructorUsedError;
  double get rate => throw _privateConstructorUsedError;
  double get metalValue => throw _privateConstructorUsedError;
  String get makingChargeType =>
      throw _privateConstructorUsedError; // FIXED, PER_GRAM, PERCENTAGE
  double get makingChargeValue => throw _privateConstructorUsedError;
  double get makingChargeTotal => throw _privateConstructorUsedError;
  double get wastagePercentage => throw _privateConstructorUsedError;
  double get wastageWeight => throw _privateConstructorUsedError;
  double get wastageValue => throw _privateConstructorUsedError;
  String? get stoneType => throw _privateConstructorUsedError;
  double get stoneWeight => throw _privateConstructorUsedError;
  double get stoneValue => throw _privateConstructorUsedError;
  double get discountValue => throw _privateConstructorUsedError;
  double get itemTotal => throw _privateConstructorUsedError;

  /// Serializes this InvoiceItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceItemCopyWith<InvoiceItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceItemCopyWith<$Res> {
  factory $InvoiceItemCopyWith(
    InvoiceItem value,
    $Res Function(InvoiceItem) then,
  ) = _$InvoiceItemCopyWithImpl<$Res, InvoiceItem>;
  @useResult
  $Res call({
    String productId,
    String productName,
    String? huidNumber,
    String hsnCode,
    String category,
    String purity,
    int quantity,
    double grossWeight,
    double netWeight,
    double rate,
    double metalValue,
    String makingChargeType,
    double makingChargeValue,
    double makingChargeTotal,
    double wastagePercentage,
    double wastageWeight,
    double wastageValue,
    String? stoneType,
    double stoneWeight,
    double stoneValue,
    double discountValue,
    double itemTotal,
  });
}

/// @nodoc
class _$InvoiceItemCopyWithImpl<$Res, $Val extends InvoiceItem>
    implements $InvoiceItemCopyWith<$Res> {
  _$InvoiceItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? productName = null,
    Object? huidNumber = freezed,
    Object? hsnCode = null,
    Object? category = null,
    Object? purity = null,
    Object? quantity = null,
    Object? grossWeight = null,
    Object? netWeight = null,
    Object? rate = null,
    Object? metalValue = null,
    Object? makingChargeType = null,
    Object? makingChargeValue = null,
    Object? makingChargeTotal = null,
    Object? wastagePercentage = null,
    Object? wastageWeight = null,
    Object? wastageValue = null,
    Object? stoneType = freezed,
    Object? stoneWeight = null,
    Object? stoneValue = null,
    Object? discountValue = null,
    Object? itemTotal = null,
  }) {
    return _then(
      _value.copyWith(
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            productName: null == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String,
            huidNumber: freezed == huidNumber
                ? _value.huidNumber
                : huidNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            hsnCode: null == hsnCode
                ? _value.hsnCode
                : hsnCode // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            purity: null == purity
                ? _value.purity
                : purity // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            grossWeight: null == grossWeight
                ? _value.grossWeight
                : grossWeight // ignore: cast_nullable_to_non_nullable
                      as double,
            netWeight: null == netWeight
                ? _value.netWeight
                : netWeight // ignore: cast_nullable_to_non_nullable
                      as double,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
            metalValue: null == metalValue
                ? _value.metalValue
                : metalValue // ignore: cast_nullable_to_non_nullable
                      as double,
            makingChargeType: null == makingChargeType
                ? _value.makingChargeType
                : makingChargeType // ignore: cast_nullable_to_non_nullable
                      as String,
            makingChargeValue: null == makingChargeValue
                ? _value.makingChargeValue
                : makingChargeValue // ignore: cast_nullable_to_non_nullable
                      as double,
            makingChargeTotal: null == makingChargeTotal
                ? _value.makingChargeTotal
                : makingChargeTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            wastagePercentage: null == wastagePercentage
                ? _value.wastagePercentage
                : wastagePercentage // ignore: cast_nullable_to_non_nullable
                      as double,
            wastageWeight: null == wastageWeight
                ? _value.wastageWeight
                : wastageWeight // ignore: cast_nullable_to_non_nullable
                      as double,
            wastageValue: null == wastageValue
                ? _value.wastageValue
                : wastageValue // ignore: cast_nullable_to_non_nullable
                      as double,
            stoneType: freezed == stoneType
                ? _value.stoneType
                : stoneType // ignore: cast_nullable_to_non_nullable
                      as String?,
            stoneWeight: null == stoneWeight
                ? _value.stoneWeight
                : stoneWeight // ignore: cast_nullable_to_non_nullable
                      as double,
            stoneValue: null == stoneValue
                ? _value.stoneValue
                : stoneValue // ignore: cast_nullable_to_non_nullable
                      as double,
            discountValue: null == discountValue
                ? _value.discountValue
                : discountValue // ignore: cast_nullable_to_non_nullable
                      as double,
            itemTotal: null == itemTotal
                ? _value.itemTotal
                : itemTotal // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InvoiceItemImplCopyWith<$Res>
    implements $InvoiceItemCopyWith<$Res> {
  factory _$$InvoiceItemImplCopyWith(
    _$InvoiceItemImpl value,
    $Res Function(_$InvoiceItemImpl) then,
  ) = __$$InvoiceItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productId,
    String productName,
    String? huidNumber,
    String hsnCode,
    String category,
    String purity,
    int quantity,
    double grossWeight,
    double netWeight,
    double rate,
    double metalValue,
    String makingChargeType,
    double makingChargeValue,
    double makingChargeTotal,
    double wastagePercentage,
    double wastageWeight,
    double wastageValue,
    String? stoneType,
    double stoneWeight,
    double stoneValue,
    double discountValue,
    double itemTotal,
  });
}

/// @nodoc
class __$$InvoiceItemImplCopyWithImpl<$Res>
    extends _$InvoiceItemCopyWithImpl<$Res, _$InvoiceItemImpl>
    implements _$$InvoiceItemImplCopyWith<$Res> {
  __$$InvoiceItemImplCopyWithImpl(
    _$InvoiceItemImpl _value,
    $Res Function(_$InvoiceItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? productName = null,
    Object? huidNumber = freezed,
    Object? hsnCode = null,
    Object? category = null,
    Object? purity = null,
    Object? quantity = null,
    Object? grossWeight = null,
    Object? netWeight = null,
    Object? rate = null,
    Object? metalValue = null,
    Object? makingChargeType = null,
    Object? makingChargeValue = null,
    Object? makingChargeTotal = null,
    Object? wastagePercentage = null,
    Object? wastageWeight = null,
    Object? wastageValue = null,
    Object? stoneType = freezed,
    Object? stoneWeight = null,
    Object? stoneValue = null,
    Object? discountValue = null,
    Object? itemTotal = null,
  }) {
    return _then(
      _$InvoiceItemImpl(
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        productName: null == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String,
        huidNumber: freezed == huidNumber
            ? _value.huidNumber
            : huidNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        hsnCode: null == hsnCode
            ? _value.hsnCode
            : hsnCode // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        purity: null == purity
            ? _value.purity
            : purity // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        grossWeight: null == grossWeight
            ? _value.grossWeight
            : grossWeight // ignore: cast_nullable_to_non_nullable
                  as double,
        netWeight: null == netWeight
            ? _value.netWeight
            : netWeight // ignore: cast_nullable_to_non_nullable
                  as double,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
        metalValue: null == metalValue
            ? _value.metalValue
            : metalValue // ignore: cast_nullable_to_non_nullable
                  as double,
        makingChargeType: null == makingChargeType
            ? _value.makingChargeType
            : makingChargeType // ignore: cast_nullable_to_non_nullable
                  as String,
        makingChargeValue: null == makingChargeValue
            ? _value.makingChargeValue
            : makingChargeValue // ignore: cast_nullable_to_non_nullable
                  as double,
        makingChargeTotal: null == makingChargeTotal
            ? _value.makingChargeTotal
            : makingChargeTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        wastagePercentage: null == wastagePercentage
            ? _value.wastagePercentage
            : wastagePercentage // ignore: cast_nullable_to_non_nullable
                  as double,
        wastageWeight: null == wastageWeight
            ? _value.wastageWeight
            : wastageWeight // ignore: cast_nullable_to_non_nullable
                  as double,
        wastageValue: null == wastageValue
            ? _value.wastageValue
            : wastageValue // ignore: cast_nullable_to_non_nullable
                  as double,
        stoneType: freezed == stoneType
            ? _value.stoneType
            : stoneType // ignore: cast_nullable_to_non_nullable
                  as String?,
        stoneWeight: null == stoneWeight
            ? _value.stoneWeight
            : stoneWeight // ignore: cast_nullable_to_non_nullable
                  as double,
        stoneValue: null == stoneValue
            ? _value.stoneValue
            : stoneValue // ignore: cast_nullable_to_non_nullable
                  as double,
        discountValue: null == discountValue
            ? _value.discountValue
            : discountValue // ignore: cast_nullable_to_non_nullable
                  as double,
        itemTotal: null == itemTotal
            ? _value.itemTotal
            : itemTotal // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceItemImpl implements _InvoiceItem {
  const _$InvoiceItemImpl({
    required this.productId,
    required this.productName,
    this.huidNumber,
    required this.hsnCode,
    required this.category,
    required this.purity,
    this.quantity = 1,
    required this.grossWeight,
    required this.netWeight,
    required this.rate,
    required this.metalValue,
    required this.makingChargeType,
    required this.makingChargeValue,
    required this.makingChargeTotal,
    this.wastagePercentage = 0.0,
    this.wastageWeight = 0.0,
    this.wastageValue = 0.0,
    this.stoneType,
    this.stoneWeight = 0.0,
    this.stoneValue = 0.0,
    this.discountValue = 0.0,
    required this.itemTotal,
  });

  factory _$InvoiceItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceItemImplFromJson(json);

  @override
  final String productId;
  @override
  final String productName;
  @override
  final String? huidNumber;
  @override
  final String hsnCode;
  @override
  final String category;
  // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
  @override
  final String purity;
  @override
  @JsonKey()
  final int quantity;
  @override
  final double grossWeight;
  @override
  final double netWeight;
  @override
  final double rate;
  @override
  final double metalValue;
  @override
  final String makingChargeType;
  // FIXED, PER_GRAM, PERCENTAGE
  @override
  final double makingChargeValue;
  @override
  final double makingChargeTotal;
  @override
  @JsonKey()
  final double wastagePercentage;
  @override
  @JsonKey()
  final double wastageWeight;
  @override
  @JsonKey()
  final double wastageValue;
  @override
  final String? stoneType;
  @override
  @JsonKey()
  final double stoneWeight;
  @override
  @JsonKey()
  final double stoneValue;
  @override
  @JsonKey()
  final double discountValue;
  @override
  final double itemTotal;

  @override
  String toString() {
    return 'InvoiceItem(productId: $productId, productName: $productName, huidNumber: $huidNumber, hsnCode: $hsnCode, category: $category, purity: $purity, quantity: $quantity, grossWeight: $grossWeight, netWeight: $netWeight, rate: $rate, metalValue: $metalValue, makingChargeType: $makingChargeType, makingChargeValue: $makingChargeValue, makingChargeTotal: $makingChargeTotal, wastagePercentage: $wastagePercentage, wastageWeight: $wastageWeight, wastageValue: $wastageValue, stoneType: $stoneType, stoneWeight: $stoneWeight, stoneValue: $stoneValue, discountValue: $discountValue, itemTotal: $itemTotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceItemImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.huidNumber, huidNumber) ||
                other.huidNumber == huidNumber) &&
            (identical(other.hsnCode, hsnCode) || other.hsnCode == hsnCode) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.purity, purity) || other.purity == purity) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.grossWeight, grossWeight) ||
                other.grossWeight == grossWeight) &&
            (identical(other.netWeight, netWeight) ||
                other.netWeight == netWeight) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.metalValue, metalValue) ||
                other.metalValue == metalValue) &&
            (identical(other.makingChargeType, makingChargeType) ||
                other.makingChargeType == makingChargeType) &&
            (identical(other.makingChargeValue, makingChargeValue) ||
                other.makingChargeValue == makingChargeValue) &&
            (identical(other.makingChargeTotal, makingChargeTotal) ||
                other.makingChargeTotal == makingChargeTotal) &&
            (identical(other.wastagePercentage, wastagePercentage) ||
                other.wastagePercentage == wastagePercentage) &&
            (identical(other.wastageWeight, wastageWeight) ||
                other.wastageWeight == wastageWeight) &&
            (identical(other.wastageValue, wastageValue) ||
                other.wastageValue == wastageValue) &&
            (identical(other.stoneType, stoneType) ||
                other.stoneType == stoneType) &&
            (identical(other.stoneWeight, stoneWeight) ||
                other.stoneWeight == stoneWeight) &&
            (identical(other.stoneValue, stoneValue) ||
                other.stoneValue == stoneValue) &&
            (identical(other.discountValue, discountValue) ||
                other.discountValue == discountValue) &&
            (identical(other.itemTotal, itemTotal) ||
                other.itemTotal == itemTotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    productId,
    productName,
    huidNumber,
    hsnCode,
    category,
    purity,
    quantity,
    grossWeight,
    netWeight,
    rate,
    metalValue,
    makingChargeType,
    makingChargeValue,
    makingChargeTotal,
    wastagePercentage,
    wastageWeight,
    wastageValue,
    stoneType,
    stoneWeight,
    stoneValue,
    discountValue,
    itemTotal,
  ]);

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      __$$InvoiceItemImplCopyWithImpl<_$InvoiceItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceItemImplToJson(this);
  }
}

abstract class _InvoiceItem implements InvoiceItem {
  const factory _InvoiceItem({
    required final String productId,
    required final String productName,
    final String? huidNumber,
    required final String hsnCode,
    required final String category,
    required final String purity,
    final int quantity,
    required final double grossWeight,
    required final double netWeight,
    required final double rate,
    required final double metalValue,
    required final String makingChargeType,
    required final double makingChargeValue,
    required final double makingChargeTotal,
    final double wastagePercentage,
    final double wastageWeight,
    final double wastageValue,
    final String? stoneType,
    final double stoneWeight,
    final double stoneValue,
    final double discountValue,
    required final double itemTotal,
  }) = _$InvoiceItemImpl;

  factory _InvoiceItem.fromJson(Map<String, dynamic> json) =
      _$InvoiceItemImpl.fromJson;

  @override
  String get productId;
  @override
  String get productName;
  @override
  String? get huidNumber;
  @override
  String get hsnCode;
  @override
  String get category; // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
  @override
  String get purity;
  @override
  int get quantity;
  @override
  double get grossWeight;
  @override
  double get netWeight;
  @override
  double get rate;
  @override
  double get metalValue;
  @override
  String get makingChargeType; // FIXED, PER_GRAM, PERCENTAGE
  @override
  double get makingChargeValue;
  @override
  double get makingChargeTotal;
  @override
  double get wastagePercentage;
  @override
  double get wastageWeight;
  @override
  double get wastageValue;
  @override
  String? get stoneType;
  @override
  double get stoneWeight;
  @override
  double get stoneValue;
  @override
  double get discountValue;
  @override
  double get itemTotal;

  /// Create a copy of InvoiceItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RatesSnapshot _$RatesSnapshotFromJson(Map<String, dynamic> json) {
  return _RatesSnapshot.fromJson(json);
}

/// @nodoc
mixin _$RatesSnapshot {
  double get rateGold22K => throw _privateConstructorUsedError;
  double get rateGold18K => throw _privateConstructorUsedError;
  double get rateSilver => throw _privateConstructorUsedError;

  /// Serializes this RatesSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RatesSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RatesSnapshotCopyWith<RatesSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RatesSnapshotCopyWith<$Res> {
  factory $RatesSnapshotCopyWith(
    RatesSnapshot value,
    $Res Function(RatesSnapshot) then,
  ) = _$RatesSnapshotCopyWithImpl<$Res, RatesSnapshot>;
  @useResult
  $Res call({double rateGold22K, double rateGold18K, double rateSilver});
}

/// @nodoc
class _$RatesSnapshotCopyWithImpl<$Res, $Val extends RatesSnapshot>
    implements $RatesSnapshotCopyWith<$Res> {
  _$RatesSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RatesSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rateGold22K = null,
    Object? rateGold18K = null,
    Object? rateSilver = null,
  }) {
    return _then(
      _value.copyWith(
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RatesSnapshotImplCopyWith<$Res>
    implements $RatesSnapshotCopyWith<$Res> {
  factory _$$RatesSnapshotImplCopyWith(
    _$RatesSnapshotImpl value,
    $Res Function(_$RatesSnapshotImpl) then,
  ) = __$$RatesSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double rateGold22K, double rateGold18K, double rateSilver});
}

/// @nodoc
class __$$RatesSnapshotImplCopyWithImpl<$Res>
    extends _$RatesSnapshotCopyWithImpl<$Res, _$RatesSnapshotImpl>
    implements _$$RatesSnapshotImplCopyWith<$Res> {
  __$$RatesSnapshotImplCopyWithImpl(
    _$RatesSnapshotImpl _value,
    $Res Function(_$RatesSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RatesSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rateGold22K = null,
    Object? rateGold18K = null,
    Object? rateSilver = null,
  }) {
    return _then(
      _$RatesSnapshotImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RatesSnapshotImpl implements _RatesSnapshot {
  const _$RatesSnapshotImpl({
    required this.rateGold22K,
    required this.rateGold18K,
    required this.rateSilver,
  });

  factory _$RatesSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$RatesSnapshotImplFromJson(json);

  @override
  final double rateGold22K;
  @override
  final double rateGold18K;
  @override
  final double rateSilver;

  @override
  String toString() {
    return 'RatesSnapshot(rateGold22K: $rateGold22K, rateGold18K: $rateGold18K, rateSilver: $rateSilver)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RatesSnapshotImpl &&
            (identical(other.rateGold22K, rateGold22K) ||
                other.rateGold22K == rateGold22K) &&
            (identical(other.rateGold18K, rateGold18K) ||
                other.rateGold18K == rateGold18K) &&
            (identical(other.rateSilver, rateSilver) ||
                other.rateSilver == rateSilver));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, rateGold22K, rateGold18K, rateSilver);

  /// Create a copy of RatesSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RatesSnapshotImplCopyWith<_$RatesSnapshotImpl> get copyWith =>
      __$$RatesSnapshotImplCopyWithImpl<_$RatesSnapshotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RatesSnapshotImplToJson(this);
  }
}

abstract class _RatesSnapshot implements RatesSnapshot {
  const factory _RatesSnapshot({
    required final double rateGold22K,
    required final double rateGold18K,
    required final double rateSilver,
  }) = _$RatesSnapshotImpl;

  factory _RatesSnapshot.fromJson(Map<String, dynamic> json) =
      _$RatesSnapshotImpl.fromJson;

  @override
  double get rateGold22K;
  @override
  double get rateGold18K;
  @override
  double get rateSilver;

  /// Create a copy of RatesSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RatesSnapshotImplCopyWith<_$RatesSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Invoice _$InvoiceFromJson(Map<String, dynamic> json) {
  return _Invoice.fromJson(json);
}

/// @nodoc
mixin _$Invoice {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  String? get invoiceNumber => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
  String? get customerId => throw _privateConstructorUsedError;
  String? get tempCustomerName => throw _privateConstructorUsedError;
  String? get tempCustomerMobile => throw _privateConstructorUsedError;
  String? get tempCustomerAddress => throw _privateConstructorUsedError;
  String? get tempCustomerPincode => throw _privateConstructorUsedError;
  String? get tempCustomerCity => throw _privateConstructorUsedError;
  String? get tempCustomerState => throw _privateConstructorUsedError;
  List<InvoiceItem> get items => throw _privateConstructorUsedError;
  double get grossAmount => throw _privateConstructorUsedError;
  String? get couponCode => throw _privateConstructorUsedError;
  double get couponDiscount => throw _privateConstructorUsedError;
  double get manualDiscount => throw _privateConstructorUsedError;
  OldGoldAdjustment? get oldGold => throw _privateConstructorUsedError;
  double get taxableAmount => throw _privateConstructorUsedError;
  double get cgst => throw _privateConstructorUsedError;
  double get sgst => throw _privateConstructorUsedError;
  double get totalTax => throw _privateConstructorUsedError;
  double get netAmount => throw _privateConstructorUsedError;
  double get finalPayable => throw _privateConstructorUsedError;
  List<Payment> get payments => throw _privateConstructorUsedError;
  double get totalAmountPaid => throw _privateConstructorUsedError;
  double get balanceDue => throw _privateConstructorUsedError;
  DateTime get invoiceDate => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
  String? get generatedBy => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // PAID, PARTIALLY_PAID, CANCELLED
  RatesSnapshot get ratesSnapshot => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  String? get pdfBase64 => throw _privateConstructorUsedError;

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceCopyWith<Invoice> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceCopyWith<$Res> {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) then) =
      _$InvoiceCopyWithImpl<$Res, Invoice>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String? invoiceNumber,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    String? customerId,
    String? tempCustomerName,
    String? tempCustomerMobile,
    String? tempCustomerAddress,
    String? tempCustomerPincode,
    String? tempCustomerCity,
    String? tempCustomerState,
    List<InvoiceItem> items,
    double grossAmount,
    String? couponCode,
    double couponDiscount,
    double manualDiscount,
    OldGoldAdjustment? oldGold,
    double taxableAmount,
    double cgst,
    double sgst,
    double totalTax,
    double netAmount,
    double finalPayable,
    List<Payment> payments,
    double totalAmountPaid,
    double balanceDue,
    DateTime invoiceDate,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    String? generatedBy,
    String status,
    RatesSnapshot ratesSnapshot,
    DateTime? deletedAt,
    String? pdfBase64,
  });

  $OldGoldAdjustmentCopyWith<$Res>? get oldGold;
  $RatesSnapshotCopyWith<$Res> get ratesSnapshot;
}

/// @nodoc
class _$InvoiceCopyWithImpl<$Res, $Val extends Invoice>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? invoiceNumber = freezed,
    Object? customerId = freezed,
    Object? tempCustomerName = freezed,
    Object? tempCustomerMobile = freezed,
    Object? tempCustomerAddress = freezed,
    Object? tempCustomerPincode = freezed,
    Object? tempCustomerCity = freezed,
    Object? tempCustomerState = freezed,
    Object? items = null,
    Object? grossAmount = null,
    Object? couponCode = freezed,
    Object? couponDiscount = null,
    Object? manualDiscount = null,
    Object? oldGold = freezed,
    Object? taxableAmount = null,
    Object? cgst = null,
    Object? sgst = null,
    Object? totalTax = null,
    Object? netAmount = null,
    Object? finalPayable = null,
    Object? payments = null,
    Object? totalAmountPaid = null,
    Object? balanceDue = null,
    Object? invoiceDate = null,
    Object? generatedBy = freezed,
    Object? status = null,
    Object? ratesSnapshot = null,
    Object? deletedAt = freezed,
    Object? pdfBase64 = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            invoiceNumber: freezed == invoiceNumber
                ? _value.invoiceNumber
                : invoiceNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerId: freezed == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            tempCustomerName: freezed == tempCustomerName
                ? _value.tempCustomerName
                : tempCustomerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            tempCustomerMobile: freezed == tempCustomerMobile
                ? _value.tempCustomerMobile
                : tempCustomerMobile // ignore: cast_nullable_to_non_nullable
                      as String?,
            tempCustomerAddress: freezed == tempCustomerAddress
                ? _value.tempCustomerAddress
                : tempCustomerAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            tempCustomerPincode: freezed == tempCustomerPincode
                ? _value.tempCustomerPincode
                : tempCustomerPincode // ignore: cast_nullable_to_non_nullable
                      as String?,
            tempCustomerCity: freezed == tempCustomerCity
                ? _value.tempCustomerCity
                : tempCustomerCity // ignore: cast_nullable_to_non_nullable
                      as String?,
            tempCustomerState: freezed == tempCustomerState
                ? _value.tempCustomerState
                : tempCustomerState // ignore: cast_nullable_to_non_nullable
                      as String?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<InvoiceItem>,
            grossAmount: null == grossAmount
                ? _value.grossAmount
                : grossAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            couponCode: freezed == couponCode
                ? _value.couponCode
                : couponCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            couponDiscount: null == couponDiscount
                ? _value.couponDiscount
                : couponDiscount // ignore: cast_nullable_to_non_nullable
                      as double,
            manualDiscount: null == manualDiscount
                ? _value.manualDiscount
                : manualDiscount // ignore: cast_nullable_to_non_nullable
                      as double,
            oldGold: freezed == oldGold
                ? _value.oldGold
                : oldGold // ignore: cast_nullable_to_non_nullable
                      as OldGoldAdjustment?,
            taxableAmount: null == taxableAmount
                ? _value.taxableAmount
                : taxableAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            cgst: null == cgst
                ? _value.cgst
                : cgst // ignore: cast_nullable_to_non_nullable
                      as double,
            sgst: null == sgst
                ? _value.sgst
                : sgst // ignore: cast_nullable_to_non_nullable
                      as double,
            totalTax: null == totalTax
                ? _value.totalTax
                : totalTax // ignore: cast_nullable_to_non_nullable
                      as double,
            netAmount: null == netAmount
                ? _value.netAmount
                : netAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            finalPayable: null == finalPayable
                ? _value.finalPayable
                : finalPayable // ignore: cast_nullable_to_non_nullable
                      as double,
            payments: null == payments
                ? _value.payments
                : payments // ignore: cast_nullable_to_non_nullable
                      as List<Payment>,
            totalAmountPaid: null == totalAmountPaid
                ? _value.totalAmountPaid
                : totalAmountPaid // ignore: cast_nullable_to_non_nullable
                      as double,
            balanceDue: null == balanceDue
                ? _value.balanceDue
                : balanceDue // ignore: cast_nullable_to_non_nullable
                      as double,
            invoiceDate: null == invoiceDate
                ? _value.invoiceDate
                : invoiceDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            generatedBy: freezed == generatedBy
                ? _value.generatedBy
                : generatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            ratesSnapshot: null == ratesSnapshot
                ? _value.ratesSnapshot
                : ratesSnapshot // ignore: cast_nullable_to_non_nullable
                      as RatesSnapshot,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pdfBase64: freezed == pdfBase64
                ? _value.pdfBase64
                : pdfBase64 // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OldGoldAdjustmentCopyWith<$Res>? get oldGold {
    if (_value.oldGold == null) {
      return null;
    }

    return $OldGoldAdjustmentCopyWith<$Res>(_value.oldGold!, (value) {
      return _then(_value.copyWith(oldGold: value) as $Val);
    });
  }

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RatesSnapshotCopyWith<$Res> get ratesSnapshot {
    return $RatesSnapshotCopyWith<$Res>(_value.ratesSnapshot, (value) {
      return _then(_value.copyWith(ratesSnapshot: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InvoiceImplCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$$InvoiceImplCopyWith(
    _$InvoiceImpl value,
    $Res Function(_$InvoiceImpl) then,
  ) = __$$InvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String? invoiceNumber,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    String? customerId,
    String? tempCustomerName,
    String? tempCustomerMobile,
    String? tempCustomerAddress,
    String? tempCustomerPincode,
    String? tempCustomerCity,
    String? tempCustomerState,
    List<InvoiceItem> items,
    double grossAmount,
    String? couponCode,
    double couponDiscount,
    double manualDiscount,
    OldGoldAdjustment? oldGold,
    double taxableAmount,
    double cgst,
    double sgst,
    double totalTax,
    double netAmount,
    double finalPayable,
    List<Payment> payments,
    double totalAmountPaid,
    double balanceDue,
    DateTime invoiceDate,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    String? generatedBy,
    String status,
    RatesSnapshot ratesSnapshot,
    DateTime? deletedAt,
    String? pdfBase64,
  });

  @override
  $OldGoldAdjustmentCopyWith<$Res>? get oldGold;
  @override
  $RatesSnapshotCopyWith<$Res> get ratesSnapshot;
}

/// @nodoc
class __$$InvoiceImplCopyWithImpl<$Res>
    extends _$InvoiceCopyWithImpl<$Res, _$InvoiceImpl>
    implements _$$InvoiceImplCopyWith<$Res> {
  __$$InvoiceImplCopyWithImpl(
    _$InvoiceImpl _value,
    $Res Function(_$InvoiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? invoiceNumber = freezed,
    Object? customerId = freezed,
    Object? tempCustomerName = freezed,
    Object? tempCustomerMobile = freezed,
    Object? tempCustomerAddress = freezed,
    Object? tempCustomerPincode = freezed,
    Object? tempCustomerCity = freezed,
    Object? tempCustomerState = freezed,
    Object? items = null,
    Object? grossAmount = null,
    Object? couponCode = freezed,
    Object? couponDiscount = null,
    Object? manualDiscount = null,
    Object? oldGold = freezed,
    Object? taxableAmount = null,
    Object? cgst = null,
    Object? sgst = null,
    Object? totalTax = null,
    Object? netAmount = null,
    Object? finalPayable = null,
    Object? payments = null,
    Object? totalAmountPaid = null,
    Object? balanceDue = null,
    Object? invoiceDate = null,
    Object? generatedBy = freezed,
    Object? status = null,
    Object? ratesSnapshot = null,
    Object? deletedAt = freezed,
    Object? pdfBase64 = freezed,
  }) {
    return _then(
      _$InvoiceImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        invoiceNumber: freezed == invoiceNumber
            ? _value.invoiceNumber
            : invoiceNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerId: freezed == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tempCustomerName: freezed == tempCustomerName
            ? _value.tempCustomerName
            : tempCustomerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        tempCustomerMobile: freezed == tempCustomerMobile
            ? _value.tempCustomerMobile
            : tempCustomerMobile // ignore: cast_nullable_to_non_nullable
                  as String?,
        tempCustomerAddress: freezed == tempCustomerAddress
            ? _value.tempCustomerAddress
            : tempCustomerAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        tempCustomerPincode: freezed == tempCustomerPincode
            ? _value.tempCustomerPincode
            : tempCustomerPincode // ignore: cast_nullable_to_non_nullable
                  as String?,
        tempCustomerCity: freezed == tempCustomerCity
            ? _value.tempCustomerCity
            : tempCustomerCity // ignore: cast_nullable_to_non_nullable
                  as String?,
        tempCustomerState: freezed == tempCustomerState
            ? _value.tempCustomerState
            : tempCustomerState // ignore: cast_nullable_to_non_nullable
                  as String?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<InvoiceItem>,
        grossAmount: null == grossAmount
            ? _value.grossAmount
            : grossAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        couponCode: freezed == couponCode
            ? _value.couponCode
            : couponCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        couponDiscount: null == couponDiscount
            ? _value.couponDiscount
            : couponDiscount // ignore: cast_nullable_to_non_nullable
                  as double,
        manualDiscount: null == manualDiscount
            ? _value.manualDiscount
            : manualDiscount // ignore: cast_nullable_to_non_nullable
                  as double,
        oldGold: freezed == oldGold
            ? _value.oldGold
            : oldGold // ignore: cast_nullable_to_non_nullable
                  as OldGoldAdjustment?,
        taxableAmount: null == taxableAmount
            ? _value.taxableAmount
            : taxableAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        cgst: null == cgst
            ? _value.cgst
            : cgst // ignore: cast_nullable_to_non_nullable
                  as double,
        sgst: null == sgst
            ? _value.sgst
            : sgst // ignore: cast_nullable_to_non_nullable
                  as double,
        totalTax: null == totalTax
            ? _value.totalTax
            : totalTax // ignore: cast_nullable_to_non_nullable
                  as double,
        netAmount: null == netAmount
            ? _value.netAmount
            : netAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        finalPayable: null == finalPayable
            ? _value.finalPayable
            : finalPayable // ignore: cast_nullable_to_non_nullable
                  as double,
        payments: null == payments
            ? _value._payments
            : payments // ignore: cast_nullable_to_non_nullable
                  as List<Payment>,
        totalAmountPaid: null == totalAmountPaid
            ? _value.totalAmountPaid
            : totalAmountPaid // ignore: cast_nullable_to_non_nullable
                  as double,
        balanceDue: null == balanceDue
            ? _value.balanceDue
            : balanceDue // ignore: cast_nullable_to_non_nullable
                  as double,
        invoiceDate: null == invoiceDate
            ? _value.invoiceDate
            : invoiceDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        generatedBy: freezed == generatedBy
            ? _value.generatedBy
            : generatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        ratesSnapshot: null == ratesSnapshot
            ? _value.ratesSnapshot
            : ratesSnapshot // ignore: cast_nullable_to_non_nullable
                  as RatesSnapshot,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pdfBase64: freezed == pdfBase64
            ? _value.pdfBase64
            : pdfBase64 // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceImpl implements _Invoice {
  const _$InvoiceImpl({
    @JsonKey(name: '_id') this.id,
    this.invoiceNumber,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    this.customerId,
    this.tempCustomerName,
    this.tempCustomerMobile,
    this.tempCustomerAddress,
    this.tempCustomerPincode,
    this.tempCustomerCity,
    this.tempCustomerState,
    required final List<InvoiceItem> items,
    required this.grossAmount,
    this.couponCode,
    this.couponDiscount = 0.0,
    this.manualDiscount = 0.0,
    this.oldGold,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.totalTax,
    required this.netAmount,
    required this.finalPayable,
    required final List<Payment> payments,
    required this.totalAmountPaid,
    required this.balanceDue,
    required this.invoiceDate,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    this.generatedBy,
    this.status = 'PAID',
    required this.ratesSnapshot,
    this.deletedAt,
    this.pdfBase64,
  }) : _items = items,
       _payments = payments;

  factory _$InvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final String? invoiceNumber;
  @override
  @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
  final String? customerId;
  @override
  final String? tempCustomerName;
  @override
  final String? tempCustomerMobile;
  @override
  final String? tempCustomerAddress;
  @override
  final String? tempCustomerPincode;
  @override
  final String? tempCustomerCity;
  @override
  final String? tempCustomerState;
  final List<InvoiceItem> _items;
  @override
  List<InvoiceItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final double grossAmount;
  @override
  final String? couponCode;
  @override
  @JsonKey()
  final double couponDiscount;
  @override
  @JsonKey()
  final double manualDiscount;
  @override
  final OldGoldAdjustment? oldGold;
  @override
  final double taxableAmount;
  @override
  final double cgst;
  @override
  final double sgst;
  @override
  final double totalTax;
  @override
  final double netAmount;
  @override
  final double finalPayable;
  final List<Payment> _payments;
  @override
  List<Payment> get payments {
    if (_payments is EqualUnmodifiableListView) return _payments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_payments);
  }

  @override
  final double totalAmountPaid;
  @override
  final double balanceDue;
  @override
  final DateTime invoiceDate;
  @override
  @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
  final String? generatedBy;
  @override
  @JsonKey()
  final String status;
  // PAID, PARTIALLY_PAID, CANCELLED
  @override
  final RatesSnapshot ratesSnapshot;
  @override
  final DateTime? deletedAt;
  @override
  final String? pdfBase64;

  @override
  String toString() {
    return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, customerId: $customerId, tempCustomerName: $tempCustomerName, tempCustomerMobile: $tempCustomerMobile, tempCustomerAddress: $tempCustomerAddress, tempCustomerPincode: $tempCustomerPincode, tempCustomerCity: $tempCustomerCity, tempCustomerState: $tempCustomerState, items: $items, grossAmount: $grossAmount, couponCode: $couponCode, couponDiscount: $couponDiscount, manualDiscount: $manualDiscount, oldGold: $oldGold, taxableAmount: $taxableAmount, cgst: $cgst, sgst: $sgst, totalTax: $totalTax, netAmount: $netAmount, finalPayable: $finalPayable, payments: $payments, totalAmountPaid: $totalAmountPaid, balanceDue: $balanceDue, invoiceDate: $invoiceDate, generatedBy: $generatedBy, status: $status, ratesSnapshot: $ratesSnapshot, deletedAt: $deletedAt, pdfBase64: $pdfBase64)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.tempCustomerName, tempCustomerName) ||
                other.tempCustomerName == tempCustomerName) &&
            (identical(other.tempCustomerMobile, tempCustomerMobile) ||
                other.tempCustomerMobile == tempCustomerMobile) &&
            (identical(other.tempCustomerAddress, tempCustomerAddress) ||
                other.tempCustomerAddress == tempCustomerAddress) &&
            (identical(other.tempCustomerPincode, tempCustomerPincode) ||
                other.tempCustomerPincode == tempCustomerPincode) &&
            (identical(other.tempCustomerCity, tempCustomerCity) ||
                other.tempCustomerCity == tempCustomerCity) &&
            (identical(other.tempCustomerState, tempCustomerState) ||
                other.tempCustomerState == tempCustomerState) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.grossAmount, grossAmount) ||
                other.grossAmount == grossAmount) &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode) &&
            (identical(other.couponDiscount, couponDiscount) ||
                other.couponDiscount == couponDiscount) &&
            (identical(other.manualDiscount, manualDiscount) ||
                other.manualDiscount == manualDiscount) &&
            (identical(other.oldGold, oldGold) || other.oldGold == oldGold) &&
            (identical(other.taxableAmount, taxableAmount) ||
                other.taxableAmount == taxableAmount) &&
            (identical(other.cgst, cgst) || other.cgst == cgst) &&
            (identical(other.sgst, sgst) || other.sgst == sgst) &&
            (identical(other.totalTax, totalTax) ||
                other.totalTax == totalTax) &&
            (identical(other.netAmount, netAmount) ||
                other.netAmount == netAmount) &&
            (identical(other.finalPayable, finalPayable) ||
                other.finalPayable == finalPayable) &&
            const DeepCollectionEquality().equals(other._payments, _payments) &&
            (identical(other.totalAmountPaid, totalAmountPaid) ||
                other.totalAmountPaid == totalAmountPaid) &&
            (identical(other.balanceDue, balanceDue) ||
                other.balanceDue == balanceDue) &&
            (identical(other.invoiceDate, invoiceDate) ||
                other.invoiceDate == invoiceDate) &&
            (identical(other.generatedBy, generatedBy) ||
                other.generatedBy == generatedBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.ratesSnapshot, ratesSnapshot) ||
                other.ratesSnapshot == ratesSnapshot) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.pdfBase64, pdfBase64) ||
                other.pdfBase64 == pdfBase64));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    invoiceNumber,
    customerId,
    tempCustomerName,
    tempCustomerMobile,
    tempCustomerAddress,
    tempCustomerPincode,
    tempCustomerCity,
    tempCustomerState,
    const DeepCollectionEquality().hash(_items),
    grossAmount,
    couponCode,
    couponDiscount,
    manualDiscount,
    oldGold,
    taxableAmount,
    cgst,
    sgst,
    totalTax,
    netAmount,
    finalPayable,
    const DeepCollectionEquality().hash(_payments),
    totalAmountPaid,
    balanceDue,
    invoiceDate,
    generatedBy,
    status,
    ratesSnapshot,
    deletedAt,
    pdfBase64,
  ]);

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      __$$InvoiceImplCopyWithImpl<_$InvoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceImplToJson(this);
  }
}

abstract class _Invoice implements Invoice {
  const factory _Invoice({
    @JsonKey(name: '_id') final String? id,
    final String? invoiceNumber,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    final String? customerId,
    final String? tempCustomerName,
    final String? tempCustomerMobile,
    final String? tempCustomerAddress,
    final String? tempCustomerPincode,
    final String? tempCustomerCity,
    final String? tempCustomerState,
    required final List<InvoiceItem> items,
    required final double grossAmount,
    final String? couponCode,
    final double couponDiscount,
    final double manualDiscount,
    final OldGoldAdjustment? oldGold,
    required final double taxableAmount,
    required final double cgst,
    required final double sgst,
    required final double totalTax,
    required final double netAmount,
    required final double finalPayable,
    required final List<Payment> payments,
    required final double totalAmountPaid,
    required final double balanceDue,
    required final DateTime invoiceDate,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
    final String? generatedBy,
    final String status,
    required final RatesSnapshot ratesSnapshot,
    final DateTime? deletedAt,
    final String? pdfBase64,
  }) = _$InvoiceImpl;

  factory _Invoice.fromJson(Map<String, dynamic> json) = _$InvoiceImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  String? get invoiceNumber;
  @override
  @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
  String? get customerId;
  @override
  String? get tempCustomerName;
  @override
  String? get tempCustomerMobile;
  @override
  String? get tempCustomerAddress;
  @override
  String? get tempCustomerPincode;
  @override
  String? get tempCustomerCity;
  @override
  String? get tempCustomerState;
  @override
  List<InvoiceItem> get items;
  @override
  double get grossAmount;
  @override
  String? get couponCode;
  @override
  double get couponDiscount;
  @override
  double get manualDiscount;
  @override
  OldGoldAdjustment? get oldGold;
  @override
  double get taxableAmount;
  @override
  double get cgst;
  @override
  double get sgst;
  @override
  double get totalTax;
  @override
  double get netAmount;
  @override
  double get finalPayable;
  @override
  List<Payment> get payments;
  @override
  double get totalAmountPaid;
  @override
  double get balanceDue;
  @override
  DateTime get invoiceDate;
  @override
  @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson)
  String? get generatedBy;
  @override
  String get status; // PAID, PARTIALLY_PAID, CANCELLED
  @override
  RatesSnapshot get ratesSnapshot;
  @override
  DateTime? get deletedAt;
  @override
  String? get pdfBase64;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
