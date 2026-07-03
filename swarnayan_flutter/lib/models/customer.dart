import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
class Customer with _$Customer {
  const factory Customer({
    @JsonKey(name: '_id') String? id,
    required String mobile,
    required String name,
    String? email,
    String? address,
    String? pincode,
    String? city,
    String? state,
    String? panCard,
    String? gstNumber,
    String? additionalNote,
    @Default(0.0) double totalPurchaseAmount,
    @Default(0) int totalInvoices,
    DateTime? lastVisitDate,
    DateTime? createdAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
}
