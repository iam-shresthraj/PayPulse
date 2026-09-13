import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_input.dart';
import '../../core/utils/file_saver_helper.dart';
import '../../core/utils/pdf_helper.dart';
import '../../models/company_settings.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../auth/auth_provider.dart';
import '../admin/admin_reports_view.dart';
import '../billing/invoices_provider.dart';
import '../customers/customers_provider.dart';
import '../more/company_provider.dart';

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
  bool _isCardView = false;
  bool _isExporting = false;

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
    (key: 'customerName', label: 'Customer Name'),
    (key: 'customerPhone', label: 'Customer Phone'),
    (key: 'productDetails', label: 'Products / Items'),
    (key: 'purity', label: 'Purity'),
    (key: 'netWeight', label: 'Net Weight'),
    (key: 'grossAmount', label: 'Gross Amount'),
    (key: 'couponDiscount', label: 'Discount'),
    (key: 'taxableAmount', label: 'Taxable Amount'),
    (key: 'totalTax', label: 'Total Tax'),
    (key: 'netAmount', label: 'Net Amount'),
    (key: 'paymentMode', label: 'Payment Mode'),
    (key: 'dues', label: 'Dues'),
    (key: 'status', label: 'Status'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    super.dispose();
  }

  // --- Calculations for Summary Metrics ---
  double get _totalGrossSales => _filteredInvoices.fold<double>(0, (sum, inv) => sum + inv.grossAmount);
  double get _totalGst => _filteredInvoices.fold<double>(0, (sum, inv) => sum + inv.totalTax);
  double get _totalNetSales => _filteredInvoices.fold<double>(0, (sum, inv) => sum + inv.netAmount);
  double get _totalPaid => _filteredInvoices.fold<double>(0, (sum, inv) => sum + inv.totalAmountPaid);
  double get _totalDues => _filteredInvoices.fold<double>(0, (sum, inv) => sum + inv.balanceDue);
  double get _totalWeight => _filteredInvoices.fold<double>(0, (sum, inv) => sum + _getTotalNetWeight(inv));

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
            final phone = _getCustomerPhone(inv).toLowerCase();
            final invNum = (inv.invoiceNumber ?? inv.id ?? '').toLowerCase();
            final prodDetails = _getProductDetails(inv).toLowerCase();
            final purity = _getPurity(inv).toLowerCase();
            final netWt = _getTotalNetWeight(inv).toStringAsFixed(3);
            final grossAmt = inv.grossAmount.toStringAsFixed(2);
            final discount = (inv.couponDiscount + inv.manualDiscount).toStringAsFixed(2);
            final taxable = inv.taxableAmount.toStringAsFixed(2);
            final tax = inv.totalTax.toStringAsFixed(2);
            final netAmt = inv.netAmount.toStringAsFixed(2);
            final paymentMode = _getPaymentBreakdown(inv).toLowerCase();
            final dues = inv.balanceDue.toStringAsFixed(2);
            final status = _getInvoiceStatus(inv).toLowerCase();

            final matchAny = selectedFields.contains('ALL')
                ? invNum.contains(query) ||
                    custName.contains(query) ||
                    phone.contains(query) ||
                    prodDetails.contains(query) ||
                    purity.contains(query) ||
                    netWt.contains(query) ||
                    grossAmt.contains(query) ||
                    discount.contains(query) ||
                    taxable.contains(query) ||
                    tax.contains(query) ||
                    netAmt.contains(query) ||
                    paymentMode.contains(query) ||
                    dues.contains(query) ||
                    status.contains(query)
                : selectedFields.any((field) {
                    switch (field) {
                      case 'invoiceNumber':
                        return invNum.contains(query);
                      case 'customerName':
                        return custName.contains(query);
                      case 'customerPhone':
                        return phone.contains(query);
                      case 'productDetails':
                        return prodDetails.contains(query);
                      case 'purity':
                        return purity.contains(query);
                      case 'netWeight':
                        return netWt.contains(query);
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
                      case 'paymentMode':
                        return paymentMode.contains(query);
                      case 'dues':
                        return dues.contains(query);
                      case 'status':
                        return status.contains(query);
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
      _performSearch();
    }
  }

  // --- Helper Methods ---

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

  String _getCustomerPhone(Invoice invoice) {
    if (invoice.tempCustomerMobile != null && invoice.tempCustomerMobile!.isNotEmpty) {
      return invoice.tempCustomerMobile!;
    }
    final customers = ref.read(customersProvider).value ?? [];
    try {
      final cust = customers.firstWhere((c) => c.id == invoice.customerId);
      return cust.mobile.isNotEmpty ? cust.mobile : '—';
    } catch (_) {
      return '—';
    }
  }

  String _getCustomerAddress(Invoice invoice) {
    final addrParts = [
      if (invoice.tempCustomerAddress?.isNotEmpty == true) invoice.tempCustomerAddress!,
      if (invoice.tempCustomerCity?.isNotEmpty == true) invoice.tempCustomerCity!,
      if (invoice.tempCustomerState?.isNotEmpty == true) invoice.tempCustomerState!,
      if (invoice.tempCustomerPincode?.isNotEmpty == true) invoice.tempCustomerPincode!,
    ];
    if (addrParts.isNotEmpty) return addrParts.join(', ');
    final customers = ref.read(customersProvider).value ?? [];
    try {
      final cust = customers.firstWhere((c) => c.id == invoice.customerId);
      if (cust.address != null && cust.address!.isNotEmpty) return cust.address!;
    } catch (_) {}
    return '—';
  }

  Customer _resolveCustomer(Invoice invoice) {
    final customers = ref.read(customersProvider).value ?? [];
    try {
      return customers.firstWhere((c) => c.id == invoice.customerId);
    } catch (_) {
      return Customer(
        id: invoice.customerId,
        name: invoice.tempCustomerName ?? 'Walk-in Customer',
        mobile: invoice.tempCustomerMobile ?? '',
        address: invoice.tempCustomerAddress ?? '',
        city: invoice.tempCustomerCity ?? '',
        state: invoice.tempCustomerState ?? '',
        pincode: invoice.tempCustomerPincode ?? '',
      );
    }
  }

  String _getProductDetails(Invoice invoice) {
    if (invoice.items.isEmpty) return '—';
    return invoice.items.map((item) {
      final huidStr = item.huidNumber != null && item.huidNumber!.isNotEmpty ? ' (HUID:${item.huidNumber})' : '';
      return '${item.productName}$huidStr';
    }).join('; ');
  }

  String _getPurity(Invoice invoice) {
    final purities = invoice.items.map((i) => i.purity.trim()).where((p) => p.isNotEmpty).toSet();
    if (purities.isEmpty) return '—';
    return purities.join(', ');
  }

  double _getTotalNetWeight(Invoice invoice) {
    return invoice.items.fold<double>(0, (sum, i) => sum + i.netWeight);
  }

  double _getTotalGrossWeight(Invoice invoice) {
    return invoice.items.fold<double>(0, (sum, i) => sum + i.grossWeight);
  }

  double _getCashPaid(Invoice invoice) {
    return invoice.payments.where((p) => p.method.toUpperCase() == 'CASH').fold<double>(0, (sum, p) => sum + p.amount);
  }

  double _getCardPaid(Invoice invoice) {
    return invoice.payments.where((p) => p.method.toUpperCase() == 'CARD').fold<double>(0, (sum, p) => sum + p.amount);
  }

  double _getUpiPaid(Invoice invoice) {
    return invoice.payments.where((p) => p.method.toUpperCase().contains('UPI') || p.method.toUpperCase().contains('BANK')).fold<double>(0, (sum, p) => sum + p.amount);
  }

  String _getPaymentBreakdown(Invoice invoice) {
    if (invoice.payments.isEmpty) return '—';
    final parts = <String>[];
    final cash = _getCashPaid(invoice);
    final card = _getCardPaid(invoice);
    final upi = _getUpiPaid(invoice);

    if (cash > 0) parts.add('Cash ₹${cash.toStringAsFixed(cash % 1 == 0 ? 0 : 2)}');
    if (card > 0) parts.add('Card ₹${card.toStringAsFixed(card % 1 == 0 ? 0 : 2)}');
    if (upi > 0) parts.add('UPI ₹${upi.toStringAsFixed(upi % 1 == 0 ? 0 : 2)}');

    if (parts.isEmpty) {
      for (final p in invoice.payments) {
        if (p.amount > 0) {
          parts.add('${p.method} ₹${p.amount.toStringAsFixed(p.amount % 1 == 0 ? 0 : 2)}');
        }
      }
    }
    return parts.isEmpty ? '—' : parts.join('; ');
  }

  String _getInvoiceStatus(Invoice invoice) {
    if (invoice.status == 'CANCELLED') return 'CANCELLED';
    if (invoice.balanceDue <= 0.05) return 'PAID';
    return 'PARTIAL';
  }

  String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  // --- Export Methods ---

  String _getReportFileName(String companyName, String extension) {
    final cleanCompany = companyName.trim().replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
    final startStr = DateFormat('dd-MM-yyyy').format(_startDate);
    final endStr = DateFormat('dd-MM-yyyy').format(_endDate);
    final dateRangeStr = startStr == endStr ? startStr : '${startStr}_to_$endStr';
    return '${cleanCompany}_Report_$dateRangeStr.$extension';
  }

  Future<void> _exportToCsv(String companyName) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final buffer = StringBuffer();
      // Complete Database CSV Schema
      buffer.writeln('Invoice No.,Date,Customer Name,Phone,Address,Particulars,Purity,Gross Wt (gm),Net Wt (gm),Making Charge (₹),Gross Amt (₹),Discount (₹),Taxable Amt (₹),CGST (₹),SGST (₹),Total Tax (₹),Net Amt (₹),By Cash (₹),By Card (₹),By UPI (₹),Total Paid (₹),Dues (₹),Status');

      for (final inv in _filteredInvoices) {
        final invNo = inv.invoiceNumber ?? inv.id ?? '';
        final date = DateFormat('dd/MM/yyyy').format(inv.invoiceDate);
        final custName = _escapeCsv(_getCustomerName(inv));
        final phone = _escapeCsv(_getCustomerPhone(inv));
        final address = _escapeCsv(_getCustomerAddress(inv));
        final products = _escapeCsv(_getProductDetails(inv));
        final purity = _escapeCsv(_getPurity(inv));
        final grossWt = _getTotalGrossWeight(inv).toStringAsFixed(3);
        final netWt = _getTotalNetWeight(inv).toStringAsFixed(3);
        final makingCharge = inv.items.fold<double>(0, (s, i) => s + i.makingChargeTotal).toStringAsFixed(2);
        final grossAmt = inv.grossAmount.toStringAsFixed(2);
        final discount = (inv.couponDiscount + inv.manualDiscount).toStringAsFixed(2);
        final taxable = inv.taxableAmount.toStringAsFixed(2);
        final cgst = inv.cgst.toStringAsFixed(2);
        final sgst = inv.sgst.toStringAsFixed(2);
        final totalTax = inv.totalTax.toStringAsFixed(2);
        final netAmt = inv.netAmount.toStringAsFixed(2);

        final cash = _getCashPaid(inv).toStringAsFixed(2);
        final card = _getCardPaid(inv).toStringAsFixed(2);
        final upi = _getUpiPaid(inv).toStringAsFixed(2);
        final totalPaid = inv.totalAmountPaid.toStringAsFixed(2);
        final dues = inv.balanceDue.toStringAsFixed(2);
        final status = _getInvoiceStatus(inv);

        buffer.writeln('$invNo,$date,$custName,$phone,$address,$products,$purity,$grossWt,$netWt,$makingCharge,$grossAmt,$discount,$taxable,$cgst,$sgst,$totalTax,$netAmt,$cash,$card,$upi,$totalPaid,$dues,$status');
      }

      final bytes = utf8.encode(buffer.toString());
      final fileName = _getReportFileName(companyName, 'csv');
      await FileSaverHelper.saveCsvFile(bytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${_filteredInvoices.length} records as CSV database file.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToExcel(String companyName) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final excel = Excel.createExcel();
      final sheetName = excel.sheets.keys.first;
      final Sheet sheet = excel[sheetName];

      // Title Row
      sheet.appendRow([TextCellValue('$companyName Invoice Database Report')]);
      
      // Subtitle Date Row reflecting the defined period
      final dateRangeStr = 'Date Range: ${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)} | Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())} | Total Records: ${_filteredInvoices.length}';
      sheet.appendRow([TextCellValue(dateRangeStr)]);
      sheet.appendRow([]); // empty buffer row

      // Table Header
      final headers = [
        'Invoice No',
        'Date',
        'Customer Name',
        'Phone',
        'Address',
        'Particulars',
        'Purity',
        'Gross Wt (gm)',
        'Net Wt (gm)',
        'Making Charge (₹)',
        'Gross Amount (₹)',
        'Discount (₹)',
        'Taxable Amount (₹)',
        'CGST (₹)',
        'SGST (₹)',
        'Total Tax (₹)',
        'Net Amount (₹)',
        'Cash (₹)',
        'Card (₹)',
        'UPI (₹)',
        'Total Paid (₹)',
        'Dues (₹)',
        'Status',
      ].map((h) => TextCellValue(h)).toList();
      sheet.appendRow(headers);

      // Data Rows
      for (final inv in _filteredInvoices) {
        final makingChargeSum = inv.items.fold<double>(0, (sum, item) => sum + item.makingChargeTotal);
        final discountSum = inv.couponDiscount + inv.manualDiscount;
        sheet.appendRow([
          TextCellValue(inv.invoiceNumber ?? inv.id ?? ''),
          TextCellValue(DateFormat('dd/MM/yyyy').format(inv.invoiceDate)),
          TextCellValue(_getCustomerName(inv)),
          TextCellValue(_getCustomerPhone(inv)),
          TextCellValue(_getCustomerAddress(inv)),
          TextCellValue(_getProductDetails(inv)),
          TextCellValue(_getPurity(inv)),
          DoubleCellValue(_getTotalGrossWeight(inv)),
          DoubleCellValue(_getTotalNetWeight(inv)),
          DoubleCellValue(makingChargeSum),
          DoubleCellValue(inv.grossAmount),
          DoubleCellValue(discountSum),
          DoubleCellValue(inv.taxableAmount),
          DoubleCellValue(inv.cgst),
          DoubleCellValue(inv.sgst),
          DoubleCellValue(inv.totalTax),
          DoubleCellValue(inv.netAmount),
          DoubleCellValue(_getCashPaid(inv)),
          DoubleCellValue(_getCardPaid(inv)),
          DoubleCellValue(_getUpiPaid(inv)),
          DoubleCellValue(inv.totalAmountPaid),
          DoubleCellValue(inv.balanceDue),
          TextCellValue(_getInvoiceStatus(inv)),
        ]);
      }

      final bytes = excel.save();
      if (bytes != null) {
        final fileName = _getReportFileName(companyName, 'xlsx');
        await FileSaverHelper.saveExcelFile(bytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${_filteredInvoices.length} records to Excel.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToPdf(String companyName) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final doc = pw.Document();
      pw.Font fontData;
      pw.Font fontBold;
      try {
        fontData = await PdfGoogleFonts.poppinsRegular();
        fontBold = await PdfGoogleFonts.poppinsBold();
      } catch (_) {
        fontData = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$companyName — Invoices Database Report',
                      style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.amber900),
                    ),
                    pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(font: fontData, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Date Range: ${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)} | Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())} | Total Records: ${_filteredInvoices.length}',
                  style: pw.TextStyle(font: fontData, fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Divider(thickness: 1, color: PdfColors.amber900),
                pw.SizedBox(height: 6),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headers: [
                  'Inv No',
                  'Date',
                  'Customer',
                  'Phone',
                  'Particulars',
                  'Purity',
                  'Net Wt',
                  'Gross (₹)',
                  'Tax (₹)',
                  'Net (₹)',
                  'Paid (₹)',
                  'Dues (₹)',
                  'Status',
                ],
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.amber900),
                cellStyle: pw.TextStyle(font: fontData, fontSize: 7),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FixedColumnWidth(45),
                  1: const pw.FixedColumnWidth(45),
                  2: const pw.FixedColumnWidth(75),
                  3: const pw.FixedColumnWidth(55),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FixedColumnWidth(35),
                  6: const pw.FixedColumnWidth(40),
                  7: const pw.FixedColumnWidth(50),
                  8: const pw.FixedColumnWidth(45),
                  9: const pw.FixedColumnWidth(50),
                  10: const pw.FixedColumnWidth(48),
                  11: const pw.FixedColumnWidth(45),
                  12: const pw.FixedColumnWidth(42),
                },
                data: _filteredInvoices.map((inv) {
                  return [
                    inv.invoiceNumber ?? inv.id ?? '',
                    DateFormat('dd/MM/yy').format(inv.invoiceDate),
                    _getCustomerName(inv),
                    _getCustomerPhone(inv),
                    _getProductDetails(inv),
                    _getPurity(inv),
                    _getTotalNetWeight(inv).toStringAsFixed(3),
                    inv.grossAmount.toStringAsFixed(2),
                    inv.totalTax.toStringAsFixed(2),
                    inv.netAmount.toStringAsFixed(2),
                    inv.totalAmountPaid.toStringAsFixed(2),
                    inv.balanceDue.toStringAsFixed(2),
                    _getInvoiceStatus(inv),
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );
      final bytes = await doc.save();
      final fileName = _getReportFileName(companyName, 'pdf');
      await FileSaverHelper.savePdfFile(bytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${_filteredInvoices.length} records to PDF.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // --- Invoice Detail Modal Dialog ---

  void _showInvoiceDetailsDialog(Invoice inv, CompanySettings? company) {
    final customer = _resolveCustomer(inv);
    final status = _getInvoiceStatus(inv);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNumber ?? inv.id ?? 'Invoice Record',
                            style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat('dd MMMM yyyy, hh:mm a').format(inv.invoiceDate),
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CUSTOMER DETAILS', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoRow('Name', customer.name),
                                  ),
                                  Expanded(
                                    child: _buildInfoRow('Phone', customer.mobile.isNotEmpty ? customer.mobile : '—'),
                                  ),
                                ],
                              ),
                              if (customer.address != null && customer.address!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow('Address', customer.address!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Itemized Products
                        Text('ITEMS & ORNAMENTS', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('Item', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 1, child: Text('Purity', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('Weight', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('Making', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                    Expanded(flex: 2, child: Text('Total', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                  ],
                                ),
                              ),
                              if (inv.items.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('No itemized ornaments recorded.', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                )
                              else
                                ...inv.items.map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.productName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                                                if (item.huidNumber?.isNotEmpty == true)
                                                  Text('HUID: ${item.huidNumber}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                              ],
                                            ),
                                          ),
                                          Expanded(flex: 1, child: Text(item.purity, style: AppTextStyles.bodyMd)),
                                          Expanded(flex: 2, child: Text('${item.netWeight.toStringAsFixed(3)} g', style: AppTextStyles.bodyMd)),
                                          Expanded(flex: 2, child: Text('₹${item.makingChargeTotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMd, textAlign: TextAlign.right)),
                                          Expanded(flex: 2, child: Text('₹${item.itemTotal.toStringAsFixed(2)}', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                        ],
                                      ),
                                    )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Financial & Tax Breakdown
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FINANCIAL & TAX SUMMARY', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildAmountRow('Gross Amount', inv.grossAmount),
                              if (inv.couponDiscount + inv.manualDiscount > 0)
                                _buildAmountRow('Discount', -(inv.couponDiscount + inv.manualDiscount), color: AppColors.success),
                              _buildAmountRow('Taxable Amount', inv.taxableAmount),
                              _buildAmountRow('CGST (1.5%)', inv.cgst),
                              _buildAmountRow('SGST (1.5%)', inv.sgst),
                              _buildAmountRow('Total GST (3.0%)', inv.totalTax),
                              const Divider(height: 16),
                              _buildAmountRow('Net Total Amount', inv.netAmount, isBold: true, fontSize: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Payments & Dues
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PAYMENTS & BALANCE', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildAmountRow('By Cash', _getCashPaid(inv)),
                              _buildAmountRow('By Card', _getCardPaid(inv)),
                              _buildAmountRow('By UPI / Bank', _getUpiPaid(inv)),
                              const Divider(height: 12),
                              _buildAmountRow('Total Received', inv.totalAmountPaid, isBold: true, color: AppColors.success),
                              _buildAmountRow('Outstanding Dues', inv.balanceDue, isBold: true, color: inv.balanceDue > 0 ? AppColors.error : AppColors.onSurfaceMuted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        PdfHelper.downloadInvoicePdf(
                          invoice: inv,
                          customer: customer,
                          company: company,
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download PDF'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        PdfHelper.generateAndPrintInvoice(
                          invoice: inv,
                          customer: customer,
                          company: company,
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print / View Invoice'),
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

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'PAID':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'PARTIAL':
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber.shade800;
        break;
      case 'CANCELLED':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelMd.copyWith(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
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
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
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

  // --- Metrics Summary Cards ---

  Widget _buildSummaryMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 650;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricCard(
                'TOTAL INVOICES',
                '${_filteredInvoices.length}',
                Icons.receipt_long_rounded,
                AppColors.primary,
                isSmall ? (constraints.maxWidth - 12) / 2 : null,
              ),
              _buildMetricCard(
                'TOTAL WEIGHT',
                '${_totalWeight.toStringAsFixed(3)} gm',
                Icons.scale_rounded,
                Colors.amber.shade700,
                isSmall ? (constraints.maxWidth - 12) / 2 : null,
              ),
              _buildMetricCard(
                'GROSS SALES',
                '₹${_totalGrossSales.toStringAsFixed(2)}',
                Icons.account_balance_wallet_rounded,
                Colors.indigo,
                isSmall ? (constraints.maxWidth - 12) / 2 : null,
              ),
              _buildMetricCard(
                'GST COLLECTED',
                '₹${_totalGst.toStringAsFixed(2)}',
                Icons.percent_rounded,
                Colors.teal,
                isSmall ? (constraints.maxWidth - 12) / 2 : null,
              ),
              _buildMetricCard(
                'NET SALES',
                '₹${_totalNetSales.toStringAsFixed(2)}',
                Icons.payments_rounded,
                AppColors.success,
                isSmall ? (constraints.maxWidth - 12) / 2 : null,
              ),
              _buildMetricCard(
                'TOTAL RECEIVED',
                '₹${_totalPaid.toStringAsFixed(2)}',
                Icons.price_check_rounded,
                Colors.teal.shade700,
                isSmall ? (constraints.maxWidth - 12) / 2 : null,
              ),
              _buildMetricCard(
                'OUTSTANDING DUES',
                '₹${_totalDues.toStringAsFixed(2)}',
                Icons.pending_actions_rounded,
                _totalDues > 0 ? AppColors.error : AppColors.onSurfaceMuted,
                isSmall ? (constraints.maxWidth - 12) / 2 : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, double? fixedWidth) {
    return Container(
      width: fixedWidth,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: fixedWidth != null ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Mobile Card View ---

  Widget _buildMobileCardsList(CompanySettings? company) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _filteredInvoices.length,
      itemBuilder: (context, index) {
        final inv = _filteredInvoices[index];
        final customerName = _getCustomerName(inv);
        final customerPhone = _getCustomerPhone(inv);
        final particulars = _getProductDetails(inv);
        final purity = _getPurity(inv);
        final netWt = _getTotalNetWeight(inv);
        final status = _getInvoiceStatus(inv);
        final paymentBreakdown = _getPaymentBreakdown(inv);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.glassBorder),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showInvoiceDetailsDialog(inv, company),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Inv No + Date + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            inv.invoiceNumber ?? inv.id ?? '',
                            style: AppTextStyles.titleSm.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(inv.invoiceDate),
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(status),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Customer Name & Phone
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16, color: AppColors.onSurfaceMuted),
                      const SizedBox(width: 6),
                      Text(customerName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                      if (customerPhone != '—') ...[
                        const SizedBox(width: 10),
                        Icon(Icons.phone_outlined, size: 14, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text(customerPhone, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Particulars, Purity & Weight badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Text(
                          particulars,
                          style: AppTextStyles.bodySm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (purity != '—')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            purity,
                            style: AppTextStyles.labelSm.copyWith(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (netWt > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${netWt.toStringAsFixed(3)} gm',
                            style: AppTextStyles.labelSm.copyWith(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 4: Net Amount & Dues
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NET AMOUNT', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10)),
                          Text(
                            '₹${inv.netAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.titleMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('PAYMENT / DUES', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10)),
                          Row(
                            children: [
                              Text(
                                paymentBreakdown != '—' ? paymentBreakdown : 'Paid: ₹${inv.totalAmountPaid.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                              ),
                              if (inv.balanceDue > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Dues: ₹${inv.balanceDue.toStringAsFixed(0)}',
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Main Build ---

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports & Invoice Database',
                        style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Filter, view complete invoice records, and export full database',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      alignment: Alignment.centerLeft,
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
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      alignment: Alignment.centerLeft,
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
                                hint: 'Search invoice no, customer, purity, cash, etc...',
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
                                  minimumSize: const Size(0, 50),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
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

                  // Summary Statistics Strip (Matches Swarnayan Invoice DB stats)
                  if (_hasSearched && _filteredInvoices.isNotEmpty) ...[
                    _buildSummaryMetrics(),
                    const SizedBox(height: 20),
                  ],

                  // Action Toolbar (Export Buttons & View Toggle)
                  if (_hasSearched && _filteredInvoices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // View Switcher (Cards vs Table)
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.table_chart_rounded, size: 16),
                                label: Text('Table'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.view_agenda_rounded, size: 16),
                                label: Text('Cards'),
                              ),
                            ],
                            selected: {_isCardView},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                _isCardView = newSelection.first;
                              });
                            },
                          ),

                          // Export Buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (_isExporting) ...[
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                                const SizedBox(width: 4),
                                Text('Downloading...', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                              ],
                              // CSV (Database Dump)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _isExporting ? null : () => _exportToCsv(companyName),
                                icon: const Icon(Icons.dataset_rounded, size: 16),
                                label: const Text('Export CSV (DB)'),
                              ),
                              // XLSX
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _isExporting ? null : () => _exportToExcel(companyName),
                                icon: const Icon(Icons.grid_on_rounded, size: 16),
                                label: const Text('Export XLSX'),
                              ),
                              // PDF
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _isExporting ? null : () => _exportToPdf(companyName),
                                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                                label: const Text('Export PDF'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Results Grid / Table / Cards
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
                          : _isCardView
                              ? _buildMobileCardsList(companyState.value)
                              : Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  color: AppColors.surfaceContainer,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                    side: BorderSide(color: AppColors.glassBorder),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainerHigh),
                                        dataRowColor: WidgetStateProperty.all(AppColors.surface),
                                        dividerThickness: 0.5,
                                        showCheckboxColumn: false,
                                        columns: [
                                          DataColumn(label: Text('Invoice No.', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Date', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Customer Name', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Phone', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Particulars', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Purity', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Net Wt (gm)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Gross Amt (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Making (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Discount (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Taxable (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('CGST (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('SGST (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Total GST (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Net Amt (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Payment Mode', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Paid (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Dues (₹)', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Status', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('Actions', style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: _filteredInvoices.map((inv) {
                                          final makingChargeSum = inv.items.fold<double>(0, (sum, item) => sum + item.makingChargeTotal);
                                          final discountSum = inv.couponDiscount + inv.manualDiscount;
                                          final status = _getInvoiceStatus(inv);

                                          return DataRow(
                                            onSelectChanged: (_) => _showInvoiceDetailsDialog(inv, companyState.value),
                                            cells: [
                                              DataCell(
                                                Row(
                                                  children: [
                                                    Icon(Icons.receipt_rounded, size: 16, color: AppColors.primary),
                                                    const SizedBox(width: 6),
                                                    Text(inv.invoiceNumber ?? inv.id ?? '', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(DateFormat('dd/MM/yyyy').format(inv.invoiceDate), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(_getCustomerName(inv), style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600))),
                                              DataCell(Text(_getCustomerPhone(inv), style: AppTextStyles.bodyMd)),
                                              DataCell(
                                                Container(
                                                  constraints: const BoxConstraints(maxWidth: 220),
                                                  child: Text(
                                                    _getProductDetails(inv),
                                                    style: AppTextStyles.bodyMd,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(_getPurity(inv), style: AppTextStyles.bodySm.copyWith(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              DataCell(Text(_getTotalNetWeight(inv).toStringAsFixed(3), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(inv.grossAmount.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(makingChargeSum.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(discountSum.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(inv.taxableAmount.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(inv.cgst.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(inv.sgst.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(inv.totalTax.toStringAsFixed(2), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(inv.netAmount.toStringAsFixed(2), style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary))),
                                              DataCell(Text(_getPaymentBreakdown(inv), style: AppTextStyles.bodyMd)),
                                              DataCell(Text(inv.totalAmountPaid.toStringAsFixed(2), style: AppTextStyles.bodyMd.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))),
                                              DataCell(
                                                Text(
                                                  inv.balanceDue.toStringAsFixed(2),
                                                  style: AppTextStyles.bodyMd.copyWith(
                                                    color: inv.balanceDue > 0 ? AppColors.error : AppColors.onSurfaceMuted,
                                                    fontWeight: inv.balanceDue > 0 ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              DataCell(_buildStatusBadge(status)),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                                      tooltip: 'View Details',
                                                      onPressed: () => _showInvoiceDetailsDialog(inv, companyState.value),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.download_outlined, size: 18),
                                                      tooltip: 'Download Invoice PDF',
                                                      onPressed: () {
                                                        PdfHelper.downloadInvoicePdf(
                                                          invoice: inv,
                                                          customer: _resolveCustomer(inv),
                                                          company: companyState.value,
                                                        );
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.print_outlined, size: 18),
                                                      tooltip: 'Print Invoice',
                                                      onPressed: () {
                                                        PdfHelper.generateAndPrintInvoice(
                                                          invoice: inv,
                                                          customer: _resolveCustomer(inv),
                                                          company: companyState.value,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
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
