import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/section_header.dart';
import '../../models/user.dart';
import 'admin_provider.dart';
import 'widgets/add_business_dialog.dart';
import 'widgets/user_access_dialog.dart';
import 'widgets/send_notification_dialog.dart';
import 'platform_settings_provider.dart';
import 'package:file_picker/file_picker.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final TextEditingController _customerSearchController = TextEditingController();
  String _customerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _customerSearchController.addListener(() {
      setState(() {
        _customerSearchQuery = _customerSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // Analytics Center Tab
  // -------------------------------------------------------------
  Widget _buildAnalyticsCenter(AdminState state) {
    // Role Counts
    int staffCount = 0;
    int managerCount = 0;
    int ownerCount = 0;
    for (final u in state.users) {
      if (u.isStaff) staffCount++;
      else if (u.isManager) managerCount++;
      else if (u.isOwner && !u.isSuperAdmin) ownerCount++;
    }

    // Category Counts
    final Map<String, int> categoryCounts = {};
    for (final company in state.companies) {
      final cat = company.category;
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of KPIs (non-confidential overview)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 2.5 : 1.3,
            children: [
              StatCard(
                title: 'Total Businesses',
                value: state.companies.length.toString(),
                icon: Icons.business_rounded,
              ),
              StatCard(
                title: 'Total System Users',
                value: state.users.length.toString(),
                icon: Icons.people_alt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Two Column Graph Layout (User distribution & Business Categories)
          Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isWide ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'User Roles Distribution'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDistributionRow('Staff Members', staffCount, state.users.length, AppColors.success),
                          const SizedBox(height: 16),
                          _buildDistributionRow('Store Managers', managerCount, state.users.length, AppColors.info),
                          const SizedBox(height: 16),
                          _buildDistributionRow('Company Owners', ownerCount, state.users.length, AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
              Expanded(
                flex: isWide ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Business Verticals / Categories'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: categoryCounts.isEmpty
                            ? [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      'No business categories registered.',
                                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                                    ),
                                  ),
                                )
                              ]
                            : categoryCounts.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildDistributionRow(
                                    entry.key,
                                    entry.value,
                                    state.companies.length,
                                    AppColors.primary,
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(String title, int count, int total, Color color) {
    final double percent = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Text('$count (${(percent * 100).toStringAsFixed(0)}%)', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          color: color,
          backgroundColor: AppColors.border.withValues(alpha: 0.2),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Customer Directory Tab
  // -------------------------------------------------------------
  Widget _buildCustomersTab(AdminState state) {
    final filteredCustomers = state.customers.where((c) {
      final query = _customerSearchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
             c.mobile.toLowerCase().contains(query) ||
             (c.email?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Row(
          children: [
            Expanded(
              child: Container(
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
            ),
          ],
        ),
        const SizedBox(height: 20),

        // List
        Expanded(
          child: filteredCustomers.isEmpty
              ? Center(
                  child: Text('No customers found.', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
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
                                            softWrap: true,
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
    );
  }

  // -------------------------------------------------------------
  // Businesses & Codes Tab
  // -------------------------------------------------------------
  Widget _buildBusinessesTab(AdminState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Registered Businesses'),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const AddBusinessDialog(),
                ),
                icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 20),
                label: Text('New Business', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.companies.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text('No companies registered.', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.companies.length,
              itemBuilder: (context, index) {
                final company = state.companies[index];
                final now = DateTime.now();
                final isExpired = company.renewDate != null && now.isAfter(company.renewDate!);
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(company.name, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    company.category.toUpperCase(),
                                    style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Created: ${DateFormat('dd MMM yyyy').format(company.createdAt)}',
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isExpired ? AppColors.error.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isExpired ? AppColors.error.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        company.renewDate != null
                                            ? 'Renews: ${DateFormat('dd MMM yyyy').format(company.renewDate!)}'
                                            : 'No Expiry Set',
                                        style: AppTextStyles.bodySm.copyWith(
                                          color: isExpired ? AppColors.error : AppColors.success,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: company.renewDate ?? DateTime.now().add(const Duration(days: 365)),
                                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                                          helpText: 'Set Renewal Date',
                                        );
                                        if (picked != null && mounted) {
                                          await ref.read(adminProvider.notifier).updateCompanyRenewDate(company.id, picked);
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text('Set Date', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await ref.read(adminProvider.notifier).renewCompanySubscription(company.id, company.renewDate);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${company.name} renewed for 1 year!'), backgroundColor: AppColors.success),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Text('ACCESS PASS CODES', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildCodeTile('STAFF', company.staffCode, company.id)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCodeTile('MANAGER', company.managerCode, company.id)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCodeTile('OWNER', company.ownerCode, company.id)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCodeTile(String role, String code, String companyId) {
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
              SelectableText(
                code,
                style: AppTextStyles.titleSm.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onBackground,
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
                      if (newCode != null && mounted) {
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

  // -------------------------------------------------------------
  // Global Access Control Tab
  // -------------------------------------------------------------
  Widget _buildUsersTab(AdminState state) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Row(
          children: [
            Expanded(
              child: Container(
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
            ),
          ],
        ),
        const SizedBox(height: 20),

        // List View
        Expanded(
          child: filteredUsers.isEmpty
              ? Center(
                  child: Text('No users found matching search.', style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
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
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(user.name, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(user.email, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('Role: ', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                      Text(user.role, style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Text('|  ', style: AppTextStyles.bodySm.copyWith(color: AppColors.border)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Admin Dashboard',
                  style: AppTextStyles.headlineLgMobile.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.read(adminProvider.notifier).loadAdminData(),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'System Overview'),
              Tab(text: 'Businesses & Codes'),
              Tab(text: 'Customer Directory'),
              Tab(text: 'User Access Control'),
              Tab(text: 'Notifications'),
              Tab(text: 'System Branding'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceMuted,
            indicatorColor: AppColors.primary,
            dividerColor: Colors.transparent,
          ),
          const SizedBox(height: 16),

          // Tab Contents
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAnalyticsCenter(state),
                  _buildBusinessesTab(state),
                  _buildCustomersTab(state),
                  _buildUsersTab(state),
                  _buildNotificationsTab(state),
                  const SystemBrandingTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Broadcast Notifications Tab
  // -------------------------------------------------------------
  Widget _buildNotificationsTab(AdminState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Broadcast History'),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const SendNotificationDialog(),
                );
                if (result == true) {
                  setState(() {}); // refresh list view
                }
              },
              icon: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              label: Text('New Broadcast', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold)),
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: Supabase.instance.client
                .from('notifications')
                .select()
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// System Branding Tab
// -------------------------------------------------------------
class SystemBrandingTab extends ConsumerStatefulWidget {
  const SystemBrandingTab({super.key});

  @override
  ConsumerState<SystemBrandingTab> createState() => _SystemBrandingTabState();
}

class _SystemBrandingTabState extends ConsumerState<SystemBrandingTab> {
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
    _initialized = true;
  }

  Future<void> _pickAndUploadLogo(bool isLightLogo) async {
    try {
      final result = await FilePicker.platform.pickFiles(
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

    return settingsAsync.when(
      data: (settings) {
        if (!_initialized) {
          _initControllers(settings);
        }
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Configure Platform & System Branding'),
                const SizedBox(height: 8),
                Text(
                  'These settings configure the branding, logos, and support information that reflects across all companies and all employees.',
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
                                child: Center(child: Text('No logo uploaded', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted))),
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
                                child: Center(child: Text('No logo uploaded', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted))),
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
    );
  }
}

