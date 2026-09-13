import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnayan_flutter/core/utils/bulk_invoice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleCsv = '''Invoice No.,Date,Customer Name,Particulars,Purity,Net Wt (gm),Gross Amt (₹),CGST (₹),SGST (₹),Net Amt (₹),Payment Mode,Dues (₹)
S-000463,06/07/2022,SONALI CHAUHAN,G RING 22K HM,22K,4.090,22495.00,337.43,337.43,23170.00,Cash ₹23170,0.00
S-000464,13/07/2022,SHIV KUMAR CHAUDARY,L RING 22K HM; G RING 22K HM,22K,7.970,41842.50,627.65,627.65,43098.00,Cash ₹43098,0.00
S-000466,14/07/2022,ARTI GUPTA,SILVER LOTIA,SILVER,34.780,2330.26,34.96,34.96,2400.00,Cash ₹500,1900.00
''';

  test('BulkInvoiceService.parseCsv correctly parses rows', () {
    final result = BulkInvoiceService.parseCsv(sampleCsv);
    expect(result.errors, isEmpty);
    expect(result.invoices.length, 3);
    
    // Check first invoice
    final inv1 = result.invoices[0];
    expect(inv1.invoiceNumber, 'S-000463');
    expect(inv1.tempCustomerName, 'SONALI CHAUHAN');
    expect(inv1.items.length, 1);
    expect(inv1.items.first.productName, 'G RING 22K HM');
    expect(inv1.finalPayable, 23170.00);
    expect(inv1.payments.length, 1);
    expect(inv1.payments.first.method, 'CASH');
    expect(inv1.payments.first.amount, 23170.00);
    expect(inv1.status, 'PAID');

    // Check multi-product row
    final inv2 = result.invoices[1];
    expect(inv2.invoiceNumber, 'S-000464');
    expect(inv2.items.length, 2);
    expect(inv2.items[0].productName, 'L RING 22K HM');
    expect(inv2.items[1].productName, 'G RING 22K HM');

    // Check partial payment with dues
    final inv3 = result.invoices[2];
    expect(inv3.invoiceNumber, 'S-000466');
    expect(inv3.balanceDue, 1900.00);
    expect(inv3.totalAmountPaid, 500.00);
    expect(inv3.status, 'PARTIAL');
  });

  test('BulkInvoiceService.generateBulkInvoicesZip creates valid zip bytes', () async {
    final result = BulkInvoiceService.parseCsv(sampleCsv);
    final zipBytes = await BulkInvoiceService.generateBulkInvoicesZip(
      invoices: result.invoices,
      customers: result.customers,
    );

    expect(zipBytes, isNotEmpty);
    print('Generated zip archive size: ${zipBytes.length} bytes');
  });
}
