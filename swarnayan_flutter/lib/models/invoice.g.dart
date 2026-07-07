// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      method: json['method'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{'method': instance.method, 'amount': instance.amount};

_$OldGoldAdjustmentImpl _$$OldGoldAdjustmentImplFromJson(
  Map<String, dynamic> json,
) => _$OldGoldAdjustmentImpl(
  weight: (json['weight'] as num).toDouble(),
  purity: json['purity'] as String,
  rate: (json['rate'] as num).toDouble(),
  metalValue: (json['metalValue'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$OldGoldAdjustmentImplToJson(
  _$OldGoldAdjustmentImpl instance,
) => <String, dynamic>{
  'weight': instance.weight,
  'purity': instance.purity,
  'rate': instance.rate,
  'metalValue': instance.metalValue,
};

_$InvoiceItemImpl _$$InvoiceItemImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceItemImpl(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      huidNumber: json['huidNumber'] as String?,
      hsnCode: json['hsnCode'] as String,
      category: json['category'] as String,
      purity: json['purity'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      grossWeight: (json['grossWeight'] as num).toDouble(),
      netWeight: (json['netWeight'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      metalValue: (json['metalValue'] as num).toDouble(),
      makingChargeType: json['makingChargeType'] as String,
      makingChargeValue: (json['makingChargeValue'] as num).toDouble(),
      makingChargeTotal: (json['makingChargeTotal'] as num).toDouble(),
      wastagePercentage: (json['wastagePercentage'] as num?)?.toDouble() ?? 0.0,
      wastageWeight: (json['wastageWeight'] as num?)?.toDouble() ?? 0.0,
      wastageValue: (json['wastageValue'] as num?)?.toDouble() ?? 0.0,
      stoneType: json['stoneType'] as String?,
      stoneWeight: (json['stoneWeight'] as num?)?.toDouble() ?? 0.0,
      stoneValue: (json['stoneValue'] as num?)?.toDouble() ?? 0.0,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      itemTotal: (json['itemTotal'] as num).toDouble(),
    );

Map<String, dynamic> _$$InvoiceItemImplToJson(_$InvoiceItemImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'huidNumber': instance.huidNumber,
      'hsnCode': instance.hsnCode,
      'category': instance.category,
      'purity': instance.purity,
      'quantity': instance.quantity,
      'grossWeight': instance.grossWeight,
      'netWeight': instance.netWeight,
      'rate': instance.rate,
      'metalValue': instance.metalValue,
      'makingChargeType': instance.makingChargeType,
      'makingChargeValue': instance.makingChargeValue,
      'makingChargeTotal': instance.makingChargeTotal,
      'wastagePercentage': instance.wastagePercentage,
      'wastageWeight': instance.wastageWeight,
      'wastageValue': instance.wastageValue,
      'stoneType': instance.stoneType,
      'stoneWeight': instance.stoneWeight,
      'stoneValue': instance.stoneValue,
      'discountValue': instance.discountValue,
      'itemTotal': instance.itemTotal,
    };

_$RatesSnapshotImpl _$$RatesSnapshotImplFromJson(Map<String, dynamic> json) =>
    _$RatesSnapshotImpl(
      rateGold22K: (json['rateGold22K'] as num).toDouble(),
      rateGold18K: (json['rateGold18K'] as num).toDouble(),
      rateSilver: (json['rateSilver'] as num).toDouble(),
    );

Map<String, dynamic> _$$RatesSnapshotImplToJson(_$RatesSnapshotImpl instance) =>
    <String, dynamic>{
      'rateGold22K': instance.rateGold22K,
      'rateGold18K': instance.rateGold18K,
      'rateSilver': instance.rateSilver,
    };

_$InvoiceImpl _$$InvoiceImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceImpl(
      id: json['_id'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      customerId: _stringOrIdFromJson(json['customerId']),
      tempCustomerName: json['tempCustomerName'] as String?,
      tempCustomerMobile: json['tempCustomerMobile'] as String?,
      tempCustomerAddress: json['tempCustomerAddress'] as String?,
      tempCustomerPincode: json['tempCustomerPincode'] as String?,
      tempCustomerCity: json['tempCustomerCity'] as String?,
      tempCustomerState: json['tempCustomerState'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      grossAmount: (json['grossAmount'] as num).toDouble(),
      couponCode: json['couponCode'] as String?,
      couponDiscount: (json['couponDiscount'] as num?)?.toDouble() ?? 0.0,
      manualDiscount: (json['manualDiscount'] as num?)?.toDouble() ?? 0.0,
      oldGold: json['oldGold'] == null
          ? null
          : OldGoldAdjustment.fromJson(json['oldGold'] as Map<String, dynamic>),
      taxableAmount: (json['taxableAmount'] as num).toDouble(),
      cgst: (json['cgst'] as num).toDouble(),
      sgst: (json['sgst'] as num).toDouble(),
      totalTax: (json['totalTax'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      finalPayable: (json['finalPayable'] as num).toDouble(),
      payments: (json['payments'] as List<dynamic>)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmountPaid: (json['totalAmountPaid'] as num).toDouble(),
      balanceDue: (json['balanceDue'] as num).toDouble(),
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      generatedBy: _stringOrIdFromJson(json['generatedBy']),
      status: json['status'] as String? ?? 'PAID',
      ratesSnapshot: RatesSnapshot.fromJson(
        json['ratesSnapshot'] as Map<String, dynamic>,
      ),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      pdfBase64: json['pdfBase64'] as String?,
    );

Map<String, dynamic> _$$InvoiceImplToJson(_$InvoiceImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'invoiceNumber': instance.invoiceNumber,
      'customerId': _stringOrIdToJson(instance.customerId),
      'tempCustomerName': instance.tempCustomerName,
      'tempCustomerMobile': instance.tempCustomerMobile,
      'tempCustomerAddress': instance.tempCustomerAddress,
      'tempCustomerPincode': instance.tempCustomerPincode,
      'tempCustomerCity': instance.tempCustomerCity,
      'tempCustomerState': instance.tempCustomerState,
      'items': instance.items,
      'grossAmount': instance.grossAmount,
      'couponCode': instance.couponCode,
      'couponDiscount': instance.couponDiscount,
      'manualDiscount': instance.manualDiscount,
      'oldGold': instance.oldGold,
      'taxableAmount': instance.taxableAmount,
      'cgst': instance.cgst,
      'sgst': instance.sgst,
      'totalTax': instance.totalTax,
      'netAmount': instance.netAmount,
      'finalPayable': instance.finalPayable,
      'payments': instance.payments,
      'totalAmountPaid': instance.totalAmountPaid,
      'balanceDue': instance.balanceDue,
      'invoiceDate': instance.invoiceDate.toIso8601String(),
      'generatedBy': _stringOrIdToJson(instance.generatedBy),
      'status': instance.status,
      'ratesSnapshot': instance.ratesSnapshot,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'pdfBase64': instance.pdfBase64,
    };
