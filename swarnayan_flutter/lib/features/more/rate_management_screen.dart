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
                const SizedBox(width: 12),
                Text('Rate Management', style: AppTextStyles.titleMd),
                const Spacer(),
                IconButton(
                  icon:  Icon(Icons.add_rounded, color: AppColors.primary),
                  onPressed: () => _showAddRateDialog(context),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 24),

          // Title Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Metal Rates History',
                  style: AppTextStyles.headlineLgMobile,
                ),
                const SizedBox(height: 4),
                Text(
                  'Verify and adjust live selling rates',
                  style: AppTextStyles.sectionSubtitle,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          const SizedBox(height: 20),

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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        padding: const EdgeInsets.all(16),
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
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) => DailyRatePromptDialog(
                                            isDismissible: true,
                                            initialRate: rate,
                                          ),
                                        );
                                      },
                                    ),
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
