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
    ScaffoldMessenger.of(this).clearMaterialBanners();
    ScaffoldMessenger.of(this).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        backgroundColor: AppColors.surfaceContainer,
        actions: [
          IconButton(
            icon:  Icon(Icons.close, color: AppColors.onSurfaceMuted, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(this).clearMaterialBanners();
            },
          ),
        ],
      ),
    );
    final messenger = ScaffoldMessenger.of(this);
    Future.delayed(const Duration(seconds: 3), () {
      messenger.clearMaterialBanners();
    });
  }
}
