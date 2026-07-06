import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // Analytics Center Tab
  // -------------------------------------------------------------
  Widget _buildAnalyticsCenter(AdminState state) {
    final activeInvoices = state.invoices.where((i) => i.status != 'CANCELLED' && i.deletedAt == null).toList();
    final totalRevenue = activeInvoices.fold(0.0, (sum, i) => sum + i.finalPayable);
    
    // Group invoices by company
    final Map<String, double> companyRevenue = {};
    final Map<String, int> companyInvoicesCount = {};
    for (final company in state.companies) {
      companyRevenue[company.id] = 0.0;
      companyInvoicesCount[company.id] = 0;
    }
    for (final inv in activeInvoices) {
      if (companyRevenue.containsKey(inv.companyId)) {
        companyRevenue[inv.companyId] = companyRevenue[inv.companyId]! + inv.finalPayable;
        companyInvoicesCount[inv.companyId] = companyInvoicesCount[inv.companyId]! + 1;
      }
    }

    // Role Counts
    int staffCount = 0;
    int managerCount = 0;
    int ownerCount = 0;
    for (final u in state.users) {
      if (u.isStaff) staffCount++;
      else if (u.isManager) managerCount++;
      else if (u.isOwner && !u.isSuperAdmin) ownerCount++;
    }

    // Weekly Invoice Volume
    final weeklyInvoices = List.filled(7, 0);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    for (final inv in activeInvoices) {
      final diff = inv.invoiceDate.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        final weekdayIndex = inv.invoiceDate.weekday % 7;
        weeklyInvoices[weekdayIndex]++;
      }
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of KPIs
          GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 1.4 : 1.3,
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
              StatCard(
                title: 'Total Invoices',
                value: state.invoices.length.toString(),
                icon: Icons.receipt_long_rounded,
              ),
              StatCard(
                title: 'System Revenue',
                value: '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                icon: Icons.currency_rupee_rounded,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Business Performance Graph (Horizontal Bar Chart)
          const SectionHeader(title: 'Business Revenue Share'),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.companies.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('No businesses registered yet.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
                    ),
                  )
                else
                  ...state.companies.map((company) {
                    final rev = companyRevenue[company.id] ?? 0.0;
                    final maxRev = companyRevenue.values.fold(1.0, (m, v) => v > m ? v : m);
                    final ratio = maxRev > 0 ? (rev / maxRev) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(company.name, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
                              Text('₹${(rev / 1000).toStringAsFixed(1)}k', style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.border.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio > 0 ? ratio : 0.01,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: AppColors.primaryGradient),
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.primaryGlow, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Two Column Graph Layout (User distribution & Weekly Volume)
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
                    const SectionHeader(title: 'Weekly Invoice Volume'),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        height: 160,
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (index) {
                          final count = weeklyInvoices[index];
                          final maxCount = weeklyInvoices.fold(1, (m, v) => v > m ? v : m);
                          final ratio = count / maxCount;
                          final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(count > 0 ? '$count' : '', style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                width: 20,
                                height: ratio > 0 ? (ratio * 100) + 8 : 8,
                                decoration: BoxDecoration(
                                  color: count > 0 ? AppColors.info : AppColors.border.withValues(alpha: 0.3),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(days[index], style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted)),
                            ],
                          );
                        }),
                        ),
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
                            Text(company.name, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            Text(
                              'Created: ${DateFormat('dd MMM yyyy').format(company.createdAt)}',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
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
      final matchesSearch = u.name.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery) ||
          u.role.toLowerCase().contains(_searchQuery);
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
                    hintText: 'Search system users by name, email, or role...',
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
                      orElse: () => AdminBusiness(id: '', name: '', staffCode: '', managerCode: '', ownerCode: '', createdAt: DateTime.now()),
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
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                        status: user.isActive ? 'PAID' : 'CANCELLED',
                                        fontSize: 8.0,
                                      ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYPULSE',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin Dashboard',
                      style: AppTextStyles.headlineLgMobile.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
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
              Tab(text: 'Analytics Center'),
              Tab(text: 'Businesses & Codes'),
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
