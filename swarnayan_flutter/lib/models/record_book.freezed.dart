// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'record_book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RecordBookEntry _$RecordBookEntryFromJson(Map<String, dynamic> json) {
  return _RecordBookEntry.fromJson(json);
}

/// @nodoc
mixin _$RecordBookEntry {
  @JsonKey(name: '_id')
  String? get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError; // INCOME, EXPENSE
  String get category =>
      throw _privateConstructorUsedError; // SALE, OVERHEAD, RENT, SALARY, UTILITIES, TEA_SNACKS, METAL_PURCHASE, OTHER
  double get amount => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get referenceId => throw _privateConstructorUsedError;
  String? get enteredBy => throw _privateConstructorUsedError;

  /// Serializes this RecordBookEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecordBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecordBookEntryCopyWith<RecordBookEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordBookEntryCopyWith<$Res> {
  factory $RecordBookEntryCopyWith(
    RecordBookEntry value,
    $Res Function(RecordBookEntry) then,
  ) = _$RecordBookEntryCopyWithImpl<$Res, RecordBookEntry>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String type,
    String category,
    double amount,
    DateTime date,
    String? description,
    String? referenceId,
    String? enteredBy,
  });
}

/// @nodoc
class _$RecordBookEntryCopyWithImpl<$Res, $Val extends RecordBookEntry>
    implements $RecordBookEntryCopyWith<$Res> {
  _$RecordBookEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecordBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? type = null,
    Object? category = null,
    Object? amount = null,
    Object? date = null,
    Object? description = freezed,
    Object? referenceId = freezed,
    Object? enteredBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            referenceId: freezed == referenceId
                ? _value.referenceId
                : referenceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            enteredBy: freezed == enteredBy
                ? _value.enteredBy
                : enteredBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecordBookEntryImplCopyWith<$Res>
    implements $RecordBookEntryCopyWith<$Res> {
  factory _$$RecordBookEntryImplCopyWith(
    _$RecordBookEntryImpl value,
    $Res Function(_$RecordBookEntryImpl) then,
  ) = __$$RecordBookEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String? id,
    String type,
    String category,
    double amount,
    DateTime date,
    String? description,
    String? referenceId,
    String? enteredBy,
  });
}

/// @nodoc
class __$$RecordBookEntryImplCopyWithImpl<$Res>
    extends _$RecordBookEntryCopyWithImpl<$Res, _$RecordBookEntryImpl>
    implements _$$RecordBookEntryImplCopyWith<$Res> {
  __$$RecordBookEntryImplCopyWithImpl(
    _$RecordBookEntryImpl _value,
    $Res Function(_$RecordBookEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecordBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? type = null,
    Object? category = null,
    Object? amount = null,
    Object? date = null,
    Object? description = freezed,
    Object? referenceId = freezed,
    Object? enteredBy = freezed,
  }) {
    return _then(
      _$RecordBookEntryImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        referenceId: freezed == referenceId
            ? _value.referenceId
            : referenceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        enteredBy: freezed == enteredBy
            ? _value.enteredBy
            : enteredBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordBookEntryImpl implements _RecordBookEntry {
  const _$RecordBookEntryImpl({
    @JsonKey(name: '_id') this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.referenceId,
    this.enteredBy,
  });

  factory _$RecordBookEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecordBookEntryImplFromJson(json);

  @override
  @JsonKey(name: '_id')
  final String? id;
  @override
  final String type;
  // INCOME, EXPENSE
  @override
  final String category;
  // SALE, OVERHEAD, RENT, SALARY, UTILITIES, TEA_SNACKS, METAL_PURCHASE, OTHER
  @override
  final double amount;
  @override
  final DateTime date;
  @override
  final String? description;
  @override
  final String? referenceId;
  @override
  final String? enteredBy;

  @override
  String toString() {
    return 'RecordBookEntry(id: $id, type: $type, category: $category, amount: $amount, date: $date, description: $description, referenceId: $referenceId, enteredBy: $enteredBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordBookEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.enteredBy, enteredBy) ||
                other.enteredBy == enteredBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    category,
    amount,
    date,
    description,
    referenceId,
    enteredBy,
  );

  /// Create a copy of RecordBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordBookEntryImplCopyWith<_$RecordBookEntryImpl> get copyWith =>
      __$$RecordBookEntryImplCopyWithImpl<_$RecordBookEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordBookEntryImplToJson(this);
  }
}

abstract class _RecordBookEntry implements RecordBookEntry {
  const factory _RecordBookEntry({
    @JsonKey(name: '_id') final String? id,
    required final String type,
    required final String category,
    required final double amount,
    required final DateTime date,
    final String? description,
    final String? referenceId,
    final String? enteredBy,
  }) = _$RecordBookEntryImpl;

  factory _RecordBookEntry.fromJson(Map<String, dynamic> json) =
      _$RecordBookEntryImpl.fromJson;

  @override
  @JsonKey(name: '_id')
  String? get id;
  @override
  String get type; // INCOME, EXPENSE
  @override
  String get category; // SALE, OVERHEAD, RENT, SALARY, UTILITIES, TEA_SNACKS, METAL_PURCHASE, OTHER
  @override
  double get amount;
  @override
  DateTime get date;
  @override
  String? get description;
  @override
  String? get referenceId;
  @override
  String? get enteredBy;

  /// Create a copy of RecordBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecordBookEntryImplCopyWith<_$RecordBookEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
