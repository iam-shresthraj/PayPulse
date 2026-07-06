import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/auth_provider.dart';
import '../staff_provider.dart';
import '../team_provider.dart';
import 'more_dialogs.dart';

// -----------------------------------------------------------
// Company Codes Dialog — role-based visibility (server enforced)
// -----------------------------------------------------------
class CompanyCodesDialog extends ConsumerWidget {
  const CompanyCodesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codesState = ref.watch(companyCodesProvider);
    final user = ref.watch(authProvider).user;

    return GlassDialogWrapper(
      title: 'Company Codes',
      child: codesState.when(
        data: (codes) {
          if (codes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No codes are visible for your access level.',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share these codes carefully — each code grants the matching '
                'access level when a new account is created.',
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 16),
              if (codes.staffCode != null)
                _CodeTile(
                  label: 'Staff Code',
                  code: codes.staffCode!,
                  icon: Icons.badge_outlined,
                  description: 'Invoicing, rates, customers & products',
                ),
              if (codes.managerCode != null)
                _CodeTile(
                  label: 'Manager Code',
                  code: codes.managerCode!,
                  icon: Icons.supervisor_account_outlined,
                  description: 'Staff access + invoice edits, reports, team',
                ),
              if (codes.ownerCode != null)
                _CodeTile(
                  label: 'Owner Code',
                  code: codes.ownerCode!,
                  icon: Icons.workspace_premium_outlined,
                  description: 'Full access including company details',
                ),
              if (user != null && user.isManager && !user.isOwner) ...[
                const SizedBox(height: 8),
                Text(
                  'Manager and owner codes are only visible to the owner.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.onSurfaceDim, fontSize: 10),
                ),
              ],
            ],
          );
        },
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, _) => Text(
          'Could not load codes: $err',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  final String label;
  final String code;
  final IconData icon;
  final String description;

  const _CodeTile({
    required this.label,
    required this.code,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(description, style: AppTextStyles.cardSubtitle),
                  const SizedBox(height: 6),
                  Text(
                    code,
                    style: AppTextStyles.amountMd.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy_rounded,
                  color: AppColors.onSurfaceMuted, size: 18),
              tooltip: 'Copy code',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied to clipboard'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Pending Approvals Dialog — manager approves staff, owner approves all
// -----------------------------------------------------------
class PendingApprovalsDialog extends ConsumerStatefulWidget {
  const PendingApprovalsDialog({super.key});

  @override
  ConsumerState<PendingApprovalsDialog> createState() =>
      _PendingApprovalsDialogState();
}

class _PendingApprovalsDialogState
    extends ConsumerState<PendingApprovalsDialog> {
  String? _busyId;

  Future<void> _review(PendingMember member, bool approve) async {
    setState(() => _busyId = member.id);
    try {
      await reviewMember(member.id, approve);
      ref.invalidate(pendingMembersProvider);
      ref.read(staffProvider.notifier).loadStaff();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? '${member.name} approved as ${_roleLabel(member.role)}.'
                : '${member.name}\'s request was rejected.'),
            backgroundColor: approve ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return 'Owner';
      case 'MANAGER':
        return 'Manager';
      default:
        return 'Staff';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingMembersProvider);

    return GlassDialogWrapper(
      title: 'Pending Approvals',
      child: pendingState.when(
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No access requests waiting for approval.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceMuted),
                ),
              ),
            );
          }
          return Column(
            children: list.map((member) {
              final busy = _busyId == member.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name,
                                    style: AppTextStyles.cardTitle),
                                const SizedBox(height: 2),
                                Text(member.email,
                                    style: AppTextStyles.cardSubtitle),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _roleLabel(member.role).toUpperCase(),
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (member.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Requested: ${DateFormat('dd MMM yyyy, hh:mm a').format(member.createdAt!.toLocal())}',
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.onSurfaceDim),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed:
                                  busy ? null : () => _review(member, false),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed:
                                  busy ? null : () => _review(member, true),
                              child: busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, _) => Text(
          'Could not load approvals: $err',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
