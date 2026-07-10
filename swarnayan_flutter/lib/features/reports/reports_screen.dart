import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/utils/file_saver_helper.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../admin/admin_reports_view.dart';
import '../billing/invoices_provider.dart';
import '../customers/customers_provider.dart';
import '../more/company_provider.dart';
import '../../models/invoice.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  List<Invoice> _filteredInvoices = [];
  bool _hasSearched = false;
  final Set<String> _selectedStatusFilters = {'ALL'};
  final Set<String> _selectedSearchFields = {'ALL'};

  static const List<({String key, String label})> _statusScopes = [
    (key: 'ALL', label: 'All Statuses'),
    (key: 'PAID', label: 'Paid'),
    (key: 'PARTIAL', label: 'Partial'),
    (key: 'CANCELLED', label: 'Cancelled'),
  ];
  final TextEditingController _searchQueryController = TextEditingController();

  static const List<({String key, String label})> _searchScopes = [
    (key: 'ALL', label: 'All Columns'),
    (key: 'invoiceNumber', label: 'Invoice No'),
    (key: 'customerName', label: 'Customer'),
    (key: 'productDetails', label: 'Products'),
    (key: 'grossAmount', label: 'Gross Amount'),
    (key: 'couponDiscount', label: 'Discount'),
    (key: 'taxableAmount', label: 'Taxable Amount'),
    (key: 'totalTax', label: 'Total Tax'),
    (key: 'netAmount', label: 'Net Amount'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final invoicesState = ref.read(invoicesProvider);
    if (invoicesState is AsyncData<List<Invoice>>) {
      final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      final query = _searchQueryController.text.trim().toLowerCase();
      final selectedFields = _selectedSearchFields.toSet();

      setState(() {
        _filteredInvoices = invoicesState.value.where((inv) {
          final dateMatch = inv.invoiceDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                 inv.invoiceDate.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
                 inv.deletedAt == null;
          if (!dateMatch) return false;

          if (!_selectedStatusFilters.contains('ALL')) {
            final isPaid = inv.balanceDue <= 0.05 && inv.status != 'CANCELLED';
            final isPartial = inv.balanceDue > 0.05 && inv.status != 'CANCELLED';
            final isCancelled = inv.status == 'CANCELLED';

            bool match = false;
            if (_selectedStatusFilters.contains('PAID') && isPaid) match = true;
            if (_selectedStatusFilters.contains('PARTIAL') && isPartial) match = true;
            if (_selectedStatusFilters.contains('CANCELLED') && isCancelled) match = true;

            if (!match) return false;
          }

          if (query.isNotEmpty) {
            final custName = _getCustomerName(inv).toLowerCase();
            final invNum = (inv.invoiceNumber ?? inv.id ?? '').toLowerCase();
            final prodDetails = _getProductDetails(inv).toLowerCase();
            final grossAmt = inv.grossAmount.toStringAsFixed(2);
            final discount = inv.couponDiscount.toStringAsFixed(2);
            final taxable = inv.taxableAmount.toStringAsFixed(2);
            final tax = inv.totalTax.toStringAsFixed(2);
            final netAmt = inv.netAmount.toStringAsFixed(2);
            final matchAny = selectedFields.contains('ALL')
                ? invNum.contains(query) ||
                    custName.contains(query) ||
                    prodDetails.contains(query) ||
                    grossAmt.contains(query) ||
                    discount.contains(query) ||
                    taxable.contains(query) ||
                    tax.contains(query) ||
                    netAmt.contains(query)
                : selectedFields.any((field) {
                    switch (field) {
                      case 'invoiceNumber':
                        return invNum.contains(query);
                      case 'customerName':
                        return custName.contains(query);
                      case 'productDetails':
                        return prodDetails.contains(query);
                      case 'grossAmount':
                        return grossAmt.contains(query);
                      case 'couponDiscount':
                        return discount.contains(query);
                      case 'taxableAmount':
                        return taxable.contains(query);
                      case 'totalTax':
                        return tax.contains(query);
                      case 'netAmount':
                        return netAmt.contains(query);
                      default:
                        return false;
                    }
                  });
            if (!matchAny) return false;
          }
          return true;
        }).toList();
        _hasSearched = true;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final isLight = AppColors.isLight;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isLight
                ? ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceContainer,
                    onSurface: AppColors.onSurface,
                  )
                : ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.black,
                    surface: AppColors.surfaceContainer,
                    onSurface: AppColors.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _getCustomerName(Invoice invoice) {
    if (invoice.tempCustomerName != null && invoice.tempCustomerName!.isNotEmpty) {
      return invoice.tempCustomerName!;
    }
    final customers = ref.read(customersProvider).value ?? [];
    try {
      final cust = customers.firstWhere((c) => c.id == invoice.customerId);
      return cust.name;
    } catch (_) {
      return 'Walk-in Customer';
    }
  }

  String _getProductDetails(Invoice invoice) {
    return invoice.items.map((item) => '${item.productName} (${item.purity}, ${item.netWeight}g, x${item.quantity})').join(', ');
  }

  Future<void> _exportToPdf(String companyName) async {
    final doc = pw.Document();
    final fontData = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Text(
              '$companyName Report',
              style: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date Range: ${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)}',
              style: pw.TextStyle(font: fontData, fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: [
                'Invoice No',
                'Date',
                'Customer',
                'Products',
                'Making Charge',
                'Gross',
                'Discount',
                'Taxable',
                'CGST',
                'SGST',
                'Total Tax',
                'Net Amt',
              ],
              columnWidths: {
                0: const pw.FixedColumnWidth(40), // Invoice No
                1: const pw.FixedColumnWidth(45), // Date
                2: const pw.FixedColumnWidth(70), // Customer
                3: const pw.FixedColumnWidth(130), // Products
                4: const pw.FixedColumnWidth(55), // Making Charge
                5: const pw.FixedColumnWidth(45), // Gross
                6: const pw.FixedColumnWidth(45), // Discount
                7: const pw.FixedColumnWidth(45), // Taxable
                8: const pw.FixedColumnWidth(30), // CGST
                9: const pw.FixedColumnWidth(30), // SGST
                10: const pw.FixedColumnWidth(45), // Total Tax
                11: const pw.FixedColumnWidth(45), // Net Amt
              },
              data: _filteredInvoices.map((inv) {
                final makingChargeSum = inv.items.fold<double>(0, (sum, item) => sum + item.makingChargeTotal);
                return [
                  inv.invoiceNumber ?? inv.id ?? '',
                  DateFormat('dd/MM/yyyy').format(inv.invoiceDate),
                  _getCustomerName(inv),
                  _getProductDetails(inv),
                  makingChargeSum.toStringAsFixed(2),
                  inv.grossAmount.toStringAsFixed(2),
                  inv.couponDiscount.toStringAsFixed(2),
                  inv.taxableAmount.toStringAsFixed(2),
                  inv.cgst.toStringAsFixed(2),
                  inv.sgst.toStringAsFixed(2),
                  inv.totalTax.toStringAsFixed(2),
                  inv.netAmount.toStringAsFixed(2),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 6.5),
              cellStyle: pw.TextStyle(font: fontData, fontSize: 6.0),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );
    final bytes = await doc.save();
    await FileSaverHelper.savePdfFile(
      bytes,
      'PayPulse $companyName Report - ${DateFormat('dd-MM-yyyy').format(DateTime.now())}.pdf',
    );
  }

  void _exportToExcel(String companyName) {
    final excel = Excel.createExcel();
    final sheetName = excel.sheets.keys.first;
    final Sheet sheet = excel[sheetName];

    // Title Row
    sheet.appendRow([TextCellValue('$companyName Report')]);
    
    // Subtitle Date Row
    final dateRangeStr = 'Date Range: ${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)}';
    sheet.appendRow([TextCellValue(dateRangeStr)]);
    sheet.appendRow([]); // empty buffer row

    // Table Header
    final headers = [
      'Invoice No',
      'Date',
      'Customer',
      'Products',
      'Making Charge (₹)',
      'Gross Amount (₹)',
      'Discount (₹)',
      'Taxable Amount (₹)',
      'CGST (₹)',
      'SGST (₹)',
      'Total Tax (₹)',
      'Net Amount (₹)',
    ].map((h) => TextCellValue(h)).toList();
    sheet.appendRow(headers);

    // Data Row
    for (final inv in _filteredInvoices) {
      final makingChargeSum = inv.items.fold<double>(0, (sum, item) => sum + item.makingChargeTotal);
      sheet.appendRow([
        TextCellValue(inv.invoiceNumber ?? inv.id ?? ''),
        TextCellValue(DateFormat('dd/MM/yyyy').format(inv.invoiceDate)),
        TextCellValue(_getCustomerName(inv)),
        TextCellValue(_getProductDetails(inv)),
        DoubleCellValue(makingChargeSum),
        DoubleCellValue(inv.grossAmount),
        DoubleCellValue(inv.couponDiscount),
        DoubleCellValue(inv.taxableAmount),
        DoubleCellValue(inv.cgst),
        DoubleCellValue(inv.sgst),
        DoubleCellValue(inv.totalTax),
        DoubleCellValue(inv.netAmount),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      FileSaverHelper.saveExcelFile(
        bytes,
        'PayPulse $companyName Report - ${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx',
      );
    }
  }

  Future<void> _pickSearchScopes() async {
    final selected = Set<String>.from(_selectedSearchFields);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Text('Search In', style: AppTextStyles.titleMd),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _searchScopes.map((scope) {
                    final checked = selected.contains(scope.key);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checked,
                      title: Text(scope.label, style: AppTextStyles.bodyMd),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (scope.key == 'ALL') {
                            selected
                              ..clear()
                              ..add('ALL');
                          } else if (val == true) {
                            selected.remove('ALL');
                            selected.add(scope.key);
                          } else {
                            selected.remove(scope.key);
                            if (selected.isEmpty) selected.add('ALL');
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedSearchFields
          ..clear()
          ..addAll(result);
        if (_selectedSearchFields.isEmpty) _selectedSearchFields.add('ALL');
      });
      _performSearch();
    }
  }



  Future<void> _pickStatusFilter() async {
    final selected = Set<String>.from(_selectedStatusFilters);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Text('Payment Status', style: AppTextStyles.titleMd),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _statusScopes.map((scope) {
                    final checked = selected.contains(scope.key);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checked,
                      title: Text(scope.label, style: AppTextStyles.bodyMd),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (scope.key == 'ALL') {
                            selected
                              ..clear()
                              ..add('ALL');
                          } else if (val == true) {
                            selected.remove('ALL');
                            selected.add(scope.key);
                          } else {
                            selected.remove(scope.key);
                            if (selected.isEmpty) selected.add('ALL');
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedStatusFilters
          ..clear()
          ..addAll(result);
        if (_selectedStatusFilters.isEmpty) _selectedStatusFilters.add('ALL');
      });
      _performSearch();
    }
  }

  Widget _buildStatusFilterDropdown() {
    final selectedLabel = _selectedStatusFilters.contains('ALL')
        ? 'All Statuses'
        : _selectedStatusFilters.length == 1
            ? _statusScopes.firstWhere((scope) => scope.key == _selectedStatusFilters.first).label
            : '${_selectedStatusFilters.length} Statuses';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PAYMENT STATUS',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickStatusFilter,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel,
                    style: AppTextStyles.bodyLg.copyWith(color: AppColors.onBackground),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: AppColors.onSurfaceMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If the user is a Super Admin, show the Admin Reports view
    final user = ref.watch(authProvider).user;
    if (user?.isSuperAdmin ?? false) {
      return const AdminReportsView();
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final companyState = ref.watch(companyProvider);
    final companyName = companyState.value?.companyName ?? 'PayPulse';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding > 0 ? topPadding + 20 : 20),
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
                      shape: BoxShape.circle,
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
                    'Reports',
                    style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unified Filters Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      animationIndex: 0,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 900;

                              final startWidget = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'START DATE',
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context, true),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                        border: Border.all(color: AppColors.glassBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            DateFormat('dd MMM yyyy').format(_startDate),
                                            style: AppTextStyles.bodyLg.copyWith(
                                              color: AppColors.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );

                              final endWidget = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'END DATE',
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context, false),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainer.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                        border: Border.all(color: AppColors.glassBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            DateFormat('dd MMM yyyy').format(_endDate),
                                            style: AppTextStyles.bodyLg.copyWith(
                                              color: AppColors.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );

                              final selectedLabel = _selectedSearchFields.contains('ALL')
                                  ? 'All Columns'
                                  : _selectedSearchFields.length == 1
                                      ? _searchScopes.firstWhere((scope) => scope.key == _selectedSearchFields.first).label
                                      : '${_selectedSearchFields.length} Columns';

                              final inputWidget = GlassInput(
                                controller: _searchQueryController,
                                label: 'Search Query ($selectedLabel)',
                                hint: 'Type search text...',
                                prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
                                suffixIcon: InkWell(
                                  onTap: _pickSearchScopes,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 24),
                                ),
                                onChanged: (_) => _performSearch(),
                              );

                              if (isMobile) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: startWidget),
                                        const SizedBox(width: 12),
                                        Expanded(child: endWidget),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    inputWidget,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: startWidget),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 2, child: endWidget),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 5, child: inputWidget),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _buildStatusFilterDropdown(),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _performSearch,
                                icon: const Icon(Icons.search_rounded),
                                label: Text(
                                  'Search',
                                  style: AppTextStyles.titleSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Toolbar (Export Buttons)
                  if (_hasSearched && _filteredInvoices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _exportToExcel(companyName),
                            icon: const Icon(Icons.grid_on_rounded, size: 18),
                            label: const Text('Export XLSX'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _exportToPdf(companyName),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            label: const Text('Export PDF'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Results Grid / Table
                  _hasSearched
                      ? (_filteredInvoices.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No invoices found in selected date range.',
                                  style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                                ),
                              ),
                            )
                          : Card(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainerHigh),
                                    dataRowColor: WidgetStateProperty.all(AppColors.surface),
                                    dividerThickness: 0.5,
                                    columns: [
                                      DataColumn(label: Text('Invoice No', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Date', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Customer', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Products', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Making Chg (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Gross (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Discount (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Taxable (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('CGST (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('SGST (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Total Tax (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Net Amt (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _filteredInvoices.map((inv) {
                                      final makingChargeSum = inv.items.fold<double>(0, (sum, item) => sum + item.makingChargeTotal);
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(inv.invoiceNumber ?? inv.id ?? '', style: AppTextStyles.bodyMd)),
                                          DataCell(Text(DateFormat('dd/MM/yyyy').format(inv.invoiceDate), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(_getCustomerName(inv), style: AppTextStyles.bodyMd)),
                                          DataCell(
                                            Container(
                                              constraints: const BoxConstraints(maxWidth: 300),
                                              child: Text(
                                                _getProductDetails(inv),
                                                style: AppTextStyles.bodyMd,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(makingChargeSum.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(inv.grossAmount.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(inv.couponDiscount.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(inv.taxableAmount.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(inv.cgst.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(inv.sgst.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(inv.totalTax.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                          DataCell(Text(inv.netAmount.toStringAsFixed(2), style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ))
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Select a date range and click Search to display reports.',
                                style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 72),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
