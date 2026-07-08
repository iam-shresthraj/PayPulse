import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'auth_provider.dart';
import '../admin/platform_settings_provider.dart';

class ExpiredScreen extends ConsumerStatefulWidget {
  const ExpiredScreen({super.key});

  @override
  ConsumerState<ExpiredScreen> createState() => _ExpiredScreenState();
}

class _ExpiredScreenState extends ConsumerState<ExpiredScreen> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final platformSettings = ref.watch(platformSettingsProvider).value;
    final contactEmail = platformSettings?.contactEmail ?? 'contact.shresthraj@gmail.com';
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit PayPulse'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.error, width: 2),
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Access Expired',
                    style: AppTextStyles.titleLg.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your business subscription for PayPulse has expired.\n\n'
                    'All features and data access have been temporarily revoked. '
                    'Please contact the platform administrator to renew your access.',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    contactEmail,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                    },
                    icon: Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                    label: Text(
                      'Sign out',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
