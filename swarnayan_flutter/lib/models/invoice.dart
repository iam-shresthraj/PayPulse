import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String method, // CASH, CARD, UPI, BANK_TRANSFER
    required double amount,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
class OldGoldAdjustment with _$OldGoldAdjustment {
  const factory OldGoldAdjustment({
    required double weight,
    required String purity, // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
    required double rate,
    @Default(0.0) double metalValue,
  }) = _OldGoldAdjustment;

  factory OldGoldAdjustment.fromJson(Map<String, dynamic> json) => _$OldGoldAdjustmentFromJson(json);
}

@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String productId,
    required String productName,
    String? huidNumber,
    required String hsnCode,
    required String category, // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
    required String purity,
    @Default(1) int quantity,
    required double grossWeight,
    required double netWeight,
    required double rate,
    required double metalValue,
    required String makingChargeType, // FIXED, PER_GRAM, PERCENTAGE
    required double makingChargeValue,
    required double makingChargeTotal,
    @Default(0.0) double wastagePercentage,
    @Default(0.0) double wastageWeight,
    @Default(0.0) double wastageValue,
    String? stoneType,
    @Default(0.0) double stoneWeight,
    @Default(0.0) double stoneValue,
    @Default(0.0) double discountValue,
    required double itemTotal,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => _$InvoiceItemFromJson(json);
}

@freezed
class RatesSnapshot with _$RatesSnapshot {
  const factory RatesSnapshot({
    required double rateGold22K,
    required double rateGold18K,
    required double rateSilver,
  }) = _RatesSnapshot;

  factory RatesSnapshot.fromJson(Map<String, dynamic> json) => _$RatesSnapshotFromJson(json);
}

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    @JsonKey(name: '_id') String? id,
    String? invoiceNumber,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson) String? customerId,
    String? tempCustomerName,
    String? tempCustomerMobile,
    String? tempCustomerAddress,
    String? tempCustomerPincode,
    String? tempCustomerCity,
    String? tempCustomerState,
    required List<InvoiceItem> items,
    required double grossAmount,
    String? couponCode,
    @Default(0.0) double couponDiscount,
    OldGoldAdjustment? oldGold,
    required double taxableAmount,
    required double cgst,
    required double sgst,
    required double totalTax,
    required double netAmount,
    required double finalPayable,
    required List<Payment> payments,
    required double totalAmountPaid,
    required double balanceDue,
    required DateTime invoiceDate,
    @JsonKey(fromJson: _stringOrIdFromJson, toJson: _stringOrIdToJson) String? generatedBy,
    @Default('PAID') String status, // PAID, PARTIALLY_PAID, CANCELLED
    required RatesSnapshot ratesSnapshot,
    DateTime? deletedAt,
    String? pdfBase64,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
}

String? _stringOrIdFromJson(dynamic jsonVal) {
  if (jsonVal == null) return null;
  if (jsonVal is Map) {
    return jsonVal['_id'] as String?;
  }
  return jsonVal.toString();
}

dynamic _stringOrIdToJson(String? val) => val;
