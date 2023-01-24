import 'package:json_annotation/json_annotation.dart';

import 'package:equatable/equatable.dart';

part 'id.g.dart';

@JsonSerializable()
class ID extends Equatable {
  final String source;
  final String id;
  final String uid;

  ID({required this.source, required this.id, String? uid})
      : uid = (uid != null && uid.isNotEmpty) ? uid : '$source:$id';

  factory ID.fromJson(Map<String, dynamic> json) => _$IDFromJson(json);

  Map<String, dynamic> toJson() => _$IDToJson(this);

  @override
  List<Object> get props => <Object>[uid];
}
