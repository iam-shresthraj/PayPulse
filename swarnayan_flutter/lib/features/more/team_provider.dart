import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Company access codes with role-based visibility applied server-side:
/// staff sees none, manager sees the staff code, owner sees all three.
class CompanyCodes {
  final String? staffCode;
  final String? managerCode;
  final String? ownerCode;

  const CompanyCodes({this.staffCode, this.managerCode, this.ownerCode});

  bool get isEmpty =>
      staffCode == null && managerCode == null && ownerCode == null;
}

final companyCodesProvider = FutureProvider<CompanyCodes>((ref) async {
  final client = Supabase.instance.client;
  try {
    final result = await client.rpc('get_company_codes');
    if (result is List && result.isNotEmpty) {
      final row = Map<String, dynamic>.from(result.first);
      String? clean(dynamic v) {
        final s = v?.toString().trim();
        return (s == null || s.isEmpty) ? null : s;
      }

      return CompanyCodes(
        staffCode: clean(row['staff_code']),
        managerCode: clean(row['manager_code']),
        ownerCode: clean(row['owner_code']),
      );
    }
  } catch (_) {
    // RPC missing (migration not applied yet) or no access.
  }
  return const CompanyCodes();
});

/// A member of the company waiting for access approval.
class PendingMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  const PendingMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });
}

final pendingMembersProvider = FutureProvider<List<PendingMember>>((ref) async {
  final client = Supabase.instance.client;
  try {
    final result = await client.rpc('get_pending_members');
    if (result is List) {
      return result.map((item) {
        final row = Map<String, dynamic>.from(item);
        return PendingMember(
          id: row['id'].toString(),
          name: (row['name'] ?? '').toString(),
          email: (row['email'] ?? '').toString(),
          role: (row['role'] ?? 'STAFF').toString(),
          createdAt: row['created_at'] != null
              ? DateTime.tryParse(row['created_at'].toString())
              : null,
        );
      }).toList();
    }
  } catch (_) {
    // RPC missing or not authorised — treat as no pending members.
  }
  return const [];
});

/// Approve or reject a pending member. Hierarchy is enforced server-side.
Future<void> reviewMember(String userId, bool approve) async {
  final client = Supabase.instance.client;
  await client.rpc('review_member', params: {
    'p_user_id': userId,
    'p_approve': approve,
  });
}
