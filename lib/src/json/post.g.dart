// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      id: Post._id(json['id']),
      name: json['name'] as String,
      coverurl: json['coverurl'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      altnames: json['altnames'] as String? ?? '',
      authors: json['authors'] == null
          ? const []
          : Post._authors(json['authors'] as List?),
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      chapterNumber: json['chapterNumber'] as int? ?? 0,
      released: Post._dateTime(json['released']),
    );

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'coverurl': instance.coverurl,
      'completed': instance.completed,
      'altnames': instance.altnames,
      'categories': instance.categories,
      'type': instance.type,
      'description': instance.description,
      'id': instance.id.toJson(),
      'authors': instance.authors.map((e) => e.toJson()).toList(),
      'name': instance.name,
      'chapterNumber': instance.chapterNumber,
      'released': Post._dateTimeString(instance.released),
    };
