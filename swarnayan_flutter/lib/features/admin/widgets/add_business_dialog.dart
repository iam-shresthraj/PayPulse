import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_input.dart';
import '../../more/widgets/more_dialogs.dart';
import '../admin_provider.dart';

class AddBusinessDialog extends ConsumerStatefulWidget {
  const AddBusinessDialog({super.key});

  @override
  ConsumerState<AddBusinessDialog> createState() => _AddBusinessDialogState();
}

class _AddBusinessDialogState extends ConsumerState<AddBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final success = await ref.read(adminProvider.notifier).createBusiness(_nameController.text.trim());
    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Business registered successfully! Codes generated.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(adminProvider).error ?? 'Failed to create business.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogWrapper(
      title: 'Add New Business',
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Create Business',
                  style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold),
                ),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Register a new tenant company in the PayPulse system. This will generate Owner, Manager, and Staff access codes automatically.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 20),
            GlassInput(
              label: 'BUSINESS NAME',
              controller: _nameController,
              hint: 'e.g. Swarnayan Jewellers Branch B',
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a business name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
