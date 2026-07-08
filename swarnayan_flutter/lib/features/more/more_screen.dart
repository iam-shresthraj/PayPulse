

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../auth/auth_provider.dart';
import '../../core/utils/dialog_helper.dart';
import 'widgets/more_dialogs.dart';
import 'widgets/team_dialogs.dart';
import 'company_provider.dart';
import 'daily_rates_provider.dart';
import 'team_provider.dart';
import 'role_permissions_provider.dart';
import '../../core/theme/theme_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  String _formatRole(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return 'Owner';
      case 'MANAGER':
      case 'CO_OWNER':
        return 'Manager';
      case 'STAFF':
        return 'Staff';
      default:
        return role;
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isWide = MediaQuery.of(context).size.width >= 850;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final rolePermissions = ref.watch(rolePermissionsProvider).value ?? {};
    final canManage = user?.canManage ?? false;
    final isOwner = user?.isOwner ?? false;
    final companyName =
        ref.watch(companyProvider).value?.companyName ?? 'PayPulse';
    final pendingCount =
        canManage ? (ref.watch(pendingMembersProvider).value?.length ?? 0) : 0;
    final themeOverride = ref.watch(themeModeProvider);
    final isLight = themeOverride ?? (MediaQuery.of(context).size.width >= 850);

    // Visibility checks based on role and feature permissions
    final showCustomers = !isWide && (user?.hasAccess('customers', rolePermissions) ?? true);
    final showProducts = !isWide && (user?.hasAccess('inventory', rolePermissions) ?? true);
    final showDirectorySection = showCustomers || showProducts;

    final showReports = !isWide && canManage && (user?.hasAccess('reports', rolePermissions) ?? true);
    final showSettings = !isWide && isOwner && (user?.hasAccess('settings', rolePermissions) ?? true);
    final showRates = user?.hasAccess('rates', rolePermissions) ?? true;
    final showRecords = !isWide && (user?.hasAccess('records', rolePermissions) ?? true);
    final showCoupons = user?.hasAccess('coupons', rolePermissions) ?? true;
    final showBusinessSection = showReports || showSettings || showRates || showRecords || showCoupons;

    final showStaffMgmt = canManage && (user?.hasAccess('staff', rolePermissions) ?? true);
    final showPending = canManage && (user?.hasAccess('staff', rolePermissions) ?? true);
    final showCompanyCodes = canManage && ((user?.hasAccess('settings', rolePermissions) ?? true) || (user?.hasAccess('staff', rolePermissions) ?? true));
    final showChangePassword = true; // Always visible
    final showTeamSection = showStaffMgmt || showPending || showCompanyCodes || showChangePassword;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(companyProvider.notifier).loadCompanySettings();
          await ref.read(dailyRatesProvider.notifier).loadRates();
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPadding + 8),

            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  const SizedBox(width: 12),
                  Text('Management', style: AppTextStyles.titleMd),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // ── Profile Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                animationIndex: 0,
                padding: const EdgeInsets.all(20),
                onTap: () {
                  showSingleDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (_) => const EditProfileDialog(),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(user?.name),
                          style: AppTextStyles.titleSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Admin User',
                            style: AppTextStyles.titleSm,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRole(user?.role ?? 'STAFF'),
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            companyName,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (user?.isSuperAdmin ?? false) ...[
              // ── Admin Panel Section ──
              _buildSectionLabel('Admin Panel'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildAdminBox(
                      context: context,
                      icon: Icons.business_rounded,
                      label: 'Businesses & Codes',
                      onTap: () => context.push('/admin/businesses'),
                    ),
                    _buildAdminBox(
                      context: context,
                      icon: Icons.people_alt_rounded,
                      label: 'Customer Directory',
                      onTap: () => context.push('/admin/customers'),
                    ),
                    _buildAdminBox(
                      context: context,
                      icon: Icons.lock_person_rounded,
                      label: 'User Access Control',
                      onTap: () => context.push('/admin/users'),
                    ),
                    _buildAdminBox(
                      context: context,
                      icon: Icons.campaign_rounded,
                      label: 'Notifications',
                      onTap: () => context.push('/admin/notifications'),
                    ),
                    _buildAdminBox(
                      context: context,
                      icon: Icons.palette_rounded,
                      label: 'System Branding',
                      onTap: () => context.push('/admin/branding'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              if (showDirectorySection) ...[
                // ── Directory Section ──
                _buildSectionLabel('Directory'),
                const SizedBox(height: 12),
                if (showCustomers)
                  _buildMenuItem(
                    icon: Icons.people_alt_rounded,
                    label: 'Customers',
                    subtitle: 'Manage client directory & balances',
                    index: 20,
                    onTap: () => context.go('/customers'),
                  ),
                if (showProducts)
                  _buildMenuItem(
                    icon: Icons.diamond_rounded,
                    label: 'Products',
                    subtitle: 'Manage inventory & prices',
                    index: 21,
                    onTap: () => context.go('/products'),
                  ),
                const SizedBox(height: 24),
              ],

              if (showBusinessSection) ...[
                // ── Business Section ──
                _buildSectionLabel('Business'),
                const SizedBox(height: 12),
                if (showReports)
                  _buildMenuItem(
                    icon: Icons.analytics_rounded,
                    label: 'Reports',
                    subtitle: 'Search & export reports',
                    index: 0,
                    onTap: () => context.go('/reports'),
                  ),
                if (showSettings)
                  _buildMenuItem(
                    icon: Icons.business_rounded,
                    label: 'Company Settings',
                    subtitle: 'Name, address, GSTIN, logo',
                    index: 1,
                    onTap: () {
                      showSingleDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => const CompanySettingsDialog(),
                      );
                    },
                  ),
                if (showRates)
                  _buildMenuItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Rate Management',
                    subtitle: 'Daily gold & silver rates',
                    index: 2,
                    onTap: () => context.push('/more/rates'),
                  ),
                if (showRecords)
                  _buildMenuItem(
                    icon: Icons.book_rounded,
                    label: 'Record Book',
                    subtitle: 'Income & expense tracking',
                    index: 3,
                    onTap: () => context.push('/more/records'),
                  ),
                if (showCoupons)
                  _buildMenuItem(
                    icon: Icons.local_offer_rounded,
                    label: 'Coupons & Offers',
                    subtitle: 'Manage discount codes',
                    index: 4,
                    onTap: () {
                      showSingleDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => const CouponsManagementDialog(),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],

              // ── Team Section ──
              if (showTeamSection) ...[
                _buildSectionLabel('Team'),
                const SizedBox(height: 12),
                if (showStaffMgmt)
                  _buildMenuItem(
                    icon: Icons.people_outline_rounded,
                    label: 'Staff Management',
                    subtitle: 'Users, roles & permissions',
                    index: 5,
                    onTap: () {
                      showSingleDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => const StaffManagementDialog(),
                      );
                    },
                  ),
                if (showPending)
                  _buildMenuItem(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Pending Approvals',
                    subtitle: pendingCount > 0
                        ? '$pendingCount request${pendingCount == 1 ? '' : 's'} waiting for you'
                        : 'Review new account requests',
                    index: 10,
                    badgeCount: pendingCount,
                    onTap: () {
                      showSingleDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => const PendingApprovalsDialog(),
                      ).then((_) => ref.invalidate(pendingMembersProvider));
                    },
                  ),
                if (showCompanyCodes)
                  _buildMenuItem(
                    icon: Icons.vpn_key_rounded,
                    label: 'Company Codes',
                    subtitle: isOwner
                        ? 'Staff, manager & owner access codes'
                        : 'Staff access code',
                    index: 11,
                    onTap: () {
                      showSingleDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => const CompanyCodesDialog(),
                      );
                    },
                  ),
                if (showChangePassword)
                  _buildMenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    subtitle: 'Update your credentials',
                    index: 6,
                    onTap: () {
                      showSingleDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (_) => const ChangePasswordDialog(),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ],

            // ── App Section ──
            _buildSectionLabel('App'),
            const SizedBox(height: 12),
            if (!isWide) ...[
              _buildMenuItem(
                icon: isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                label: isLight ? 'Dark Mode' : 'Light Mode',
                subtitle: isLight ? 'Switch to dark theme' : 'Switch to light theme',
                index: 99,
                onTap: () {
                  ref.read(themeModeProvider.notifier).toggleTheme(isLight);
                },
              ),
            ],
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              label: 'About',
              subtitle: 'Version 1.0.0',
              index: 7,
              onTap: () {
                showSingleDialog(
                  context: context,
                  useRootNavigator: false,
                  builder: (_) => const AboutDetailsDialog(),
                );
              },
            ),
            if (!isWide) ...[
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                subtitle: 'FAQs & contact',
                index: 8,
                onTap: () {
                  showSingleDialog(
                    context: context,
                    useRootNavigator: false,
                    builder: (_) => const HelpSupportDialog(),
                  );
                },
              ),
            ],

            if (!isWide) ...[
              const SizedBox(height: 24),
              // ── Logout ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  animationIndex: 9,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  borderColor: AppColors.error.withValues(alpha: 0.3),
                  onTap: () async {
                    final confirm = await showSingleDialog<bool>(
                      context: context,
                      useRootNavigator: false,
                      builder: (context) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: AlertDialog(
                          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.glassBorder),
                          ),
                          title: Text(
                            'Sign Out',
                            style: AppTextStyles.titleLg.copyWith(color: AppColors.error),
                          ),
                          content: Text(
                            'Are you sure you want to sign out?',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Sign Out',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authProvider.notifier).logout();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.onSurfaceDim,
          letterSpacing: 1.5,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required int index,
    int? badgeCount,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 10),
      child: GlassCard(
        animationIndex: index,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
             Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceDim,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBox({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      animationIndex: 1,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

