import 'package:web_content_parser/src/util/Result.dart';
import 'package:web_content_parser/src/util/log.dart';

import '../json/catalogEntry.dart';
import '../json/chapter.dart';
import '../json/chapterID.dart';
import '../json/id.dart';
import '../json/post.dart';
import '../../util/RequestType.dart';

///Base of all sources
///Provides a consistent API for the sources
abstract class SourceTemplate {
  final String source;
  ///Stores the types of requests that the source supports. Refer to [RequestType]
  final Set<RequestType> requestTypes;
  ///Subdomain to match if not null
  final String? subdomain;
  ///Base url to match for a source
  final String baseurl;
  ///Keeps track of current source version
  final int version;

  SourceTemplate({
    required this.source,
    required this.requestTypes,
    required this.baseurl,
    required this.version,
    this.subdomain,
  });

  Future<Result<Post>> fetchPost(ID id) async {
    log('Empty request for fetch post');
    return Result.fail();
  }

  Future<Result<Post>> fetchPostUrl(String url) async {
    log('Empty request for fetch post url');
    return Result.fail();
  }

  Future<Result<List<Chapter>>> fetchChapters(ID id) async {
    log('Empty request for fetch chapters');
    return Result.fail();
  }

  Future<Result<Map<int, String>>> fetchChapterImages(ChapterID chapterId) async {
    log('Empty request for fetch chapter images');
    return Result.fail();
  }

  Future<Result<Map<int, String>>> fetchChapterImagesUrl(String url) async {
    log('Empty request for chapter images url');
    return Result.fail();
  }

  Future<Result<List<CatalogEntry>>> fetchCatalog({int page = 0}) async {
    log('Empty request for fetch catalog');
    return Result.fail();
  }

  bool supports(RequestType type) {
    return requestTypes.contains(type);
  }

  String host() {
    if (subdomain != null) {
      return subdomain! + '.' + baseurl;
    } else {
      return baseurl;
    }
  }
}
