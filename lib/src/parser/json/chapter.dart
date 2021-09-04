import 'package:computer/computer.dart';
import 'package:json_annotation/json_annotation.dart';
import './chapterID.dart';

part 'chapter.g.dart';

@JsonSerializable(explicitToJson: true)
class Chapter {
  final String name;
  @JsonKey(fromJson: _dateTime, toJson: _dateTimeString)
  final DateTime date;
  @JsonKey(fromJson: _chapterID)
  final ChapterID chapterID;
  final Map<int, String>? images;
  final ChapterUpdateState? chapterUpdateState;

  Chapter({
    required this.name,
    required this.date, //TODO: might need to change from date to more dynamic system
    required this.chapterID,
    this.images = const {},
    this.chapterUpdateState = ChapterUpdateState.Same,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterToJson(this);

  static DateTime _dateTime(dynamic time) {
    if (time is DateTime) {
      return time;
    } else {
      return DateTime.parse(time as String);
    }
  }

  static String _dateTimeString(DateTime time) {
    return time.toIso8601String();
  }

  static ChapterID _chapterID(dynamic id) {
    if (id is ChapterID) {
      return id;
    } else {
      return ChapterID.fromJson(id);
    }
  }

  static Future<Chapter> computeChapterFromJson(Computer computer, Map<String, dynamic> chapter) async {
    return computer.compute<Map<String, dynamic>, Chapter>(_$ChapterFromJson, param: chapter);
  }

  static Future<Map<String, dynamic>> computeChapterToJson(Computer computer, Chapter chapter) async {
    return computer.compute<Chapter, Map<String, dynamic>>(_$ChapterToJson, param: chapter);
  }

  static Future<List<Chapter>> computeChaptersFromJson(Computer computer, List<Map<String, dynamic>> chapters) async {
    return computer.compute<List<Map<String, dynamic>>, List<Chapter>>(chaptersFromJson, param: chapters);
  }

  static chaptersFromJson(List<Map<String, dynamic>> chapters) {
    return chapters.map((e) => _$ChapterFromJson(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> computeChaptersToJson(Computer computer, List<Chapter> chapters) async {
    return computer.compute((List<Chapter> chapters) => chapters.map((e) => _$ChapterToJson(e)).toList(),
        param: chapters);
  }
}

//This is for if tracking is added for changes made to a chapter list
//This package current doesn't have a set way to do this since it would require some previous knowledge of stored chapters
enum ChapterUpdateState {
  Same,
  New,
  Deleted,
}
