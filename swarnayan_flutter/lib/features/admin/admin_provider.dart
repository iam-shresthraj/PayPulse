import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../models/user.dart';

class AdminBusiness {
  final String id;
  final String name;
  final String staffCode;
  final String managerCode;
  final String ownerCode;
  final DateTime createdAt;

  AdminBusiness({
    required this.id,
    required this.name,
    required this.staffCode,
    required this.managerCode,
    required this.ownerCode,
    required this.createdAt,
  });

  factory AdminBusiness.fromJson(Map<String, dynamic> json) {
    return AdminBusiness(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      staffCode: json['staff_code'] ?? '',
      managerCode: json['manager_code'] ?? '',
      ownerCode: json['owner_code'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
}

/// Lightweight invoice model for admin dashboard stats only.
/// Avoids pulling in the full freezed Invoice with all required fields.
class AdminInvoice {
  final String id;
  final String? invoiceNumber;
  final String companyId;
  final DateTime invoiceDate;
  final double grossAmount;
  final double finalPayable;
  final double totalAmountPaid;
  final double balanceDue;
  final String status;
  final DateTime? deletedAt;

  AdminInvoice({
    required this.id,
    required this.companyId,
    required this.invoiceDate,
    required this.grossAmount,
    required this.finalPayable,
    required this.totalAmountPaid,
    required this.balanceDue,
    required this.status,
    this.invoiceNumber,
    this.deletedAt,
  });

  factory AdminInvoice.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) => v == null ? 0.0 : (v is int ? v.toDouble() : (v as num).toDouble());
    return AdminInvoice(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      companyId: json['company_id']?.toString() ?? '',
      invoiceDate: json['invoice_date'] != null 
          ? DateTime.parse(json['invoice_date'].toString())
          : DateTime.now(),
      grossAmount: _toDouble(json['gross_amount']),
      finalPayable: _toDouble(json['final_payable']),
      totalAmountPaid: _toDouble(json['total_amount_paid']),
      balanceDue: _toDouble(json['balance_due']),
      status: json['status'] ?? 'DRAFT',
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'].toString())
          : null,
    );
  }
}

class AdminState {
  final List<AdminBusiness> companies;
  final List<User> users;
  final List<AdminInvoice> invoices;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.companies = const [],
    this.users = const [],
    this.invoices = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<AdminBusiness>? companies,
    List<User>? users,
    List<AdminInvoice>? invoices,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      companies: companies ?? this.companies,
      users: users ?? this.users,
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final SupabaseClient _client = Supabase.instance.client;

  AdminNotifier() : super(const AdminState());

  Future<void> loadAdminData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Only fetch lightweight columns for invoices to keep it fast
      final companiesData = await _client.from('companies').select().order('created_at', ascending: false);
      final usersData = await _client.from('profiles').select().order('created_at', ascending: false);
      final invoicesData = await _client
          .from('invoices')
          .select('id, invoice_number, company_id, invoice_date, gross_amount, final_payable, total_amount_paid, balance_due, status, deleted_at')
          .order('created_at', ascending: false);

      final companies = (companiesData as List).map((x) => AdminBusiness.fromJson(x)).toList();
      final users = (usersData as List).map((x) => User.fromJson(x)).toList();
      final invoices = (invoicesData as List).map((x) => AdminInvoice.fromJson(x)).toList();

      state = state.copyWith(
        companies: companies,
        users: users,
        invoices: invoices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createBusiness(String name) async {
    state = state.copyWith(isLoading: true);
    try {
      await _client.from('companies').insert({
        'name': name,
      });
      await loadAdminData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<String?> regenerateCode(String companyId, String role) async {
    try {
      final response = await _client.rpc('regenerate_company_code', params: {
        'p_company_id': companyId,
        'p_role': role.toUpperCase(),
      });
      await loadAdminData();
      return response?.toString();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> updateUserProfile(
    String userId, {
    required String role,
    required bool isActive,
    required String approvalStatus,
    required Map<String, bool> accessList,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _client.from('profiles').update({
        'role': role,
        'is_active': isActive,
        'approval_status': approvalStatus,
        'access_dashboard': accessList['dashboard'] ?? true,
        'access_invoices': accessList['invoices'] ?? true,
        'access_customers': accessList['customers'] ?? true,
        'access_inventory': accessList['inventory'] ?? true,
        'access_reports': accessList['reports'] ?? true,
        'access_records': accessList['records'] ?? true,
        'access_rates': accessList['rates'] ?? true,
        'access_staff': accessList['staff'] ?? true,
        'access_settings': accessList['settings'] ?? true,
        'access_coupons': accessList['coupons'] ?? true,
      }).eq('id', userId);
      await loadAdminData();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final notifier = AdminNotifier();
  notifier.loadAdminData();
  return notifier;
});

