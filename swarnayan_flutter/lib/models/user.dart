/// Plain user model (no codegen) so security fields can evolve freely.
class User {
  final String id;
  final String name;
  final String email;
  final String role; // OWNER, MANAGER, STAFF
  final bool isActive;
  final String approvalStatus; // PENDING, APPROVED, REJECTED
  final String? companyId;
  final String? avatarUrl;
  final DateTime? lastLogin;
  final String? phone;
  final String? address;

  // Feature-wise Access Control Toggles
  final bool accessInvoices;
  final bool accessInventory;
  final bool accessCustomers;
  final bool accessRates;
  final bool accessReports;

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
    this.accessInvoices = true,
    this.accessInventory = true,
    this.accessCustomers = true,
    this.accessRates = true,
    this.accessReports = true,
  });

  bool get isOwner => role.toUpperCase() == 'OWNER';
  bool get isManager => role.toUpperCase() == 'MANAGER' || role.toUpperCase() == 'CO_OWNER';
  bool get isStaff => role.toUpperCase() == 'STAFF';
  bool get isApproved => approvalStatus.toUpperCase() == 'APPROVED';

  /// Manager-level access (manager or owner).
  bool get canManage => isOwner || isManager;

  factory User.fromJson(Map<String, dynamic> json) {
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
      accessInvoices: json['accessInvoices'] ?? json['access_invoices'] ?? true,
      accessInventory: json['accessInventory'] ?? json['access_inventory'] ?? true,
      accessCustomers: json['accessCustomers'] ?? json['access_customers'] ?? true,
      accessRates: json['accessRates'] ?? json['access_rates'] ?? true,
      accessReports: json['accessReports'] ?? json['access_reports'] ?? true,
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
        'access_invoices': accessInvoices,
        'access_inventory': accessInventory,
        'access_customers': accessCustomers,
        'access_rates': accessRates,
        'access_reports': accessReports,
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
    bool? accessInvoices,
    bool? accessInventory,
    bool? accessCustomers,
    bool? accessRates,
    bool? accessReports,
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
      accessInvoices: accessInvoices ?? this.accessInvoices,
      accessInventory: accessInventory ?? this.accessInventory,
      accessCustomers: accessCustomers ?? this.accessCustomers,
      accessRates: accessRates ?? this.accessRates,
      accessReports: accessReports ?? this.accessReports,
    );
  }
}
