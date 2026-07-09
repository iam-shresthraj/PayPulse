import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/utils/pdf_helper.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../billing/invoices_provider.dart';
import '../customers/customers_provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../billing/billing_provider.dart';
import 'company_provider.dart';
import '../../core/widgets/skeleton_widgets.dart';

class RecordBookScreen extends ConsumerStatefulWidget {
  const RecordBookScreen({super.key});

  @override
  ConsumerState<RecordBookScreen> createState() => _RecordBookScreenState();
}

class _RecordBookScreenState extends ConsumerState<RecordBookScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, PAID, PARTIAL, CANCELLED

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _printInvoice(Invoice invoice) {
    final customers = ref.read(customersProvider).value ?? [];
    final customerIndex = customers.indexWhere((c) => c.id == invoice.customerId);
    final Customer customer;
    if (customerIndex != -1) {
      customer = customers[customerIndex];
    } else {
      customer = Customer(
        id: '',
        name: invoice.tempCustomerName ?? 'Customer',
        mobile: invoice.tempCustomerMobile ?? '',
        address: invoice.tempCustomerAddress ?? '',
        totalPurchaseAmount: 0.0,
        totalInvoices: 0,
      );
    }
    final company = ref.read(companyProvider).value;
    PdfHelper.generateAndPrintInvoice(
      invoice: invoice,
      customer: customer,
      company: company,
    );
  }

  void _cancelInvoice(Invoice invoice) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side:  BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Cancel Invoice',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.error),
          ),
          content: Text(
            'Are you sure you want to cancel invoice "${invoice.invoiceNumber}"? This will restore product stock levels and deduct total purchases from the client profile.',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (invoice.id != null) {
                  await ref.read(invoicesProvider.notifier).cancelInvoice(invoice.id!);
                }
              },
              child: Text('Cancel Invoice', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteInvoice(Invoice invoice) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side:  BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Delete Invoice',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.error),
          ),
           content: Text(
            'Are you sure you want to delete invoice "${invoice.invoiceNumber}"? You can recycle it for 24 hours or permanently delete it now.',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (invoice.id != null) {
                  try {
                    await ref.read(invoicesProvider.notifier).deleteInvoicePermanently(invoice.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text('Invoice deleted permanently.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to permanently delete invoice: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text('Delete Permanently', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                if (invoice.id != null) {
                  try {
                    await ref.read(invoicesProvider.notifier).deleteInvoice(invoice.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text('Invoice moved to bin. You can restore it from the DELETED tab within 24 hours.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete invoice: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Delete (24h Recycle)'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestoreInvoice(Invoice invoice) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side:  BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Restore Invoice',
            style: AppTextStyles.titleLg.copyWith(color: AppColors.success),
          ),
          content: Text(
            'Are you sure you want to restore invoice "${invoice.invoiceNumber}"? This will restore it to the active register and re-adjust stock levels.',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (invoice.id != null) {
                  try {
                    await ref.read(invoicesProvider.notifier).restoreInvoice(invoice.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text('Invoice restored successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to restore invoice: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text('Restore', style: AppTextStyles.bodyMd.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesState = ref.watch(invoicesProvider);
    final customersState = ref.watch(customersProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding > 0 ? topPadding + 20 : 20),

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
                    'Sales Invoice Register',
                    style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // ── Search & Filter ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchBarWidget(
              controller: _searchController,
              hint: 'Search by Invoice No, Customer ID...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

          const SizedBox(height: 12),

          // Filter Chips
          _buildFilterChips(),

          const SizedBox(height: 16),

          // ── Table/List Invoices ──
          Expanded(
            child: _selectedFilter == 'DELETED'
                ? ref.watch(deletedInvoicesProvider).when(
                    data: (deletedList) {
                      if (customersState is! AsyncData) {
                        return const SkeletonList(type: SkeletonType.invoice, count: 5, padding: EdgeInsets.zero);

                      }
                      final customers = customersState.value!;

                      // Filter deleted invoices
                      final filtered = deletedList.where((inv) {
                        if (_searchQuery.isNotEmpty) {
                          final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
                          final customerName = customerIndex != -1 ? customers[customerIndex].name.toLowerCase() : '';
                          final invNum = (inv.invoiceNumber ?? '').toLowerCase();
                          final idMatch = (inv.customerId ?? '').toLowerCase().contains(_searchQuery);
                          return invNum.contains(_searchQuery) || customerName.contains(_searchQuery) || idMatch;
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(deletedInvoicesProvider);
                          },
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.5,
                              alignment: Alignment.center,
                              child: Text(
                                'No deleted invoices.',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(deletedInvoicesProvider);
                        },
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final inv = filtered[index];
                            final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
                            final customerName = customerIndex != -1 ? customers[customerIndex].name : 'Unknown';

                            // Calculate remaining minutes from deletedAt (24 hours)
                            final deletedAt = inv.deletedAt ?? inv.invoiceDate;
                            final diff = DateTime.now().difference(deletedAt);
                            final remainingMins = 24 * 60 - diff.inMinutes;
                            final remainingHours = (remainingMins / 60).ceil();
                            final countdownText = remainingMins > 0 ? 'Purges in ${remainingHours}h' : 'Purging soon';

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
                                        Text(
                                          inv.invoiceNumber ?? 'INV-${inv.invoiceDate.millisecondsSinceEpoch}',
                                          style: AppTextStyles.cardTitle,
                                        ),
                                        const StatusBadge(status: 'CANCELLED'),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Client: $customerName (${inv.items.length} items)',
                                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Deleted: ${Formatters.formatDateTime(deletedAt)}',
                                          style: AppTextStyles.cardSubtitle,
                                        ),
                                        Text(
                                          countdownText,
                                          style: AppTextStyles.labelSm.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'TOTAL: ₹${Formatters.formatCurrency(inv.finalPayable).replaceFirst('₹', '')}',
                                          style: AppTextStyles.amountSm.copyWith(color: AppColors.primary),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.restore_rounded, color: AppColors.success, size: 22),
                                              onPressed: () => _confirmRestoreInvoice(inv),
                                              tooltip: 'Restore Invoice',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22),
                                              onPressed: () => _confirmDeleteInvoice(inv),
                                              tooltip: 'Delete Permanently',
                                            ),
                                          ],
                                        ),
                                      ],
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
                      type: SkeletonType.invoice,
                      count: 6,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    error: (err, _) => Center(child: Text('Error loading deleted: $err', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))),
                  )
                : invoicesState.when(
                    data: (invoicesList) {
                      if (customersState is! AsyncData) {
                        return  Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final customers = customersState.value!;

                      // Apply Filters
                      var filtered = invoicesList.where((inv) {
                        // Status filter
                        if (_selectedFilter != 'ALL') {
                          if (_selectedFilter == 'PAID' && (inv.status == 'CANCELLED' || inv.balanceDue > 0.05)) return false;
                          if (_selectedFilter == 'PARTIAL' && (inv.status == 'CANCELLED' || inv.balanceDue <= 0.05)) return false;
                          if (_selectedFilter == 'CANCELLED' && inv.status != 'CANCELLED') return false;
                        }

                        // Search query
                        if (_searchQuery.isNotEmpty) {
                          final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
                          final customerName = customerIndex != -1 ? customers[customerIndex].name.toLowerCase() : '';
                          final invNum = (inv.invoiceNumber ?? '').toLowerCase();
                          final idMatch = (inv.customerId ?? '').toLowerCase().contains(_searchQuery);

                          return invNum.contains(_searchQuery) || customerName.contains(_searchQuery) || idMatch;
                        }

                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(invoicesProvider.notifier).loadInvoices();
                          },
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.5,
                              alignment: Alignment.center,
                              child: Text(
                                'No invoices found matching criteria.',
                                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(invoicesProvider.notifier).loadInvoices();
                        },
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final inv = filtered[index];
                            final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
                            final customerName = customerIndex != -1 ? customers[customerIndex].name : 'Unknown';

                            final String badgeStatus = inv.status == 'CANCELLED'
                                ? 'CANCELLED'
                                : inv.balanceDue <= 0
                                    ? 'PAID'
                                    : 'PARTIAL';

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
                                        Text(
                                          inv.invoiceNumber ?? 'INV-${inv.invoiceDate.millisecondsSinceEpoch}',
                                          style: AppTextStyles.cardTitle,
                                        ),
                                        StatusBadge(status: badgeStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
                                          onPressed: () {
                                            final customers = ref.read(customersProvider).value ?? [];
                                            final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
                                            final customer = customerIndex != -1 
                                                ? customers[customerIndex] 
                                                : Customer(
                                                    name: inv.tempCustomerName ?? 'Customer',
                                                    mobile: inv.tempCustomerMobile ?? '',
                                                    address: inv.tempCustomerAddress ?? '',
                                                  );
                                            ref.read(billingProvider.notifier).loadInvoiceToEdit(inv, customer);
                                            context.go('/billing');
                                          },
                                          tooltip: 'Edit Invoice',
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Client: $customerName (${inv.items.length} items)',
                                          style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Date: ${Formatters.formatDateTime(inv.invoiceDate)}',
                                      style: AppTextStyles.cardSubtitle,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'TOTAL: ₹${Formatters.formatCurrency(inv.finalPayable).replaceFirst('₹', '')}',
                                              style: AppTextStyles.amountSm.copyWith(color: AppColors.primary),
                                            ),
                                            if (inv.balanceDue > 0.05 && inv.status != 'CANCELLED')
                                              Text(
                                                'DUE: ₹${Formatters.formatCurrency(inv.balanceDue).replaceFirst('₹', '')}',
                                                style: AppTextStyles.labelSm.copyWith(color: AppColors.error, fontSize: 10),
                                              ),
                                          ],
                                        ),
                                        Row(
                                            children: [
                                              IconButton(
                                                icon:  Icon(Icons.print_rounded, color: AppColors.primary, size: 20),
                                                onPressed: () => _printInvoice(inv),
                                                tooltip: 'Print PDF',
                                              ),
                                              IconButton(
                                                icon:  Icon(Icons.chat_bubble_outline_rounded, color: AppColors.success, size: 20),
                                                onPressed: () async {
                                                  final customer = customerIndex != -1 
                                                      ? customers[customerIndex] 
                                                      : Customer(
                                                          name: inv.tempCustomerName ?? 'Customer',
                                                          mobile: inv.tempCustomerMobile ?? '',
                                                          address: inv.tempCustomerAddress ?? '',
                                                        );
                                                  final company = ref.read(companyProvider).value;
                                                  await WhatsAppHelper.shareInvoice(
                                                    invoice: inv,
                                                    customer: customer,
                                                    company: company,
                                                  );
                                                },
                                                tooltip: 'Share on WhatsApp',
                                              ),
                                              const SizedBox(width: 8),
                                            IconButton(
                                              icon:  Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                              onPressed: () => _confirmDeleteInvoice(inv),
                                            ),
                                          ],
                                        ),
                                      ],
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
                      type: SkeletonType.invoice,
                      count: 6,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    error: (err, _) => Center(child: Text('Error loading register: $err', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['ALL', 'PAID', 'PARTIAL', 'DELETED'];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSel = f == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.glassBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: isSel ? AppColors.primary : AppColors.glassBorder),
              ),
              child: Text(
                f,
                style: AppTextStyles.labelSm.copyWith(
                  color: isSel ? Colors.black : AppColors.onSurfaceMuted,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
