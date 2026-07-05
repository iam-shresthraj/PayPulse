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
import '../../core/utils/file_saver_helper.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    // Pre-populate search with default range on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  void _performSearch() {
    final invoicesState = ref.read(invoicesProvider);
    if (invoicesState is AsyncData<List<Invoice>>) {
      final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      setState(() {
        _filteredInvoices = invoicesState.value.where((inv) {
          return inv.invoiceDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                 inv.invoiceDate.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
                 inv.deletedAt == null;
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
                'Paid',
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
                12: const pw.FixedColumnWidth(45), // Paid
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
                  inv.totalAmountPaid.toStringAsFixed(2),
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

    final rangeFormatted = '${DateFormat('dd-MM-yyyy').format(_startDate)} to ${DateFormat('dd-MM-yyyy').format(_endDate)}';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '$companyName Report ($rangeFormatted).pdf',
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
      'Paid (₹)',
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
        DoubleCellValue(inv.totalAmountPaid),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final rangeFormatted = '${DateFormat('dd-MM-yyyy').format(_startDate)} to ${DateFormat('dd-MM-yyyy').format(_endDate)}';
      FileSaverHelper.saveExcelFile(
        bytes,
        '$companyName Report ($rangeFormatted).xlsx',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final companyState = ref.watch(companyProvider);
    final companyName = companyState.value?.companyName ?? 'PayPulse';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding + 8),
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
                const SizedBox(width: 12),
                Text('Reports & Export', style: AppTextStyles.titleMd),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date Filter Inputs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              animationIndex: 0,
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  final startButton = InkWell(
                    onTap: () => _selectDate(context, true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(_startDate),
                            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );

                  final endButton = InkWell(
                    onTap: () => _selectDate(context, false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(_endDate),
                            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );

                  final searchButton = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 16 : 20,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      'Search',
                      style: AppTextStyles.titleSm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        startButton,
                        const SizedBox(height: 12),
                        endButton,
                        const SizedBox(height: 16),
                        searchButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: startButton),
                      const SizedBox(width: 12),
                      Expanded(child: endButton),
                      const SizedBox(width: 12),
                      searchButton,
                    ],
                  );
                },
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
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _exportToExcel(companyName),
                    icon: const Icon(Icons.grid_on_rounded, size: 18),
                    label: const Text('Export XLSX'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
          Expanded(
            child: _hasSearched
                ? (_filteredInvoices.isEmpty
                    ? Center(
                        child: Text(
                          'No invoices found in selected date range.',
                          style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                        ),
                      )
                    : Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
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
                                  DataColumn(label: Text('Paid (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
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
                                      DataCell(Text(inv.totalAmountPaid.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ))
                : Center(
                    child: Text(
                      'Select a date range and click Search to display reports.',
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
