import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

extension BuildContextExtensions on BuildContext {
  // Theme shortcut
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Media Query shortcuts
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Viewport padding shortcuts
  EdgeInsets get padding => MediaQuery.of(this).padding;
  double get topPadding => padding.top;
  double get bottomPadding => padding.bottom;

  // Show premium notification SnackBars
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.error : AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? AppColors.error.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
