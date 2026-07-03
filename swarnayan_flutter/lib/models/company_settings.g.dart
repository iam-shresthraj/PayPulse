// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompanyAddressImpl _$$CompanyAddressImplFromJson(Map<String, dynamic> json) =>
    _$CompanyAddressImpl(
      line1: json['line1'] as String,
      line2: json['line2'] as String? ?? '',
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
    );

Map<String, dynamic> _$$CompanyAddressImplToJson(
  _$CompanyAddressImpl instance,
) => <String, dynamic>{
  'line1': instance.line1,
  'line2': instance.line2,
  'city': instance.city,
  'state': instance.state,
  'postalCode': instance.postalCode,
};

_$InvoiceConfigImpl _$$InvoiceConfigImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceConfigImpl(
      prefix: json['prefix'] as String? ?? 'SW',
      suffix: json['suffix'] as String? ?? '',
      separator: json['separator'] as String? ?? '/',
      paddingLength: (json['paddingLength'] as num?)?.toInt() ?? 5,
      currentCounter: (json['currentCounter'] as num?)?.toInt() ?? 0,
      financialYear: json['financialYear'] as String? ?? '',
    );

Map<String, dynamic> _$$InvoiceConfigImplToJson(_$InvoiceConfigImpl instance) =>
    <String, dynamic>{
      'prefix': instance.prefix,
      'suffix': instance.suffix,
      'separator': instance.separator,
      'paddingLength': instance.paddingLength,
      'currentCounter': instance.currentCounter,
      'financialYear': instance.financialYear,
    };

_$CompanySettingsImpl _$$CompanySettingsImplFromJson(
  Map<String, dynamic> json,
) => _$CompanySettingsImpl(
  id: json['_id'] as String?,
  companyName: json['companyName'] as String,
  address: CompanyAddress.fromJson(json['address'] as Map<String, dynamic>),
  gstin: json['gstin'] as String,
  mobile: json['mobile'] as String,
  email: json['email'] as String,
  invoiceConfig: InvoiceConfig.fromJson(
    json['invoiceConfig'] as Map<String, dynamic>,
  ),
  termsAndConditions:
      (json['termsAndConditions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  tagline: json['tagline'] as String? ?? '',
  notes: json['notes'] as String? ?? '',
  stateWithCode: json['stateWithCode'] as String? ?? '',
  logoUrl: json['logoUrl'] as String? ?? '',
);

Map<String, dynamic> _$$CompanySettingsImplToJson(
  _$CompanySettingsImpl instance,
) => <String, dynamic>{
  '_id': instance.id,
  'companyName': instance.companyName,
  'address': instance.address,
  'gstin': instance.gstin,
  'mobile': instance.mobile,
  'email': instance.email,
  'invoiceConfig': instance.invoiceConfig,
  'termsAndConditions': instance.termsAndConditions,
  'tagline': instance.tagline,
  'notes': instance.notes,
  'stateWithCode': instance.stateWithCode,
  'logoUrl': instance.logoUrl,
};
