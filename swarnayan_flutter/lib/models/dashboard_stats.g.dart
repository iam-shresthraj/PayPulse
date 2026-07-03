// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SalesCollectionDataImpl _$$SalesCollectionDataImplFromJson(
  Map<String, dynamic> json,
) => _$SalesCollectionDataImpl(
  grossSales: (json['grossSales'] as num).toDouble(),
  netRevenue: (json['netRevenue'] as num).toDouble(),
  totalDiscount: (json['totalDiscount'] as num).toDouble(),
  collectionCash: (json['collectionCash'] as num).toDouble(),
  collectionCard: (json['collectionCard'] as num).toDouble(),
  collectionUpi: (json['collectionUpi'] as num).toDouble(),
  collectionBankTransfer: (json['collectionBankTransfer'] as num).toDouble(),
  totalCollection: (json['totalCollection'] as num).toDouble(),
  invoiceCount: (json['invoiceCount'] as num).toInt(),
);

Map<String, dynamic> _$$SalesCollectionDataImplToJson(
  _$SalesCollectionDataImpl instance,
) => <String, dynamic>{
  'grossSales': instance.grossSales,
  'netRevenue': instance.netRevenue,
  'totalDiscount': instance.totalDiscount,
  'collectionCash': instance.collectionCash,
  'collectionCard': instance.collectionCard,
  'collectionUpi': instance.collectionUpi,
  'collectionBankTransfer': instance.collectionBankTransfer,
  'totalCollection': instance.totalCollection,
  'invoiceCount': instance.invoiceCount,
};

_$RecentActivityImpl _$$RecentActivityImplFromJson(Map<String, dynamic> json) =>
    _$RecentActivityImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      user: json['user'] as String,
    );

Map<String, dynamic> _$$RecentActivityImplToJson(
  _$RecentActivityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'action': instance.action,
  'description': instance.description,
  'timestamp': instance.timestamp.toIso8601String(),
  'user': instance.user,
};

_$DashboardStatsImpl _$$DashboardStatsImplFromJson(Map<String, dynamic> json) =>
    _$DashboardStatsImpl(
      today: SalesCollectionData.fromJson(
        json['today'] as Map<String, dynamic>,
      ),
      monthly: SalesCollectionData.fromJson(
        json['monthly'] as Map<String, dynamic>,
      ),
      categorySales: (json['categorySales'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      recentActivities: (json['recentActivities'] as List<dynamic>)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCustomers: (json['totalCustomers'] as num).toInt(),
      lowStockCount: (json['lowStockCount'] as num).toInt(),
    );

Map<String, dynamic> _$$DashboardStatsImplToJson(
  _$DashboardStatsImpl instance,
) => <String, dynamic>{
  'today': instance.today,
  'monthly': instance.monthly,
  'categorySales': instance.categorySales,
  'recentActivities': instance.recentActivities,
  'totalCustomers': instance.totalCustomers,
  'lowStockCount': instance.lowStockCount,
};
