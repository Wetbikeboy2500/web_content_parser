import 'package:computer/computer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:web_content_parser/src/parser/sources/computeDecorator.dart';
import '../../parser/sources/computer.dart';
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
    if (time == null) {
      return DateTime.now();
    }

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

  static Future<Chapter> computeChapterFromJson(ComputerDecorator computer, Map<String, dynamic> chapter) {
    return computer.compute<Chapter, Map<String, dynamic>>(_$ChapterFromJson, chapter);
  }

  static Future<Map<String, dynamic>> computeChapterToJson(ComputerDecorator computer, Chapter chapter) {
    return computer.compute<Map<String, dynamic>, Chapter>(_$ChapterToJson, chapter);
  }

  static Future<List<Chapter>> computeChaptersFromJson(ComputeDecorator computer, List<Map<String, dynamic>> chapters) {
    return computer.compute<List<Chapter>, List<Map<String, dynamic>>>(chaptersFromJson, chapters);
  }

  static List<Chapter> chaptersFromJson(List<Map<String, dynamic>> chapters) {
    return chapters.map((e) => _$ChapterFromJson(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> computeChaptersToJson(ComputeDecorator computer, List<Chapter> chapters) {
    return computer.compute<List<Map<String, dynamic>>, List<Chapter>>(
      (List<Chapter> chapters) => chapters.map((e) => _$ChapterToJson(e)).toList(),
      chapters,
    );
  }
}

//This is for if tracking is added for changes made to a chapter list
//This package current doesn't have a set way to do this since it would require some previous knowledge of stored chapters
enum ChapterUpdateState {
  Same,
  New,
  Deleted,
}
