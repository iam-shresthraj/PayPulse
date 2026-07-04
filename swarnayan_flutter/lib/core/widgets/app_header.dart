import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_provider.dart';

/// Unified header widget used across all tab screens.
/// Displays logo at top left and date at top right on mobile, and hides on desktop.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 850;
    if (isWide) {
      return const SizedBox.shrink();
    }

    final themeOverride = ref.watch(themeModeProvider);
    final isLight = themeOverride ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            isLight
                ? 'assets/images/paypulse2.png'
                : 'assets/images/paypulse1.png',
            height: 24,
            fit: BoxFit.contain,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surfaceContainer.withValues(alpha: 0.5),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(
              DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
