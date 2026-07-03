// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerImpl _$$CustomerImplFromJson(Map<String, dynamic> json) =>
    _$CustomerImpl(
      id: json['_id'] as String?,
      mobile: json['mobile'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      pincode: json['pincode'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      panCard: json['panCard'] as String?,
      gstNumber: json['gstNumber'] as String?,
      additionalNote: json['additionalNote'] as String?,
      totalPurchaseAmount:
          (json['totalPurchaseAmount'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      lastVisitDate: json['lastVisitDate'] == null
          ? null
          : DateTime.parse(json['lastVisitDate'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CustomerImplToJson(_$CustomerImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'mobile': instance.mobile,
      'name': instance.name,
      'email': instance.email,
      'address': instance.address,
      'pincode': instance.pincode,
      'city': instance.city,
      'state': instance.state,
      'panCard': instance.panCard,
      'gstNumber': instance.gstNumber,
      'additionalNote': instance.additionalNote,
      'totalPurchaseAmount': instance.totalPurchaseAmount,
      'totalInvoices': instance.totalInvoices,
      'lastVisitDate': instance.lastVisitDate?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
