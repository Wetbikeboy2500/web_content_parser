import '../../util/RequestType.dart';
import '../../util/log.dart';
import '../json/catalogEntry.dart';
import '../json/chapter.dart';
import '../json/chapterID.dart';
import '../json/id.dart';
import '../json/post.dart';

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
    log('Empty request for fetch post', level: const LogLevel.warn());
    return const Fail();
  }

  Future<Result<Post>> fetchPostUrl(String url) async {
    log('Empty request for fetch post url', level: const LogLevel.warn());
    return const Fail();
  }

  Future<Result<List<Chapter>>> fetchChapters(ID id) async {
    log('Empty request for fetch chapters', level: const LogLevel.warn());
    return const Fail();
  }

  Future<Result<Map<int, String>>> fetchChapterImages(ChapterID chapterId) async {
    log('Empty request for fetch chapter images', level: const LogLevel.warn());
    return const Fail();
  }

  Future<Result<Map<int, String>>> fetchChapterImagesUrl(String url) async {
    log('Empty request for chapter images url', level: const LogLevel.warn());
    return const Fail();
  }

  Future<Result<List<CatalogEntry>>> fetchCatalog({int page = 0, Map<String, dynamic> options = const {}}) async {
    log('Empty request for fetch catalog', level: const LogLevel.warn());
    return const Fail();
  }

  bool supports(RequestType type) {
    return requestTypes.contains(type);
  }

  String get host => subdomain != null ? '${subdomain!}.$baseurl' : baseurl;
}
