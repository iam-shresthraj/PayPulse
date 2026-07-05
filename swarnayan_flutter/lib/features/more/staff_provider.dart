import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../models/user.dart';

class StaffNotifier extends StateNotifier<AsyncValue<List<User>>> {
  StaffNotifier() : super(const AsyncValue.loading()) {
    loadStaff();
  }

  final _client = Supabase.instance.client;

  User _mapUser(Map<String, dynamic> data) {
    return User.fromJson(data);
  }

  Future<void> loadStaff() async {
    try {
      state = const AsyncValue.loading();
      final data = await _client.from('profiles').select().order('name', ascending: true);
      final users = (data as List).map((item) => _mapUser(item)).toList();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addStaff({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      // 1. Fetch current owner's company codes to match selected role
      final codesResponse = await _client.rpc('get_company_codes');
      String companyCode = '';
      if (codesResponse is List && codesResponse.isNotEmpty) {
        final row = Map<String, dynamic>.from(codesResponse.first);
        if (role.toUpperCase() == 'OWNER') {
          companyCode = row['owner_code'] ?? '';
        } else if (role.toUpperCase() == 'MANAGER') {
          companyCode = row['manager_code'] ?? '';
        } else {
          companyCode = row['staff_code'] ?? '';
        }
      }

      if (companyCode.isEmpty) {
        throw Exception('Could not fetch company codes for registration.');
      }

      // 2. Create the user via a temporary SupabaseClient instance
      final tempClient = SupabaseClient(
        'https://gnyzctxlqcidubanoiae.supabase.co',
        'sb_publishable_h-fS9Q3g4ucAfmvD9btgWg_NwH4PKbH',
      );
      
      await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'company_code': companyCode,
        },
      );
      
      await loadStaff();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleUserStatus(User user) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': !user.isActive})
          .eq('id', user.id);
      await loadStaff();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStaff({
    required String id,
    required String name,
    required String role,
    required bool accessInvoices,
    required bool accessInventory,
    required bool accessCustomers,
    required bool accessRates,
    required bool accessReports,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({
            'name': name,
            'role': role,
            'access_invoices': accessInvoices,
            'access_inventory': accessInventory,
            'access_customers': accessCustomers,
            'access_rates': accessRates,
            'access_reports': accessReports,
          })
          .eq('id', id);
      await loadStaff();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStaff(String id) async {
    try {
      await _client.rpc('delete_user_pp', params: {'p_user_id': id});
      await loadStaff();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> bulkUpdateAccess({
    required List<String> userIds,
    required bool accessInvoices,
    required bool accessInventory,
    required bool accessCustomers,
    required bool accessRates,
    required bool accessReports,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({
            'access_invoices': accessInvoices,
            'access_inventory': accessInventory,
            'access_customers': accessCustomers,
            'access_rates': accessRates,
            'access_reports': accessReports,
          })
          .inFilter('id', userIds);
      await loadStaff();
    } catch (e) {
      rethrow;
    }
  }
}

final staffProvider =
    StateNotifierProvider<StaffNotifier, AsyncValue<List<User>>>((ref) {
  return StaffNotifier();
});
