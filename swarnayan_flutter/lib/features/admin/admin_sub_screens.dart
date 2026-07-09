import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/widgets/glass_dropdown.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../models/user.dart';
import 'admin_provider.dart';
import 'widgets/add_business_dialog.dart';
import 'widgets/user_access_dialog.dart';
import 'platform_settings_provider.dart';

class AdminPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const AdminPageWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. Businesses & Codes Screen
// -------------------------------------------------------------
class AdminBusinessesScreen extends ConsumerWidget {
  const AdminBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);

    return AdminPageWrapper(
      title: 'Businesses & Codes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddBusinessDialog(),
                );
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: Text('Add Business', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: state.companies.isEmpty
                ? Center(
                    child: Text('No businesses registered yet.', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: state.companies.length,
                    itemBuilder: (context, index) {
                      final company = state.companies[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(company.name, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Category: ${company.category}',
                                          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Text('ACCESS PASS CODES', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isCompact = constraints.maxWidth < 620;
                                  final tiles = [
                                    _buildCodeTile(context, ref, 'STAFF', company.staffCode, company.id),
                                    _buildCodeTile(context, ref, 'MANAGER', company.managerCode, company.id),
                                    _buildCodeTile(context, ref, 'OWNER', company.ownerCode, company.id),
                                  ];
                                  if (isCompact) {
                                    return Column(
                                      children: [
                                        for (var i = 0; i < tiles.length; i++) ...[
                                          tiles[i],
                                          if (i != tiles.length - 1) const SizedBox(height: 12),
                                        ],
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: tiles[0]),
                                      const SizedBox(width: 12),
                                      Expanded(child: tiles[1]),
                                      const SizedBox(width: 12),
                                      Expanded(child: tiles[2]),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeTile(BuildContext context, WidgetRef ref, String role, String code, String companyId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: AppTextStyles.titleSm.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$role access code copied!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, size: 16, color: AppColors.warning),
                    onPressed: () async {
                      final newCode = await ref.read(adminProvider.notifier).regenerateCode(companyId, role);
                      if (newCode != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$role code rotated: $newCode'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. Customer Directory Screen
// -------------------------------------------------------------
class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final TextEditingController _customerSearchController = TextEditingController();
  String _customerSearchQuery = '';
  String _selectedCompanyId = 'ALL';

  @override
  void initState() {
    super.initState();
    _customerSearchController.addListener(() {
      setState(() {
        _customerSearchQuery = _customerSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final filteredCustomers = state.customers.where((c) {
      final query = _customerSearchQuery;
      final companyMatches = _selectedCompanyId == 'ALL' || c.companyId == _selectedCompanyId;
      return companyMatches &&
             (c.name.toLowerCase().contains(query) ||
             c.mobile.toLowerCase().contains(query) ||
             (c.email?.toLowerCase().contains(query) ?? false));
    }).toList();

    return AdminPageWrapper(
      title: 'Customer Directory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBarWidget(
            controller: _customerSearchController,
            hint: 'Search by name, phone, or client ID..',
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCompanyId,
            dropdownColor: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceMuted),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
            items: [
              const DropdownMenuItem(value: 'ALL', child: Text('All Companies')),
              ...state.companies.map(
                (company) => DropdownMenuItem(
                  value: company.id,
                  child: Text(company.name),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedCompanyId = value);
            },
            decoration: InputDecoration(
              labelText: 'Filter by company',
              labelStyle: TextStyle(color: AppColors.primary),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 1.2)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Text('No customers found.', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final companyName = state.companies.firstWhere(
                        (c) => c.id == customer.companyId,
                        orElse: () => AdminBusiness(id: '', name: 'Unknown Business', category: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
                      ).name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.name, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_rounded, size: 12, color: AppColors.onSurfaceMuted),
                                        const SizedBox(width: 4),
                                        Text(customer.mobile, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                      ],
                                    ),
                                    if (customer.email != null && customer.email!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        customer.email!,
                                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                        softWrap: true,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            companyName,
                                            style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                        if (customer.pincode != null && customer.pincode!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Pincode: ${customer.pincode}',
                                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 11),
                                          ),
                                        ],
                                        if (customer.address != null && customer.address!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Addr: ${customer.address}',
                                              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. User Access Control Screen
// -------------------------------------------------------------
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final filteredUsers = state.users.where((User u) {
      final companyName = state.companies.firstWhere(
        (c) => c.id == u.companyId,
        orElse: () => AdminBusiness(id: '', name: '', category: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
      ).name;
      final matchesSearch = u.name.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery) ||
          u.role.toLowerCase().contains(_searchQuery) ||
          companyName.toLowerCase().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    return AdminPageWrapper(
      title: 'User Access Control',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBarWidget(
            controller: _searchController,
            hint: 'Search by name, email, role, or company name...',
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Text('No users found matching search.', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final companyName = state.companies.firstWhere(
                        (c) => c.id == user.companyId,
                        orElse: () => AdminBusiness(id: '', name: '', category: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
                      ).name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(user.name, style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: user.isActive 
                                                ? AppColors.success.withValues(alpha: 0.1)
                                                : AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.isActive ? 'ACTIVE' : 'INACTIVE',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: user.isActive ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(user.email, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.role,
                                            style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 9),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            companyName.isNotEmpty ? companyName : 'No Company (Super Admin)',
                                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => UserAccessDialog(user: user, companyName: companyName),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Access'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. Notifications Screen (With Tabs)
// -------------------------------------------------------------
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _welcomeTitleController = TextEditingController();
  final _welcomeBodyController = TextEditingController();
  
  String? _targetCompanyId;
  String _targetRole = 'ALL';
  bool _submitting = false;
  bool _savingWelcome = false;
  bool _welcomeInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _fileUrlController.dispose();
    _welcomeTitleController.dispose();
    _welcomeBodyController.dispose();
    super.dispose();
  }

  String _applyWelcomeTemplate(String input, {required String name, required String email}) {
    return input
        .replaceAll('{name}', name)
        .replaceAll('{email}', email)
        .trim();
  }

  Future<void> _saveWelcomeTemplate() async {
    final current = ref.read(platformSettingsProvider).value;
    if (current == null) return;

    setState(() => _savingWelcome = true);
    final updated = PlatformSettings(
      companyName: current.companyName,
      tagline: current.tagline,
      gstNo: current.gstNo,
      logoLightUrl: current.logoLightUrl,
      logoDarkUrl: current.logoDarkUrl,
      address: current.address,
      contactEmail: current.contactEmail,
      workingTime: current.workingTime,
      notifyOnSignup: current.notifyOnSignup,
      welcomeTitle: _welcomeTitleController.text.trim().isEmpty
          ? 'Welcome to PayPulse'
          : _welcomeTitleController.text.trim(),
      welcomeBody: _welcomeBodyController.text.trim().isEmpty
          ? 'Welcome to PayPulse, {name}! Your account has been created successfully.'
          : _welcomeBodyController.text.trim(),
    );
    final error = await ref.read(platformSettingsProvider.notifier).updateSettings(updated);
    if (mounted) {
      setState(() => _savingWelcome = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error == null ? 'Welcome template saved.' : 'Failed to save welcome template: $error'),
          backgroundColor: error == null ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Map<String, int> _calculateNotificationStats(Map<String, dynamic> item, AdminState state) {
    final targetCompanyId = item['target_company_id']?.toString();
    final targetRole = (item['target_role'] ?? 'ALL').toString().toUpperCase();

    int deliveredCompanies = 0;
    int deliveredUsers = 0;

    if (targetCompanyId != null && targetCompanyId.isNotEmpty) {
      deliveredCompanies = 1;
    } else {
      deliveredCompanies = state.companies.length;
    }

    if (targetCompanyId != null && targetCompanyId.isNotEmpty) {
      if (targetRole == 'ALL') {
        deliveredUsers = state.users.where((u) => 
          u.companyId == targetCompanyId && 
          u.isActive && 
          u.approvalStatus.toUpperCase() == 'APPROVED'
        ).length;
      } else {
        deliveredUsers = state.users.where((u) => 
          u.companyId == targetCompanyId && 
          u.role.toUpperCase() == targetRole && 
          u.isActive && 
          u.approvalStatus.toUpperCase() == 'APPROVED'
        ).length;
      }
    } else {
      if (targetRole == 'ALL') {
        deliveredUsers = state.users.where((u) => 
          u.isActive && 
          u.approvalStatus.toUpperCase() == 'APPROVED'
        ).length;
      } else if (targetRole == 'SUPER_ADMIN') {
        deliveredUsers = state.users.where((u) => 
          u.role.toUpperCase() == 'SUPER_ADMIN' && 
          u.isActive
        ).length;
      } else {
        deliveredUsers = state.users.where((u) => 
          u.role.toUpperCase() == targetRole && 
          u.isActive && 
          u.approvalStatus.toUpperCase() == 'APPROVED'
        ).length;
      }
    }

    return {
      'companies': deliveredCompanies,
      'users': deliveredUsers,
    };
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      final notifications = List<Map<String, dynamic>>.from(rows as List);
      if (notifications.isEmpty) return notifications;

      final ids = notifications.map((e) => e['id']?.toString()).whereType<String>().toList();
      final readCounts = <String, int>{};
      try {
        final reads = await client
            .from('notification_reads')
            .select('notification_id')
            .inFilter('notification_id', ids);
        for (final row in List<Map<String, dynamic>>.from(reads as List)) {
          final notificationId = row['notification_id']?.toString();
          if (notificationId == null) continue;
          readCounts[notificationId] = (readCounts[notificationId] ?? 0) + 1;
        }
      } catch (_) {}

      return notifications
          .map((item) => {
                ...item,
                '__seen_count': readCounts[item['id']?.toString()] ?? 0,
              })
          .toList();
    } catch (e) {
      if (e.toString().contains("Could not find the table 'public.notifications'")) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    final success = await ref.read(adminProvider.notifier).sendNotification(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      fileUrl: _fileUrlController.text.trim().isNotEmpty ? _fileUrlController.text.trim() : null,
      targetCompanyId: _targetCompanyId,
      targetRole: _targetRole,
    );
    
    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        _titleController.clear();
        _bodyController.clear();
        _fileUrlController.clear();
        setState(() {
          _targetCompanyId = null;
          _targetRole = 'ALL';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Broadcast notification sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _tabController.animateTo(1); // Switch to View History tab
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(adminProvider).error ?? 'Failed to send broadcast.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final platformSettingsAsync = ref.watch(platformSettingsProvider);
    final platformSettings = platformSettingsAsync.value;
    if (platformSettings != null && !_welcomeInitialized) {
      _welcomeInitialized = true;
      _welcomeTitleController.text = platformSettings.welcomeTitle;
      _welcomeBodyController.text = platformSettings.welcomeBody;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Notifications Center',
                      style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // Two tabs header
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Send Notification'),
                Tab(text: 'View Notifications'),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              indicatorColor: AppColors.primary,
              dividerColor: Colors.transparent,
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broadcast an alert or announcement to businesses and employees in the PayPulse system.',
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                            ),
                            const SizedBox(height: 20),
                            
                            // Title
                            GlassInput(
                              controller: _titleController,
                              label: 'Title',
                              hint: 'e.g. System Maintenance Notice',
                              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Body
                            GlassInput(
                              controller: _bodyController,
                              label: 'Message Body',
                              hint: 'Enter notification message details...',
                              maxLines: 4,
                              validator: (v) => v == null || v.isEmpty ? 'Message body is required' : null,
                            ),
                            const SizedBox(height: 16),

                            // Attachment URL
                            GlassInput(
                              controller: _fileUrlController,
                              label: 'Attachment / Learn More URL (Optional)',
                              hint: 'https://example.com/details',
                            ),
                            const SizedBox(height: 16),
                            
                            // Target Business
                            GlassDropdown<String?>(
                              label: 'Target Business / Company',
                              value: _targetCompanyId,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All Businesses'),
                                ),
                                ...state.companies.map((c) => DropdownMenuItem<String?>(
                                      value: c.id,
                                      child: Text(c.name),
                                    )),
                              ],
                              onChanged: (val) => setState(() => _targetCompanyId = val),
                            ),
                            const SizedBox(height: 16),

                            // Target Role
                            GlassDropdown<String>(
                              label: 'Target User Roles',
                              value: _targetRole,
                              items: const [
                                DropdownMenuItem<String>(
                                  value: 'ALL',
                                  child: Text('All Users'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'OWNER',
                                  child: Text('Owners Only'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'MANAGER',
                                  child: Text('Managers Only'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'STAFF',
                                  child: Text('Staff Only'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _targetRole = val);
                              },
                            ),
                            const SizedBox(height: 32),

                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'First Time Message',
                                    style: AppTextStyles.titleSm.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This message is sent automatically to a user after signup when signup notifications are enabled.',
                                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                  ),
                                  const SizedBox(height: 16),
                                  GlassInput(
                                    controller: _welcomeTitleController,
                                    label: 'Welcome Title',
                                    hint: 'Welcome to PayPulse',
                                  ),
                                  const SizedBox(height: 16),
                                  GlassInput(
                                    controller: _welcomeBodyController,
                                    label: 'Welcome Message',
                                    hint: 'Welcome to PayPulse, {name}!',
                                    maxLines: 4,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _savingWelcome ? null : _saveWelcomeTemplate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.surfaceContainer,
                                      foregroundColor: AppColors.primary,
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: _savingWelcome
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.save_rounded, size: 18),
                                    label: Text(
                                      _savingWelcome ? 'Saving...' : 'Save Welcome Template',
                                      style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Send Broadcast',
                                      style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadHistory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading history: ${snapshot.error}',
                              style: TextStyle(color: AppColors.error),
                            ),
                          );
                        }
                        final list = snapshot.data ?? [];
                        final now = DateTime.now();
                        final startOfMonth = DateTime(now.year, now.month, 1);
                        
                        // Calculate metrics
                        final totalDeliveredUsers = list.fold<int>(
                          0,
                          (sum, item) {
                            final stats = _calculateNotificationStats(item, state);
                            return sum + (stats['users'] ?? 0);
                          },
                        );

                        final totalDeliveredThisMonth = list.where((item) {
                          final createdAtStr = item['created_at']?.toString();
                          if (createdAtStr == null) return false;
                          final createdAt = DateTime.tryParse(createdAtStr);
                          if (createdAt == null) return false;
                          return createdAt.isAfter(startOfMonth) || createdAt.isAtSameMomentAs(startOfMonth);
                        }).fold<int>(0, (sum, item) {
                          final stats = _calculateNotificationStats(item, state);
                          return sum + (stats['users'] ?? 0);
                        });

                        final totalSeen = list.fold<int>(
                          0,
                          (sum, item) => sum + ((item['__seen_count'] ?? 0) as num).toInt(),
                        );

                        final totalUnseen = (totalDeliveredUsers - totalSeen).clamp(0, 1 << 30);

                        // Compute fastest and slowest readers
                        String fastestReaderName = 'No data';
                        String fastestReaderComp = '';
                        String fastestReaderSub = '';
                        
                        String slowestReaderName = 'No data';
                        String slowestReaderComp = '';
                        String slowestReaderSub = '';
                        
                        if (list.isNotEmpty && state.users.isNotEmpty) {
                          final userStats = <String, _UserReadStats>{};
                          
                          for (final u in state.users) {
                            int deliveredCount = 0;
                            int readCount = 0;
                            List<Duration> durations = [];
                            
                            for (final item in list) {
                              final targetCompanyId = item['target_company_id']?.toString();
                              final targetRole = (item['target_role'] ?? 'ALL').toString().toUpperCase();
                              
                              bool isDelivered = false;
                              if (targetCompanyId != null && targetCompanyId.isNotEmpty) {
                                if (targetCompanyId == u.companyId) {
                                  if (targetRole == 'ALL' || targetRole == u.role.toUpperCase()) {
                                    isDelivered = true;
                                  }
                                }
                              } else {
                                if (targetRole == 'ALL') {
                                  isDelivered = true;
                                } else if (targetRole == 'SUPER_ADMIN') {
                                  isDelivered = u.role.toUpperCase() == 'SUPER_ADMIN';
                                } else {
                                  isDelivered = targetRole == u.role.toUpperCase() && u.approvalStatus.toUpperCase() == 'APPROVED';
                                }
                              }
                              
                              if (isDelivered) {
                                deliveredCount++;
                                final rawReads = item['__raw_reads'] as List?;
                                final readObj = rawReads?.firstWhere(
                                  (r) => r['user_id']?.toString() == u.id,
                                  orElse: () => null,
                                );
                                if (readObj != null) {
                                  readCount++;
                                  final readAtStr = readObj['read_at']?.toString();
                                  final createdAtStr = item['created_at']?.toString();
                                  if (readAtStr != null && createdAtStr != null) {
                                    final readAt = DateTime.tryParse(readAtStr);
                                    final createdAt = DateTime.tryParse(createdAtStr);
                                    if (readAt != null && createdAt != null) {
                                      durations.add(readAt.difference(createdAt));
                                    }
                                  }
                                }
                              }
                            }
                            
                            if (deliveredCount > 0) {
                              userStats[u.id] = _UserReadStats(
                                user: u,
                                deliveredCount: deliveredCount,
                                readCount: readCount,
                                averageDuration: durations.isEmpty
                                    ? const Duration(days: 999)
                                    : Duration(
                                        microseconds: (durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds) / durations.length).round(),
                                      ),
                              );
                            }
                          }
                          
                          final readersWithReads = userStats.values.where((s) => s.readCount > 0).toList();
                          if (readersWithReads.isNotEmpty) {
                            readersWithReads.sort((a, b) => a.averageDuration.compareTo(b.averageDuration));
                            final fastest = readersWithReads.first;
                            final compName = state.companies.firstWhere(
                              (c) => c.id == fastest.user.companyId,
                              orElse: () => AdminBusiness(id: '', name: 'PayPulse', category: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
                            ).name;
                            fastestReaderName = fastest.user.name;
                            fastestReaderComp = compName;
                            fastestReaderSub = "Avg response: ${_formatDuration(fastest.averageDuration)}";
                          }
                          
                          final allTargeted = userStats.values.toList();
                          if (allTargeted.isNotEmpty) {
                            allTargeted.sort((a, b) {
                              final rateA = a.readCount / a.deliveredCount;
                              final rateB = b.readCount / b.deliveredCount;
                              if (rateA != rateB) return rateA.compareTo(rateB);
                              
                              final unreadA = a.deliveredCount - a.readCount;
                              final unreadB = b.deliveredCount - b.readCount;
                              if (unreadA != unreadB) return unreadB.compareTo(unreadA);
                              
                              return b.averageDuration.compareTo(a.averageDuration);
                            });
                            final slowest = allTargeted.first;
                            final compName = state.companies.firstWhere(
                              (c) => c.id == slowest.user.companyId,
                              orElse: () => AdminBusiness(id: '', name: 'PayPulse', category: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
                            ).name;
                            slowestReaderName = slowest.user.name;
                            slowestReaderComp = compName;
                            final unreadCount = slowest.deliveredCount - slowest.readCount;
                            slowestReaderSub = "Unread: $unreadCount / ${slowest.deliveredCount} messages";
                          }
                        }

                        if (list.isEmpty) {
                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 120),
                            children: [
                              _buildDashboardHeader(
                                totalDeliveredThisMonth: 0,
                                totalSeen: 0,
                                totalUnseen: 0,
                                fastestReaderName: 'No data',
                                fastestReaderComp: '',
                                fastestReaderSub: '',
                                slowestReaderName: 'No data',
                                slowestReaderComp: '',
                                slowestReaderSub: '',
                              ),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text(
                                  'No broadcasts sent yet.',
                                  style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        }
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: list.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildDashboardHeader(
                                  totalDeliveredThisMonth: totalDeliveredThisMonth,
                                  totalSeen: totalSeen,
                                  totalUnseen: totalUnseen,
                                  fastestReaderName: fastestReaderName,
                                  fastestReaderComp: fastestReaderComp,
                                  fastestReaderSub: fastestReaderSub,
                                  slowestReaderName: slowestReaderName,
                                  slowestReaderComp: slowestReaderComp,
                                  slowestReaderSub: slowestReaderSub,
                                ),
                              );
                            }

                            final item = list[index - 1];
                            final title = (item['title'] ?? '').toString();
                            final body = (item['body'] ?? '').toString();
                            final created = item['created_at'] != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(item['created_at'].toString()).toLocal())
                                : '';
                            final role = (item['target_role'] ?? 'ALL').toString();
                            final companyId = item['target_company_id']?.toString();
                            final companyName = companyId == null || companyId.isEmpty
                                ? 'All Businesses'
                                : state.companies.firstWhere(
                                    (c) => c.id == companyId,
                                    orElse: () => AdminBusiness(id: '', name: 'Unknown', category: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
                                  ).name;
                            final seenCount = (item['__seen_count'] ?? 0) as int;
                            final stats = _calculateNotificationStats(item, state);
                            final deliveredUsers = stats['users'] ?? 0;
                            final deliveredCompanies = stats['companies'] ?? 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      created,
                                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      body,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _buildBadge(Icons.business_rounded, 'Target: $companyName'),
                                        _buildBadge(Icons.person_outline_rounded, 'Role: $role'),
                                        _buildBadge(Icons.send_rounded, 'Delivered: $deliveredCompanies companies, $deliveredUsers users'),
                                        _buildBadge(Icons.remove_red_eye_rounded, 'Seen: $seenCount users'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader({
    required int totalDeliveredThisMonth,
    required int totalSeen,
    required int totalUnseen,
    required String fastestReaderName,
    required String fastestReaderComp,
    required String fastestReaderSub,
    required String slowestReaderName,
    required String slowestReaderComp,
    required String slowestReaderSub,
  }) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: [
            _buildMetricCard('Total No. of Message', '$totalDeliveredThisMonth', Icons.send_rounded, subtitle: 'Delivered this Month'),
            _buildMetricCard('Messages Seen', '$totalSeen', Icons.visibility_rounded),
            _buildMetricCard('Unseen Messages', '$totalUnseen', Icons.mark_email_unread_rounded),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: MediaQuery.of(context).size.width >= 700 ? 3.5 : 2.8,
          children: [
            _buildAnalyticsCard(
              'Fastest Reader',
              fastestReaderName,
              fastestReaderComp,
              fastestReaderSub,
              Icons.bolt_rounded,
              AppColors.success,
            ),
            _buildAnalyticsCard(
              'Least Active Reader',
              slowestReaderName,
              slowestReaderComp,
              slowestReaderSub,
              Icons.snooze_rounded,
              AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String name,
    String company,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                ),
                if (company.isNotEmpty) ...[
                  Text(
                    company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 11),
                  ),
                ],
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMetricCard(String title, String value, IconData icon, {String? subtitle}) {
  return GlassCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildBadge(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

// -------------------------------------------------------------
// 5. System Branding Screen
// -------------------------------------------------------------
class AdminBrandingScreen extends ConsumerStatefulWidget {
  const AdminBrandingScreen({super.key});

  @override
  ConsumerState<AdminBrandingScreen> createState() => _AdminBrandingScreenState();
}

class _AdminBrandingScreenState extends ConsumerState<AdminBrandingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _hoursController;
  late TextEditingController _logoLightController;
  late TextEditingController _logoDarkController;

  bool _initialized = false;
  bool _saving = false;
  bool _uploadingLight = false;
  bool _uploadingDark = false;
  bool _notifyOnSignup = true;

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _taglineController.dispose();
      _addressController.dispose();
      _emailController.dispose();
      _hoursController.dispose();
      _logoLightController.dispose();
      _logoDarkController.dispose();
    }
    super.dispose();
  }

  void _initControllers(PlatformSettings settings) {
    _nameController = TextEditingController(text: settings.companyName);
    _taglineController = TextEditingController(text: settings.tagline);
    _addressController = TextEditingController(text: settings.address ?? '');
    _emailController = TextEditingController(text: settings.contactEmail);
    _hoursController = TextEditingController(text: settings.workingTime);
    _logoLightController = TextEditingController(text: settings.logoLightUrl ?? '');
    _logoDarkController = TextEditingController(text: settings.logoDarkUrl ?? '');
    _notifyOnSignup = settings.notifyOnSignup;
    _initialized = true;
  }

  Future<void> _pickAndUploadLogo(bool isLightLogo) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      
      final file = result.files.first;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file data'), backgroundColor: Colors.red),
        );
        return;
      }
      
      setState(() {
        if (isLightLogo) _uploadingLight = true;
        else _uploadingDark = true;
      });
      
      final url = await ref.read(platformSettingsProvider.notifier).uploadLogoFile(
        file.bytes!,
        file.name,
      );
      
      setState(() {
        if (isLightLogo) {
          _uploadingLight = false;
          if (url != null) _logoLightController.text = url;
        } else {
          _uploadingDark = false;
          if (url != null) _logoDarkController.text = url;
        }
      });
      
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isLightLogo ? "Light" : "Dark"} logo uploaded successfully!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload logo file'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _uploadingLight = false;
        _uploadingDark = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    
    final currentSettings = ref.read(platformSettingsProvider).value;
    
    final updated = PlatformSettings(
      companyName: _nameController.text.trim(),
      tagline: _taglineController.text.trim(),
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      contactEmail: _emailController.text.trim(),
      workingTime: _hoursController.text.trim(),
      logoLightUrl: currentSettings?.logoLightUrl,
      logoDarkUrl: currentSettings?.logoDarkUrl,
      notifyOnSignup: _notifyOnSignup,
    );
    
    final error = await ref.read(platformSettingsProvider.notifier).updateSettings(updated);
    if (mounted) {
      setState(() => _saving = false);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('System branding settings saved!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return AdminPageWrapper(
      title: 'System Branding',
      child: settingsAsync.when(
        data: (settings) {
          if (!_initialized) {
            _initControllers(settings);
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure the global branding, logos, and support details that reflect across all companies.',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name
                  GlassInput(
                    controller: _nameController,
                    label: 'Platform / Company Name',
                    hint: 'e.g. PayPulse',
                    validator: (v) => v == null || v.isEmpty ? 'Company name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Tagline
                  GlassInput(
                    controller: _taglineController,
                    label: 'Tagline / Slogan',
                    hint: 'e.g. Manage Gold and Invoices Seamlessly',
                  ),
                  const SizedBox(height: 16),

                  // Address
                  GlassInput(
                    controller: _addressController,
                    label: 'Physical Address',
                    hint: 'Enter platform headquarters address...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  GlassInput(
                    controller: _emailController,
                    label: 'Contact / Support Email',
                    hint: 'support@paypulse.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                  ),
                  const SizedBox(height: 16),

                  // Working Hours
                  GlassInput(
                    controller: _hoursController,
                    label: 'Operational / Support Hours',
                    hint: 'e.g. 10:00 AM - 08:00 PM (Mon - Sat)',
                  ),
                  const SizedBox(height: 16),

                  // Notify on user signup toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notify on New User Signups',
                              style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Automatically send a system notification when a new member signs up.',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _notifyOnSignup,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _notifyOnSignup = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save Branding Settings', style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(
          height: 200,
          child: Center(
            child: Text('Error loading platform settings: $e', style: TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

class _UserReadStats {
  final User user;
  final int deliveredCount;
  final int readCount;
  final Duration averageDuration;

  _UserReadStats({
    required this.user,
    required this.deliveredCount,
    required this.readCount,
    required this.averageDuration,
  });
}

String _formatDuration(Duration d) {
  if (d.inDays >= 999) return 'N/A';
  if (d.inMinutes < 1) {
    return '${d.inSeconds}s';
  } else if (d.inHours < 1) {
    return '${d.inMinutes}m';
  } else if (d.inDays < 1) {
    return '${d.inHours}h ${d.inMinutes % 60}m';
  } else {
    return '${d.inDays}d ${d.inHours % 24}h';
  }
}
