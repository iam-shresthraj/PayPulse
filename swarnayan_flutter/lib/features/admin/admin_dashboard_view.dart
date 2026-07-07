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
    _tabController = TabController(length: 4, vsync: this);
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
            tabs: const [
              Tab(text: 'System Overview'),
              Tab(text: 'Businesses & Codes'),
              Tab(text: 'Customer Directory'),
              Tab(text: 'User Access Control'),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
