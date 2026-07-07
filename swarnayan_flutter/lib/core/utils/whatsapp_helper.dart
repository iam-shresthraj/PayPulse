import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'pdf_helper.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/company_settings.dart';

class WhatsAppHelper {
  static Future<void> shareInvoice({
    required Invoice invoice,
    required Customer customer,
    CompanySettings? company,
  }) async {
    final String dateStr = DateFormat('dd/MM/yyyy').format(invoice.invoiceDate);
    final String invoiceNumber = invoice.invoiceNumber ?? 'N/A';
    final String totalAmount = invoice.finalPayable.toStringAsFixed(2);
    final String balanceDue = invoice.balanceDue.toStringAsFixed(2);
    final String firstName = _toPascalCase(customer.name);

    final message = '''Hello $firstName,

Thank you for shopping at *Swarnayan Jewellers*! 🙏

Here is your invoice summary:
- *Invoice No:* $invoiceNumber
- *Date:* $dateStr
- *Grand Total:* ₹$totalAmount
- *Balance Due:* ₹$balanceDue

*Trusted Hallmark Jewellery Destination* 

*Please share your feedback* : https://bit.ly/swarnayan-jewellers-feedback

Gulab Bagh Market, Thakurbari Road, Patna, Bihar - 800004
Phone: 7903111274''';

    try {
      // 1. Generate the PDF bytes in WhatsApp mode (no signatures)
      final pdfBytes = await PdfHelper.generateInvoicePdfBytes(
        invoice: invoice,
        customer: customer,
        company: company,
        forWhatsApp: true,
      );

      // 2. Save the PDF to a temporary file
      final tempDir = await getTemporaryDirectory();
      final sanitizedInvNum = invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
      final file = File('${tempDir.path}/Invoice_$sanitizedInvNum.pdf');
      await file.writeAsBytes(pdfBytes);

      // 3. Share both the PDF file and the message via share_plus
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: message,
        subject: 'Invoice $invoiceNumber - Swarnayan Jewellers',
      );
    } catch (e) {
      throw 'Failed to share invoice: $e';
    }
  }

  static String _toPascalCase(String name) {
    if (name.isEmpty) return 'Customer';
    final firstWord = name.trim().split(' ').first;
    if (firstWord.isEmpty) return 'Customer';
    return firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase();
  }
}
