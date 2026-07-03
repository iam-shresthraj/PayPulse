import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/utils/formatters.dart';
import 'customers_provider.dart';
import '../billing/invoices_provider.dart';
import 'package:go_router/go_router.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);
    final invoicesState = ref.watch(invoicesProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: customersState.when(
        data: (customers) {
          final customerIndex = customers.indexWhere((c) => c.id == customerId);
          if (customerIndex == -1) {
            return Center(
              child: Text(
                'Customer not found',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
              ),
            );
          }

          final customer = customers[customerIndex];
          final hasLocation = (customer.city != null && customer.city!.isNotEmpty) ||
              (customer.state != null && customer.state!.isNotEmpty) ||
              (customer.pincode != null && customer.pincode!.isNotEmpty);

          return invoicesState.when(
            data: (invoices) {
              // Filter active invoices for this customer
              final clientInvoices = invoices
                  .where((inv) => inv.customerId == customerId && inv.status != 'CANCELLED')
                  .toList();

              // Dynamic calculations
              final double dynamicTotalSpend = clientInvoices.fold(0, (sum, inv) => sum + inv.finalPayable);
              final int dynamicInvoicesCount = clientInvoices.length;
              final String lastVisit = clientInvoices.isNotEmpty
                  ? _formatRelativeDate(clientInvoices.first.invoiceDate)
                  : 'No visits';

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topPadding + 8),

                    // ── Back + Title + Delete ──
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
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.onSurface,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Customer Profile', style: AppTextStyles.titleMd),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                            onPressed: () {
                              context.push('/customers/edit', extra: customer);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            onPressed: () => _confirmDelete(context, ref, customer.name),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 24),

                    // ── Profile Card ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        animationIndex: 0,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.15),
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                  style: AppTextStyles.headlineLg.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(customer.name, style: AppTextStyles.titleLg),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded, color: _getDurationColor(customer.createdAt), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _getMemberDurationTag(customer.createdAt),
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: _getDurationColor(customer.createdAt),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              customer.mobile,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            if (customer.email != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                customer.email!,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.onSurfaceDim,
                                ),
                              ),
                            ],
                            if (customer.address != null) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  customer.address!,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            if (hasLocation) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '${customer.city ?? ''}${customer.city != null && customer.city!.isNotEmpty && customer.state != null && customer.state!.isNotEmpty ? ', ' : ''}${customer.state ?? ''}${customer.pincode != null && customer.pincode!.isNotEmpty ? ' - ${customer.pincode}' : ''}',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            if (customer.panCard != null && customer.panCard!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDim,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'PAN: ${customer.panCard!}',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onBackground,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            if (customer.gstNumber != null && customer.gstNumber!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDim,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'GSTIN: ${customer.gstNumber!}',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onBackground,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Stats Row ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _StatTile('Total Spend', '₹${_formatCompact(dynamicTotalSpend)}', 1),
                          const SizedBox(width: 12),
                          _StatTile('Invoices', '$dynamicInvoicesCount', 2),
                          const SizedBox(width: 12),
                          _StatTile('Last Visit', lastVisit, 3),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Purchase History ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Purchase History', style: AppTextStyles.sectionTitle),
                    ).animate().fadeIn(duration: 300.ms, delay: 300.ms),

                    const SizedBox(height: 12),

                    if (clientInvoices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: GlassCard(
                          animationIndex: 4,
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No invoices recorded yet.',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                            ),
                          ),
                        ),
                      )
                    else
                      ...clientInvoices.asMap().entries.map((entry) {
                        final i = entry.key;
                        final inv = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(
                            bottom: 10,
                          ),
                          child: GlassCard(
                            animationIndex: 4 + i,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inv.invoiceNumber ?? 'INV-${inv.invoiceDate.millisecondsSinceEpoch}', style: AppTextStyles.cardTitle),
                                      const SizedBox(height: 2),
                                      Text(Formatters.formatDate(inv.invoiceDate), style: AppTextStyles.cardSubtitle),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${Formatters.formatCurrency(inv.finalPayable).replaceFirst('₹', '')}', style: AppTextStyles.amountMd),
                                    const SizedBox(height: 4),
                                    StatusBadge(status: inv.balanceDue <= 0 ? 'PAID' : 'PARTIAL'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Error loading invoices: $err', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading customers: $err', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String name) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Delete Customer',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.error),
          ),
          content: Text(
            'Are you sure you want to delete customer "$name"? This action cannot be undone.',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to list
                await ref.read(customersProvider.notifier).deleteCustomer(customerId);
              },
              child: Text('Delete', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
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

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '$difference days ago';
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final int animIndex;

  const _StatTile(this.label, this.value, this.animIndex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        animationIndex: animIndex,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.amountMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
