import 'dart:typed_data';
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
import '../../core/widgets/section_header.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Registered Businesses'),
              ElevatedButton.icon(
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
            ],
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        company.renewDate != null
                                            ? 'Expires: ${DateFormat('dd MMM yyyy').format(company.renewDate!)}'
                                            : 'Expires: N/A',
                                        style: AppTextStyles.bodySm.copyWith(
                                          color: company.renewDate != null && company.renewDate!.isBefore(DateTime.now())
                                              ? AppColors.error
                                              : AppColors.onSurfaceMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await ref.read(adminProvider.notifier).renewCompanySubscription(company.id, company.renewDate);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Validity extended for ${company.name}'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text('+1 Year', style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              Text('ACCESS PASS CODES', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.2)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildCodeTile(context, ref, 'STAFF', company.staffCode, company.id)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildCodeTile(context, ref, 'MANAGER', company.managerCode, company.id)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildCodeTile(context, ref, 'OWNER', company.ownerCode, company.id)),
                                ],
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
      return c.name.toLowerCase().contains(query) ||
             c.mobile.toLowerCase().contains(query) ||
             (c.email?.toLowerCase().contains(query) ?? false);
    }).toList();

    return AdminPageWrapper(
      title: 'Customer Directory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _customerSearchController,
              decoration: InputDecoration(
                hintText: 'Search global customer directory by name or phone...',
                hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: AppColors.onSurfaceMuted),
              ),
              style: TextStyle(color: AppColors.onBackground),
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
                                        if (customer.email != null && customer.email!.isNotEmpty) ...[
                                          const SizedBox(width: 12),
                                          Icon(Icons.email_rounded, size: 12, color: AppColors.onSurfaceMuted),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              customer.email!,
                                              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, role, or company name...',
                hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: AppColors.onSurfaceMuted),
              ),
              style: TextStyle(color: AppColors.onBackground),
            ),
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
  
  String? _targetCompanyId;
  String _targetRole = 'ALL';
  bool _submitting = false;

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
    super.dispose();
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
                    // Tab 1: Send Notification Form
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

                            // Submit Button
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

                    // Tab 2: View Broadcast History
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: Supabase.instance.client
                          .from('notifications')
                          .select('*, notification_reads(count)')
                          .order('created_at', ascending: false)
                          .limit(20)
                          .then((res) => List<Map<String, dynamic>>.from(res as List)),
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
                        if (list.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text('No broadcasts sent yet.', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted)),
                            ),
                          );
                        }
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final title = item['title'] ?? '';
                            final body = item['body'] ?? '';
                            final created = item['created_at'] != null 
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(item['created_at'].toString()).toLocal())
                                : '';
                            final role = item['target_role'] ?? 'ALL';
                            final companyId = item['target_company_id'];
                            final companyName = companyId == null 
                                ? 'All Businesses'
                                : state.companies.firstWhere((c) => c.id == companyId, orElse: () => AdminBusiness(id: '', name: 'Unknown', category: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now())).name;

                            final notificationReads = item['notification_reads'] as List?;
                            final seenCount = (notificationReads != null && notificationReads.isNotEmpty)
                                ? (notificationReads[0]['count'] as num?)?.toInt() ?? 0
                                : 0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(title, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                        ),
                                        Text(created, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(body, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.business_rounded, size: 12, color: AppColors.onSurfaceMuted),
                                        const SizedBox(width: 4),
                                        Text('Target: $companyName', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 11)),
                                        const SizedBox(width: 16),
                                        Icon(Icons.person_outline_rounded, size: 12, color: AppColors.onSurfaceMuted),
                                        const SizedBox(width: 4),
                                        Text('Role: $role', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.send_rounded, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Delivered to: ${item['delivered_companies_count'] ?? 0} comp., ${item['delivered_users_count'] ?? 0} users',
                                          style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.remove_red_eye_rounded, size: 12, color: AppColors.success),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Seen by: $seenCount users',
                                          style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
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
    
    final updated = PlatformSettings(
      companyName: _nameController.text.trim(),
      tagline: _taglineController.text.trim(),
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      contactEmail: _emailController.text.trim(),
      workingTime: _hoursController.text.trim(),
      logoLightUrl: _logoLightController.text.trim().isNotEmpty ? _logoLightController.text.trim() : null,
      logoDarkUrl: _logoDarkController.text.trim().isNotEmpty ? _logoDarkController.text.trim() : null,
      notifyOnSignup: _notifyOnSignup,
    );
    
    final success = await ref.read(platformSettingsProvider.notifier).updateSettings(updated);
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('System branding settings saved!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to save settings to database'), backgroundColor: AppColors.error),
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
                  const SizedBox(height: 24),

                  // Company Logos Title
                  Text(
                    'COMPANY LOGOS',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  
                  // Light & Dark Logos in Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Light Logo Picker
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('Light Theme Logo', style: AppTextStyles.labelMd),
                              const SizedBox(height: 12),
                              if (_logoLightController.text.isNotEmpty)
                                Container(
                                  height: 50,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(_logoLightController.text, fit: BoxFit.contain),
                                )
                              else
                                Container(
                                  height: 50,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Center(child: Text('No logo', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted))),
                                ),
                              ElevatedButton.icon(
                                onPressed: _uploadingLight ? null : () => _pickAndUploadLogo(true),
                                icon: _uploadingLight 
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.upload_rounded, size: 16),
                                label: const Text('Upload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  textStyle: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Dark Logo Picker
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('Dark Theme Logo', style: AppTextStyles.labelMd),
                              const SizedBox(height: 12),
                              if (_logoDarkController.text.isNotEmpty)
                                Container(
                                  height: 50,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(_logoDarkController.text, fit: BoxFit.contain),
                                )
                              else
                                Container(
                                  height: 50,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Center(child: Text('No logo', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted))),
                                ),
                              ElevatedButton.icon(
                                onPressed: _uploadingDark ? null : () => _pickAndUploadLogo(false),
                                icon: _uploadingDark 
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.upload_rounded, size: 16),
                                label: const Text('Upload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  textStyle: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

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
