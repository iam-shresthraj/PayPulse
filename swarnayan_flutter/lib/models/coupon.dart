import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon.freezed.dart';
part 'coupon.g.dart';

@freezed
class Coupon with _$Coupon {
  const factory Coupon({
    @JsonKey(name: '_id') String? id,
    required String code,
    required String discountType, // PERCENTAGE, FIXED
    required double discountValue,
    @Default(0.0) double minBillAmount,
    @Default(0.0) double maxDiscount,
    required DateTime expiryDate,
    DateTime? startsAt,
    @Default(true) bool isActive,
    int? usageLimit,
    @Default(0) int usedCount,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);
}
