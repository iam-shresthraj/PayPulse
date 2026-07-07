import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RolePermissionsNotifier extends StateNotifier<AsyncValue<Map<String, bool>>> {
  RolePermissionsNotifier() : super(const AsyncValue.loading()) {
    loadPermissions();
  }

  final _client = Supabase.instance.client;

  Future<void> loadPermissions() async {
    try {
      state = const AsyncValue.loading();
      final response = await _client.rpc('get_active_role_permissions');
      final Map<String, bool> permissions = {};
      if (response is List && response.isNotEmpty) {
        final row = Map<String, dynamic>.from(response.first);
        row.forEach((key, value) {
          if (value is bool) {
            permissions[key] = value;
          }
        });
      }
      state = AsyncValue.data(permissions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePermissions(Map<String, bool> updated) async {
    try {
      await _client.rpc('update_role_permissions', params: {
        'p_staff_dashboard': updated['staff_access_dashboard'] ?? true,
        'p_staff_invoices': updated['staff_access_invoices'] ?? true,
        'p_staff_customers': updated['staff_access_customers'] ?? true,
        'p_staff_inventory': updated['staff_access_inventory'] ?? true,
        'p_staff_reports': updated['staff_access_reports'] ?? false,
        'p_staff_records': updated['staff_access_records'] ?? true,
        'p_staff_rates': updated['staff_access_rates'] ?? true,
        'p_staff_staff': updated['staff_access_staff'] ?? false,
        'p_staff_settings': updated['staff_access_settings'] ?? false,
        'p_staff_coupons': updated['staff_access_coupons'] ?? false,
        'p_manager_dashboard': updated['manager_access_dashboard'] ?? true,
        'p_manager_invoices': updated['manager_access_invoices'] ?? true,
        'p_manager_customers': updated['manager_access_customers'] ?? true,
        'p_manager_inventory': updated['manager_access_inventory'] ?? true,
        'p_manager_reports': updated['manager_access_reports'] ?? true,
        'p_manager_records': updated['manager_access_records'] ?? true,
        'p_manager_rates': updated['manager_access_rates'] ?? true,
        'p_manager_staff': updated['manager_access_staff'] ?? true,
        'p_manager_settings': updated['manager_access_settings'] ?? false,
        'p_manager_coupons': updated['manager_access_coupons'] ?? true,
      });

      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        final profileRes = await _client
            .from('profiles')
            .select('company_id')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (profileRes != null && profileRes['company_id'] != null) {
          final String companyId = profileRes['company_id'];

          // Sync Staff Profiles
          await _client.from('profiles').update({
            'access_dashboard': updated['staff_access_dashboard'] ?? true,
            'access_invoices': updated['staff_access_invoices'] ?? true,
            'access_customers': updated['staff_access_customers'] ?? true,
            'access_inventory': updated['staff_access_inventory'] ?? true,
            'access_reports': updated['staff_access_reports'] ?? false,
            'access_records': updated['staff_access_records'] ?? true,
            'access_rates': updated['staff_access_rates'] ?? true,
            'access_staff': updated['staff_access_staff'] ?? false,
            'access_settings': updated['staff_access_settings'] ?? false,
            'access_coupons': updated['staff_access_coupons'] ?? false,
          }).eq('company_id', companyId).eq('role', 'STAFF');

          // Sync Manager Profiles
          await _client.from('profiles').update({
            'access_dashboard': updated['manager_access_dashboard'] ?? true,
            'access_invoices': updated['manager_access_invoices'] ?? true,
            'access_customers': updated['manager_access_customers'] ?? true,
            'access_inventory': updated['manager_access_inventory'] ?? true,
            'access_reports': updated['manager_access_reports'] ?? true,
            'access_records': updated['manager_access_records'] ?? true,
            'access_rates': updated['manager_access_rates'] ?? true,
            'access_staff': updated['manager_access_staff'] ?? true,
            'access_settings': updated['manager_access_settings'] ?? false,
            'access_coupons': updated['manager_access_coupons'] ?? true,
          }).eq('company_id', companyId).eq('role', 'MANAGER');
        }
      }

      await loadPermissions();
    } catch (e) {
      rethrow;
    }
  }
}

final rolePermissionsProvider =
    StateNotifierProvider<RolePermissionsNotifier, AsyncValue<Map<String, bool>>>((ref) {
  return RolePermissionsNotifier();
});
