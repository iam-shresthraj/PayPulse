import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/company_settings.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';

class WhatsAppHelper {
  static Future<void> shareInvoice({
    required Invoice invoice,
    required Customer customer,
    CompanySettings? company,
  }) async {
    final message = _buildWhatsAppMessage(invoice, customer, company);
    final formattedPhone = _formatPhone(customer.mobile);
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open WhatsApp sharing link.';
    }
  }

  static String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '91$digits';
    }
    return digits;
  }

  static String _buildWhatsAppMessage(Invoice invoice, Customer customer, CompanySettings? company) {
    final String dateStr = DateFormat('dd/MM/yyyy').format(invoice.invoiceDate);
    final String invoiceNumber = invoice.invoiceNumber ?? 'N/A';
    final String totalAmount = invoice.finalPayable.toStringAsFixed(2);
    final String balanceDue = invoice.balanceDue.toStringAsFixed(2);
    final String rawName = customer.name.isNotEmpty && customer.name.toLowerCase() != 'client'
        ? customer.name
        : (invoice.tempCustomerName?.isNotEmpty == true ? invoice.tempCustomerName! : 'Customer');
    final String firstName = _toPascalCase(rawName);

    final String cName = company?.companyName.isNotEmpty == true ? company!.companyName : 'PayPulse';
    final String cTagline = company?.tagline.isNotEmpty == true ? company!.tagline : 'Trusted Hallmark Jewellery Destination';
    final String cFeedback = company?.logoUrl.isNotEmpty == true ? company!.logoUrl : 'https://bit.ly/swarnayan-jewellers-feedback';
    final String cPhone = company?.mobile.isNotEmpty == true ? company!.mobile : '7903111274';

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

    return '''Hello $firstName,

Thank you for shopping at *$cName*!

Here is your invoice summary:
- *Invoice No:* $invoiceNumber
- *Date:* $dateStr
- *Grand Total:* ₹$totalAmount
- *Balance Due:* ₹$balanceDue

*$cTagline*

*Please share your feedback* : $cFeedback

$cAddressLine
Phone: $cPhone''';
  }

  static String _toPascalCase(String name) {
    if (name.isEmpty) return 'Customer';
    final firstWord = name.trim().split(' ').first;
    if (firstWord.isEmpty) return 'Customer';
    return firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase();
  }
}
