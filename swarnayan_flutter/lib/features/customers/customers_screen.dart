import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/search_bar_widget.dart';

import 'customers_provider.dart';
import '../../core/widgets/skeleton_widgets.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}


class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding + 8),

          // ── Top Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/more');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Customer Directory',
                    style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchBarWidget(
              controller: _searchController,
              hint: 'Search by name, phone, or client ID..',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

          const SizedBox(height: 20),

          // ── Customer List ──
          Expanded(
            child: customersState.when(
              data: (list) {
                final filtered = list.where((c) {
                  final nameMatch = c.name.toLowerCase().contains(_searchQuery);
                  final phoneMatch = c.mobile.contains(_searchQuery);
                  final idMatch = (c.id ?? '').toLowerCase().contains(_searchQuery);
                  final pincodeMatch = (c.pincode ?? '').toLowerCase().contains(_searchQuery);
                  return nameMatch || phoneMatch || idMatch || pincodeMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(customersProvider.notifier).loadCustomers();
                    },
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: Text(
                          _searchQuery.isEmpty ? 'No customers found.' : 'No matching customers.',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(customersProvider.notifier).loadCustomers();
                  },
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        animationIndex: index + 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        onTap: () => context.push('/customers/${customer.id}'),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.12),
                              ),
                              child: Center(
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                  style: AppTextStyles.titleSm.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: AppTextStyles.cardTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: [
                                      Text(
                                        customer.mobile,
                                        style: AppTextStyles.cardSubtitle,
                                      ),
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      Text(
                                        _getMemberDurationTag(customer.createdAt),
                                        style: AppTextStyles.labelSm.copyWith(
                                          color: _getDurationColor(customer.createdAt),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${_formatCompact(customer.totalPurchaseAmount)}',
                                  style: AppTextStyles.amountSm.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.onSurfaceDim,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
              loading: () => const SkeletonList(
                type: SkeletonType.customer,
                count: 7,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              ),
              error: (err, _) => Center(
                child: Text('Error loading customers: $err', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          onPressed: () => context.push('/customers/add'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.person_add_rounded, color: Colors.black),
        ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 400.ms,
              delay: 300.ms,
              curve: Curves.elasticOut,
            ),
      ),
    );
  }



  String _getMemberDurationTag(DateTime? createdAt) {
    if (createdAt == null) return 'Member';
    final now = DateTime.now();
    int months = (now.year - createdAt.year) * 12 + now.month - createdAt.month;
    if (months <= 0) {
      return 'Member since this month';
    } else if (months < 12) {
      return 'Member since $months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (months / 12).floor();
      final remaining = months % 12;
      if (remaining == 0) {
        return 'Member since $years ${years == 1 ? 'year' : 'years'}';
      } else {
        return 'Member since $years ${years == 1 ? 'year' : 'years'}, $remaining ${remaining == 1 ? 'month' : 'months'}';
      }
    }
  }

  Color _getDurationColor(DateTime? createdAt) {
    if (createdAt == null) return AppColors.tierBronze;
    final now = DateTime.now();
    int months = (now.year - createdAt.year) * 12 + now.month - createdAt.month;
    if (months >= 12) {
      return AppColors.tierGold;
    } else if (months >= 3) {
      return AppColors.tierSilver;
    } else {
      return AppColors.tierBronze;
    }
  }

  String _formatCompact(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
