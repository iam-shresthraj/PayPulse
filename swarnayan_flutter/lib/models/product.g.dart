// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['_id'] as String?,
      name: json['name'] as String,
      category: json['category'] as String,
      purity: json['purity'] as String,
      huidNumber: json['huidNumber'] as String?,
      hsnCode: json['hsnCode'] as String? ?? '7113',
      stockUnits: (json['stockUnits'] as num?)?.toInt() ?? 1,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      makingChargeValue: (json['makingChargeValue'] as num?)?.toDouble() ?? 0.0,
      stoneType: json['stoneType'] as String?,
      stoneWeight: (json['stoneWeight'] as num?)?.toDouble() ?? 0.0,
      stoneValue: (json['stoneValue'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'purity': instance.purity,
      'huidNumber': instance.huidNumber,
      'hsnCode': instance.hsnCode,
      'stockUnits': instance.stockUnits,
      'weight': instance.weight,
      'makingChargeValue': instance.makingChargeValue,
      'stoneType': instance.stoneType,
      'stoneWeight': instance.stoneWeight,
      'stoneValue': instance.stoneValue,
      'imageUrl': instance.imageUrl,
      'isActive': instance.isActive,
    };
