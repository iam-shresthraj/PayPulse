// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategorySummaryImpl _$$CategorySummaryImplFromJson(
  Map<String, dynamic> json,
) => _$CategorySummaryImpl(
  category: json['category'] as String,
  totalProducts: (json['totalProducts'] as num).toInt(),
  totalStockUnits: (json['totalStockUnits'] as num).toInt(),
  totalWeight: (json['totalWeight'] as num).toDouble(),
  metalValueEstimate: (json['metalValueEstimate'] as num).toDouble(),
);

Map<String, dynamic> _$$CategorySummaryImplToJson(
  _$CategorySummaryImpl instance,
) => <String, dynamic>{
  'category': instance.category,
  'totalProducts': instance.totalProducts,
  'totalStockUnits': instance.totalStockUnits,
  'totalWeight': instance.totalWeight,
  'metalValueEstimate': instance.metalValueEstimate,
};

_$InventorySummaryImpl _$$InventorySummaryImplFromJson(
  Map<String, dynamic> json,
) => _$InventorySummaryImpl(
  categories: (json['categories'] as List<dynamic>)
      .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalUniqueItems: (json['totalUniqueItems'] as num).toInt(),
  totalItemsInStock: (json['totalItemsInStock'] as num).toInt(),
  totalWeightGold: (json['totalWeightGold'] as num).toDouble(),
  totalWeightSilver: (json['totalWeightSilver'] as num).toDouble(),
  totalValuationEstimate: (json['totalValuationEstimate'] as num).toDouble(),
);

Map<String, dynamic> _$$InventorySummaryImplToJson(
  _$InventorySummaryImpl instance,
) => <String, dynamic>{
  'categories': instance.categories,
  'totalUniqueItems': instance.totalUniqueItems,
  'totalItemsInStock': instance.totalItemsInStock,
  'totalWeightGold': instance.totalWeightGold,
  'totalWeightSilver': instance.totalWeightSilver,
  'totalValuationEstimate': instance.totalValuationEstimate,
};
