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
      chapterUpdateState: $enumDecodeNullable(
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

const _$ChapterUpdateStateEnumMap = {
  ChapterUpdateState.Same: 'Same',
  ChapterUpdateState.New: 'New',
  ChapterUpdateState.Deleted: 'Deleted',
};
