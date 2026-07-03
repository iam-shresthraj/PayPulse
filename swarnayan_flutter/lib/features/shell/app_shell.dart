import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../more/daily_rates_provider.dart';
import '../more/daily_rate_prompt_dialog.dart';
import '../more/widgets/more_dialogs.dart';
import '../auth/auth_provider.dart';

/// Main application shell supporting both mobile bottom navigation bar 
/// and desktop left-navigation sidebar.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _prompted = false;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/billing')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/billing');
        break;
      case 2:
        context.go('/customers');
        break;
      case 3:
        context.go('/products');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  void _checkRates() {
    if (_prompted) return;

    final ratesState = ref.read(dailyRatesProvider);
    if (ratesState is AsyncData) {
      final hasToday = ref.read(dailyRatesProvider.notifier).isTodayRateEntered();
      if (!hasToday) {
        _prompted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false, // Force them to set rates on startup
            builder: (context) => const DailyRatePromptDialog(isDismissible: false),
          );
        });
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
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
  }

  @override
  Widget build(BuildContext context) {
    // Watch dailyRatesProvider to trigger loading if not already
    final ratesState = ref.watch(dailyRatesProvider);

    // Call checkRates when rates data is loaded
    if (ratesState is AsyncData && !_prompted) {
      _checkRates();
    }

    // Also set up a listener to trigger on changes
    ref.listen(dailyRatesProvider, (previous, next) {
      if (next is AsyncData && !_prompted) {
        _checkRates();
      }
    });

    final currentIndex = _currentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isWide = MediaQuery.of(context).size.width >= 850;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildLeftSidebar(context),
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.only(bottom: 68.0 + bottomPadding + 16.0),
        child: widget.child,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: bottomPadding + 8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    onTap: () => _onTap(context, 0),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Billing',
                    isActive: currentIndex == 1,
                    onTap: () => _onTap(context, 1),
                  ),
                  _NavItem(
                    icon: Icons.people_alt_rounded,
                    label: 'Customers',
                    isActive: currentIndex == 2,
                    onTap: () => _onTap(context, 2),
                  ),
                  _NavItem(
                    icon: Icons.diamond_rounded,
                    label: 'Products',
                    isActive: currentIndex == 3,
                    onTap: () => _onTap(context, 3),
                  ),
                  _NavItem(
                    icon: Icons.menu_rounded,
                    label: 'More',
                    isActive: currentIndex == 4,
                    onTap: () => _onTap(context, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PayPulse',
                  style: AppTextStyles.titleLg.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              children: [
                _buildSidebarHeader('MENU'),
                _buildSidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isActive: currentIndex == 0,
                  onTap: () => _onTap(context, 0),
                ),
                _buildSidebarItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Billing',
                  isActive: currentIndex == 1,
                  onTap: () => _onTap(context, 1),
                ),
                _buildSidebarItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Customers',
                  isActive: currentIndex == 2,
                  onTap: () => _onTap(context, 2),
                ),
                _buildSidebarItem(
                  icon: Icons.diamond_rounded,
                  label: 'Products',
                  isActive: currentIndex == 3,
                  onTap: () => _onTap(context, 3),
                ),
                _buildSidebarItem(
                  icon: Icons.folder_shared_rounded,
                  label: 'Management',
                  isActive: currentIndex == 4,
                  onTap: () => _onTap(context, 4),
                ),

                const SizedBox(height: 24),
                _buildSidebarHeader('GENERAL'),
                _buildSidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: false,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CompanySettingsDialog(),
                    );
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help',
                  isActive: false,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const HelpSupportDialog(),
                    );
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isActive: false,
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),

          // Bottom Date Display
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              DateFormat('dd MMMM yyyy').format(DateTime.now()),
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurfaceMuted,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final activeBg = AppColors.primary.withValues(alpha: 0.08);
    final activeFg = AppColors.primary;
    final defaultFg = AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? activeFg : (iconColor ?? AppColors.onSurfaceDim),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: isActive ? activeFg : (textColor ?? defaultFg),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.onSurfaceDim,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isActive
                  ? AppTextStyles.navLabelActive
                  : AppTextStyles.navLabel,
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration:  BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
