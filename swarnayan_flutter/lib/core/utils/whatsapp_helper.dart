import 'package:url_launcher/url_launcher.dart';
import '../../models/company_settings.dart';

class WhatsAppHelper {
  static Future<void> shareInvoice({
    required String? customerName,
    required String? customerPhone,
    required String invoiceNumber,
    required double totalAmount,
    required double balanceDue,
    required DateTime date,
    CompanySettings? company,
  }) async {
    final phoneNum = customerPhone ?? '';
    final name = customerName ?? 'Customer';
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    var phone = phoneNum.replaceAll(RegExp(r'\D'), '');
    if (phone.length == 10) {
      phone = '91$phone';
    }

    final String cName = company?.companyName.isNotEmpty == true ? company!.companyName : 'PAYPULSE';
    final String cPhone = company?.mobile.isNotEmpty == true ? company!.mobile : '7903111274';
    final String cTagline = company?.tagline.isNotEmpty == true ? company!.tagline : 'Offering Gold, Silver & Diamond Collections.';
    
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
      cAddressLine = 'Gulab Bagh Market, Thakurbari Road, Patna - 800004';
    }

    final message = '''
Hello $name,

Thank you for shopping at *$cName*! 🙏
Here is your invoice summary:

*Invoice No:* $invoiceNumber
*Date:* $dateStr
*Grand Total:* ₹${totalAmount.toStringAsFixed(0)}
*Balance Due:* ₹${balanceDue.toStringAsFixed(0)}

_${cTagline}_
$cAddressLine
Phone: $cPhone
''';

    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=$encodedMessage');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp link';
    }
  }
}
