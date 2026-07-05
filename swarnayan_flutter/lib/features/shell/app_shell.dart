import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../more/daily_rates_provider.dart';
import '../more/daily_rate_prompt_dialog.dart';
import '../more/widgets/more_dialogs.dart';
import '../auth/auth_provider.dart';
import '../more/role_permissions_provider.dart';

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
    if (location.startsWith('/more/rates')) return 7;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/reports')) return 4;
    if (location.contains('/records')) return 5;
    if (location.startsWith('/more')) return 6;
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
        context.go('/reports');
        break;
      case 5:
        context.go('/more/records');
        break;
      case 6:
        context.go('/more');
        break;
      case 7:
        context.go('/more/rates');
        break;
    }
  }

  int _bottomBarIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/billing')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/reports') || location.contains('/records') || location.startsWith('/more')) return 4;
    return 0;
  }

  void _onBottomBarTap(BuildContext context, int index) {
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

    final bottomIndex = _bottomBarIndex(context);
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
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          int selectedTab = -1;
          if (bottomIndex == 0) selectedTab = 0;
          if (bottomIndex == 4) selectedTab = 1;
          final isBillingActive = bottomIndex == 1;

          Widget buildCapsuleContent() {
            if (isBillingActive) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _onBottomBarTap(context, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.home_outlined, 
                        color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5), 
                        size: 22,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onBottomBarTap(context, 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.menu_rounded, 
                        color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5), 
                        size: 22,
                      ),
                    ),
                  ),
                ],
              );
            }

            if (selectedTab == 0) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _onBottomBarTap(context, 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Icon(
                        Icons.menu_rounded, 
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4), 
                        size: 22,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                GestureDetector(
                  onTap: () => _onBottomBarTap(context, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Icon(
                      Icons.home_outlined, 
                      color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4), 
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'More',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          Widget buildAddButton() {
            final buttonWidget = Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(29),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: isBillingActive
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Invoice',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            );

            final buttonGesture = GestureDetector(
              onTap: () => _onBottomBarTap(context, 1),
              child: buttonWidget,
            );

            return isBillingActive
                ? Expanded(child: buttonGesture)
                : SizedBox(width: 75, child: buttonGesture);
          }

          return Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomPadding + 12,
            ),
            child: Row(
              children: [
                if (isBillingActive)
                  SizedBox(
                    width: 110,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      clipBehavior: Clip.antiAlias,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.12) 
                                  : Colors.white.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: buildCapsuleContent(),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      clipBehavior: Clip.antiAlias,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.12) 
                                  : Colors.white.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: buildCapsuleContent(),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                buildAddButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final themeOverride = ref.watch(themeModeProvider);
    final isLight = themeOverride ?? (MediaQuery.of(context).size.width >= 850);

    final user = ref.watch(authProvider).user;
    final rolePermissions = ref.watch(rolePermissionsProvider).value ?? {};
    final canManage = user?.canManage ?? false;
    final isOwner = user?.isOwner ?? false;

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
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  isLight
                      ? 'assets/images/paypulse2.png'
                      : 'assets/images/paypulse1.png',
                  height: 36,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()).toUpperCase(),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceMuted,
                    letterSpacing: 1.2,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
                if (user?.hasAccess('dashboard', rolePermissions) ?? true)
                  _buildSidebarItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: currentIndex == 0,
                    onTap: () => _onTap(context, 0),
                  ),
                if (user?.hasAccess('invoices', rolePermissions) ?? true)
                  _buildSidebarItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Invoice',
                    isActive: currentIndex == 1,
                    onTap: () => _onTap(context, 1),
                  ),
                if (user?.hasAccess('rates', rolePermissions) ?? true)
                  _buildSidebarItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Rate Management',
                    isActive: currentIndex == 7,
                    onTap: () => _onTap(context, 7),
                  ),
                if (user?.hasAccess('customers', rolePermissions) ?? true)
                  _buildSidebarItem(
                    icon: Icons.people_alt_rounded,
                    label: 'Customers',
                    isActive: currentIndex == 2,
                    onTap: () => _onTap(context, 2),
                  ),
                if (user?.hasAccess('inventory', rolePermissions) ?? true)
                  _buildSidebarItem(
                    icon: Icons.diamond_rounded,
                    label: 'Products',
                    isActive: currentIndex == 3,
                    onTap: () => _onTap(context, 3),
                  ),
                if (canManage && (user?.hasAccess('reports', rolePermissions) ?? true))
                  _buildSidebarItem(
                    icon: Icons.analytics_rounded,
                    label: 'Reports',
                    isActive: currentIndex == 4,
                    onTap: () => _onTap(context, 4),
                  ),
                if (user?.hasAccess('records', rolePermissions) ?? true)
                  _buildSidebarItem(
                    icon: Icons.book_rounded,
                    label: 'Record Book',
                    isActive: currentIndex == 5,
                    onTap: () => _onTap(context, 5),
                  ),
                if (user?.hasAccess('staff', rolePermissions) ?? true)
                  _buildSidebarItem(
                    icon: Icons.folder_shared_rounded,
                    label: 'Managements',
                    isActive: currentIndex == 6,
                    onTap: () => _onTap(context, 6),
                  ),
                const SizedBox(height: 16),
                _buildSidebarHeader('GENERAL'),
                _buildSidebarItem(
                  icon: isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  label: isLight ? 'Dark Mode' : 'Light Mode',
                  isActive: false,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).toggleTheme(isLight);
                  },
                ),
                if (isOwner)
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
