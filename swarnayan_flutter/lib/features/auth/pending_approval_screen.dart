import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_provider.dart';

/// Blocking screen shown after signup until a manager/owner approves access.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _checking = false;
  DateTime? _lastBackPressTime;

  Future<void> _refresh() async {
    setState(() => _checking = true);
    await ref.read(authProvider.notifier).refreshProfile();
    if (mounted) {
      setState(() => _checking = false);
      final auth = ref.read(authProvider);
      if (auth.user?.isApproved == true) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Still waiting for approval.'),
            backgroundColor: AppColors.surfaceContainer,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final role = (auth.user?.role ?? 'STAFF').toUpperCase();
    final approver = role == 'STAFF' ? 'a manager or the owner' : 'the owner';

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
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.warning, width: 2),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.warning,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Waiting for Approval',
                  style: AppTextStyles.titleLg,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your ${role.toLowerCase()} account was created successfully. '
                  'For security, $approver must approve your access before you '
                  'can use the app.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Check Approval Status',
                  isLoading: _checking,
                  onPressed: _refresh,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                  child: Text(
                    'Sign out',
                    style:
                        AppTextStyles.bodyMd.copyWith(color: AppColors.error),
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
