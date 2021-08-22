// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
      name: json['name'] as String,
      date: Chapter._dateTime(json['date']),
      chapterID: Chapter._chapterID(json['chapterID']),
      images: (json['images'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), e as String),
          ) ??
          const {},
      chapterUpdateState: _$enumDecodeNullable(
              _$ChapterUpdateStateEnumMap, json['chapterUpdateState']) ??
          ChapterUpdateState.Same,
    );

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
      'name': instance.name,
      'date': Chapter._dateTimeString(instance.date),
      'chapterID': instance.chapterID.toJson(),
      'images': instance.images?.map((k, e) => MapEntry(k.toString(), e)),
      'chapterUpdateState':
          _$ChapterUpdateStateEnumMap[instance.chapterUpdateState],
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$ChapterUpdateStateEnumMap = {
  ChapterUpdateState.Same: 'Same',
  ChapterUpdateState.New: 'New',
  ChapterUpdateState.Deleted: 'Deleted',
};
