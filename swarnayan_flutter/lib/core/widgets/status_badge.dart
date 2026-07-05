import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Status badge pill (PAID, PARTIAL, PENDING) as seen in invoice list items.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 6.0,
  });

  Color get _backgroundColor {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.paid.withValues(alpha: 0.2);
      case 'PARTIAL':
        return AppColors.partial.withValues(alpha: 0.2);
      case 'PENDING':
      case 'DUE':
        return AppColors.pending.withValues(alpha: 0.2);
      case 'CANCELLED':
        return AppColors.error.withValues(alpha: 0.2);
      default:
        return AppColors.onSurfaceMuted.withValues(alpha: 0.2);
    }
  }

  Color get _textColor {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.paid;
      case 'PARTIAL':
        return AppColors.partial;
      case 'PENDING':
      case 'DUE':
        return AppColors.pending;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.onSurfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.0),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _textColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          color: _textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
