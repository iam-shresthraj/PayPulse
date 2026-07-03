// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Customer _$CustomerFromJson(Map<String, dynamic> json) {
  return _Customer.fromJson(json);
}

/// @nodoc
mixin _$Customer {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  String get mobile => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get pincode => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  String? get panCard => throw _privateConstructorUsedError;
  String? get gstNumber => throw _privateConstructorUsedError;
  String? get additionalNote => throw _privateConstructorUsedError;
  double get totalPurchaseAmount => throw _privateConstructorUsedError;
  int get totalInvoices => throw _privateConstructorUsedError;
  DateTime? get lastVisitDate => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Customer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Customer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerCopyWith<Customer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerCopyWith<$Res> {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) then) =
      _$CustomerCopyWithImpl<$Res, Customer>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String mobile,
    String name,
    String? email,
    String? address,
    String? pincode,
    String? city,
    String? state,
    String? panCard,
    String? gstNumber,
    String? additionalNote,
    double totalPurchaseAmount,
    int totalInvoices,
    DateTime? lastVisitDate,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$CustomerCopyWithImpl<$Res, $Val extends Customer>
    implements $CustomerCopyWith<$Res> {
  _$CustomerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Customer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? mobile = null,
    Object? name = null,
    Object? email = freezed,
    Object? address = freezed,
    Object? pincode = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? panCard = freezed,
    Object? gstNumber = freezed,
    Object? additionalNote = freezed,
    Object? totalPurchaseAmount = null,
    Object? totalInvoices = null,
    Object? lastVisitDate = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            mobile: null == mobile
                ? _value.mobile
                : mobile // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            pincode: freezed == pincode
                ? _value.pincode
                : pincode // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
            state: freezed == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String?,
            panCard: freezed == panCard
                ? _value.panCard
                : panCard // ignore: cast_nullable_to_non_nullable
                      as String?,
            gstNumber: freezed == gstNumber
                ? _value.gstNumber
                : gstNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            additionalNote: freezed == additionalNote
                ? _value.additionalNote
                : additionalNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalPurchaseAmount: null == totalPurchaseAmount
                ? _value.totalPurchaseAmount
                : totalPurchaseAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            totalInvoices: null == totalInvoices
                ? _value.totalInvoices
                : totalInvoices // ignore: cast_nullable_to_non_nullable
                      as int,
            lastVisitDate: freezed == lastVisitDate
                ? _value.lastVisitDate
                : lastVisitDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerImplCopyWith<$Res>
    implements $CustomerCopyWith<$Res> {
  factory _$$CustomerImplCopyWith(
    _$CustomerImpl value,
    $Res Function(_$CustomerImpl) then,
  ) = __$$CustomerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String mobile,
    String name,
    String? email,
    String? address,
    String? pincode,
    String? city,
    String? state,
    String? panCard,
    String? gstNumber,
    String? additionalNote,
    double totalPurchaseAmount,
    int totalInvoices,
    DateTime? lastVisitDate,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$CustomerImplCopyWithImpl<$Res>
    extends _$CustomerCopyWithImpl<$Res, _$CustomerImpl>
    implements _$$CustomerImplCopyWith<$Res> {
  __$$CustomerImplCopyWithImpl(
    _$CustomerImpl _value,
    $Res Function(_$CustomerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Customer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? mobile = null,
    Object? name = null,
    Object? email = freezed,
    Object? address = freezed,
    Object? pincode = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? panCard = freezed,
    Object? gstNumber = freezed,
    Object? additionalNote = freezed,
    Object? totalPurchaseAmount = null,
    Object? totalInvoices = null,
    Object? lastVisitDate = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CustomerImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        mobile: null == mobile
            ? _value.mobile
            : mobile // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        pincode: freezed == pincode
            ? _value.pincode
            : pincode // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
        state: freezed == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String?,
        panCard: freezed == panCard
            ? _value.panCard
            : panCard // ignore: cast_nullable_to_non_nullable
                  as String?,
        gstNumber: freezed == gstNumber
            ? _value.gstNumber
            : gstNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        additionalNote: freezed == additionalNote
            ? _value.additionalNote
            : additionalNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalPurchaseAmount: null == totalPurchaseAmount
            ? _value.totalPurchaseAmount
            : totalPurchaseAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        totalInvoices: null == totalInvoices
            ? _value.totalInvoices
            : totalInvoices // ignore: cast_nullable_to_non_nullable
                  as int,
        lastVisitDate: freezed == lastVisitDate
            ? _value.lastVisitDate
            : lastVisitDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerImpl implements _Customer {
  const _$CustomerImpl({
    @JsonKey(name: '_id') this.id,
    required this.mobile,
    required this.name,
    this.email,
    this.address,
    this.pincode,
    this.city,
    this.state,
    this.panCard,
    this.gstNumber,
    this.additionalNote,
    this.totalPurchaseAmount = 0.0,
    this.totalInvoices = 0,
    this.lastVisitDate,
    this.createdAt,
  });

  factory _$CustomerImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final String mobile;
  @override
  final String name;
  @override
  final String? email;
  @override
  final String? address;
  @override
  final String? pincode;
  @override
  final String? city;
  @override
  final String? state;
  @override
  final String? panCard;
  @override
  final String? gstNumber;
  @override
  final String? additionalNote;
  @override
  @JsonKey()
  final double totalPurchaseAmount;
  @override
  @JsonKey()
  final int totalInvoices;
  @override
  final DateTime? lastVisitDate;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Customer(id: $id, mobile: $mobile, name: $name, email: $email, address: $address, pincode: $pincode, city: $city, state: $state, panCard: $panCard, gstNumber: $gstNumber, additionalNote: $additionalNote, totalPurchaseAmount: $totalPurchaseAmount, totalInvoices: $totalInvoices, lastVisitDate: $lastVisitDate, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.pincode, pincode) || other.pincode == pincode) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.panCard, panCard) || other.panCard == panCard) &&
            (identical(other.gstNumber, gstNumber) ||
                other.gstNumber == gstNumber) &&
            (identical(other.additionalNote, additionalNote) ||
                other.additionalNote == additionalNote) &&
            (identical(other.totalPurchaseAmount, totalPurchaseAmount) ||
                other.totalPurchaseAmount == totalPurchaseAmount) &&
            (identical(other.totalInvoices, totalInvoices) ||
                other.totalInvoices == totalInvoices) &&
            (identical(other.lastVisitDate, lastVisitDate) ||
                other.lastVisitDate == lastVisitDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    mobile,
    name,
    email,
    address,
    pincode,
    city,
    state,
    panCard,
    gstNumber,
    additionalNote,
    totalPurchaseAmount,
    totalInvoices,
    lastVisitDate,
    createdAt,
  );

  /// Create a copy of Customer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerImplCopyWith<_$CustomerImpl> get copyWith =>
      __$$CustomerImplCopyWithImpl<_$CustomerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerImplToJson(this);
  }
}

abstract class _Customer implements Customer {
  const factory _Customer({
    @JsonKey(name: '_id') final String? id,
    required final String mobile,
    required final String name,
    final String? email,
    final String? address,
    final String? pincode,
    final String? city,
    final String? state,
    final String? panCard,
    final String? gstNumber,
    final String? additionalNote,
    final double totalPurchaseAmount,
    final int totalInvoices,
    final DateTime? lastVisitDate,
    final DateTime? createdAt,
  }) = _$CustomerImpl;

  factory _Customer.fromJson(Map<String, dynamic> json) =
      _$CustomerImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  String get mobile;
  @override
  String get name;
  @override
  String? get email;
  @override
  String? get address;
  @override
  String? get pincode;
  @override
  String? get city;
  @override
  String? get state;
  @override
  String? get panCard;
  @override
  String? get gstNumber;
  @override
  String? get additionalNote;
  @override
  double get totalPurchaseAmount;
  @override
  int get totalInvoices;
  @override
  DateTime? get lastVisitDate;
  @override
  DateTime? get createdAt;

  /// Create a copy of Customer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerImplCopyWith<_$CustomerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
