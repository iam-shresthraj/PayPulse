// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CategorySummary _$CategorySummaryFromJson(Map<String, dynamic> json) {
  return _CategorySummary.fromJson(json);
}

/// @nodoc
mixin _$CategorySummary {
  String get category =>
      throw _privateConstructorUsedError; // GOLD, SILVER, etc.
  int get totalProducts => throw _privateConstructorUsedError;
  int get totalStockUnits => throw _privateConstructorUsedError;
  double get totalWeight => throw _privateConstructorUsedError;
  double get metalValueEstimate => throw _privateConstructorUsedError;

  /// Serializes this CategorySummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategorySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategorySummaryCopyWith<CategorySummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategorySummaryCopyWith<$Res> {
  factory $CategorySummaryCopyWith(
    CategorySummary value,
    $Res Function(CategorySummary) then,
  ) = _$CategorySummaryCopyWithImpl<$Res, CategorySummary>;
  @useResult
  $Res call({
    String category,
    int totalProducts,
    int totalStockUnits,
    double totalWeight,
    double metalValueEstimate,
  });
}

/// @nodoc
class _$CategorySummaryCopyWithImpl<$Res, $Val extends CategorySummary>
    implements $CategorySummaryCopyWith<$Res> {
  _$CategorySummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategorySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? totalProducts = null,
    Object? totalStockUnits = null,
    Object? totalWeight = null,
    Object? metalValueEstimate = null,
  }) {
    return _then(
      _value.copyWith(
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            totalProducts: null == totalProducts
                ? _value.totalProducts
                : totalProducts // ignore: cast_nullable_to_non_nullable
                      as int,
            totalStockUnits: null == totalStockUnits
                ? _value.totalStockUnits
                : totalStockUnits // ignore: cast_nullable_to_non_nullable
                      as int,
            totalWeight: null == totalWeight
                ? _value.totalWeight
                : totalWeight // ignore: cast_nullable_to_non_nullable
                      as double,
            metalValueEstimate: null == metalValueEstimate
                ? _value.metalValueEstimate
                : metalValueEstimate // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategorySummaryImplCopyWith<$Res>
    implements $CategorySummaryCopyWith<$Res> {
  factory _$$CategorySummaryImplCopyWith(
    _$CategorySummaryImpl value,
    $Res Function(_$CategorySummaryImpl) then,
  ) = __$$CategorySummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String category,
    int totalProducts,
    int totalStockUnits,
    double totalWeight,
    double metalValueEstimate,
  });
}

/// @nodoc
class __$$CategorySummaryImplCopyWithImpl<$Res>
    extends _$CategorySummaryCopyWithImpl<$Res, _$CategorySummaryImpl>
    implements _$$CategorySummaryImplCopyWith<$Res> {
  __$$CategorySummaryImplCopyWithImpl(
    _$CategorySummaryImpl _value,
    $Res Function(_$CategorySummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategorySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? totalProducts = null,
    Object? totalStockUnits = null,
    Object? totalWeight = null,
    Object? metalValueEstimate = null,
  }) {
    return _then(
      _$CategorySummaryImpl(
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        totalProducts: null == totalProducts
            ? _value.totalProducts
            : totalProducts // ignore: cast_nullable_to_non_nullable
                  as int,
        totalStockUnits: null == totalStockUnits
            ? _value.totalStockUnits
            : totalStockUnits // ignore: cast_nullable_to_non_nullable
                  as int,
        totalWeight: null == totalWeight
            ? _value.totalWeight
            : totalWeight // ignore: cast_nullable_to_non_nullable
                  as double,
        metalValueEstimate: null == metalValueEstimate
            ? _value.metalValueEstimate
            : metalValueEstimate // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategorySummaryImpl implements _CategorySummary {
  const _$CategorySummaryImpl({
    required this.category,
    required this.totalProducts,
    required this.totalStockUnits,
    required this.totalWeight,
    required this.metalValueEstimate,
  });

  factory _$CategorySummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategorySummaryImplFromJson(json);

  @override
  final String category;
  // GOLD, SILVER, etc.
  @override
  final int totalProducts;
  @override
  final int totalStockUnits;
  @override
  final double totalWeight;
  @override
  final double metalValueEstimate;

  @override
  String toString() {
    return 'CategorySummary(category: $category, totalProducts: $totalProducts, totalStockUnits: $totalStockUnits, totalWeight: $totalWeight, metalValueEstimate: $metalValueEstimate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategorySummaryImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.totalProducts, totalProducts) ||
                other.totalProducts == totalProducts) &&
            (identical(other.totalStockUnits, totalStockUnits) ||
                other.totalStockUnits == totalStockUnits) &&
            (identical(other.totalWeight, totalWeight) ||
                other.totalWeight == totalWeight) &&
            (identical(other.metalValueEstimate, metalValueEstimate) ||
                other.metalValueEstimate == metalValueEstimate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    category,
    totalProducts,
    totalStockUnits,
    totalWeight,
    metalValueEstimate,
  );

  /// Create a copy of CategorySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategorySummaryImplCopyWith<_$CategorySummaryImpl> get copyWith =>
      __$$CategorySummaryImplCopyWithImpl<_$CategorySummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CategorySummaryImplToJson(this);
  }
}

abstract class _CategorySummary implements CategorySummary {
  const factory _CategorySummary({
    required final String category,
    required final int totalProducts,
    required final int totalStockUnits,
    required final double totalWeight,
    required final double metalValueEstimate,
  }) = _$CategorySummaryImpl;

  factory _CategorySummary.fromJson(Map<String, dynamic> json) =
      _$CategorySummaryImpl.fromJson;

  @override
  String get category; // GOLD, SILVER, etc.
  @override
  int get totalProducts;
  @override
  int get totalStockUnits;
  @override
  double get totalWeight;
  @override
  double get metalValueEstimate;

  /// Create a copy of CategorySummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategorySummaryImplCopyWith<_$CategorySummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InventorySummary _$InventorySummaryFromJson(Map<String, dynamic> json) {
  return _InventorySummary.fromJson(json);
}

/// @nodoc
mixin _$InventorySummary {
  List<CategorySummary> get categories => throw _privateConstructorUsedError;
  int get totalUniqueItems => throw _privateConstructorUsedError;
  int get totalItemsInStock => throw _privateConstructorUsedError;
  double get totalWeightGold => throw _privateConstructorUsedError;
  double get totalWeightSilver => throw _privateConstructorUsedError;
  double get totalValuationEstimate => throw _privateConstructorUsedError;

  /// Serializes this InventorySummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InventorySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventorySummaryCopyWith<InventorySummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventorySummaryCopyWith<$Res> {
  factory $InventorySummaryCopyWith(
    InventorySummary value,
    $Res Function(InventorySummary) then,
  ) = _$InventorySummaryCopyWithImpl<$Res, InventorySummary>;
  @useResult
  $Res call({
    List<CategorySummary> categories,
    int totalUniqueItems,
    int totalItemsInStock,
    double totalWeightGold,
    double totalWeightSilver,
    double totalValuationEstimate,
  });
}

/// @nodoc
class _$InventorySummaryCopyWithImpl<$Res, $Val extends InventorySummary>
    implements $InventorySummaryCopyWith<$Res> {
  _$InventorySummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventorySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? totalUniqueItems = null,
    Object? totalItemsInStock = null,
    Object? totalWeightGold = null,
    Object? totalWeightSilver = null,
    Object? totalValuationEstimate = null,
  }) {
    return _then(
      _value.copyWith(
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<CategorySummary>,
            totalUniqueItems: null == totalUniqueItems
                ? _value.totalUniqueItems
                : totalUniqueItems // ignore: cast_nullable_to_non_nullable
                      as int,
            totalItemsInStock: null == totalItemsInStock
                ? _value.totalItemsInStock
                : totalItemsInStock // ignore: cast_nullable_to_non_nullable
                      as int,
            totalWeightGold: null == totalWeightGold
                ? _value.totalWeightGold
                : totalWeightGold // ignore: cast_nullable_to_non_nullable
                      as double,
            totalWeightSilver: null == totalWeightSilver
                ? _value.totalWeightSilver
                : totalWeightSilver // ignore: cast_nullable_to_non_nullable
                      as double,
            totalValuationEstimate: null == totalValuationEstimate
                ? _value.totalValuationEstimate
                : totalValuationEstimate // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InventorySummaryImplCopyWith<$Res>
    implements $InventorySummaryCopyWith<$Res> {
  factory _$$InventorySummaryImplCopyWith(
    _$InventorySummaryImpl value,
    $Res Function(_$InventorySummaryImpl) then,
  ) = __$$InventorySummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<CategorySummary> categories,
    int totalUniqueItems,
    int totalItemsInStock,
    double totalWeightGold,
    double totalWeightSilver,
    double totalValuationEstimate,
  });
}

/// @nodoc
class __$$InventorySummaryImplCopyWithImpl<$Res>
    extends _$InventorySummaryCopyWithImpl<$Res, _$InventorySummaryImpl>
    implements _$$InventorySummaryImplCopyWith<$Res> {
  __$$InventorySummaryImplCopyWithImpl(
    _$InventorySummaryImpl _value,
    $Res Function(_$InventorySummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InventorySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? totalUniqueItems = null,
    Object? totalItemsInStock = null,
    Object? totalWeightGold = null,
    Object? totalWeightSilver = null,
    Object? totalValuationEstimate = null,
  }) {
    return _then(
      _$InventorySummaryImpl(
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<CategorySummary>,
        totalUniqueItems: null == totalUniqueItems
            ? _value.totalUniqueItems
            : totalUniqueItems // ignore: cast_nullable_to_non_nullable
                  as int,
        totalItemsInStock: null == totalItemsInStock
            ? _value.totalItemsInStock
            : totalItemsInStock // ignore: cast_nullable_to_non_nullable
                  as int,
        totalWeightGold: null == totalWeightGold
            ? _value.totalWeightGold
            : totalWeightGold // ignore: cast_nullable_to_non_nullable
                  as double,
        totalWeightSilver: null == totalWeightSilver
            ? _value.totalWeightSilver
            : totalWeightSilver // ignore: cast_nullable_to_non_nullable
                  as double,
        totalValuationEstimate: null == totalValuationEstimate
            ? _value.totalValuationEstimate
            : totalValuationEstimate // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InventorySummaryImpl implements _InventorySummary {
  const _$InventorySummaryImpl({
    required final List<CategorySummary> categories,
    required this.totalUniqueItems,
    required this.totalItemsInStock,
    required this.totalWeightGold,
    required this.totalWeightSilver,
    required this.totalValuationEstimate,
  }) : _categories = categories;

  factory _$InventorySummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$InventorySummaryImplFromJson(json);

  final List<CategorySummary> _categories;
  @override
  List<CategorySummary> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  final int totalUniqueItems;
  @override
  final int totalItemsInStock;
  @override
  final double totalWeightGold;
  @override
  final double totalWeightSilver;
  @override
  final double totalValuationEstimate;

  @override
  String toString() {
    return 'InventorySummary(categories: $categories, totalUniqueItems: $totalUniqueItems, totalItemsInStock: $totalItemsInStock, totalWeightGold: $totalWeightGold, totalWeightSilver: $totalWeightSilver, totalValuationEstimate: $totalValuationEstimate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventorySummaryImpl &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            (identical(other.totalUniqueItems, totalUniqueItems) ||
                other.totalUniqueItems == totalUniqueItems) &&
            (identical(other.totalItemsInStock, totalItemsInStock) ||
                other.totalItemsInStock == totalItemsInStock) &&
            (identical(other.totalWeightGold, totalWeightGold) ||
                other.totalWeightGold == totalWeightGold) &&
            (identical(other.totalWeightSilver, totalWeightSilver) ||
                other.totalWeightSilver == totalWeightSilver) &&
            (identical(other.totalValuationEstimate, totalValuationEstimate) ||
                other.totalValuationEstimate == totalValuationEstimate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_categories),
    totalUniqueItems,
    totalItemsInStock,
    totalWeightGold,
    totalWeightSilver,
    totalValuationEstimate,
  );

  /// Create a copy of InventorySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventorySummaryImplCopyWith<_$InventorySummaryImpl> get copyWith =>
      __$$InventorySummaryImplCopyWithImpl<_$InventorySummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InventorySummaryImplToJson(this);
  }
}

abstract class _InventorySummary implements InventorySummary {
  const factory _InventorySummary({
    required final List<CategorySummary> categories,
    required final int totalUniqueItems,
    required final int totalItemsInStock,
    required final double totalWeightGold,
    required final double totalWeightSilver,
    required final double totalValuationEstimate,
  }) = _$InventorySummaryImpl;

  factory _InventorySummary.fromJson(Map<String, dynamic> json) =
      _$InventorySummaryImpl.fromJson;

  @override
  List<CategorySummary> get categories;
  @override
  int get totalUniqueItems;
  @override
  int get totalItemsInStock;
  @override
  double get totalWeightGold;
  @override
  double get totalWeightSilver;
  @override
  double get totalValuationEstimate;

  /// Create a copy of InventorySummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventorySummaryImplCopyWith<_$InventorySummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
