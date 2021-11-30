// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapterID.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChapterID _$ChapterIDFromJson(Map<String, dynamic> json) => ChapterID(
      url: json['url'] as String,
      index: ChapterID._integer(json['index']),
      id: ChapterID._id(json['id']),
      uid: json['uid'] as String?,
    );

Map<String, dynamic> _$ChapterIDToJson(ChapterID instance) => <String, dynamic>{
      'url': instance.url,
      'index': instance.index,
      'id': instance.id.toJson(),
      'uid': instance.uid,
    };
