import 'package:flutter_test/flutter_test.dart';
import 'package:swarnayan_flutter/core/utils/formatters.dart';
import 'package:swarnayan_flutter/core/utils/pdf_helper.dart';
import 'package:swarnayan_flutter/models/invoice.dart';
import 'package:swarnayan_flutter/models/customer.dart';

void main() {
  group('Invoice Numbering & Sequential Increment Tests', () {
    test('Formatters.extractInvoiceCounter correctly extracts numeric counters', () {
      expect(Formatters.extractInvoiceCounter('S-000646'), 646);
      expect(Formatters.extractInvoiceCounter('S-000463'), 463);
      expect(Formatters.extractInvoiceCounter('S-000001'), 1);
      expect(Formatters.extractInvoiceCounter('S-646'), 646);
      expect(Formatters.extractInvoiceCounter('646'), 646);
      expect(Formatters.extractInvoiceCounter('INV-000646'), 646);
      expect(Formatters.extractInvoiceCounter('2024-25-S-000646', financialYear: '2024-25'), 646);
    });

    test('Formatters.formatInvoiceNumber formats with prefix and padding', () {
      expect(
        Formatters.formatInvoiceNumber(647, prefix: 'S', separator: '-', paddingLength: 6),
        'S-000647',
      );
      expect(
        Formatters.formatInvoiceNumber(647, prefix: 'INV', separator: '/', paddingLength: 4),
        'INV/0647',
      );
    });

    test('Sequential increment: current 646 results in next 647', () {
      final existingInvoiceNumbers = [
        'S-000463',
        'S-000464',
        'S-000640',
        'S-000645',
        'S-000646',
      ];

      int maxCounter = 0;
      for (final inv in existingInvoiceNumbers) {
        final counter = Formatters.extractInvoiceCounter(inv);
        if (counter != null && counter > maxCounter) {
          maxCounter = counter;
        }
      }

      expect(maxCounter, 646);
      final nextCounter = maxCounter + 1;
      expect(nextCounter, 647);
      final nextInvoiceNumber = Formatters.formatInvoiceNumber(nextCounter);
      expect(nextInvoiceNumber, 'S-000647');
    });

    test('PdfHelper.getInvoiceDocumentTitle formats as "{Invoice number} - {Customer name}"', () {
      final title1 = PdfHelper.getInvoiceDocumentTitle(
        invoice: Invoice(
          id: '1',
          invoiceNumber: 'S-000646',
          items: const [],
          grossAmount: 0,
          taxableAmount: 0,
          cgst: 0,
          sgst: 0,
          totalTax: 0,
          netAmount: 0,
          finalPayable: 0,
          payments: const [],
          totalAmountPaid: 0,
          balanceDue: 0,
          invoiceDate: DateTime(2026, 5, 23),
          status: 'PAID',
          ratesSnapshot: const RatesSnapshot(rateGold22K: 6850, rateGold18K: 5610, rateSilver: 82.4),
        ),
        customer: const Customer(id: 'c1', name: 'SONALI CHAUHAN', mobile: '9999999999'),
      );
      expect(title1, 'S-000646 - SONALI CHAUHAN');

      // Test fallback to tempCustomerName
      final title2 = PdfHelper.getInvoiceDocumentTitle(
        invoice: Invoice(
          id: '2',
          invoiceNumber: 'S-000647',
          tempCustomerName: 'RAHUL SHARMA',
          items: const [],
          grossAmount: 0,
          taxableAmount: 0,
          cgst: 0,
          sgst: 0,
          totalTax: 0,
          netAmount: 0,
          finalPayable: 0,
          payments: const [],
          totalAmountPaid: 0,
          balanceDue: 0,
          invoiceDate: DateTime(2026, 5, 23),
          status: 'PAID',
          ratesSnapshot: const RatesSnapshot(rateGold22K: 6850, rateGold18K: 5610, rateSilver: 82.4),
        ),
        customer: const Customer(id: '', name: '', mobile: ''),
      );
      expect(title2, 'S-000647 - RAHUL SHARMA');
    });
  });
}
