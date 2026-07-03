import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/company_settings.dart';

String numberToRupeesWords(double amount) {
  final intAmount = amount.floor();
  final fraction = ((amount - intAmount) * 100).round();
  
  String fractionStr = '';
  if (fraction > 0) {
    fractionStr = ' and ${numberToWords(fraction)} Paise';
  }
  
  return 'Rupees ${numberToWords(intAmount)}$fractionStr Only';
}

String numberToWords(int num) {
  if (num == 0) return 'Zero';
  
  const a = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
  ];
  
  const b = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
  
  String words = '';
  
  if (num >= 10000000) {
    words += '${numberToWords(num ~/ 10000000)} Crore ';
    num %= 10000000;
  }
  
  if (num >= 100000) {
    words += '${numberToWords(num ~/ 100000)} Lakh ';
    num %= 100000;
  }
  
  if (num >= 1000) {
    words += '${numberToWords(num ~/ 1000)} Thousand ';
    num %= 1000;
  }
  
  if (num >= 100) {
    words += '${a[num ~/ 100]} Hundred ';
    num %= 100;
  }
  
  if (num > 0) {
    if (words.isNotEmpty) words += 'and ';
    if (num < 20) {
      words += a[num];
    } else {
      words += b[num ~/ 10];
      if (num % 10 > 0) {
        words += '-${a[num % 10]}';
      }
    }
  }
  
  return words.trim();
}

class PdfHelper {
  PdfHelper._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );

  static Future<void> generateAndPrintInvoice({
    required Invoice invoice,
    required Customer customer,
    CompanySettings? company,
  }) async {
    final doc = pw.Document();

    final fontData = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontItalic = await PdfGoogleFonts.poppinsItalic();

    // Dynamically retrieve company details with Patna settings as fallback
    final String cName = company?.companyName.isNotEmpty == true ? company!.companyName : 'SWARNAYAN JEWELLERS';
    final String cTagline = company?.tagline.isNotEmpty == true ? company!.tagline : 'Trusted Hallmark Jewellery Destination';
    final String cNotes = company?.notes.isNotEmpty == true ? company!.notes : 'Offering Gold, Silver & Diamond Collections';
    final String cPhone = company?.mobile.isNotEmpty == true ? company!.mobile : '7903111274';
    final String cEmail = company?.email.isNotEmpty == true ? company!.email : 'swarnayanjewellers@gmail.com';
    
    String cAddressLine = '';
    if (company != null) {
      final addr = company.address;
      final parts = <String>[];
      if (addr.line1.isNotEmpty) parts.add(addr.line1);
      if (addr.line2.isNotEmpty) parts.add(addr.line2);
      if (addr.city.isNotEmpty) parts.add(addr.city);
      if (addr.state.isNotEmpty) parts.add(addr.state);
      cAddressLine = parts.join(', ');
      if (addr.postalCode.isNotEmpty) {
        cAddressLine += ' - ${addr.postalCode}';
      }
    } else {
      cAddressLine = 'Gulab Bagh Market, Thakurbari Road, Patna, Bihar - 800004';
    }

    final String cGstin = company?.gstin.isNotEmpty == true ? company!.gstin : '10AQOPK4039R1ZF';

    final List<String> cTerms = company != null && company.termsAndConditions.isNotEmpty
        ? company.termsAndConditions
        : [
            'Making charges, GST, and wastage charges are non-refundable under any circumstances once the purchase has been completed.',
            'No guarantee is provided against breakage or damage after purchase',
            'Subject to Patna jurisdiction only',
            'Please present the original invoice for any return or exchange of purchased items.',
          ];

    final double totalMakingCharge = invoice.items.fold<double>(0, (sum, item) => sum + item.makingChargeTotal);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header section (Branding & Shop Details)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cName,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        cTagline,
                        style: pw.TextStyle(
                          font: fontItalic,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        cNotes,
                        style: pw.TextStyle(
                          font: fontData,
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'GSTIN: $cGstin | Phone: +91 $cPhone',
                        style: pw.TextStyle(font: fontData, fontSize: 8.5),
                      ),
                      pw.Text(
                        cAddressLine,
                        style: pw.TextStyle(font: fontData, fontSize: 8.5),
                      ),
                      pw.Text(
                        'Email: $cEmail',
                        style: pw.TextStyle(font: fontData, fontSize: 8.5),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _invoiceMetaRow('Invoice No:', invoice.invoiceNumber ?? 'N/A', fontBold, fontData),
                      _invoiceMetaRow('Date:', DateFormat('dd MMM yyyy').format(invoice.invoiceDate), fontBold, fontData),
                      _invoiceMetaRow('Status:', invoice.status, fontBold, fontData),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Customer Details block
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILLED TO:',
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          customer.name,
                          style: pw.TextStyle(font: fontBold, fontSize: 11),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'Mobile: ${customer.mobile}',
                          style: pw.TextStyle(font: fontData, fontSize: 9),
                        ),
                        if (customer.email != null && customer.email!.isNotEmpty)
                          pw.Text(
                            'Email: ${customer.email!}',
                            style: pw.TextStyle(font: fontData, fontSize: 9),
                          ),
                        if (customer.address != null && customer.address!.isNotEmpty)
                          pw.Text(
                            'Address: ${customer.address!}',
                            style: pw.TextStyle(font: fontData, fontSize: 9),
                          ),
                        if (customer.panCard != null && customer.panCard!.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'PAN Card: ${customer.panCard!}',
                              style: pw.TextStyle(font: fontBold, fontSize: 9),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.0), // Name/Details
                  1: const pw.FlexColumnWidth(1.0), // HSN
                  2: const pw.FlexColumnWidth(1.0), // Purity
                  3: const pw.FlexColumnWidth(1.2), // Weight
                  4: const pw.FlexColumnWidth(1.2), // Rate
                  5: const pw.FlexColumnWidth(1.5), // Making Charge (format: ₹Amount/type)
                  6: const pw.FlexColumnWidth(1.5), // Total
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableHeaderCell('Product / Details', fontBold),
                      _tableHeaderCell('HSN', fontBold),
                      _tableHeaderCell('Purity', fontBold),
                      _tableHeaderCell('Weight', fontBold),
                      _tableHeaderCell('Rate', fontBold),
                      _tableHeaderCell('Making Charge', fontBold),
                      _tableHeaderCell('Total', fontBold),
                    ],
                  ),
                  // Table Rows
                  ...invoice.items.map((item) {
                    final String makingTypeStr = item.makingChargeType == 'FIXED'
                        ? '/pcs'
                        : item.makingChargeType == 'PER_GRAM'
                            ? '/gm'
                            : '%';
                    final makingChargeDetail = item.makingChargeType == 'PERCENTAGE'
                        ? '${item.makingChargeValue.toStringAsFixed(0)}%'
                        : 'Rs ${item.makingChargeValue.toStringAsFixed(0)}$makingTypeStr';

                    return pw.TableRow(
                      children: [
                        _tableDataCell(
                          '${item.productName}${item.huidNumber != null && item.huidNumber!.isNotEmpty ? '\nHUID: ${item.huidNumber}' : ''}',
                          fontData,
                        ),
                        _tableDataCell(item.hsnCode, fontData, align: pw.TextAlign.center),
                        _tableDataCell(item.purity, fontData, align: pw.TextAlign.center),
                        _tableDataCell('${item.grossWeight.toStringAsFixed(3)} g', fontData, align: pw.TextAlign.right),
                        _tableDataCell(_currencyFormat.format(item.rate), fontData, align: pw.TextAlign.right),
                        _tableDataCell('$makingChargeDetail\n(Rs ${item.makingChargeTotal.toStringAsFixed(2)})', fontData, align: pw.TextAlign.right),
                        _tableDataCell(_currencyFormat.format(item.itemTotal), fontBold, align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 16),

              // Summary and Payments
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Payment Info & Amount in Words
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PAYMENT DETAILS:',
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                        ),
                        pw.SizedBox(height: 4),
                        ...invoice.payments.map((pay) {
                          if (pay.amount <= 0) return pw.Container();
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                            child: pw.Row(
                              children: [
                                pw.Text(
                                  '${pay.method}:',
                                  style: pw.TextStyle(font: fontData, fontSize: 8.5),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  _currencyFormat.format(pay.amount),
                                  style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                                ),
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 4),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Total Paid:',
                              style: pw.TextStyle(font: fontData, fontSize: 8.5),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              _currencyFormat.format(invoice.totalAmountPaid),
                              style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.green800),
                            ),
                          ],
                        ),
                        if (invoice.balanceDue > 0)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Row(
                              children: [
                                pw.Text(
                                  'Balance Due:',
                                  style: pw.TextStyle(font: fontData, fontSize: 8.5, color: PdfColors.red800),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  _currencyFormat.format(invoice.balanceDue),
                                  style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.red800),
                                ),
                              ],
                            ),
                          ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'AMOUNT IN WORDS:',
                          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey600),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          numberToRupeesWords(invoice.finalPayable),
                          style: pw.TextStyle(font: fontData, fontSize: 8.5, color: PdfColors.black),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 32),
                  // Financial Breakdown
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      children: [
                        _summaryRow('Subtotal (Gross):', _currencyFormat.format(invoice.grossAmount), fontData, fontData),
                        _summaryRow('Total Making Charge:', _currencyFormat.format(totalMakingCharge), fontData, fontData),
                        if (invoice.couponDiscount > 0)
                          _summaryRow('Discount:', '- ${_currencyFormat.format(invoice.couponDiscount)}', fontData, fontData),
                        _summaryRow('Taxable Value:', _currencyFormat.format(invoice.taxableAmount), fontBold, fontBold),
                        pw.SizedBox(height: 3),
                        
                        // CGST & SGST vs IGST
                        if (customer.state == null || customer.state!.isEmpty || customer.state!.toLowerCase() == 'bihar') ...[
                          _summaryRow('CGST (1.5%):', _currencyFormat.format(invoice.cgst), fontData, fontData),
                          _summaryRow('SGST (1.5%):', _currencyFormat.format(invoice.sgst), fontData, fontData),
                        ] else ...[
                          _summaryRow('IGST (3.0%):', _currencyFormat.format(invoice.totalTax), fontData, fontData),
                        ],
                        
                        if (invoice.oldGold != null && invoice.oldGold!.metalValue > 0)
                          _summaryRow('Old Gold adjustment:', '- ${_currencyFormat.format(invoice.oldGold!.metalValue)}', fontData, fontData),
                        
                        // Roundoff Calculation
                        if (invoice.finalPayable - (invoice.netAmount - (invoice.oldGold?.metalValue ?? 0)) != 0)
                          _summaryRow('Roundoff:', _currencyFormat.format(invoice.finalPayable - (invoice.netAmount - (invoice.oldGold?.metalValue ?? 0))), fontData, fontData),

                        pw.SizedBox(height: 3),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'GRAND TOTAL:',
                              style: pw.TextStyle(font: fontBold, fontSize: 11),
                            ),
                            pw.Text(
                              _currencyFormat.format(invoice.finalPayable),
                              style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Signature Box
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 120,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey600),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Customer Signature',
                        style: pw.TextStyle(font: fontBold, fontSize: 8),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'For Swarnayan Jewellers',
                        style: pw.TextStyle(font: fontBold, fontSize: 8),
                      ),
                      pw.SizedBox(height: 35),
                      pw.Container(
                        width: 120,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey600),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorised Signatory',
                        style: pw.TextStyle(font: fontBold, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer Declarations
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms & Conditions:',
                        style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                      ),
                      pw.SizedBox(height: 2),
                      ...cTerms.asMap().entries.map((entry) {
                        return pw.Text(
                          '${entry.key + 1}. ${entry.value}',
                          style: pw.TextStyle(font: fontData, fontSize: 6.5, color: PdfColors.grey700),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Launch print preview overlay
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice_${invoice.invoiceNumber ?? invoice.id}.pdf',
    );
  }

  static pw.Widget _invoiceMetaRow(String label, String value, pw.Font fontBold, pw.Font fontData) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            style: pw.TextStyle(font: fontData, fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, pw.Font fontLabel, pw.Font fontVal) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: fontLabel, fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: fontVal, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}
