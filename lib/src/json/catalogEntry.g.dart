// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalogEntry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogEntry _$CatalogEntryFromJson(Map<String, dynamic> json) => CatalogEntry(
      id: CatalogEntry._id(json['id']),
      coverurl: json['coverurl'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$CatalogEntryToJson(CatalogEntry instance) =>
    <String, dynamic>{
      'id': instance.id.toJson(),
      'coverurl': instance.coverurl,
      'name': instance.name,
    };
