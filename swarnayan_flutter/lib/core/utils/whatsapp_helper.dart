import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
      final cleanPhone = customer.mobile.replaceAll(RegExp(r'\D'), '');
      final whatsappPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
      final encodedMsg = Uri.encodeComponent(message);
      
      final whatsappUrl = 'https://wa.me/$whatsappPhone?text=$encodedMsg';
      final uri = Uri.parse(whatsappUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      throw 'Failed to open WhatsApp: $e';
    }
  }

  static String _toPascalCase(String name) {
    if (name.isEmpty) return 'Customer';
    final firstWord = name.trim().split(' ').first;
    if (firstWord.isEmpty) return 'Customer';
    return firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase();
  }
}
