import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../more/widgets/more_dialogs.dart';
import '../../auth/auth_provider.dart';
import '../../more/role_permissions_provider.dart';
import '../../../../models/user.dart';
import '../admin_provider.dart';

class UserAccessDialog extends ConsumerStatefulWidget {
  final User user;
  final String companyName;

  const UserAccessDialog({
    super.key,
    required this.user,
    required this.companyName,
  });

  @override
  ConsumerState<UserAccessDialog> createState() => _UserAccessDialogState();
}

class _UserAccessDialogState extends ConsumerState<UserAccessDialog> {
  late String _selectedRole;
  late bool _isActive;
  late String _selectedStatus;
  late Map<String, bool> _accessList;
  String? _selectedCompanyId;
  bool _submitting = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
    _selectedStatus = widget.user.approvalStatus;
    _selectedCompanyId = widget.user.companyId;
    _accessList = {
      'dashboard': widget.user.accessDashboard,
      'invoices': widget.user.accessInvoices,
      'customers': widget.user.accessCustomers,
      'inventory': widget.user.accessInventory,
      'reports': widget.user.accessReports,
      'records': widget.user.accessRecords,
      'rates': widget.user.accessRates,
      'staff': widget.user.accessStaff,
      'settings': widget.user.accessSettings,
      'coupons': widget.user.accessCoupons,
    };
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    final success = await ref.read(adminProvider.notifier).updateUserProfile(
          widget.user.id,
          role: _selectedRole,
          isActive: _isActive,
          approvalStatus: _selectedStatus,
          accessList: _accessList,
          companyId: _selectedCompanyId,
        );
    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        final currentUser = ref.read(authProvider).user;
        if (currentUser != null && currentUser.id == widget.user.id) {
          await ref.read(authProvider.notifier).refreshProfile();
          await ref.read(rolePermissionsProvider.notifier).loadPermissions();
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User profile and permissions updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(adminProvider).error ?? 'Failed to update user.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete User', style: AppTextStyles.titleLg.copyWith(color: AppColors.error)),
        content: Text(
          'Are you sure you want to permanently delete "${widget.user.name}"? This action cannot be undone.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    final success = await ref.read(adminProvider.notifier).deleteUser(widget.user.id);
    if (mounted) {
      setState(() => _deleting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('User deleted successfully.'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(adminProvider).error ?? 'Failed to delete user.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildSwitchTile(String key, String title, String subtitle) {
    return SwitchListTile(
      value: _accessList[key] ?? true,
      onChanged: (val) {
        setState(() {
          _accessList[key] = val;
        });
      },
      title: Text(title, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
      activeColor: AppColors.primary,
      inactiveThumbColor: Colors.grey,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = ['SUPER_ADMIN', 'OWNER', 'MANAGER', 'STAFF'];
    final statuses = ['PENDING', 'APPROVED', 'REJECTED', 'DEASSOCIATED'];
    final adminState = ref.watch(adminProvider);
    final companies = adminState.companies;

    return GlassDialogWrapper(
      title: 'Manage User & Access',
      actions: [
        IconButton(
          onPressed: (_submitting || _deleting) ? null : _deleteUser,
          icon: _deleting
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
        ),
        const Spacer(),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceDim)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _submitting ? null : _save,
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
              : Text('Save Changes', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;
              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Flex(
                  direction: isCompact ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                        style: AppTextStyles.titleLg.copyWith(color: AppColors.primary),
                      ),
                    ),
                    SizedBox(width: isCompact ? 0 : 16, height: isCompact ? 12 : 0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.user.name, style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(widget.user.email, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                          const SizedBox(height: 2),
                          Text(
                            widget.companyName.isNotEmpty ? 'Company: ${widget.companyName}' : 'No Company (Super Admin)',
                            style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Role Selection
          Text('ROLE & STATUS', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 540;
              final roleField = DropdownButtonFormField<String>(
                value: _selectedRole,
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role, style: AppTextStyles.bodyMd),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
                decoration: InputDecoration(
                  labelText: 'User Role',
                  labelStyle: TextStyle(color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );

              final statusField = DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status, style: AppTextStyles.bodyMd),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
                decoration: InputDecoration(
                  labelText: 'Approval Status',
                  labelStyle: TextStyle(color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );

              if (isCompact) {
                return Column(
                  children: [
                    roleField,
                    const SizedBox(height: 16),
                    statusField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: roleField),
                  const SizedBox(width: 16),
                  Expanded(child: statusField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Company Assignment
          Text('COMPANY ASSIGNMENT', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _selectedCompanyId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('— No Company (Super Admin) —'),
              ),
              ...companies.map((company) => DropdownMenuItem<String?>(
                    value: company.id,
                    child: Text('${company.name} (${company.category})'),
                  )),
            ],
            onChanged: (val) => setState(() => _selectedCompanyId = val),
            decoration: InputDecoration(
              labelText: 'Assign to Company',
              labelStyle: TextStyle(color: AppColors.primary),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            dropdownColor: AppColors.surfaceContainer,
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
            title: Text('Account Active', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('Deactivated users cannot log in to the application', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          // Feature Permissions
          Text('FEATURE-WISE ACCESS PERMISSIONS', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _buildSwitchTile('dashboard', 'Dashboard', 'Access home screens, business stats, and charts'),
          _buildSwitchTile('invoices', 'Billing & Invoices', 'Create invoices, calculate payments, and view drafts'),
          _buildSwitchTile('rates', 'Rate Management', 'Update and configure live gold and silver rates'),
          _buildSwitchTile('customers', 'Customers Directory', 'Add and view customers, profiles, and histories'),
          _buildSwitchTile('inventory', 'Inventory Products', 'Manage catalog templates, HUID barcodes, and weights'),
          _buildSwitchTile('reports', 'Reports Engine', 'Generate custom audits, export PDF and Excel sheets'),
          _buildSwitchTile('records', 'Record Book', 'Access active and deleted invoices log'),
          _buildSwitchTile('staff', 'Staff Management', 'Add, edit, approve, and delete staff accounts'),
          _buildSwitchTile('settings', 'Company Settings', 'Edit invoice prefix, financial year, and business codes'),
          _buildSwitchTile('coupons', 'Coupons & Promo', 'Configure and toggle discount codes'),
        ],
      ),
    );
  }
}
