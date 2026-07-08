import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_input.dart';
import '../../../../core/widgets/glass_dropdown.dart';
import '../../more/widgets/more_dialogs.dart';
import '../admin_provider.dart';

class SendNotificationDialog extends ConsumerStatefulWidget {
  const SendNotificationDialog({super.key});

  @override
  ConsumerState<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends ConsumerState<SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _fileUrlController = TextEditingController();
  
  String? _targetCompanyId; // null = All Businesses
  String _targetRole = 'ALL'; // ALL, OWNER, MANAGER, STAFF
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    final success = await ref.read(adminProvider.notifier).sendNotification(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      fileUrl: _fileUrlController.text.trim().isNotEmpty ? _fileUrlController.text.trim() : null,
      targetCompanyId: _targetCompanyId,
      targetRole: _targetRole,
    );
    
    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Broadcast notification sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(adminProvider).error ?? 'Failed to send broadcast.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return GlassDialogWrapper(
      title: 'Send Notification / Broadcast',
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
                  'Send Broadcast',
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
              'Broadcast an alert or announcement to businesses and employees in the PayPulse system.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 20),
            
            // Title
            GlassInput(
              controller: _titleController,
              label: 'Title',
              hint: 'e.g. System Maintenance Notice',
              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            
            // Body
            GlassInput(
              controller: _bodyController,
              label: 'Message Body',
              hint: 'Enter notification message details...',
              maxLines: 4,
              validator: (v) => v == null || v.isEmpty ? 'Message body is required' : null,
            ),
            const SizedBox(height: 16),

            // Attachment URL (Optional)
            GlassInput(
              controller: _fileUrlController,
              label: 'Attachment / Learn More URL (Optional)',
              hint: 'https://example.com/details',
            ),
            const SizedBox(height: 16),
            
            // Target Business Dropdown
            GlassDropdown<String?>(
              label: 'Target Business / Company',
              value: _targetCompanyId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Businesses'),
                ),
                ...adminState.companies.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (val) => setState(() => _targetCompanyId = val),
            ),
            const SizedBox(height: 16),

            // Target Role Dropdown
            GlassDropdown<String>(
              label: 'Target User Roles',
              value: _targetRole,
              items: const [
                DropdownMenuItem<String>(
                  value: 'ALL',
                  child: Text('All Users'),
                ),
                DropdownMenuItem<String>(
                  value: 'OWNER',
                  child: Text('Owners Only'),
                ),
                DropdownMenuItem<String>(
                  value: 'MANAGER',
                  child: Text('Managers Only'),
                ),
                DropdownMenuItem<String>(
                  value: 'STAFF',
                  child: Text('Staff Only'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _targetRole = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
