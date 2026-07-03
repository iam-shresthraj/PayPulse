import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_summary.freezed.dart';
part 'inventory_summary.g.dart';

@freezed
class CategorySummary with _$CategorySummary {
  const factory CategorySummary({
    required String category, // GOLD, SILVER, etc.
    required int totalProducts,
    required int totalStockUnits,
    required double totalWeight,
    required double metalValueEstimate,
  }) = _CategorySummary;

  factory CategorySummary.fromJson(Map<String, dynamic> json) => _$CategorySummaryFromJson(json);
}

@freezed
class InventorySummary with _$InventorySummary {
  const factory InventorySummary({
    required List<CategorySummary> categories,
    required int totalUniqueItems,
    required int totalItemsInStock,
    required double totalWeightGold,
    required double totalWeightSilver,
    required double totalValuationEstimate,
  }) = _InventorySummary;

  factory InventorySummary.fromJson(Map<String, dynamic> json) => _$InventorySummaryFromJson(json);
}
