import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../models/coupon.dart';
import '../../models/invoice.dart';

class BillingProduct {
  final String productId;
  final String name;
  final String hsnCode;
  final String category;
  final String purity;
  final String? huidNumber;
  final double rate;
  final int quantity;
  final double grossWeight;
  final double stoneWeight;
  final double stoneValue;
  final String makingChargeType; // FIXED, PER_GRAM, PERCENTAGE
  final double makingChargeValue;
  final double discountValue; // Product-level discount

  const BillingProduct({
    required this.productId,
    required this.name,
    required this.hsnCode,
    required this.category,
    required this.purity,
    this.huidNumber,
    required this.rate,
    this.quantity = 1,
    this.grossWeight = 0,
    this.stoneWeight = 0,
    this.stoneValue = 0,
    required this.makingChargeType,
    required this.makingChargeValue,
    this.discountValue = 0.0,
  });

  double get netWeight => (grossWeight - stoneWeight).clamp(0.0, double.infinity);

  double get metalValue => netWeight * rate;

  double get makingChargeTotal {
    switch (makingChargeType) {
      case 'FIXED':
        return makingChargeValue * quantity;
      case 'PER_GRAM':
        return makingChargeValue * grossWeight; // backend uses grossWeight * makingChargeValue
      case 'PERCENTAGE':
        return metalValue * (makingChargeValue / 100);
      default:
        return 0;
    }
  }

  double get itemTotal => (metalValue + makingChargeTotal + stoneValue - discountValue).clamp(0.0, double.infinity);

  BillingProduct copyWith({
    String? productId,
    String? name,
    String? hsnCode,
    String? category,
    String? purity,
    String? huidNumber,
    double? rate,
    int? quantity,
    double? grossWeight,
    double? stoneWeight,
    double? stoneValue,
    String? makingChargeType,
    double? makingChargeValue,
    double? discountValue,
  }) {
    return BillingProduct(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      category: category ?? this.category,
      purity: purity ?? this.purity,
      huidNumber: huidNumber ?? this.huidNumber,
      rate: rate ?? this.rate,
      quantity: quantity ?? this.quantity,
      grossWeight: grossWeight ?? this.grossWeight,
      stoneWeight: stoneWeight ?? this.stoneWeight,
      stoneValue: stoneValue ?? this.stoneValue,
      makingChargeType: makingChargeType ?? this.makingChargeType,
      makingChargeValue: makingChargeValue ?? this.makingChargeValue,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}

class BillingState {
  final String? customerId;
  final String? customerPhone;
  final String? customerName;
  final String? customerTier;
  final List<BillingProduct> products;
  
  // Coupon
  final String? couponCode;
  final Coupon? appliedCoupon;

  // Custom Discount
  final double customDiscount;

  // Invoice Details
  final DateTime invoiceDate;
  final Invoice? editingInvoice;
  final String? customInvoiceNumber;

  // Payments
  final double cashAmount;
  final double upiAmount;
  final double cardAmount;
  final double? manualReceivedAmount;

  BillingState({
    this.customerId,
    this.customerPhone,
    this.customerName,
    this.customerTier,
    this.products = const [],
    this.couponCode,
    this.appliedCoupon,
    this.customDiscount = 0.0,
    DateTime? invoiceDate,
    this.editingInvoice,
    this.customInvoiceNumber,
    this.cashAmount = 0,
    this.upiAmount = 0,
    this.cardAmount = 0,
    this.manualReceivedAmount,
  }) : invoiceDate = invoiceDate ?? DateTime.now();

  double get subtotal => products.fold(0.0, (sum, p) => sum + p.itemTotal);

  double get discountAmount {
    double couponDisc = 0.0;
    final coupon = appliedCoupon;
    if (coupon != null && subtotal >= coupon.minBillAmount) {
      if (coupon.discountType == 'FIXED') {
        couponDisc = coupon.discountValue;
      } else if (coupon.discountType == 'PERCENTAGE') {
        couponDisc = subtotal * (coupon.discountValue / 100);
        if (coupon.maxDiscount > 0.0) {
          couponDisc = couponDisc.clamp(0.0, coupon.maxDiscount);
        }
      }
    }
    return (couponDisc + customDiscount).clamp(0.0, subtotal);
  }

  double get taxableAmount => (subtotal - discountAmount).clamp(0.0, double.infinity);

  double get cgst => taxableAmount * 0.015; // 1.5% CGST
  double get sgst => taxableAmount * 0.015; // 1.5% SGST
  double get totalTax => cgst + sgst;        // 3.0% Total GST

  double get grandTotal => taxableAmount + totalTax;
  double get finalPayable => grandTotal.roundToDouble();

  double get totalPaid => manualReceivedAmount ?? (cashAmount + upiAmount + cardAmount);
  double get balanceDue => finalPayable - totalPaid;

  BillingState copyWith({
    String? customerId,
    String? customerPhone,
    String? customerName,
    String? customerTier,
    List<BillingProduct>? products,
    String? couponCode,
    Coupon? appliedCoupon,
    bool clearCoupon = false,
    double? customDiscount,
    DateTime? invoiceDate,
    Invoice? editingInvoice,
    bool clearEditingInvoice = false,
    String? customInvoiceNumber,
    bool clearCustomInvoiceNumber = false,
    double? cashAmount,
    double? upiAmount,
    double? cardAmount,
    double? manualReceivedAmount,
    bool clearManualReceivedAmount = false,
  }) {
    return BillingState(
      customerId: customerId ?? this.customerId,
      customerPhone: customerPhone ?? this.customerPhone,
      customerName: customerName ?? this.customerName,
      customerTier: customerTier ?? this.customerTier,
      products: products ?? this.products,
      couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      customDiscount: customDiscount ?? this.customDiscount,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      editingInvoice: clearEditingInvoice ? null : (editingInvoice ?? this.editingInvoice),
      customInvoiceNumber: clearCustomInvoiceNumber ? null : (customInvoiceNumber ?? this.customInvoiceNumber),
      cashAmount: cashAmount ?? this.cashAmount,
      upiAmount: upiAmount ?? this.upiAmount,
      cardAmount: cardAmount ?? this.cardAmount,
      manualReceivedAmount: clearManualReceivedAmount ? null : (manualReceivedAmount ?? this.manualReceivedAmount),
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  BillingNotifier() : super(BillingState());

  void setCustomer(Customer customer) {
    state = state.copyWith(
      customerId: customer.id,
      customerPhone: customer.mobile,
      customerName: customer.name,
      customerTier: _getCustomerTier(customer.totalPurchaseAmount),
    );
  }

  void setTemporaryCustomer(String name, String phone) {
    state = state.copyWith(
      customerId: '',
      customerPhone: phone,
      customerName: name,
      customerTier: 'Temporary Customer',
    );
  }

  void clearCustomer() {
    state = BillingState(
      products: state.products,
      couponCode: state.couponCode,
      appliedCoupon: state.appliedCoupon,
      customDiscount: state.customDiscount,
      invoiceDate: state.invoiceDate,
      editingInvoice: state.editingInvoice,
      customInvoiceNumber: state.customInvoiceNumber,
      cashAmount: state.cashAmount,
      upiAmount: state.upiAmount,
      cardAmount: state.cardAmount,
      manualReceivedAmount: state.manualReceivedAmount,
    );
  }

  void addProduct(BillingProduct product) {
    state = state.copyWith(products: [...state.products, product]);
  }

  void removeProduct(int index) {
    final updated = List<BillingProduct>.from(state.products);
    updated.removeAt(index);
    state = state.copyWith(products: updated);
  }

  void setInvoiceDate(DateTime date) {
    state = state.copyWith(invoiceDate: date);
  }

  void setCustomInvoiceNumber(String? number) {
    if (number == null || number.trim().isEmpty) {
      state = state.copyWith(clearCustomInvoiceNumber: true);
    } else {
      state = state.copyWith(customInvoiceNumber: number.trim());
    }
  }

  void applyCoupon(Coupon coupon) {
    state = state.copyWith(
      couponCode: coupon.code,
      appliedCoupon: coupon,
    );
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }

  void setCustomDiscount(double discount) {
    state = state.copyWith(
      customDiscount: discount,
    );
  }

  void setCashAmount(double amount) {
    state = state.copyWith(
      cashAmount: amount,
      clearManualReceivedAmount: true,
    );
  }

  void setUpiAmount(double amount) {
    state = state.copyWith(
      upiAmount: amount,
      clearManualReceivedAmount: true,
    );
  }

  void setCardAmount(double amount) {
    state = state.copyWith(
      cardAmount: amount,
      clearManualReceivedAmount: true,
    );
  }

  void setManualReceivedAmount(double? amount) {
    if (amount == null) {
      state = state.copyWith(clearManualReceivedAmount: true);
    } else {
      state = state.copyWith(manualReceivedAmount: amount);
    }
  }

  void loadInvoiceToEdit(Invoice invoice, Customer customer) {
    final List<BillingProduct> products = invoice.items.map((item) {
      return BillingProduct(
        productId: item.productId,
        name: item.productName,
        hsnCode: item.hsnCode,
        category: item.category,
        purity: item.purity,
        huidNumber: item.huidNumber,
        rate: item.rate,
        quantity: item.quantity,
        grossWeight: item.grossWeight,
        stoneWeight: item.stoneWeight,
        stoneValue: item.stoneValue,
        makingChargeType: item.makingChargeType,
        makingChargeValue: item.makingChargeValue,
        discountValue: item.discountValue,
      );
    }).toList();

    double cash = 0;
    double upi = 0;
    double card = 0;
    for (final payment in invoice.payments) {
      if (payment.method == 'CASH') cash = payment.amount;
      if (payment.method == 'UPI') upi = payment.amount;
      if (payment.method == 'CARD') card = payment.amount;
    }

    Coupon? coupon;
    if (invoice.couponCode != null && invoice.couponCode!.isNotEmpty) {
      coupon = Coupon(
        id: '',
        code: invoice.couponCode!,
        discountType: 'FIXED',
        discountValue: invoice.couponDiscount,
        expiryDate: DateTime.now(),
      );
    }

    state = BillingState(
      customerId: invoice.customerId ?? '',
      customerName: invoice.tempCustomerName ?? customer.name,
      customerPhone: invoice.tempCustomerMobile ?? customer.mobile,
      customerTier: _getCustomerTier(customer.totalPurchaseAmount),
      products: products,
      couponCode: invoice.couponCode,
      appliedCoupon: coupon,
      customDiscount: coupon == null ? invoice.couponDiscount : 0.0,
      invoiceDate: invoice.invoiceDate,
      editingInvoice: invoice,
      cashAmount: cash,
      upiAmount: upi,
      cardAmount: card,
      manualReceivedAmount: invoice.payments.isEmpty ? invoice.totalAmountPaid : null,
    );
  }

  void reset() {
    state = BillingState();
  }

  String _getCustomerTier(double totalSpend) {
    if (totalSpend >= 500000) return 'Platinum Member';
    if (totalSpend >= 200000) return 'Gold Member';
    if (totalSpend >= 100000) return 'Silver Member';
    return 'Bronze Member';
  }
}

final billingProvider =
    StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  return BillingNotifier();
});
