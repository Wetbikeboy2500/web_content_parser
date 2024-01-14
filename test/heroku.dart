import 'dart:async';
import 'package:web_content_parser/web_content_parser_full.dart';

class TestSource extends SourceTemplate {
  TestSource(String base, String subdomain)
      : super(
            source: 'test',
            requestTypes: {RequestType.post, RequestType.chapters, RequestType.postUrl},
            baseurl: base,
            subdomain: subdomain,
            version: 1);

  @override
  Future<Result<Post>> fetchPost(ID id) async {
    if (id.id == '0') {
      throw 'Invalid ID';
    }

    return await fetchPostUrl('https://test.example.test/get/${id.id}');
  }

  @override
  Future<Result<Post>> fetchPostUrl(String url) async {
    return Pass(Post(id: ID(id: '1', source: 'test'), name: 'test'));
  }

  @override
  Future<Result<List<Chapter>>> fetchChapters(ID id) async {
    return Pass([
      Chapter(
        name: 'test 1',
        date: DateTime.now(),
        chapterID: ChapterID(
          url: 'test.example.test',
          index: 0,
          id: ID(id: '1', source: 'test'),
        ),
      ),
      Chapter(
        name: 'test 2',
        date: DateTime.now(),
        chapterID: ChapterID(
          url: 'test.example.test',
          index: 1,
          id: ID(id: '1', source: 'test'),
        ),
      ),
    ]);
  }
}
