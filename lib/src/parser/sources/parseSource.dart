import 'dart:io';

//source
import './sourceTemplate.dart';
//scraping
import '../../scraper/eval.dart';
//models
import '../json/chapter.dart';
import '../json/chapterID.dart';
import '../json/id.dart';
import '../json/post.dart';
import '../json/catalogEntry.dart';
//utils
import '../../util/ParseError.dart';
import '../../util/RequestType.dart';

///Source build from extensions
class ParseSource extends SourceTemplate {
  final List<Request> requests;
  final String dir;
  final String programType;

  ParseSource({
    required String source,
    required this.requests,
    required int version,
    required String baseurl,
    required String? subdomain,
    required this.programType,
    required this.dir,
  }) : super(
            source: source,
            requestTypes: requests.map((request) => request.type).toSet(),
            version: version,
            baseurl: baseurl,
            subdomain: subdomain);

  @override
  Future<Map<int, String>> fetchChapterImages(ChapterID chapterId) async {
    if (!supports(RequestType.IMAGES)) {
      return super.fetchChapterImages(chapterId);
    }

    final Request request = requests.firstWhere((element) => element.type == RequestType.IMAGES);

    return await eval(
      request.file,
      functionName: request.entry,
      args: [chapterId.toJson()],
      workingDirectory: dir,
    );
  }

  @override
  Future<Map<int, String>> fetchChapterImagesURL(String url) async {
    if (!supports(RequestType.IMAGESURL)) {
      return super.fetchChapterImagesURL(url);
    }

    final Request request = requests.firstWhere((element) => element.type == RequestType.IMAGESURL);

    return await eval(
      request.file,
      functionName: request.entry,
      args: [url],
      workingDirectory: dir,
    );
  }

  @override
  Future<List<Chapter>> fetchChapterList(ID id) async {
    if (!supports(RequestType.CHAPTERS)) {
      return super.fetchChapterList(id);
    }

    final Request request = requests.firstWhere((element) => element.type == RequestType.CHAPTERS);

    dynamic chapters = await eval(
      request.file,
      functionName: request.entry,
      args: [id.toJson()],
      workingDirectory: dir,
    );

    try {
      return List<Chapter>.from(chapters.map((value) => Chapter.fromJson(value)));
    } catch (e, stack) {
      print('Error fetching chapter list: $e');
      print(stack);
      throw ParseError('Error parsing chapter list: $e');
    }
  }

  @override
  Future<Post> fetchPostDataURL(String url) async {
    if (!supports(RequestType.POSTURL)) {
      return super.fetchPostDataURL(url);
    }

    final Request request = requests.firstWhere((element) => element.type == RequestType.POSTURL);

    dynamic post = await eval(
      request.file,
      functionName: request.entry,
      args: [url],
      workingDirectory: dir,
    );

    try {
      return Post.fromJson(Map<String, dynamic>.from(post));
    } catch (e, stack) {
      print('Error parsing post data: $e');
      print(stack);
      throw ParseError('Error parsing post data: $e');
    }
  }

  @override
  Future<Post> fetchPostData(ID id) async {
    if (!supports(RequestType.POST)) {
      return super.fetchPostData(id);
    }

    final Request request = requests.firstWhere((element) => element.type == RequestType.POST);

    dynamic post = await eval(
      request.file,
      functionName: request.entry,
      args: [id.toJson()],
      workingDirectory: dir,
    );
    try {
      return Post.fromJson(Map<String, dynamic>.from(post));
    } catch (e, stack) {
      print('Error parsing post data: $e');
      print(stack);
      throw ParseError('Error parsing post data: $e');
    }
  }

  @override
  Future<List<CatalogEntry>> fetchCatalog({int page = 0}) async {
    if (!supports(RequestType.CATALOG) && !supports(RequestType.CATALOGMULTI)) {
      return super.fetchCatalog();
    }

    Request request;

    //Always will try and use multicatalog first
    try {
      request = requests.firstWhere((element) => element.type == RequestType.CATALOGMULTI);
    } on StateError {
      request = requests.firstWhere((element) => element.type == RequestType.CATALOG);
    }

    dynamic entries = await eval(
      request.file,
      functionName: request.entry,
      args: [page],
      workingDirectory: dir,
    );
    try {
      return List<CatalogEntry>.from(entries.map((entry) => CatalogEntry.fromJson(entry)));
    } catch (e, stack) {
      print('Error fetching catalog: $e');
      print(stack);
      throw ParseError('Error pasing catalog: $e');
    }
  }
}

class Request {
  final RequestType type;
  final File file;
  final String entry;
  Request({required this.type, required this.file, required this.entry});
}
