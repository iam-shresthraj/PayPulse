import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../models/user.dart';

class StaffNotifier extends StateNotifier<AsyncValue<List<User>>> {
  StaffNotifier() : super(const AsyncValue.loading()) {
    loadStaff();
  }

  final _client = Supabase.instance.client;

  User _mapUser(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'STAFF',
      isActive: data['is_active'] ?? true,
      lastLogin: data['last_login'] != null ? DateTime.parse(data['last_login']) : null,
      phone: data['phone'],
      address: data['address'],
    );
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

  Future<void> addStaff(String name, String email, String password, String role) async {
    try {
      // Use a temporary SupabaseClient instance to avoid changing the logged-in session
      final tempClient = SupabaseClient(
        'https://gnyzctxlqcidubanoiae.supabase.co',
        'sb_publishable_h-fS9Q3g4ucAfmvD9btgWg_NwH4PKbH',
      );
      
      await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
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

  Future<void> updateStaff(String id, String name, String role) async {
    try {
      await _client
          .from('profiles')
          .update({
            'name': name,
            'role': role,
          })
          .eq('id', id);
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
