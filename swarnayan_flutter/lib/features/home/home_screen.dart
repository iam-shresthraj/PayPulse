import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/app_header.dart';
import '../billing/invoices_provider.dart';
import '../billing/billing_provider.dart';
import '../customers/customers_provider.dart';
import '../more/daily_rates_provider.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/daily_rate.dart';
import '../../core/utils/pdf_helper.dart';
import '../more/company_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesState = ref.watch(invoicesProvider);
    final customersState = ref.watch(customersProvider);
    final ratesState = ref.watch(dailyRatesProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: invoicesState.when(
        data: (invoicesList) {
          final activeInvoices = invoicesList.where((i) => i.status != 'CANCELLED').toList();

          // ── Calculate Dashboard Aggregations ──
          final now = DateTime.now();

          // Today's Sales (FinalPayable sum of invoices created today)
          final todaySales = activeInvoices
              .where((i) =>
                  i.invoiceDate.year == now.year &&
                  i.invoiceDate.month == now.month &&
                  i.invoiceDate.day == now.day)
              .fold(0.0, (sum, i) => sum + i.finalPayable);

          // Today's Collection (TotalAmountPaid sum of invoices created today)
          final todayCollection = activeInvoices
              .where((i) =>
                  i.invoiceDate.year == now.year &&
                  i.invoiceDate.month == now.month &&
                  i.invoiceDate.day == now.day)
              .fold(0.0, (sum, i) => sum + i.totalAmountPaid);

          // Due Amount (BalanceDue sum of all invoices)
          final totalDue = activeInvoices.fold(0.0, (sum, i) => sum + i.balanceDue);
          final dueClientsCount = activeInvoices.where((i) => i.balanceDue > 0.05).map((i) => i.customerId).toSet().length;

          // Total Invoices this month
          final monthInvoices = activeInvoices
              .where((i) => i.invoiceDate.year == now.year && i.invoiceDate.month == now.month)
              .toList();

          // Live Gold Rate
          final latestRate = ratesState.value != null && ratesState.value!.isNotEmpty
              ? ratesState.value!.first
              : null;
          final double goldRate = latestRate?.rateGold22K ?? 6850.0;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(invoicesProvider.notifier).loadInvoices();
              await ref.read(customersProvider.notifier).loadCustomers();
              await ref.read(dailyRatesProvider.notifier).loadRates();
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPadding + 8),
                // ── Top Bar ──
                const AppHeader(),

                const SizedBox(height: 24),

                // ── Stat Cards 2×2 ──
                _buildStatCards(
                  sales: todaySales,
                  collection: todayCollection,
                  dues: totalDue,
                  dueCount: dueClientsCount,
                  invoicesCount: monthInvoices.length,
                ),

                const SizedBox(height: 32),

                // ── Quick Actions ──
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActions(context),

                const SizedBox(height: 32),

                // ── Live Gold Rate ──
                _buildGoldRateBanner(latestRate),

                const SizedBox(height: 32),

                // ── Recent Invoices ──
                SectionHeader(
                  title: 'Recent Invoices',
                  actionText: 'View All',
                  onAction: () => context.go('/more/records'),
                ),
                const SizedBox(height: 16),
                customersState.when(
                  data: (clients) => _buildRecentInvoices(activeInvoices, clients, context, ref),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
        );
      },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading stats: $err',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }



  Widget _buildStatCards({
    required double sales,
    required double collection,
    required double dues,
    required int dueCount,
    required int invoicesCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: "Today's Sales",
                  value: _formatCompact(sales),
                  subtitle: 'Today',
                  icon: Icons.trending_up_rounded,
                  animationIndex: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: "Today's Collection",
                  value: _formatCompact(collection),
                  subtitle: 'Received today',
                  icon: Icons.account_balance_wallet_rounded,
                  animationIndex: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Due Amount',
                  value: _formatCompact(dues),
                  subtitle: '$dueCount customers',
                  icon: Icons.warning_amber_rounded,
                  animationIndex: 2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Invoices',
                  value: '$invoicesCount',
                  subtitle: 'This Month',
                  icon: Icons.receipt_outlined,
                  animationIndex: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(Icons.add_circle_outline_rounded, 'New Sale', 0, () => context.go('/billing')),
      _QuickAction(Icons.person_add_alt_rounded, 'Add Customer', 1, () => context.push('/customers/add')),
      _QuickAction(Icons.inventory_2_outlined, 'Inventory', 2, () => context.go('/products')),
      _QuickAction(Icons.payments_outlined, 'Record Book', 3, () => context.go('/more/records')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: action.index < 3 ? 12 : 0,
                  ),
                  child: GlassCard(
                    animationIndex: action.index + 4,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    onTap: action.onTap,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action.icon,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          action.label,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGoldRateBanner(DailyRate? latestRate) {
    final gold22 = latestRate?.rateGold22K ?? 6850.0;
    final gold18 = latestRate?.rateGold18K ?? 5610.0;
    final silver = latestRate?.rateSilver ?? 82.4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        animationIndex: 8,
        padding: const EdgeInsets.all(16),
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY\'S METAL RATES',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.primary,
                letterSpacing: 1,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _rateColumn('Gold 22K', gold22, '/gm'),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _rateColumn('Gold 18K', gold18, '/gm'),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _rateColumn('Silver', silver * 1000, '/kg'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateColumn(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${_formatCurrency(value)}',
          style: AppTextStyles.titleMd.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceDim,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentInvoices(List<Invoice> invoices, List<dynamic> customers, BuildContext context, WidgetRef ref) {
    final recent = invoices.take(5).toList();

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          animationIndex: 9,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No recent invoices.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: recent.asMap().entries.map((entry) {
          final i = entry.key;
          final inv = entry.value;

          final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
          final customer = customerIndex != -1 
              ? customers[customerIndex] as Customer 
              : Customer(id: inv.customerId ?? '', name: 'Client', mobile: '', address: '');
          final customerName = customer.name;

          final String badgeStatus = inv.balanceDue <= 0 ? 'PAID' : 'PARTIAL';

          return Padding(
            padding: EdgeInsets.only(bottom: i < recent.length - 1 ? 10 : 0),
            child: GlassCard(
              animationIndex: 9 + i,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => _showInvoiceDetails(context, ref, inv, customer),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.invoiceNumber ?? 'INV-${inv.invoiceDate.millisecondsSinceEpoch}',
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$customerName • ${inv.items.length} Items',
                          style: AppTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_formatAmount(inv.finalPayable)}',
                        style: AppTextStyles.amountMd,
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(status: badgeStatus),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceDim,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  void _showInvoiceDetails(BuildContext context, WidgetRef ref, Invoice inv, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNumber ?? 'Invoice Details',
                            style: AppTextStyles.titleLg.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(inv.invoiceDate),
                            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceDim),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 24),
                Text(
                  'CUSTOMER DETAILS',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10, letterSpacing: 1.0),
                ),
                const SizedBox(height: 6),
                Text(customer.name, style: AppTextStyles.cardTitle),
                Text(customer.mobile, style: AppTextStyles.cardSubtitle),
                const SizedBox(height: 16),
                Text(
                  'ITEMS',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: inv.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w500)),
                                    Text(
                                      '${item.category} • ${item.purity} • ${item.grossWeight}g @ ₹${item.rate.toStringAsFixed(0)}',
                                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${item.itemTotal.toStringAsFixed(0)}',
                                style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(color: AppColors.border, height: 24),
                _summaryRow('Subtotal', '₹${inv.grossAmount.toStringAsFixed(0)}'),
                if (inv.couponDiscount > 0)
                  _summaryRow('Discount', '-₹${inv.couponDiscount.toStringAsFixed(0)}', isDiscount: true),
                _summaryRow('Taxable Value', '₹${inv.taxableAmount.toStringAsFixed(0)}'),
                _summaryRow('CGST (1.5%)', '₹${inv.cgst.toStringAsFixed(0)}'),
                _summaryRow('SGST (1.5%)', '₹${inv.sgst.toStringAsFixed(0)}'),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grand Total', style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '₹${inv.finalPayable.toStringAsFixed(0)}',
                      style: AppTextStyles.titleMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('EDIT BILL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(billingProvider.notifier).loadInvoiceToEdit(inv, customer);
                          Navigator.pop(context);
                          context.go('/billing');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('PRINT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          final company = ref.read(companyProvider).value;
                          PdfHelper.generateAndPrintInvoice(
                            invoice: inv,
                            customer: customer,
                            company: company,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
          Text(
            value,
            style: AppTextStyles.bodySm.copyWith(
              color: isDiscount ? AppColors.error : AppColors.onBackground,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final int index;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.index, this.onTap);
}
