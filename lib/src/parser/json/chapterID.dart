import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import './id.dart';

part 'chapterID.g.dart';

@JsonSerializable(explicitToJson: true)
class ChapterID extends Equatable {
  final String url;
  @JsonKey(fromJson: _integer)
  final int index;
  @JsonKey(fromJson: _id)
  final ID id;
  final String uid;

  //TODO: Add support for chapter uid to replace index in the uid

  ChapterID({
    required this.url,
    required this.index,
    required this.id,
    String? uid,
  }) : uid = (uid != null && uid.isNotEmpty) ? uid : '${id.uid}:$index';

  factory ChapterID.fromJson(Map<String, dynamic> json) => _$ChapterIDFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterIDToJson(this);

  static ID _id(dynamic id) {
    if (id is ID) {
      return id;
    } else {
      return ID.fromJson(id);
    }
  }

  static int _integer(dynamic i) {
    if (i is String) {
      return int.parse(i);
    } else {
      return i as int;
    }
  }

  @override
  List<Object> get props => <Object>[uid];
}
