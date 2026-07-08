import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import 'daily_rates_provider.dart';
import 'daily_rate_prompt_dialog.dart';
import 'staff_provider.dart';
import '../../models/user.dart';

class RateManagementScreen extends ConsumerWidget {
  const RateManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesState = ref.watch(dailyRatesProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding + 8),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child:  Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Rate Management',
                    style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_rounded, color: AppColors.primary),
                  onPressed: () => _showAddRateDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Rates List ──
          Expanded(
            child: ratesState.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No rates history found.',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final rate = list[index];
                    final staffList = ref.watch(staffProvider).value ?? [];
                    final enteredBy = rate.enteredBy;
                    User? matchedStaff;
                    if (enteredBy != null) {
                      for (final s in staffList) {
                        if (s.id == enteredBy ||
                            s.email.toLowerCase() == enteredBy.toLowerCase() ||
                            s.id.replaceAll('-', '') == enteredBy.replaceAll('-', '')) {
                          matchedStaff = s;
                          break;
                        }
                      }
                    }
                    final enteredByName = matchedStaff?.name ?? rate.enteredBy ?? 'System';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        animationIndex: index,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      Formatters.formatDate(rate.date),
                                      style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          useRootNavigator: false,
                                          barrierDismissible: true,
                                          builder: (context) => DailyRatePromptDialog(
                                            isDismissible: true,
                                            initialRate: rate,
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
                                      ),
                                    ),
                                    if (rate.id != null) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: AppColors.surfaceContainer,
                                              title: const Text('Delete Rate'),
                                              content: const Text('Are you sure you want to delete this rate? This cannot be undone.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceDim)),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            try {
                                              await ref.read(dailyRatesProvider.notifier).deleteDailyRate(rate.id!);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Rate deleted successfully!'),
                                                    backgroundColor: AppColors.success,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to delete rate: $e'),
                                                    backgroundColor: AppColors.error,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (rate.enteredBy != null)
                                  Text(
                                    'By: $enteredByName',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _RateItem(
                                    label: 'GOLD 22K',
                                    value: '₹${rate.rateGold22K.toStringAsFixed(0)}/g',
                                  ),
                                ),
                                Container(width: 1, height: 24, color: AppColors.border),
                                Expanded(
                                  child: _RateItem(
                                    label: 'GOLD 18K',
                                    value: '₹${rate.rateGold18K.toStringAsFixed(0)}/g',
                                  ),
                                ),
                                Container(width: 1, height: 24, color: AppColors.border),
                                Expanded(
                                  child: _RateItem(
                                    label: 'SILVER',
                                    value: '₹${rate.rateSilver.toStringAsFixed(1)}/g',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>  Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading rates: $err',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRateDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      builder: (context) => const DailyRatePromptDialog(isDismissible: true),
    );
  }
}

class _RateItem extends StatelessWidget {
  final String label;
  final String value;
  const _RateItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceMuted,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.amountSm.copyWith(
            color: AppColors.onBackground,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
