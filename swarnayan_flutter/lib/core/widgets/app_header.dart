import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Unified header widget used across all tab screens.
/// Matches the approved home dashboard header:
/// Avatar circle → time-aware greeting → "Swarnayan Jewellers" → Current Date.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              ),
            ),
            child: const Icon(Icons.person, color: AppColors.onSurfaceMuted, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Swarnayan Jewellers',
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms);
  }
}
