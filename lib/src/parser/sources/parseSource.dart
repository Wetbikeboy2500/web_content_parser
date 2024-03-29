import 'dart:async';

//source
import 'package:web_content_parser/src/parser/sources/computer.dart';
import './computeDecorator.dart';
import '../../scraper/scraperSource.dart';
import '../../util/Result.dart';
import '../../util/log.dart';

import './sourceTemplate.dart';
//models
import '../json/chapter.dart';
import '../json/chapterID.dart';
import '../json/id.dart';
import '../json/post.dart';
import '../json/catalogEntry.dart';
//utils
import '../../util/RequestType.dart';

///Source build from extensions
class ParseSource extends SourceTemplate {
  final ScraperSource scraper;
  final String programType;

  static ComputeDecorator computeDecorator = ComputerDecorator();

  ///Enable computes for data conversion
  ///This provides better performance for multiple async calls
  static bool computeEnabled = true;

  ///Builds a parse source from a scraper source
  ///
  ///[strict] Should contentType be specified as a supported type. If it isn't, an exception will be thrown.
  ///This is to account for scraper sources being made that are not in a supported format. It currently is not an issue, but in the future, there can be times where checking the contentType will be needed for flexability.
  ParseSource(this.scraper, {bool strict = true})
      : programType = scraper.info['programType'],
        super(
          source: scraper.info['source'],
          requestTypes: scraper.requests.values.map((request) => request.type).toSet(),
          version: scraper.info['version'],
          baseurl: scraper.info['baseUrl'] ?? '',
          subdomain: scraper.info['subdomain'],
        ) {
    if (!scraper.info.containsKey('baseUrl')) {
      throw Exception('BaseUrl is not defined');
    }

    if (!scraper.info.containsKey('subdomain')) {
      throw Exception('Subdomain is not defined');
    }

    if (strict && !['seriesImage'].contains(scraper.info['contentType'])) {
      throw const FormatException('Doesn\'t have valid contentType');
    }
  }

  @override
  Future<Result<Map<int, String>>> fetchChapterImages(ChapterID chapterId) async {
    if (!supports(RequestType.images)) {
      return super.fetchChapterImages(chapterId);
    }

    final result = await scraper.makeRequest(RequestType.images.string, [MapEntry('chapterId', chapterId.toJson())]);

    if (result.fail || result.data == null) {
      log('Fetch chapter images request failed', level: const LogLevel.warn());
      return const Result.fail();
    }

    try {
      return Result.pass((result.data is! Map<int, String>) ? Map<int, String>.from(result.data) : result.data);
    } catch (e, stack) {
      log2('Error converting chapter images', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }

  @override
  Future<Result<Map<int, String>>> fetchChapterImagesUrl(String url) async {
    if (!supports(RequestType.imagesUrl)) {
      return super.fetchChapterImagesUrl(url);
    }

    final result = await scraper.makeRequest(RequestType.imagesUrl.string, [MapEntry('url', url)]);

    if (result.fail || result.data == null) {
      log('Fetch chapter images url request failed', level: const LogLevel.warn());
      return const Result.fail();
    }

    try {
      return Result.pass((result.data is! Map<int, String>) ? Map<int, String>.from(result.data!) : result.data!);
    } catch (e, stack) {
      log2('Error converting chapter images', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }

  @override
  Future<Result<List<Chapter>>> fetchChapters(ID id) async {
    if (!supports(RequestType.chapters)) {
      return super.fetchChapters(id);
    }

    final Result<List> chapters =
        await scraper.makeRequest<List>(RequestType.chapters.string, [MapEntry('id', id.toJson())]);

    if (chapters.fail || chapters.data == null) {
      log('Fetch chapters request failed', level: const LogLevel.warn());
      return const Result.fail();
    }

    if (computeEnabled) {
      computeDecorator.start();

      try {
        //I currently am only using computer here since lists of chapters can have a lot of data to be processed
        final List<Chapter> response =
            await Chapter.computeChaptersFromJson(computeDecorator, chapters.data!.cast<Map<String, dynamic>>());
        computeDecorator.end();
        return Result.pass(response);
      } catch (e, stack) {
        computeDecorator.end();
        log2('Error parsing chapter list computer:', e, level: const LogLevel.error());
        log(stack, level: const LogLevel.debug());
        //if compute fails, we cancel the return
        return const Result.fail();
      }
    }

    try {
      return Result.pass(List<Chapter>.from(chapters.data!.map((value) {
        return Chapter.fromJson((value is! Map<String, dynamic>) ? Map<String, dynamic>.from(value) : value);
      })));
    } catch (e, stack) {
      log2('Error parsing chapter list:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }

  @override
  Future<Result<Post>> fetchPostUrl(String url) async {
    if (!supports(RequestType.postUrl)) {
      return super.fetchPostUrl(url);
    }

    final Result post = await scraper.makeRequest(RequestType.postUrl.string, [MapEntry('url', url)]);

    if (post.fail || post.data == null) {
      log('Fetch post url request failed', level: const LogLevel.warn());
      return const Result.fail();
    }

    try {
      final data = (post.data is! Map<String, dynamic>) ? Map<String, dynamic>.from(post.data) : post.data;

      return Result.pass(Post.fromJson(data));
    } catch (e, stack) {
      log2('Error parsing post data:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }

  @override
  Future<Result<Post>> fetchPost(ID id) async {
    if (!supports(RequestType.post)) {
      return super.fetchPost(id);
    }

    final Result post = await scraper.makeRequest(RequestType.post.string, [MapEntry('id', id.toJson())]);

    if (post.fail || post.data == null) {
      log('Fetch post request failed', level: const LogLevel.warn());
      return const Result.fail();
    }

    try {
      final data = (post.data is! Map<String, dynamic>) ? Map<String, dynamic>.from(post.data) : post.data;

      return Result.pass(Post.fromJson(data));
    } catch (e, stack) {
      log2('Error parsing post data:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }

  @override
  Future<Result<List<CatalogEntry>>> fetchCatalog({int page = 0, Map<String, dynamic> options = const {}}) async {
    late final RequestType requestType;

    //Always will try and use multicatalog first
    if (supports(RequestType.catalogMulti)) {
      requestType = RequestType.catalogMulti;
    } else if (supports(RequestType.catalog)) {
      requestType = RequestType.catalog;
    } else {
      return super.fetchCatalog();
    }

    final Result<List> entries =
        await scraper.makeRequest<List>(requestType.string, [MapEntry('page', page), MapEntry('options', options)]);

    if (entries.fail || entries.data == null) {
      log('Fetch catalog request failed', level: const LogLevel.warn());
      return const Result.fail();
    }

    try {
      return Result.pass(List<CatalogEntry>.from(entries.data!.map((entry) {
        return CatalogEntry.fromJson((entry is! Map<String, dynamic>) ? Map<String, dynamic>.from(entry) : entry);
      })));
    } catch (e, stack) {
      log2('Error fetching catalog:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }
}
