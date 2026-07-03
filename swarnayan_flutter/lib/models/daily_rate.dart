import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_rate.freezed.dart';
part 'daily_rate.g.dart';

@freezed
class DailyRate with _$DailyRate {
  const factory DailyRate({
    @JsonKey(name: '_id') String? id,
    required DateTime date,
    required double rateGold22K,
    required double rateGold18K,
    required double rateSilver,
    String? enteredBy,
  }) = _DailyRate;

  factory DailyRate.fromJson(Map<String, dynamic> json) => _$DailyRateFromJson(json);
}
