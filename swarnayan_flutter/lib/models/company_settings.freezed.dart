// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CompanyAddress _$CompanyAddressFromJson(Map<String, dynamic> json) {
  return _CompanyAddress.fromJson(json);
}

/// @nodoc
mixin _$CompanyAddress {
  String get line1 => throw _privateConstructorUsedError;
  String get line2 => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  String get postalCode => throw _privateConstructorUsedError;

  /// Serializes this CompanyAddress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanyAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyAddressCopyWith<CompanyAddress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyAddressCopyWith<$Res> {
  factory $CompanyAddressCopyWith(
    CompanyAddress value,
    $Res Function(CompanyAddress) then,
  ) = _$CompanyAddressCopyWithImpl<$Res, CompanyAddress>;
  @useResult
  $Res call({
    String line1,
    String line2,
    String city,
    String state,
    String postalCode,
  });
}

/// @nodoc
class _$CompanyAddressCopyWithImpl<$Res, $Val extends CompanyAddress>
    implements $CompanyAddressCopyWith<$Res> {
  _$CompanyAddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanyAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? line1 = null,
    Object? line2 = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
  }) {
    return _then(
      _value.copyWith(
            line1: null == line1
                ? _value.line1
                : line1 // ignore: cast_nullable_to_non_nullable
                      as String,
            line2: null == line2
                ? _value.line2
                : line2 // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            postalCode: null == postalCode
                ? _value.postalCode
                : postalCode // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompanyAddressImplCopyWith<$Res>
    implements $CompanyAddressCopyWith<$Res> {
  factory _$$CompanyAddressImplCopyWith(
    _$CompanyAddressImpl value,
    $Res Function(_$CompanyAddressImpl) then,
  ) = __$$CompanyAddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String line1,
    String line2,
    String city,
    String state,
    String postalCode,
  });
}

/// @nodoc
class __$$CompanyAddressImplCopyWithImpl<$Res>
    extends _$CompanyAddressCopyWithImpl<$Res, _$CompanyAddressImpl>
    implements _$$CompanyAddressImplCopyWith<$Res> {
  __$$CompanyAddressImplCopyWithImpl(
    _$CompanyAddressImpl _value,
    $Res Function(_$CompanyAddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanyAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? line1 = null,
    Object? line2 = null,
    Object? city = null,
    Object? state = null,
    Object? postalCode = null,
  }) {
    return _then(
      _$CompanyAddressImpl(
        line1: null == line1
            ? _value.line1
            : line1 // ignore: cast_nullable_to_non_nullable
                  as String,
        line2: null == line2
            ? _value.line2
            : line2 // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        postalCode: null == postalCode
            ? _value.postalCode
            : postalCode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompanyAddressImpl implements _CompanyAddress {
  const _$CompanyAddressImpl({
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory _$CompanyAddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanyAddressImplFromJson(json);

  @override
  final String line1;
  @override
  @JsonKey()
  final String line2;
  @override
  final String city;
  @override
  final String state;
  @override
  final String postalCode;

  @override
  String toString() {
    return 'CompanyAddress(line1: $line1, line2: $line2, city: $city, state: $state, postalCode: $postalCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyAddressImpl &&
            (identical(other.line1, line1) || other.line1 == line1) &&
            (identical(other.line2, line2) || other.line2 == line2) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, line1, line2, city, state, postalCode);

  /// Create a copy of CompanyAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyAddressImplCopyWith<_$CompanyAddressImpl> get copyWith =>
      __$$CompanyAddressImplCopyWithImpl<_$CompanyAddressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanyAddressImplToJson(this);
  }
}

abstract class _CompanyAddress implements CompanyAddress {
  const factory _CompanyAddress({
    required final String line1,
    final String line2,
    required final String city,
    required final String state,
    required final String postalCode,
  }) = _$CompanyAddressImpl;

  factory _CompanyAddress.fromJson(Map<String, dynamic> json) =
      _$CompanyAddressImpl.fromJson;

  @override
  String get line1;
  @override
  String get line2;
  @override
  String get city;
  @override
  String get state;
  @override
  String get postalCode;

  /// Create a copy of CompanyAddress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyAddressImplCopyWith<_$CompanyAddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InvoiceConfig _$InvoiceConfigFromJson(Map<String, dynamic> json) {
  return _InvoiceConfig.fromJson(json);
}

/// @nodoc
mixin _$InvoiceConfig {
  String get prefix => throw _privateConstructorUsedError;
  String get suffix => throw _privateConstructorUsedError;
  String get separator => throw _privateConstructorUsedError;
  int get paddingLength => throw _privateConstructorUsedError;
  int get currentCounter => throw _privateConstructorUsedError;
  String get financialYear => throw _privateConstructorUsedError;

  /// Serializes this InvoiceConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InvoiceConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceConfigCopyWith<InvoiceConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceConfigCopyWith<$Res> {
  factory $InvoiceConfigCopyWith(
    InvoiceConfig value,
    $Res Function(InvoiceConfig) then,
  ) = _$InvoiceConfigCopyWithImpl<$Res, InvoiceConfig>;
  @useResult
  $Res call({
    String prefix,
    String suffix,
    String separator,
    int paddingLength,
    int currentCounter,
    String financialYear,
  });
}

/// @nodoc
class _$InvoiceConfigCopyWithImpl<$Res, $Val extends InvoiceConfig>
    implements $InvoiceConfigCopyWith<$Res> {
  _$InvoiceConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvoiceConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prefix = null,
    Object? suffix = null,
    Object? separator = null,
    Object? paddingLength = null,
    Object? currentCounter = null,
    Object? financialYear = null,
  }) {
    return _then(
      _value.copyWith(
            prefix: null == prefix
                ? _value.prefix
                : prefix // ignore: cast_nullable_to_non_nullable
                      as String,
            suffix: null == suffix
                ? _value.suffix
                : suffix // ignore: cast_nullable_to_non_nullable
                      as String,
            separator: null == separator
                ? _value.separator
                : separator // ignore: cast_nullable_to_non_nullable
                      as String,
            paddingLength: null == paddingLength
                ? _value.paddingLength
                : paddingLength // ignore: cast_nullable_to_non_nullable
                      as int,
            currentCounter: null == currentCounter
                ? _value.currentCounter
                : currentCounter // ignore: cast_nullable_to_non_nullable
                      as int,
            financialYear: null == financialYear
                ? _value.financialYear
                : financialYear // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InvoiceConfigImplCopyWith<$Res>
    implements $InvoiceConfigCopyWith<$Res> {
  factory _$$InvoiceConfigImplCopyWith(
    _$InvoiceConfigImpl value,
    $Res Function(_$InvoiceConfigImpl) then,
  ) = __$$InvoiceConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String prefix,
    String suffix,
    String separator,
    int paddingLength,
    int currentCounter,
    String financialYear,
  });
}

/// @nodoc
class __$$InvoiceConfigImplCopyWithImpl<$Res>
    extends _$InvoiceConfigCopyWithImpl<$Res, _$InvoiceConfigImpl>
    implements _$$InvoiceConfigImplCopyWith<$Res> {
  __$$InvoiceConfigImplCopyWithImpl(
    _$InvoiceConfigImpl _value,
    $Res Function(_$InvoiceConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prefix = null,
    Object? suffix = null,
    Object? separator = null,
    Object? paddingLength = null,
    Object? currentCounter = null,
    Object? financialYear = null,
  }) {
    return _then(
      _$InvoiceConfigImpl(
        prefix: null == prefix
            ? _value.prefix
            : prefix // ignore: cast_nullable_to_non_nullable
                  as String,
        suffix: null == suffix
            ? _value.suffix
            : suffix // ignore: cast_nullable_to_non_nullable
                  as String,
        separator: null == separator
            ? _value.separator
            : separator // ignore: cast_nullable_to_non_nullable
                  as String,
        paddingLength: null == paddingLength
            ? _value.paddingLength
            : paddingLength // ignore: cast_nullable_to_non_nullable
                  as int,
        currentCounter: null == currentCounter
            ? _value.currentCounter
            : currentCounter // ignore: cast_nullable_to_non_nullable
                  as int,
        financialYear: null == financialYear
            ? _value.financialYear
            : financialYear // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceConfigImpl implements _InvoiceConfig {
  const _$InvoiceConfigImpl({
    this.prefix = 'SW',
    this.suffix = '',
    this.separator = '/',
    this.paddingLength = 5,
    this.currentCounter = 0,
    this.financialYear = '',
  });

  factory _$InvoiceConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceConfigImplFromJson(json);

  @override
  @JsonKey()
  final String prefix;
  @override
  @JsonKey()
  final String suffix;
  @override
  @JsonKey()
  final String separator;
  @override
  @JsonKey()
  final int paddingLength;
  @override
  @JsonKey()
  final int currentCounter;
  @override
  @JsonKey()
  final String financialYear;

  @override
  String toString() {
    return 'InvoiceConfig(prefix: $prefix, suffix: $suffix, separator: $separator, paddingLength: $paddingLength, currentCounter: $currentCounter, financialYear: $financialYear)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceConfigImpl &&
            (identical(other.prefix, prefix) || other.prefix == prefix) &&
            (identical(other.suffix, suffix) || other.suffix == suffix) &&
            (identical(other.separator, separator) ||
                other.separator == separator) &&
            (identical(other.paddingLength, paddingLength) ||
                other.paddingLength == paddingLength) &&
            (identical(other.currentCounter, currentCounter) ||
                other.currentCounter == currentCounter) &&
            (identical(other.financialYear, financialYear) ||
                other.financialYear == financialYear));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    prefix,
    suffix,
    separator,
    paddingLength,
    currentCounter,
    financialYear,
  );

  /// Create a copy of InvoiceConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceConfigImplCopyWith<_$InvoiceConfigImpl> get copyWith =>
      __$$InvoiceConfigImplCopyWithImpl<_$InvoiceConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceConfigImplToJson(this);
  }
}

abstract class _InvoiceConfig implements InvoiceConfig {
  const factory _InvoiceConfig({
    final String prefix,
    final String suffix,
    final String separator,
    final int paddingLength,
    final int currentCounter,
    final String financialYear,
  }) = _$InvoiceConfigImpl;

  factory _InvoiceConfig.fromJson(Map<String, dynamic> json) =
      _$InvoiceConfigImpl.fromJson;

  @override
  String get prefix;
  @override
  String get suffix;
  @override
  String get separator;
  @override
  int get paddingLength;
  @override
  int get currentCounter;
  @override
  String get financialYear;

  /// Create a copy of InvoiceConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceConfigImplCopyWith<_$InvoiceConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompanySettings _$CompanySettingsFromJson(Map<String, dynamic> json) {
  return _CompanySettings.fromJson(json);
}

/// @nodoc
mixin _$CompanySettings {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  String get companyName => throw _privateConstructorUsedError;
  CompanyAddress get address => throw _privateConstructorUsedError;
  String get gstin => throw _privateConstructorUsedError;
  String get mobile => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  InvoiceConfig get invoiceConfig => throw _privateConstructorUsedError;
  List<String> get termsAndConditions => throw _privateConstructorUsedError;
  String get tagline => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  String get stateWithCode => throw _privateConstructorUsedError;
  String get logoUrl => throw _privateConstructorUsedError;

  /// Serializes this CompanySettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanySettingsCopyWith<CompanySettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanySettingsCopyWith<$Res> {
  factory $CompanySettingsCopyWith(
    CompanySettings value,
    $Res Function(CompanySettings) then,
  ) = _$CompanySettingsCopyWithImpl<$Res, CompanySettings>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String companyName,
    CompanyAddress address,
    String gstin,
    String mobile,
    String email,
    InvoiceConfig invoiceConfig,
    List<String> termsAndConditions,
    String tagline,
    String notes,
    String stateWithCode,
    String logoUrl,
  });

  $CompanyAddressCopyWith<$Res> get address;
  $InvoiceConfigCopyWith<$Res> get invoiceConfig;
}

/// @nodoc
class _$CompanySettingsCopyWithImpl<$Res, $Val extends CompanySettings>
    implements $CompanySettingsCopyWith<$Res> {
  _$CompanySettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? companyName = null,
    Object? address = null,
    Object? gstin = null,
    Object? mobile = null,
    Object? email = null,
    Object? invoiceConfig = null,
    Object? termsAndConditions = null,
    Object? tagline = null,
    Object? notes = null,
    Object? stateWithCode = null,
    Object? logoUrl = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            companyName: null == companyName
                ? _value.companyName
                : companyName // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as CompanyAddress,
            gstin: null == gstin
                ? _value.gstin
                : gstin // ignore: cast_nullable_to_non_nullable
                      as String,
            mobile: null == mobile
                ? _value.mobile
                : mobile // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            invoiceConfig: null == invoiceConfig
                ? _value.invoiceConfig
                : invoiceConfig // ignore: cast_nullable_to_non_nullable
                      as InvoiceConfig,
            termsAndConditions: null == termsAndConditions
                ? _value.termsAndConditions
                : termsAndConditions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tagline: null == tagline
                ? _value.tagline
                : tagline // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String,
            stateWithCode: null == stateWithCode
                ? _value.stateWithCode
                : stateWithCode // ignore: cast_nullable_to_non_nullable
                      as String,
            logoUrl: null == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }

  /// Create a copy of CompanySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompanyAddressCopyWith<$Res> get address {
    return $CompanyAddressCopyWith<$Res>(_value.address, (value) {
      return _then(_value.copyWith(address: value) as $Val);
    });
  }

  /// Create a copy of CompanySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InvoiceConfigCopyWith<$Res> get invoiceConfig {
    return $InvoiceConfigCopyWith<$Res>(_value.invoiceConfig, (value) {
      return _then(_value.copyWith(invoiceConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CompanySettingsImplCopyWith<$Res>
    implements $CompanySettingsCopyWith<$Res> {
  factory _$$CompanySettingsImplCopyWith(
    _$CompanySettingsImpl value,
    $Res Function(_$CompanySettingsImpl) then,
  ) = __$$CompanySettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String companyName,
    CompanyAddress address,
    String gstin,
    String mobile,
    String email,
    InvoiceConfig invoiceConfig,
    List<String> termsAndConditions,
    String tagline,
    String notes,
    String stateWithCode,
    String logoUrl,
  });

  @override
  $CompanyAddressCopyWith<$Res> get address;
  @override
  $InvoiceConfigCopyWith<$Res> get invoiceConfig;
}

/// @nodoc
class __$$CompanySettingsImplCopyWithImpl<$Res>
    extends _$CompanySettingsCopyWithImpl<$Res, _$CompanySettingsImpl>
    implements _$$CompanySettingsImplCopyWith<$Res> {
  __$$CompanySettingsImplCopyWithImpl(
    _$CompanySettingsImpl _value,
    $Res Function(_$CompanySettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? companyName = null,
    Object? address = null,
    Object? gstin = null,
    Object? mobile = null,
    Object? email = null,
    Object? invoiceConfig = null,
    Object? termsAndConditions = null,
    Object? tagline = null,
    Object? notes = null,
    Object? stateWithCode = null,
    Object? logoUrl = null,
  }) {
    return _then(
      _$CompanySettingsImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        companyName: null == companyName
            ? _value.companyName
            : companyName // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as CompanyAddress,
        gstin: null == gstin
            ? _value.gstin
            : gstin // ignore: cast_nullable_to_non_nullable
                  as String,
        mobile: null == mobile
            ? _value.mobile
            : mobile // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        invoiceConfig: null == invoiceConfig
            ? _value.invoiceConfig
            : invoiceConfig // ignore: cast_nullable_to_non_nullable
                  as InvoiceConfig,
        termsAndConditions: null == termsAndConditions
            ? _value._termsAndConditions
            : termsAndConditions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tagline: null == tagline
            ? _value.tagline
            : tagline // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
        stateWithCode: null == stateWithCode
            ? _value.stateWithCode
            : stateWithCode // ignore: cast_nullable_to_non_nullable
                  as String,
        logoUrl: null == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompanySettingsImpl implements _CompanySettings {
  const _$CompanySettingsImpl({
    @JsonKey(name: '_id') this.id,
    required this.companyName,
    required this.address,
    required this.gstin,
    required this.mobile,
    required this.email,
    required this.invoiceConfig,
    final List<String> termsAndConditions = const [],
    this.tagline = '',
    this.notes = '',
    this.stateWithCode = '',
    this.logoUrl = '',
  }) : _termsAndConditions = termsAndConditions;

  factory _$CompanySettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanySettingsImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final String companyName;
  @override
  final CompanyAddress address;
  @override
  final String gstin;
  @override
  final String mobile;
  @override
  final String email;
  @override
  final InvoiceConfig invoiceConfig;
  final List<String> _termsAndConditions;
  @override
  @JsonKey()
  List<String> get termsAndConditions {
    if (_termsAndConditions is EqualUnmodifiableListView)
      return _termsAndConditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_termsAndConditions);
  }

  @override
  @JsonKey()
  final String tagline;
  @override
  @JsonKey()
  final String notes;
  @override
  @JsonKey()
  final String stateWithCode;
  @override
  @JsonKey()
  final String logoUrl;

  @override
  String toString() {
    return 'CompanySettings(id: $id, companyName: $companyName, address: $address, gstin: $gstin, mobile: $mobile, email: $email, invoiceConfig: $invoiceConfig, termsAndConditions: $termsAndConditions, tagline: $tagline, notes: $notes, stateWithCode: $stateWithCode, logoUrl: $logoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanySettingsImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.companyName, companyName) ||
                other.companyName == companyName) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.gstin, gstin) || other.gstin == gstin) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.invoiceConfig, invoiceConfig) ||
                other.invoiceConfig == invoiceConfig) &&
            const DeepCollectionEquality().equals(
              other._termsAndConditions,
              _termsAndConditions,
            ) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.stateWithCode, stateWithCode) ||
                other.stateWithCode == stateWithCode) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    companyName,
    address,
    gstin,
    mobile,
    email,
    invoiceConfig,
    const DeepCollectionEquality().hash(_termsAndConditions),
    tagline,
    notes,
    stateWithCode,
    logoUrl,
  );

  /// Create a copy of CompanySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanySettingsImplCopyWith<_$CompanySettingsImpl> get copyWith =>
      __$$CompanySettingsImplCopyWithImpl<_$CompanySettingsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanySettingsImplToJson(this);
  }
}

abstract class _CompanySettings implements CompanySettings {
  const factory _CompanySettings({
    @JsonKey(name: '_id') final String? id,
    required final String companyName,
    required final CompanyAddress address,
    required final String gstin,
    required final String mobile,
    required final String email,
    required final InvoiceConfig invoiceConfig,
    final List<String> termsAndConditions,
    final String tagline,
    final String notes,
    final String stateWithCode,
    final String logoUrl,
  }) = _$CompanySettingsImpl;

  factory _CompanySettings.fromJson(Map<String, dynamic> json) =
      _$CompanySettingsImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  String get companyName;
  @override
  CompanyAddress get address;
  @override
  String get gstin;
  @override
  String get mobile;
  @override
  String get email;
  @override
  InvoiceConfig get invoiceConfig;
  @override
  List<String> get termsAndConditions;
  @override
  String get tagline;
  @override
  String get notes;
  @override
  String get stateWithCode;
  @override
  String get logoUrl;

  /// Create a copy of CompanySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanySettingsImplCopyWith<_$CompanySettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
