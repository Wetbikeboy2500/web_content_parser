import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:web_content_parser/web_content_parser.dart';

import 'package:http/http.dart' as http;

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
    return await fetchPostUrl('https://$host/manga/get/${id.id}');
  }

  @override
  Future<Result<Post>> fetchPostUrl(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var j = jsonDecode(response.body);
      j['id'] = ID(id: j['id'], source: 'heroku').toJson();
      return Result.pass(Post.fromJson(j));
    } else {
      Logger.root.warning('Status Error: ${response.statusCode.toString()}, $url');
      return const Result.fail();
    }
  }

  @override
  Future<Result<List<Chapter>>> fetchChapters(ID id) async {
    final url = Uri.parse('https://$host/manga/chapters/${id.id}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final chapters = List<dynamic>.from(jsonDecode(response.body)).map((obj) {
        obj['chapterID'] = {
          'url': obj['url'],
          'index': obj['chapterindex'],
          'id': id,
        };
        return Chapter.fromJson(obj);
      }).toList();
      return Result.pass(chapters);
    } else {
      Logger.root.warning('Failed to load ${id.uid}');
      return const Result.fail();
    }
  }
}
