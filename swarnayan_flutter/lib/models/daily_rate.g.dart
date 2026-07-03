// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_rate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailyRateImpl _$$DailyRateImplFromJson(Map<String, dynamic> json) =>
    _$DailyRateImpl(
      id: json['_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      rateGold22K: (json['rateGold22K'] as num).toDouble(),
      rateGold18K: (json['rateGold18K'] as num).toDouble(),
      rateSilver: (json['rateSilver'] as num).toDouble(),
      enteredBy: json['enteredBy'] as String?,
    );

Map<String, dynamic> _$$DailyRateImplToJson(_$DailyRateImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'date': instance.date.toIso8601String(),
      'rateGold22K': instance.rateGold22K,
      'rateGold18K': instance.rateGold18K,
      'rateSilver': instance.rateSilver,
      'enteredBy': instance.enteredBy,
    };
