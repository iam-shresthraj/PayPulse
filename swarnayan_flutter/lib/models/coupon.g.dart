// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CouponImpl _$$CouponImplFromJson(Map<String, dynamic> json) => _$CouponImpl(
  id: json['_id'] as String?,
  code: json['code'] as String,
  discountType: json['discountType'] as String,
  discountValue: (json['discountValue'] as num).toDouble(),
  minBillAmount: (json['minBillAmount'] as num?)?.toDouble() ?? 0.0,
  maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? 0.0,
  expiryDate: DateTime.parse(json['expiryDate'] as String),
  startsAt: json['startsAt'] == null
      ? null
      : DateTime.parse(json['startsAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  usageLimit: (json['usageLimit'] as num?)?.toInt(),
  usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$CouponImplToJson(_$CouponImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'code': instance.code,
      'discountType': instance.discountType,
      'discountValue': instance.discountValue,
      'minBillAmount': instance.minBillAmount,
      'maxDiscount': instance.maxDiscount,
      'expiryDate': instance.expiryDate.toIso8601String(),
      'startsAt': instance.startsAt?.toIso8601String(),
      'isActive': instance.isActive,
      'usageLimit': instance.usageLimit,
      'usedCount': instance.usedCount,
    };
