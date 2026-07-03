import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../more/daily_rates_provider.dart';
import '../more/daily_rate_prompt_dialog.dart';

/// Main application shell with a floating glassmorphism bottom navigation bar.
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
                decoration: const BoxDecoration(
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
