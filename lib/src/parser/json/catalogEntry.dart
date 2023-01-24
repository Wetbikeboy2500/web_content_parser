import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import './id.dart';

part 'catalogEntry.g.dart';

@JsonSerializable(explicitToJson: true)
class CatalogEntry extends Equatable {
  @JsonKey(fromJson: _id)
  final ID id;
  final String coverurl;
  final String name;

  CatalogEntry({required this.id, required this.coverurl, required this.name});

  factory CatalogEntry.fromJson(Map<String, dynamic> json) => _$CatalogEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogEntryToJson(this);

  static ID _id(dynamic id) {
    if (id is ID) {
      return id;
    } else {
      return ID.fromJson(Map<String, dynamic>.from(id));
    }
  }

  @override
  List<Object> get props => [id];
}
