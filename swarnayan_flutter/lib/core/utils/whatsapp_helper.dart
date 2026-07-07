import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_helper.dart';
import 'file_saver_helper.dart';
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

      // Web Implementation
      if (kIsWeb) {
        // Download the PDF in the browser
        final String fileName = "$invoiceNumber - ${customer.name}.pdf";
        await FileSaverHelper.savePdfFile(pdfBytes, fileName);

        // Open WhatsApp Web with prefilled message
        final cleanPhone = customer.mobile.replaceAll(RegExp(r'\D'), '');
        final whatsappPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
        final encodedMsg = Uri.encodeComponent(message);
        final whatsappUrl = 'https://wa.me/$whatsappPhone?text=$encodedMsg';
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
        return;
      }

      // Mobile (Android/iOS) Implementation
      final tempDir = await getTemporaryDirectory();
      final sanitizedInvNum = invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
      final sanitizedCustName = customer.name.replaceAll(RegExp(r'[^\w\-]'), '_');
      final file = File('${tempDir.path}/${sanitizedInvNum} - ${sanitizedCustName}.pdf');
      await file.writeAsBytes(pdfBytes);

      // Share both the PDF file and the message via share_plus
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
