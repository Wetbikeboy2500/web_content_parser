import 'package:json_annotation/json_annotation.dart';
import 'package:web_content_parser/src/json/author.dart';
import 'package:web_content_parser/src/json/id.dart';

part 'post.g.dart';

@JsonSerializable(explicitToJson: true)
class Post {
  final String coverurl;
  final bool completed;
  final String altnames;
  final List<String> categories;
  final String type;
  final String description;
  @JsonKey(fromJson: _id)
  final ID id;
  @JsonKey(fromJson: _authors)
  final List<Author> authors;
  final String name;
  final int chapterNumber;
  @JsonKey(fromJson: _dateTime, toJson: _dateTimeString)
  final DateTime? released;

  Post({
    required this.id,
    required this.name,
    this.coverurl = '',
    this.completed = false,
    this.altnames = '',
    this.authors = const [],
    this.categories = const [],
    this.description = '',
    this.type = 'unknown',
    this.chapterNumber = 0,
    this.released,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);

  static List<Author> _authors(List<dynamic>? authorList) {
    if (authorList != null) {
      if (authorList.isNotEmpty) {
        return authorList.map((auth) => (auth is Author) ? auth : Author.fromJson(auth)).toList();
      } else {
        return const [];
      }
    } else {
      return const [];
    }
  }

  static ID _id(dynamic id) {
    return (id is ID) ? id : ID.fromJson(id);
  }

  static DateTime? _dateTime(dynamic time) {
    if (time == null) {
      return null;
    }
    return (time is DateTime) ? time : DateTime.parse(time as String);
  }

  static String? _dateTimeString(DateTime? time) {
    return time?.toIso8601String();
  }
}
