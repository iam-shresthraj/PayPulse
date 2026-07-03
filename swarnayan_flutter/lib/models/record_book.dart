import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_book.freezed.dart';
part 'record_book.g.dart';

@freezed
class RecordBookEntry with _$RecordBookEntry {
  const factory RecordBookEntry({
    @JsonKey(name: '_id') String? id,
    required String type, // INCOME, EXPENSE
    required String category, // SALE, OVERHEAD, RENT, SALARY, UTILITIES, TEA_SNACKS, METAL_PURCHASE, OTHER
    required double amount,
    required DateTime date,
    String? description,
    String? referenceId,
    String? enteredBy,
  }) = _RecordBookEntry;

  factory RecordBookEntry.fromJson(Map<String, dynamic> json) => _$RecordBookEntryFromJson(json);
}
