import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/company_settings.dart';

class CompanyNotifier extends StateNotifier<AsyncValue<CompanySettings?>> {
  CompanyNotifier() : super(const AsyncValue.loading()) {
    loadCompanySettings();
  }

  final _client = Supabase.instance.client;

  CompanySettings? _mapSettings(Map<String, dynamic>? data) {
    if (data == null) return null;
    return CompanySettings(
      id: data['id'].toString(),
      companyName: data['company_name'] ?? '',
      address: CompanyAddress(
        line1: data['address_line1'] ?? '',
        line2: data['address_line2'] ?? '',
        city: data['city'] ?? '',
        state: data['state'] ?? '',
        postalCode: data['postal_code'] ?? '',
      ),
      gstin: data['gstin'] ?? '',
      mobile: data['mobile'] ?? '',
      email: data['email'] ?? '',
      invoiceConfig: InvoiceConfig(
        prefix: data['invoice_prefix'] ?? 'S',
        suffix: data['invoice_suffix'] ?? '',
        separator: data['invoice_separator'] ?? '-',
        paddingLength: data['invoice_padding_length'] ?? 6,
        currentCounter: data['invoice_current_counter'] ?? 0,
        financialYear: data['invoice_financial_year'] ?? '',
      ),
      termsAndConditions: List<String>.from(data['terms_and_conditions'] ?? []),
      tagline: data['tagline'] ?? '',
      notes: data['notes'] ?? '',
      stateWithCode: data['state_with_code'] ?? '',
      logoUrl: data['logo_url'] ?? '',
    );
  }

  Map<String, dynamic> _unmapSettings(CompanySettings settings) {
    return {
      'company_name': settings.companyName,
      'logo_url': settings.logoUrl,
      'address_line1': settings.address.line1,
      'address_line2': settings.address.line2,
      'city': settings.address.city,
      'state': settings.address.state,
      'postal_code': settings.address.postalCode,
      'gstin': settings.gstin,
      'mobile': settings.mobile,
      'email': settings.email,
      'invoice_prefix': settings.invoiceConfig.prefix,
      'invoice_suffix': settings.invoiceConfig.suffix,
      'invoice_separator': settings.invoiceConfig.separator,
      'invoice_padding_length': settings.invoiceConfig.paddingLength,
      'invoice_current_counter': settings.invoiceConfig.currentCounter,
      'invoice_financial_year': settings.invoiceConfig.financialYear,
      'terms_and_conditions': settings.termsAndConditions,
      'tagline': settings.tagline,
      'notes': settings.notes,
      'state_with_code': settings.stateWithCode,
    };
  }

  Future<void> loadCompanySettings() async {
    try {
      state = const AsyncValue.loading();
      final data = await _client.from('company_settings').select().maybeSingle();
      if (data != null) {
        state = AsyncValue.data(_mapSettings(data));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(CompanySettings settings) async {
    try {
      final payload = _unmapSettings(settings);
      final response = await _client
          .from('company_settings')
          .update(payload)
          .eq('id', int.parse(settings.id ?? '1'))
          .select()
          .single();
      state = AsyncValue.data(_mapSettings(response));
    } catch (e) {
      await loadCompanySettings();
      rethrow;
    }
  }
}

final companyProvider =
    StateNotifierProvider<CompanyNotifier, AsyncValue<CompanySettings?>>((ref) {
  return CompanyNotifier();
});
