import '../json/catalogEntry.dart';
import '../json/chapter.dart';
import '../json/chapterID.dart';
import '../json/id.dart';
import '../json/post.dart';
import '../../util/EmptyRequest.dart';
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

  Future<Post> fetchPostData(ID id) async {
    throw EmptyRequest('Fetch post');
  }

  Future<Post> fetchPostDataURL(String url) async {
    throw EmptyRequest('Fetch post URL');
  }

  Future<List<Chapter>> fetchChapterList(ID id) async {
    throw EmptyRequest('Fetch chapter list');
  }

  Future<Map<int, String>> fetchChapterImages(ChapterID chapterId) async {
    throw EmptyRequest('Fetch chapter images');
  }

  Future<Map<int, String>> fetchChapterImagesURL(String url) async {
    throw EmptyRequest('Fetch chapter images URL');
  }

  Future<List<CatalogEntry>> fetchCatalog({int page = 0}) async {
    throw EmptyRequest('Fetch Catalog');
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
