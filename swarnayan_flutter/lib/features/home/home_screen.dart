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
import '../auth/auth_provider.dart';
import '../more/widgets/team_dialogs.dart';
import '../more/team_provider.dart';
import '../admin/admin_dashboard_view.dart';
import '../../core/widgets/skeleton_widgets.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  List<double> _calculateWeeklySales(List<Invoice> invoices) {
    final weeklySales = List.filled(7, 0.0);
    final now = DateTime.now();
    // Start of current week (Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    for (final inv in invoices) {
      final diff = inv.invoiceDate.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        final weekdayIndex = inv.invoiceDate.weekday % 7; // Sunday = 0, Monday = 1, etc.
        weeklySales[weekdayIndex] += inv.finalPayable;
      }
    }
    return weeklySales;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If the user is a Super Admin, show the Admin Dashboard
    final user = ref.watch(authProvider).user;
    if (user?.isSuperAdmin ?? false) {
      return const AdminDashboardView();
    }

    final invoicesState = ref.watch(invoicesProvider);
    final customersState = ref.watch(customersProvider);
    final ratesState = ref.watch(dailyRatesProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final isWide = MediaQuery.of(context).size.width >= 850;

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

          // Invoices this month
          final monthInvoices = activeInvoices
              .where((i) => i.invoiceDate.year == now.year && i.invoiceDate.month == now.month)
              .toList();

          // Monthly Revenue (FinalPayable sum this month)
          final monthRevenue = monthInvoices.fold(0.0, (sum, i) => sum + i.finalPayable);

          // Live Gold Rate
          final latestRate = ratesState.value != null && ratesState.value!.isNotEmpty
              ? ratesState.value!.first
              : null;

          // Weekly sales trend
          final weeklySales = _calculateWeeklySales(activeInvoices);

          if (isWide) {
            return customersState.when(
              data: (clients) => _buildWebDashboard(
                context: context,
                ref: ref,
                sales: todaySales,
                collection: todayCollection,
                dues: totalDue,
                dueCount: dueClientsCount,
                invoicesCount: monthInvoices.length,
                monthRevenue: monthRevenue,
                weeklySales: weeklySales,
                latestRate: latestRate,
                activeInvoices: activeInvoices,
                customers: clients,
              ),
              loading: () => _buildDashboardSkeleton(),
              error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
            );
          }

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

                  const SizedBox(height: 16),

                  // 1. Live Gold Rate
                  _buildGoldRateBanner(latestRate),

                  _buildPendingApprovalsBanner(context, ref),

                  const SizedBox(height: 24),

                  // 2. Quick Actions
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, true),

                  const SizedBox(height: 24),

                  // 3. Stat Cards (Today's Sales & Total Invoices)
                  _buildStatCards(
                    sales: todaySales,
                    invoicesCount: monthInvoices.length,
                  ),

                  const SizedBox(height: 24),

                  // 4. Recent Invoices
                  SectionHeader(
                    title: 'Recent Invoices',
                    actionText: 'View All',
                    onAction: () => context.push('/more/records'),
                  ),
                  const SizedBox(height: 12),
                  customersState.when(
                    data: (clients) => _buildRecentInvoices(activeInvoices, clients, context, ref),
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: List.generate(3, (_) => const InvoiceListItemSkeleton()),
                      ),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => _buildDashboardSkeleton(),
        error: (err, _) => Center(
          child: Text(
            'Error loading stats: $err',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeaderSkeleton(),
          const SizedBox(height: 20),
          const ChartSkeleton(),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: StatCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: StatCardSkeleton()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: StatCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: StatCardSkeleton()),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonShimmer(child: SkeletonBox(width: 130, height: 14)),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => const InvoiceListItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildWebDashboard({
    required BuildContext context,
    required WidgetRef ref,
    required double sales,
    required double collection,
    required double dues,
    required int dueCount,
    required int invoicesCount,
    required double monthRevenue,
    required List<double> weeklySales,
    required DailyRate? latestRate,
    required List<Invoice> activeInvoices,
    required List<dynamic> customers,
  }) {
    final progressRatio = sales > 0 ? (collection / sales).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final userObj = ref.watch(authProvider).user;
                      final isManagerOrOwner = userObj?.canManage ?? false;
                      return Text(
                        isManagerOrOwner ? 'Dashboard' : 'Staff Dashboard',
                        style: AppTextStyles.headlineLg.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plan, prioritize, and accomplish your tasks with ease.',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/billing'),
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    label: const Text('New Sale', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/customers/add'),
                    icon: Icon(Icons.person_add_rounded, color: AppColors.primary, size: 18),
                    label: Text('Add Customer', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          _buildPendingApprovalsBanner(context, ref),

          // ── Metrics Row (2 Cards) ──
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: "Today's Sales",
                  value: _formatCompact(sales),
                  subtext: "Today's gross invoice value",
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildMetricCard(
                  title: "Monthly Bills",
                  value: "$invoicesCount",
                  subtext: "Bills created this month",
                  icon: Icons.receipt_long_rounded,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Middle Section (Sales Analytics & Rates/Actions) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sales Analytics Chart (60% width)
              Expanded(
                flex: 3,
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales Analytics',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SalesBarChart(weeklySales: weeklySales),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Today's Metal Rates & Quick Actions (40% width)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildWebGoldRateCard(latestRate),
                    const SizedBox(height: 20),
                    _buildWebQuickActions(context),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Bottom Section (Sales Progress Gauge & Recent Invoices) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Gauge (40% width)
              Expanded(
                flex: 2,
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection Progress',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ratio of received cash against today\'s sales.',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                      ),
                      const Spacer(),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(200, 100),
                              painter: GaugePainter(
                                progress: progressRatio,
                                color: AppColors.primary,
                                trackColor: AppColors.border,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Column(
                                children: [
                                  Text(
                                    '${(progressRatio * 100).toStringAsFixed(0)}%',
                                    style: AppTextStyles.displayLg.copyWith(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  Text(
                                    'Collected Today',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Recent Invoices List (60% width)
              Expanded(
                flex: 3,
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Invoices',
                            style: AppTextStyles.titleSm.copyWith(
                              color: AppColors.onBackground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/more/records'),
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildRecentInvoicesList(activeInvoices, customers, context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtext,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceDim,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebGoldRateCard(DailyRate? latestRate) {
    final gold22 = latestRate?.rateGold22K ?? 6850.0;
    final gold18 = latestRate?.rateGold18K ?? 5610.0;
    final silver = latestRate?.rateSilver ?? 82.4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S METAL RATES',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildWebQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(Icons.add_circle_outline_rounded, 'New Sale', 0, () => context.go('/billing')),
      _QuickAction(Icons.person_add_alt_rounded, 'Add Customer', 1, () => context.push('/customers/add')),
      _QuickAction(Icons.inventory_2_outlined, 'Inventory', 2, () => context.go('/products')),
      _QuickAction(Icons.payments_outlined, 'Record Book', 3, () => context.go('/more/records')),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: actions.map((action) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: action.index < 3 ? 10 : 0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: action.onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDim,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(action.icon, color: AppColors.primary, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              action.label,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurface,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoicesList(List<Invoice> invoices, List<dynamic> customers, BuildContext context, WidgetRef ref) {
    final recent = invoices.take(4).toList();

    if (recent.isEmpty) {
      return Center(
        child: Text(
          'No recent invoices.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
        ),
      );
    }

    return ListView.builder(
      itemCount: recent.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, idx) {
        final inv = recent[idx];
        final customerIndex = customers.indexWhere((c) => c.id == inv.customerId);
        final customer = customerIndex != -1 
            ? customers[customerIndex] as Customer 
            : Customer(id: inv.customerId ?? '', name: 'Client', mobile: '', address: '');
        
        final customerName = customer.name;
        final String badgeStatus = inv.balanceDue <= 0 ? 'PAID' : 'PARTIAL';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showInvoiceDetails(context, ref, inv, customer),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNumber ?? 'INV',
                            style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                          ),
                          Text(
                            '$customerName • ${inv.items.length} Items',
                            style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${_formatAmount(inv.finalPayable)}',
                          style: AppTextStyles.amountMd.copyWith(fontSize: 13, color: AppColors.onBackground),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(status: badgeStatus),
                      ],
                    ),
                    const SizedBox(width: 8),
                     Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceDim,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCards({
    required double sales,
    required int invoicesCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
              title: 'Total Invoices',
              value: '$invoicesCount',
              subtitle: 'This Month',
              icon: Icons.receipt_outlined,
              animationIndex: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, [bool isMobile = false]) {
    if (isMobile) {
      final actions = [
        _QuickAction(Icons.add_circle_outline_rounded, 'New Sale', 0, () => context.go('/billing')),
        _QuickAction(Icons.payments_outlined, 'Record Book', 1, () => context.push('/more/records')),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: actions
              .map(
                (action) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: action.index == 0 ? 12 : 0,
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
                   Icon(
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
    final user = ref.read(authProvider).user;
    final canManage = user?.canManage ?? false;

    showDialog(
      context: context,
      useRootNavigator: false,
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
                      icon:  Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                 Divider(color: AppColors.border, height: 24),
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
                 Divider(color: AppColors.border, height: 24),
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
                    if (canManage) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('EDIT BILL'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
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
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('PRINT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
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

  Widget _buildPendingApprovalsBanner(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null || !user.canManage) return const SizedBox();

    final pendingState = ref.watch(pendingMembersProvider);
    return pendingState.maybeWhen(
      data: (pendingList) {
        if (pendingList.isEmpty) return const SizedBox();
        final count = pendingList.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.15),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.how_to_reg_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Account Approvals',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count user request${count == 1 ? '' : 's'} waiting for review.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      useRootNavigator: false,
                      builder: (_) => const PendingApprovalsDialog(),
                    ).then((_) => ref.invalidate(pendingMembersProvider));
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Review',
                    style: AppTextStyles.labelMd.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox(),
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

// ── Custom Paint Semi-Circular Gauge Chart ──
class GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final paintTrack = Paint()
      ..color = trackColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintProgress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw track arc (180 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      3.14159265, // Pi (180 degrees)
      3.14159265, // Pi (180 degrees)
      false,
      paintTrack,
    );

    if (progress > 0) {
      // Draw progress arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        3.14159265,
        3.14159265 * progress,
        false,
        paintProgress,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Custom Weekly Sales Bar Chart ──
class SalesBarChart extends StatelessWidget {
  final List<double> weeklySales;
  const SalesBarChart({super.key, required this.weeklySales});

  @override
  Widget build(BuildContext context) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final maxVal = weeklySales.fold(1.0, (m, v) => v > m ? v : m);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final sales = weeklySales[index];
        final ratio = maxVal > 0 ? (sales / maxVal) : 0.0;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                sales > 0 ? '₹${(sales / 1000).toStringAsFixed(0)}K' : '',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: Container(
                    width: 24,
                    decoration: BoxDecoration(
                      color: sales > 0 
                          ? AppColors.primary 
                          : AppColors.border.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    // Set height fractionally
                    height: ratio > 0 ? (ratio * 160) + 8 : 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
