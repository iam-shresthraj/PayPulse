import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
part 'dashboard_stats.g.dart';

@freezed
class SalesCollectionData with _$SalesCollectionData {
  const factory SalesCollectionData({
    required double grossSales,
    required double netRevenue,
    required double totalDiscount,
    required double collectionCash,
    required double collectionCard,
    required double collectionUpi,
    required double collectionBankTransfer,
    required double totalCollection,
    required int invoiceCount,
  }) = _SalesCollectionData;

  factory SalesCollectionData.fromJson(Map<String, dynamic> json) => _$SalesCollectionDataFromJson(json);
}

@freezed
class RecentActivity with _$RecentActivity {
  const factory RecentActivity({
    required String id,
    required String type, // INVOICE, PRODUCT, CUSTOMER, RATE, RECORD
    required String action, // CREATE, CANCEL, UPDATE
    required String description,
    required DateTime timestamp,
    required String user,
  }) = _RecentActivity;

  factory RecentActivity.fromJson(Map<String, dynamic> json) => _$RecentActivityFromJson(json);
}

@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    required SalesCollectionData today,
    required SalesCollectionData monthly,
    required Map<String, double> categorySales,
    required List<RecentActivity> recentActivities,
    required int totalCustomers,
    required int lowStockCount,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);
}
