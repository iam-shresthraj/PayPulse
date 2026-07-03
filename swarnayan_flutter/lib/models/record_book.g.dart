// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecordBookEntryImpl _$$RecordBookEntryImplFromJson(
  Map<String, dynamic> json,
) => _$RecordBookEntryImpl(
  id: json['_id'] as String?,
  type: json['type'] as String,
  category: json['category'] as String,
  amount: (json['amount'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
  description: json['description'] as String?,
  referenceId: json['referenceId'] as String?,
  enteredBy: json['enteredBy'] as String?,
);

Map<String, dynamic> _$$RecordBookEntryImplToJson(
  _$RecordBookEntryImpl instance,
) => <String, dynamic>{
  '_id': instance.id,
  'type': instance.type,
  'category': instance.category,
  'amount': instance.amount,
  'date': instance.date.toIso8601String(),
  'description': instance.description,
  'referenceId': instance.referenceId,
  'enteredBy': instance.enteredBy,
};
