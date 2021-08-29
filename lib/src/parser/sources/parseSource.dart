import 'dart:async';
import 'dart:io';

//source
import 'package:computer/computer.dart';

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

  ///Enable computes for data conversion
  ///This provides better performance for multiple async calls
  static bool computeEnabled = true;

  static final _computer = Computer();
  static int _running = 0;

  ///Number of workers to be made for compute calls
  static int workers = 2;

  static void _startUp() {
    _running++;
    if (!_computer.isRunning) {
      _computer.turnOn();
    }
  }

  static Timer? _finalTimer;

  ///Time after a data conversion finishes to close all isolates. They are kept open for performance.
  static int computeCooldownMilliseconds = 5000;

  static void _shutDown() {
    _running--;
    if (_computer.isRunning && _running == 0 && (_finalTimer == null || !_finalTimer!.isActive)) {
      _finalTimer = Timer(Duration(seconds: 5), () {
        if (_running == 0) {
          _computer.turnOff();
        }
      });
    }
  }

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
    if (!supports(RequestType.images)) {
      return super.fetchChapterImages(chapterId);
    }

    final Request request = requests.firstWhere((element) => element.type == RequestType.images);

    return await eval(
      request.file,
      functionName: request.entry,
      args: [chapterId.toJson()],
      workingDirectory: dir,
    );
  }

  @override
  Future<Map<int, String>> fetchChapterImagesUrl(String url) async {
    if (!supports(RequestType.imagesUrl)) {
      return super.fetchChapterImagesUrl(url);
    }

    final Request request = requests.firstWhere((element) => element.type.imagesUrl);

    return await eval(
      request.file,
      functionName: request.entry,
      args: [url],
      workingDirectory: dir,
    );
  }

  @override
  Future<List<Chapter>> fetchChapters(ID id) async {
    if (!supports(RequestType.chapters)) {
      return super.fetchChapters(id);
    }

    final Request request = requests.firstWhere((element) => element.type.chapters);

    List chapters = await eval(
      request.file,
      functionName: request.entry,
      args: [id.toJson()],
      workingDirectory: dir,
    ) as List;

    try {
      if (computeEnabled) {
        _startUp();
        final List<Chapter> response =
            await Chapter.computeChaptersFromJson(_computer, chapters.cast<Map<String, dynamic>>());
        _shutDown();
        return response;
      } else {
        return List<Chapter>.from(chapters.map((value) => Chapter.fromJson(value)));
      }
    } catch (e, stack) {
      if (computeEnabled) {
        //going to assume there was a parse error which means there is an open compute
        _shutDown();
      }
      print('Error fetching chapter list: $e');
      print(stack);
      throw ParseError('Error parsing chapter list: $e');
    }
  }

  @override
  Future<Post> fetchPostUrl(String url) async {
    if (!supports(RequestType.postUrl)) {
      return super.fetchPostUrl(url);
    }

    final Request request = requests.firstWhere((element) => element.type.postUrl);

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
  Future<Post> fetchPost(ID id) async {
    if (!supports(RequestType.post)) {
      return super.fetchPost(id);
    }

    final Request request = requests.firstWhere((element) => element.type.post);

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
    if (!supports(RequestType.catalog) && !supports(RequestType.catalogMulti)) {
      return super.fetchCatalog();
    }

    Request request;

    //Always will try and use multicatalog first
    try {
      request = requests.firstWhere((element) => element.type.catalogMulti);
    } on StateError {
      request = requests.firstWhere((element) => element.type.catalog);
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
