import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatWeight(double weight) {
    // Jewellery standards require 3 decimal places for gold/silver weights
    return '${weight.toStringAsFixed(3)} g';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Extracts the numeric counter from an invoice number string.
  /// Handles formats like S-000646, S-646, 646, INV-000646, 2024-25-S-000646, etc.
  static int? extractInvoiceCounter(
    String invoiceNum, {
    String prefix = 'S',
    String separator = '-',
    String financialYear = '',
    String suffix = '',
  }) {
    final trimmed = invoiceNum.trim();
    if (trimmed.isEmpty) return null;

    // 1. Clean match stripping financial year, prefix, suffix, and separator
    var temp = trimmed;
    if (financialYear.isNotEmpty && temp.startsWith('$financialYear$separator')) {
      temp = temp.substring(financialYear.length + separator.length);
    }
    if (prefix.isNotEmpty && temp.startsWith('$prefix$separator')) {
      temp = temp.substring(prefix.length + separator.length);
    } else if (prefix.isNotEmpty && temp.startsWith(prefix)) {
      temp = temp.substring(prefix.length);
    }
    if (suffix.isNotEmpty && temp.endsWith('$separator$suffix')) {
      temp = temp.substring(0, temp.length - suffix.length - separator.length);
    } else if (suffix.isNotEmpty && temp.endsWith(suffix)) {
      temp = temp.substring(0, temp.length - suffix.length);
    }
    if (separator.isNotEmpty) {
      if (temp.startsWith(separator)) temp = temp.substring(separator.length);
      if (temp.endsWith(separator)) temp = temp.substring(0, temp.length - separator.length);
    }

    final directVal = int.tryParse(temp);
    if (directVal != null && directVal > 0) return directVal;

    // 2. Prefix-aware regex: e.g. S-000646 or S/000646 or S000646
    if (prefix.isNotEmpty) {
      final prefixRegex = RegExp(
        '^.*?${RegExp.escape(prefix)}[-/_ ]*(\\d+)',
        caseSensitive: false,
      );
      final match = prefixRegex.firstMatch(trimmed);
      if (match != null) {
        final val = int.tryParse(match.group(1)!);
        if (val != null && val > 0 && val < 10000000) return val;
      }
    }

    // 3. Common prefixes: INV-000646, BILL-646, S-646
    final invRegex = RegExp(r'(?:INV|BILL|REC|S)[-/_ ]*(\d+)', caseSensitive: false);
    final invMatch = invRegex.firstMatch(trimmed);
    if (invMatch != null) {
      final val = int.tryParse(invMatch.group(1)!);
      if (val != null && val > 0 && val < 10000000) return val;
    }

    // 4. Trailing integer sequence, filtering out large epoch timestamps (> 7 digits)
    final trailingDigits = RegExp(r'(\d+)(?!.*\d)').firstMatch(trimmed);
    if (trailingDigits != null) {
      final val = int.tryParse(trailingDigits.group(1)!);
      if (val != null && val > 0 && val < 10000000) {
        return val;
      }
    }

    return null;
  }

  /// Formats an invoice counter into the configured invoice string.
  /// Example: counter 647, prefix 'S', separator '-', paddingLength 6 -> 'S-000647'
  static String formatInvoiceNumber(
    int counter, {
    String prefix = 'S',
    String separator = '-',
    int paddingLength = 6,
    String financialYear = '',
    String suffix = '',
  }) {
    final padded = counter.toString().padLeft(paddingLength, '0');
    var numStr = '$prefix$separator$padded';
    if (financialYear.isNotEmpty) {
      numStr = '$financialYear$separator$numStr';
    }
    if (suffix.isNotEmpty) {
      numStr = '$numStr$separator$suffix';
    }
    return numStr;
  }
}

class TitleCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final StringBuffer buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < newValue.text.length; i++) {
      final String char = newValue.text[i];
      if (char == ' ' || char == '.' || char == '-' || char == '/') {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }

    final String formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset.clamp(0, formattedText.length),
        extentOffset: newValue.selection.extentOffset.clamp(0, formattedText.length),
      ),
    );
  }
}

class UpperCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
