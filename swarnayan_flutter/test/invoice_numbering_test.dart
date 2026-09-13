import 'package:flutter_test/flutter_test.dart';
import 'package:swarnayan_flutter/core/utils/formatters.dart';

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
  });
}
