import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/glass_input.dart';
import 'auth_provider.dart';

/// Screen displayed when a user has been deassociated/removed from their company.
class DeassociatedScreen extends ConsumerStatefulWidget {
  const DeassociatedScreen({super.key});

  @override
  ConsumerState<DeassociatedScreen> createState() => _DeassociatedScreenState();
}

class _DeassociatedScreenState extends ConsumerState<DeassociatedScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final success = await ref
          .read(authProvider.notifier)
          .reassociateCompany(_codeController.text.trim());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully requested to join company!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join company: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showEnterCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Enter Company Code', style: AppTextStyles.titleLg.copyWith(color: AppColors.primary)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the 8-character access code provided by your owner or manager.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 16),
              GlassInput(
                controller: _codeController,
                label: 'Access Code',
                hint: '8 characters',
                validator: (v) {
                  final code = v?.trim() ?? '';
                  if (code.isEmpty) return 'Code is required';
                  if (code.length != 8) return 'Code must be exactly 8 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          StatefulBuilder(
            builder: (context, setDlgState) {
              return TextButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        await _submitCode();
                        if (mounted) Navigator.pop(ctx);
                      },
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Submit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark/black page
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F), // Premium dark glass feel
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PayPulse Header/Logo
                Text(
                  'PAYPULSE',
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'BILLING & INVENTORY SYSTEM',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Account Deassociated',
                  style: AppTextStyles.titleLg.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your account is currently not associated with any business. '
                  'If you have a company and wants to use PayPulse for management, please contact our team:',
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'contact.shresthraj@gmail.com',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: 'Enter Company Code',
                  onPressed: _showEnterCodeDialog,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                  child: Text(
                    'Sign out',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
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
