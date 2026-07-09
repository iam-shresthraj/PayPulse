/// Plain user model (no codegen) so security fields can evolve freely.
class User {
  final String id;
  final String name;
  final String email;
  final String role; // OWNER, MANAGER, STAFF, SUPER_ADMIN
  final bool isActive;
  final String approvalStatus; // PENDING, APPROVED, REJECTED
  final String? companyId;
  final String? avatarUrl;
  final DateTime? lastLogin;
  final String? phone;
  final String? address;
  final String? companyCategory; // 'Jewellery' or others
  final DateTime? companyRenewDate;
  final DateTime? createdAt;

  // Feature-wise Access Control Toggles (10 sections)
  final bool accessDashboard;
  final bool accessInvoices;
  final bool accessCustomers;
  final bool accessInventory;
  final bool accessReports;
  final bool accessRecords;
  final bool accessRates;
  final bool accessStaff;
  final bool accessSettings;
  final bool accessCoupons;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.approvalStatus = 'APPROVED',
    this.companyId,
    this.avatarUrl,
    this.lastLogin,
    this.phone,
    this.address,
    this.companyCategory = 'Jewellery',
    this.companyRenewDate,
    this.createdAt,
    this.accessDashboard = true,
    this.accessInvoices = true,
    this.accessCustomers = true,
    this.accessInventory = true,
    this.accessReports = true,
    this.accessRecords = true,
    this.accessRates = true,
    this.accessStaff = true,
    this.accessSettings = true,
    this.accessCoupons = true,
  });

  bool get isSuperAdmin => role.toUpperCase() == 'SUPER_ADMIN';
  bool get isOwner => role.toUpperCase() == 'OWNER' || role.toUpperCase() == 'SUPER_ADMIN';
  bool get isManager => role.toUpperCase() == 'MANAGER';
  bool get isStaff => role.toUpperCase() == 'STAFF';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED' || role.toUpperCase() == 'SUPER_ADMIN';
  bool get isDeassociated => ((companyId == null || companyId!.isEmpty) && role.toUpperCase() != 'SUPER_ADMIN') || approvalStatus.toUpperCase() == 'DEASSOCIATED';

  bool get isJewellery => companyCategory?.toLowerCase() == 'jewellery';
  bool get hasLifetimeAccess => !isSuperAdmin && companyRenewDate == null;
  bool get isExpired => false;

  /// Manager-level access (manager or owner).
  bool get canManage => isOwner || isManager || isSuperAdmin;

  /// Dynamic access check combining individual permissions and role configurations.
  bool hasAccess(String section, Map<String, bool> rolePermissions) {
    if (isSuperAdmin) return true; // Super Admin always has full access
    if (isOwner) return true; // Owners always have full access

    // Check if the individual profile allows access
    bool profileAllowed = true;
    switch (section.toLowerCase()) {
      case 'dashboard': profileAllowed = accessDashboard; break;
      case 'invoices': profileAllowed = accessInvoices; break;
      case 'customers': profileAllowed = accessCustomers; break;
      case 'inventory': profileAllowed = accessInventory; break;
      case 'reports': profileAllowed = accessReports; break;
      case 'records': profileAllowed = accessRecords; break;
      case 'rates': profileAllowed = accessRates; break;
      case 'staff': profileAllowed = accessStaff; break;
      case 'settings': profileAllowed = accessSettings; break;
      case 'coupons': profileAllowed = accessCoupons; break;
    }

    // Check if the role configuration allows access
    final prefix = role.toLowerCase(); // staff or manager
    final key = '${prefix}_access_${section.toLowerCase()}';
    final roleAllowed = rolePermissions[key] ?? true;

    return profileAllowed && roleAllowed;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    String? category;
    DateTime? renewDate;

    if (json['companies'] != null) {
      final comp = json['companies'];
      if (comp is Map) {
        category = comp['category']?.toString();
        final rDate = comp['renew_date'];
        if (rDate != null) {
          renewDate = DateTime.tryParse(rDate.toString());
        }
      }
    } else {
      category = json['companyCategory'] ?? json['company_category'];
      final rDate = json['companyRenewDate'] ?? json['company_renew_date'];
      if (rDate != null) {
        renewDate = DateTime.tryParse(rDate.toString());
      }
    }

    return User(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'STAFF',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      approvalStatus:
          json['approvalStatus'] ?? json['approval_status'] ?? 'APPROVED',
      companyId: json['companyId'] ?? json['company_id'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : (json['last_login'] != null
              ? DateTime.tryParse(json['last_login'].toString())
              : null),
      phone: json['phone'],
      address: json['address'],
      companyCategory: category ?? 'Jewellery',
      companyRenewDate: renewDate,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
      accessDashboard: json['accessDashboard'] ?? json['access_dashboard'] ?? true,
      accessInvoices: json['accessInvoices'] ?? json['access_invoices'] ?? true,
      accessCustomers: json['accessCustomers'] ?? json['access_customers'] ?? true,
      accessInventory: json['accessInventory'] ?? json['access_inventory'] ?? true,
      accessReports: json['accessReports'] ?? json['access_reports'] ?? true,
      accessRecords: json['accessRecords'] ?? json['access_records'] ?? true,
      accessRates: json['accessRates'] ?? json['access_rates'] ?? true,
      accessStaff: json['accessStaff'] ?? json['access_staff'] ?? true,
      accessSettings: json['accessSettings'] ?? json['access_settings'] ?? true,
      accessCoupons: json['accessCoupons'] ?? json['access_coupons'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'role': role,
        'isActive': isActive,
        'approvalStatus': approvalStatus,
        'companyId': companyId,
        'avatarUrl': avatarUrl,
        'lastLogin': lastLogin?.toIso8601String(),
        'phone': phone,
        'address': address,
        'company_category': companyCategory,
        'company_renew_date': companyRenewDate?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'access_dashboard': accessDashboard,
        'access_invoices': accessInvoices,
        'access_inventory': accessInventory,
        'access_customers': accessCustomers,
        'access_reports': accessReports,
        'access_records': accessRecords,
        'access_rates': accessRates,
        'access_staff': accessStaff,
        'access_settings': accessSettings,
        'access_coupons': accessCoupons,
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    String? approvalStatus,
    String? companyId,
    String? avatarUrl,
    DateTime? lastLogin,
    String? phone,
    String? address,
    String? companyCategory,
    DateTime? companyRenewDate,
    DateTime? createdAt,
    bool? accessDashboard,
    bool? accessInvoices,
    bool? accessInventory,
    bool? accessCustomers,
    bool? accessReports,
    bool? accessRecords,
    bool? accessRates,
    bool? accessStaff,
    bool? accessSettings,
    bool? accessCoupons,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      companyId: companyId ?? this.companyId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLogin: lastLogin ?? this.lastLogin,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      companyCategory: companyCategory ?? this.companyCategory,
      companyRenewDate: companyRenewDate ?? this.companyRenewDate,
      createdAt: createdAt ?? this.createdAt,
      accessDashboard: accessDashboard ?? this.accessDashboard,
      accessInvoices: accessInvoices ?? this.accessInvoices,
      accessInventory: accessInventory ?? this.accessInventory,
      accessCustomers: accessCustomers ?? this.accessCustomers,
      accessReports: accessReports ?? this.accessReports,
      accessRecords: accessRecords ?? this.accessRecords,
      accessRates: accessRates ?? this.accessRates,
      accessStaff: accessStaff ?? this.accessStaff,
      accessSettings: accessSettings ?? this.accessSettings,
      accessCoupons: accessCoupons ?? this.accessCoupons,
    );
  }
}
