import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/company_settings.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import 'pdf_helper.dart';
import 'file_saver_helper.dart';

class BulkInvoiceParseResult {
  final List<Invoice> invoices;
  final Map<String, Customer> customers;
  final int totalRows;
  final List<String> errors;

  BulkInvoiceParseResult({
    required this.invoices,
    required this.customers,
    required this.totalRows,
    required this.errors,
  });
}

class BulkInvoiceService {
  BulkInvoiceService._();

  /// Parse CSV string into structured Invoices and Customer maps.
  /// Supports Swarnayan Jewellers format and standard retail invoice CSVs.
  static BulkInvoiceParseResult parseCsv(String csvContent) {
    final lines = const LineSplitter().convert(csvContent)
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return BulkInvoiceParseResult(invoices: [], customers: {}, totalRows: 0, errors: ['CSV file is empty.']);
    }

    // Find header line
    int headerIndex = -1;
    List<String> headers = [];
    for (int i = 0; i < lines.length; i++) {
      final cells = _parseCsvLine(lines[i]).map((c) => _cleanHeader(c)).toList();
      if (cells.any((c) => c.contains('invoice') || c == 'inv no' || c == 'invoiceno')) {
        headerIndex = i;
        headers = cells;
        break;
      }
    }

    if (headerIndex == -1) {
      // Fallback: Assume row 0 is header
      headers = _parseCsvLine(lines.first).map((c) => _cleanHeader(c)).toList();
      headerIndex = 0;
    }

    final int colInvNo = _findColumnIndex(headers, ['invoiceno', 'invoicenumber', 'invno', 'invoiceno.', 'billno']);
    final int colDate = _findColumnIndex(headers, ['date', 'invoicedate', 'billdate']);
    final int colCustomer = _findColumnIndex(headers, ['customername', 'customer', 'client', 'name', 'billedto']);
    final int colMobile = _findColumnIndex(headers, ['mobile', 'phone', 'customermobile', 'contact']);
    final int colAddress = _findColumnIndex(headers, ['address', 'customeraddress', 'city', 'location']);
    final int colParticulars = _findColumnIndex(headers, ['particulars', 'product', 'productname', 'item', 'items', 'description']);
    final int colPurity = _findColumnIndex(headers, ['purity', 'carat', 'kt']);
    final int colWeight = _findColumnIndex(headers, ['netwt(gm)', 'netwt', 'weight', 'grosswt', 'wt']);
    final int colRate = _findColumnIndex(headers, ['rate', 'metalrate', 'goldrate', 'silverrate']);
    final int colMaking = _findColumnIndex(headers, ['makingcharge', 'making', 'makingcharges', 'mc']);
    final int colGrossAmt = _findColumnIndex(headers, ['grossamt(₹)', 'grossamt', 'grossamount', 'subtotal']);
    final int colCgst = _findColumnIndex(headers, ['cgst(₹)', 'cgst', 'cgstamt']);
    final int colSgst = _findColumnIndex(headers, ['sgst(₹)', 'sgst', 'sgstamt']);
    final int colNetAmt = _findColumnIndex(headers, ['netamt(₹)', 'netamt', 'netamount', 'total', 'finalpayable', 'grandtotal']);
    final int colPaymentMode = _findColumnIndex(headers, ['paymentmode', 'payment', 'mode', 'paymentmethod']);
    final int colDues = _findColumnIndex(headers, ['dues(₹)', 'dues', 'balance', 'balancedue', 'dueamt']);

    final Map<String, List<Map<String, dynamic>>> groupedRows = {};
    final List<String> errors = [];
    int totalDataRows = 0;

    for (int i = headerIndex + 1; i < lines.length; i++) {
      final rawLine = lines[i];
      if (rawLine.startsWith('#') || rawLine.startsWith('---')) continue;
      
      final cells = _parseCsvLine(rawLine);
      if (cells.isEmpty || cells.every((c) => c.trim().isEmpty || c == '—')) continue;

      totalDataRows++;

      String invNo = colInvNo != -1 && colInvNo < cells.length ? cells[colInvNo].trim() : '';
      if (invNo.isEmpty || invNo == '—') {
        invNo = 'INV-${(i).toString().padLeft(6, '0')}';
      }

      groupedRows.putIfAbsent(invNo, () => []).add({
        'rowIndex': i + 1,
        'invNo': invNo,
        'date': colDate != -1 && colDate < cells.length ? cells[colDate].trim() : '',
        'customer': colCustomer != -1 && colCustomer < cells.length ? cells[colCustomer].trim() : '',
        'mobile': colMobile != -1 && colMobile < cells.length ? cells[colMobile].trim() : '',
        'address': colAddress != -1 && colAddress < cells.length ? cells[colAddress].trim() : '',
        'particulars': colParticulars != -1 && colParticulars < cells.length ? cells[colParticulars].trim() : '',
        'purity': colPurity != -1 && colPurity < cells.length ? cells[colPurity].trim() : '',
        'weight': colWeight != -1 && colWeight < cells.length ? cells[colWeight].trim() : '',
        'rate': colRate != -1 && colRate < cells.length ? cells[colRate].trim() : '',
        'making': colMaking != -1 && colMaking < cells.length ? cells[colMaking].trim() : '',
        'gross': colGrossAmt != -1 && colGrossAmt < cells.length ? cells[colGrossAmt].trim() : '',
        'cgst': colCgst != -1 && colCgst < cells.length ? cells[colCgst].trim() : '',
        'sgst': colSgst != -1 && colSgst < cells.length ? cells[colSgst].trim() : '',
        'net': colNetAmt != -1 && colNetAmt < cells.length ? cells[colNetAmt].trim() : '',
        'payment': colPaymentMode != -1 && colPaymentMode < cells.length ? cells[colPaymentMode].trim() : '',
        'dues': colDues != -1 && colDues < cells.length ? cells[colDues].trim() : '',
      });
    }

    final List<Invoice> invoices = [];
    final Map<String, Customer> customers = {};

    groupedRows.forEach((invNumber, rowList) {
      try {
        final firstRow = rowList.first;
        final DateTime invoiceDate = _parseDate(firstRow['date']) ?? DateTime.now();
        final String custName = firstRow['customer'].isNotEmpty && firstRow['customer'] != '—'
            ? firstRow['customer']
            : 'Counter Customer';
        final String custMobile = firstRow['mobile'] != '—' ? firstRow['mobile'] : '';
        final String custAddress = firstRow['address'] != '—' ? firstRow['address'] : '';

        final customer = Customer(
          id: 'temp-$invNumber',
          name: custName,
          mobile: custMobile,
          address: custAddress,
        );
        customers[invNumber] = customer;

        final List<InvoiceItem> items = [];
        double grossTotal = 0.0;
        double netTotal = 0.0;
        double cgstTotal = 0.0;
        double sgstTotal = 0.0;
        double duesTotal = 0.0;

        for (final row in rowList) {
          final String rawParticulars = row['particulars'] != '—' ? row['particulars'] : '';
          final String rawPurity = row['purity'] != '—' ? row['purity'] : '22K';
          final double weight = _parseDouble(row['weight']) ?? 1.0;
          final double rowGross = _parseDouble(row['gross']) ?? 0.0;
          final double rowNet = _parseDouble(row['net']) ?? rowGross;
          final double rowCgst = _parseDouble(row['cgst']) ?? 0.0;
          final double rowSgst = _parseDouble(row['sgst']) ?? 0.0;
          final double rowDues = _parseDouble(row['dues']) ?? 0.0;
          final double rowRate = _parseDouble(row['rate']) ?? (weight > 0 && rowGross > 0 ? (rowGross / weight) : 0.0);
          final double rowMaking = _parseDouble(row['making']) ?? 0.0;

          grossTotal += rowGross;
          netTotal += rowNet;
          cgstTotal += rowCgst;
          sgstTotal += rowSgst;
          duesTotal += rowDues;

          // Split particulars by semicolon if multiple products listed in one row
          final subProducts = rawParticulars.isNotEmpty
              ? rawParticulars.split(';').map((p) => p.trim()).where((p) => p.isNotEmpty).toList()
              : ['Jewellery Item'];

          final double subWeight = subProducts.length > 1 ? (weight / subProducts.length) : weight;
          final double subTotal = subProducts.length > 1 ? (rowGross / subProducts.length) : (rowGross > 0 ? rowGross : rowNet);

          for (int pIdx = 0; pIdx < subProducts.length; pIdx++) {
            final prodTitle = subProducts[pIdx];
            final category = rawPurity.toUpperCase().contains('SILVER')
                ? 'SILVER'
                : (rawPurity.toUpperCase().contains('DIAMOND') ? 'DIAMOND' : 'GOLD');

            items.add(InvoiceItem(
              productId: 'bulk-$invNumber-${items.length + 1}',
              productName: prodTitle,
              hsnCode: category == 'SILVER' ? '7113' : '7113',
              category: category,
              purity: rawPurity.isNotEmpty ? rawPurity : (category == 'SILVER' ? 'SILVER' : '22K'),
              grossWeight: subWeight,
              netWeight: subWeight,
              rate: rowRate > 0 ? rowRate : (subWeight > 0 ? subTotal / subWeight : 0.0),
              metalValue: subTotal,
              makingChargeType: 'FIXED',
              makingChargeValue: rowMaking > 0 ? rowMaking : 0.0,
              makingChargeTotal: rowMaking > 0 ? rowMaking : 0.0,
              itemTotal: subTotal,
            ));
          }
        }

        if (grossTotal == 0.0 && netTotal > 0.0) {
          grossTotal = netTotal - (cgstTotal + sgstTotal);
        }
        if (netTotal == 0.0 && grossTotal > 0.0) {
          netTotal = grossTotal + cgstTotal + sgstTotal;
        }

        // Parse payment mode
        final String rawPayment = firstRow['payment'];
        final List<Payment> payments = _parsePaymentModes(rawPayment, netTotal, duesTotal);
        final double totalPaid = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
        final double balanceDue = (netTotal - totalPaid).clamp(0.0, netTotal);

        final invoice = Invoice(
          id: 'bulk-$invNumber',
          invoiceNumber: invNumber,
          tempCustomerName: custName,
          tempCustomerMobile: custMobile,
          tempCustomerAddress: custAddress,
          items: items.isNotEmpty ? items : [
            InvoiceItem(
              productId: 'bulk-$invNumber-1',
              productName: 'Jewellery Item',
              hsnCode: '7113',
              category: 'GOLD',
              purity: '22K',
              grossWeight: 1.0,
              netWeight: 1.0,
              rate: grossTotal,
              metalValue: grossTotal,
              makingChargeType: 'FIXED',
              makingChargeValue: 0.0,
              makingChargeTotal: 0.0,
              itemTotal: grossTotal,
            )
          ],
          grossAmount: grossTotal,
          taxableAmount: grossTotal,
          cgst: cgstTotal,
          sgst: sgstTotal,
          totalTax: cgstTotal + sgstTotal,
          netAmount: netTotal,
          finalPayable: netTotal,
          payments: payments,
          totalAmountPaid: totalPaid,
          balanceDue: balanceDue,
          invoiceDate: invoiceDate,
          ratesSnapshot: const RatesSnapshot(
            rateGold22K: 7200,
            rateGold18K: 5900,
            rateSilver: 88,
          ),
          status: balanceDue <= 0.05 ? 'PAID' : (totalPaid > 0 ? 'PARTIAL' : 'PENDING'),
        );

        invoices.add(invoice);
      } catch (e) {
        errors.add('Failed to parse invoice $invNumber: $e');
      }
    });

    return BulkInvoiceParseResult(
      invoices: invoices,
      customers: customers,
      totalRows: totalDataRows,
      errors: errors,
    );
  }

  /// Generates a ZIP archive containing PDFs for all parsed invoices.
  static Future<Uint8List> generateBulkInvoicesZip({
    required List<Invoice> invoices,
    required Map<String, Customer> customers,
    CompanySettings? companySettings,
    Function(int current, int total, String currentInvoice)? onProgress,
  }) async {
    final archive = Archive();

    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final invNo = invoice.invoiceNumber ?? 'INV_${i + 1}';
      onProgress?.call(i + 1, invoices.length, invNo);

      final customer = customers[invNo] ?? Customer(
        id: '',
        name: invoice.tempCustomerName ?? 'Customer',
        mobile: invoice.tempCustomerMobile ?? '',
        address: invoice.tempCustomerAddress ?? '',
      );

      try {
        final pdfBytes = await PdfHelper.generateInvoicePdfBytes(
          invoice: invoice,
          customer: customer,
          company: companySettings,
        );

        final fileName = '${PdfHelper.getInvoiceDocumentTitle(invoice: invoice, customer: customer)}.pdf';
        archive.addFile(ArchiveFile(fileName, pdfBytes.length, pdfBytes));
      } catch (e) {
        debugPrint('Failed to generate PDF for invoice $invNo: $e');
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes ?? []);
  }

  /// Save ZIP file to device storage or trigger download/share.
  static Future<String?> saveOrShareZip(Uint8List zipBytes, {String? defaultFileName}) async {
    final fileName = defaultFileName ?? 'Swarnayan_Invoices_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.zip';

    if (kIsWeb) {
      if (fileName.toLowerCase().endsWith('.csv')) {
        await FileSaverHelper.saveCsvFile(zipBytes, fileName);
      } else {
        await FileSaverHelper.saveZipFile(zipBytes, fileName);
      }
      return fileName;
    }

    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final String? outputFile = await FilePicker.saveFile(
          dialogTitle: 'Save Invoices ZIP Archive',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['zip', 'csv'],
        );

        if (outputFile != null) {
          final file = File(outputFile.endsWith('.zip') || outputFile.endsWith('.csv') ? outputFile : '$outputFile.zip');
          await file.writeAsBytes(zipBytes);
          return file.path;
        }
        return null;
      } else {
        // Mobile / Android / iOS fallback
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(zipBytes);

        // Try SharePlus for mobile download
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Swarnayan Invoices Bulk Export',
        );
        return file.path;
      }
    } catch (e) {
      debugPrint('Error saving bulk export file: $e');
      if (!kIsWeb) {
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(zipBytes);
          return file.path;
        } catch (_) {}
      }
      return null;
    }
  }

  /// Returns a sample CSV string for users to download and follow.
  static String getSampleCsvTemplate() {
    return '''Invoice No.,Date,Customer Name,Particulars,Purity,Net Wt (gm),Gross Amt (₹),CGST (₹),SGST (₹),Net Amt (₹),Payment Mode,Dues (₹)
S-000645,05/08/2026,Ramesh Kumar,Gold Chain 22K HM,22K,12.450,89640.00,1344.60,1344.60,92329.00,Cash ₹92329,0.00
S-000646,06/08/2026,Priya Sharma,Silver Payal,SILVER,47.000,11985.00,179.78,179.78,12345.00,UPI ₹12345,0.00
S-000647,07/08/2026,Anil Verma,L Ring 18K; G Ring 22K,22K,6.500,45000.00,675.00,675.00,46350.00,Cash ₹20000; UPI ₹26350,0.00
''';
  }

  // --- Internal Parser Helpers ---

  static List<String> _parseCsvLine(String line) {
    final List<String> cells = [];
    final StringBuffer currentCell = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if ((char == ',' || char == '\t') && !insideQuotes) {
        cells.add(currentCell.toString().trim());
        currentCell.clear();
      } else if (char == '|' && !insideQuotes) {
        // Support markdown pipe format
        cells.add(currentCell.toString().trim());
        currentCell.clear();
      } else {
        currentCell.write(char);
      }
    }
    cells.add(currentCell.toString().trim());

    // If markdown table line, trim leading/trailing empty cells
    if (line.startsWith('|') && cells.isNotEmpty && cells.first.isEmpty) {
      cells.removeAt(0);
    }
    if (line.endsWith('|') && cells.isNotEmpty && cells.last.isEmpty) {
      cells.removeLast();
    }

    return cells;
  }

  static String _cleanHeader(String h) {
    return h.toLowerCase().replaceAll(RegExp(r'[\s_.\-()₹]'), '');
  }

  static int _findColumnIndex(List<String> headers, List<String> candidates) {
    for (final candidate in candidates) {
      final idx = headers.indexOf(candidate);
      if (idx != -1) return idx;
    }
    for (int i = 0; i < headers.length; i++) {
      for (final candidate in candidates) {
        if (headers[i].contains(candidate) || candidate.contains(headers[i])) {
          return i;
        }
      }
    }
    return -1;
  }

  static double? _parseDouble(String? str) {
    if (str == null) return null;
    final cleaned = str.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  static DateTime? _parseDate(String? str) {
    if (str == null || str.trim().isEmpty || str == '—') return null;
    final trimmed = str.trim();
    try {
      if (trimmed.contains('/')) {
        final parts = trimmed.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
          return DateTime(year, month, day);
        }
      }
      if (trimmed.contains('-')) {
        final parts = trimmed.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime.parse(trimmed);
          } else {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
            return DateTime(year, month, day);
          }
        }
      }
      return DateTime.tryParse(trimmed);
    } catch (_) {
      return null;
    }
  }

  static List<Payment> _parsePaymentModes(String rawPayment, double netTotal, double dues) {
    final List<Payment> payments = [];
    if (rawPayment.isEmpty || rawPayment == '—') {
      final paid = (netTotal - dues).clamp(0.0, netTotal);
      if (paid > 0) {
        payments.add(Payment(method: 'CASH', amount: paid));
      }
      return payments;
    }

    final segments = rawPayment.contains(';') ? rawPayment.split(';') : [rawPayment];
    for (final seg in segments) {
      final trimmed = seg.trim();
      final upper = trimmed.toUpperCase();
      String method = 'CASH';
      if (upper.contains('UPI') || upper.contains('GPAY') || upper.contains('PHONEPE') || upper.contains('PAYTM')) {
        method = 'UPI';
      } else if (upper.contains('CARD') || upper.contains('DEBIT') || upper.contains('CREDIT') || upper.contains('POS')) {
        method = 'CARD';
      } else if (upper.contains('BANK') || upper.contains('NEFT') || upper.contains('RTGS') || upper.contains('IMPS')) {
        method = 'BANK_TRANSFER';
      } else if (upper.contains('CHEQUE') || upper.contains('CHECK')) {
        method = 'CHEQUE';
      }

      final amount = _parseDouble(trimmed);
      if (amount != null && amount > 0) {
        payments.add(Payment(method: method, amount: amount));
      } else {
        final paid = (netTotal - dues).clamp(0.0, netTotal);
        if (paid > 0) {
          payments.add(Payment(method: method, amount: paid));
        }
      }
    }

    if (payments.isEmpty) {
      final paid = (netTotal - dues).clamp(0.0, netTotal);
      if (paid > 0) {
        payments.add(Payment(method: 'CASH', amount: paid));
      }
    }

    return payments;
  }
}
