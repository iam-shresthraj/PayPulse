import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    @JsonKey(name: '_id') String? id,
    required String name,
    required String category, // GOLD, SILVER, PLATINUM, DIAMOND, OTHER
    required String purity, // 24K, 22K, 18K, 14K, SILVER_999, SILVER_925, OTHER
    String? huidNumber,
    @Default('7113') String hsnCode,
    @Default(1) int stockUnits,
    @Default(0.0) double weight,
    @Default(0.0) double makingChargeValue,
    String? stoneType,
    @Default(0.0) double stoneWeight,
    @Default(0.0) double stoneValue,
    String? imageUrl,
    @Default(true) bool isActive,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
