import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_settings.freezed.dart';
part 'company_settings.g.dart';

@freezed
class CompanyAddress with _$CompanyAddress {
  const factory CompanyAddress({
    required String line1,
    @Default('') String line2,
    required String city,
    required String state,
    required String postalCode,
  }) = _CompanyAddress;

  factory CompanyAddress.fromJson(Map<String, dynamic> json) => _$CompanyAddressFromJson(json);
}

@freezed
class InvoiceConfig with _$InvoiceConfig {
  const factory InvoiceConfig({
    @Default('SW') String prefix,
    @Default('') String suffix,
    @Default('/') String separator,
    @Default(5) int paddingLength,
    @Default(0) int currentCounter,
    @Default('') String financialYear,
  }) = _InvoiceConfig;

  factory InvoiceConfig.fromJson(Map<String, dynamic> json) => _$InvoiceConfigFromJson(json);
}

@freezed
class CompanySettings with _$CompanySettings {
  const factory CompanySettings({
    @JsonKey(name: '_id') String? id,
    required String companyName,
    required CompanyAddress address,
    required String gstin,
    required String mobile,
    required String email,
    required InvoiceConfig invoiceConfig,
    @Default([]) List<String> termsAndConditions,
    @Default('') String tagline,
    @Default('') String notes,
    @Default('') String stateWithCode,
    @Default('') String logoUrl,
  }) = _CompanySettings;

  factory CompanySettings.fromJson(Map<String, dynamic> json) => _$CompanySettingsFromJson(json);
}
