// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category =>
      throw _privateConstructorUsedError; // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
  String get purity =>
      throw _privateConstructorUsedError; // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
  String? get serialNumber => throw _privateConstructorUsedError;
  String? get huidNumber => throw _privateConstructorUsedError;
  String get hsnCode => throw _privateConstructorUsedError;
  int get stockUnits => throw _privateConstructorUsedError;
  double get weight => throw _privateConstructorUsedError;
  double get makingChargeValue => throw _privateConstructorUsedError;
  String? get stoneType => throw _privateConstructorUsedError;
  double get stoneWeight => throw _privateConstructorUsedError;
  double get stoneValue => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String name,
    String category,
    String purity,
    String? serialNumber,
    String? huidNumber,
    String hsnCode,
    int stockUnits,
    double weight,
    double makingChargeValue,
    String? stoneType,
    double stoneWeight,
    double stoneValue,
    String? imageUrl,
    bool isActive,
  });
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? category = null,
    Object? purity = null,
    Object? serialNumber = freezed,
    Object? huidNumber = freezed,
    Object? hsnCode = null,
    Object? stockUnits = null,
    Object? weight = null,
    Object? makingChargeValue = null,
    Object? stoneType = freezed,
    Object? stoneWeight = null,
    Object? stoneValue = null,
    Object? imageUrl = freezed,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            purity: null == purity
                ? _value.purity
                : purity // ignore: cast_nullable_to_non_nullable
                      as String,
            serialNumber: freezed == serialNumber
                ? _value.serialNumber
                : serialNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            huidNumber: freezed == huidNumber
                ? _value.huidNumber
                : huidNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            hsnCode: null == hsnCode
                ? _value.hsnCode
                : hsnCode // ignore: cast_nullable_to_non_nullable
                      as String,
            stockUnits: null == stockUnits
                ? _value.stockUnits
                : stockUnits // ignore: cast_nullable_to_non_nullable
                      as int,
            weight: null == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double,
            makingChargeValue: null == makingChargeValue
                ? _value.makingChargeValue
                : makingChargeValue // ignore: cast_nullable_to_non_nullable
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
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
    _$ProductImpl value,
    $Res Function(_$ProductImpl) then,
  ) = __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String name,
    String category,
    String purity,
    String? serialNumber,
    String? huidNumber,
    String hsnCode,
    int stockUnits,
    double weight,
    double makingChargeValue,
    String? stoneType,
    double stoneWeight,
    double stoneValue,
    String? imageUrl,
    bool isActive,
  });
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
    _$ProductImpl _value,
    $Res Function(_$ProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? category = null,
    Object? purity = null,
    Object? serialNumber = freezed,
    Object? huidNumber = freezed,
    Object? hsnCode = null,
    Object? stockUnits = null,
    Object? weight = null,
    Object? makingChargeValue = null,
    Object? stoneType = freezed,
    Object? stoneWeight = null,
    Object? stoneValue = null,
    Object? imageUrl = freezed,
    Object? isActive = null,
  }) {
    return _then(
      _$ProductImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        purity: null == purity
            ? _value.purity
            : purity // ignore: cast_nullable_to_non_nullable
                  as String,
        serialNumber: freezed == serialNumber
            ? _value.serialNumber
            : serialNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        huidNumber: freezed == huidNumber
            ? _value.huidNumber
            : huidNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        hsnCode: null == hsnCode
            ? _value.hsnCode
            : hsnCode // ignore: cast_nullable_to_non_nullable
                  as String,
        stockUnits: null == stockUnits
            ? _value.stockUnits
            : stockUnits // ignore: cast_nullable_to_non_nullable
                  as int,
        weight: null == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double,
        makingChargeValue: null == makingChargeValue
            ? _value.makingChargeValue
            : makingChargeValue // ignore: cast_nullable_to_non_nullable
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
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl implements _Product {
  const _$ProductImpl({
    @JsonKey(name: '_id') this.id,
    required this.name,
    required this.category,
    required this.purity,
    this.serialNumber,
    this.huidNumber,
    this.hsnCode = '7113',
    this.stockUnits = 1,
    this.weight = 0.0,
    this.makingChargeValue = 0.0,
    this.stoneType,
    this.stoneWeight = 0.0,
    this.stoneValue = 0.0,
    this.imageUrl,
    this.isActive = true,
  });

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final String name;
  @override
  final String category;
  // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
  @override
  final String purity;
  // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
  @override
  final String? serialNumber;
  @override
  final String? huidNumber;
  @override
  @JsonKey()
  final String hsnCode;
  @override
  @JsonKey()
  final int stockUnits;
  @override
  @JsonKey()
  final double weight;
  @override
  @JsonKey()
  final double makingChargeValue;
  @override
  final String? stoneType;
  @override
  @JsonKey()
  final double stoneWeight;
  @override
  @JsonKey()
  final double stoneValue;
  @override
  final String? imageUrl;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, purity: $purity, serialNumber: $serialNumber, huidNumber: $huidNumber, hsnCode: $hsnCode, stockUnits: $stockUnits, weight: $weight, makingChargeValue: $makingChargeValue, stoneType: $stoneType, stoneWeight: $stoneWeight, stoneValue: $stoneValue, imageUrl: $imageUrl, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.purity, purity) || other.purity == purity) &&
            (identical(other.serialNumber, serialNumber) ||
                other.serialNumber == serialNumber) &&
            (identical(other.huidNumber, huidNumber) ||
                other.huidNumber == huidNumber) &&
            (identical(other.hsnCode, hsnCode) || other.hsnCode == hsnCode) &&
            (identical(other.stockUnits, stockUnits) ||
                other.stockUnits == stockUnits) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.makingChargeValue, makingChargeValue) ||
                other.makingChargeValue == makingChargeValue) &&
            (identical(other.stoneType, stoneType) ||
                other.stoneType == stoneType) &&
            (identical(other.stoneWeight, stoneWeight) ||
                other.stoneWeight == stoneWeight) &&
            (identical(other.stoneValue, stoneValue) ||
                other.stoneValue == stoneValue) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    category,
    purity,
    serialNumber,
    huidNumber,
    hsnCode,
    stockUnits,
    weight,
    makingChargeValue,
    stoneType,
    stoneWeight,
    stoneValue,
    imageUrl,
    isActive,
  );

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(this);
  }
}

abstract class _Product implements Product {
  const factory _Product({
    @JsonKey(name: '_id') final String? id,
    required final String name,
    required final String category,
    required final String purity,
    final String? serialNumber,
    final String? huidNumber,
    final String hsnCode,
    final int stockUnits,
    final double weight,
    final double makingChargeValue,
    final String? stoneType,
    final double stoneWeight,
    final double stoneValue,
    final String? imageUrl,
    final bool isActive,
  }) = _$ProductImpl;

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  String get name;
  @override
  String get category; // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
  @override
  String get purity; // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
  @override
  String? get serialNumber;
  @override
  String? get huidNumber;
  @override
  String get hsnCode;
  @override
  int get stockUnits;
  @override
  double get weight;
  @override
  double get makingChargeValue;
  @override
  String? get stoneType;
  @override
  double get stoneWeight;
  @override
  double get stoneValue;
  @override
  String? get imageUrl;
  @override
  bool get isActive;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
