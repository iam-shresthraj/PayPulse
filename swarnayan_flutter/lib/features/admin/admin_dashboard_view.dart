import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/section_header.dart';
import 'admin_provider.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    // Load admin data on mount
    Future.microtask(() {
      ref.read(adminProvider.notifier).loadAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(adminProvider.notifier).loadAdminData(),
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unified Header
              const AppHeader(),
              
              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: AppTextStyles.headlineLgMobile.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
                      onPressed: () => ref.read(adminProvider.notifier).loadAdminData(),
                    ),
                  ],
                ),
              ),

              // System Overview / Stats Center
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null
                          ? Center(child: Text('Error: ${state.error}', style: TextStyle(color: AppColors.error)))
                          : _buildAnalyticsCenter(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(bottom: 120), // Extra space in bottom so nothing gets hidden
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of KPIs
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

          // Two Column Graph Layout
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
}
