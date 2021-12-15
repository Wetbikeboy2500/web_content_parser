import 'dart:async';

//source
import 'package:computer/computer.dart';
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
          baseurl: scraper.info['baseUrl'],
          subdomain: scraper.info['subdomain'],
        ) {
    if (strict && !['seriesImage'].contains(scraper.info['contentType'])) {
      throw const FormatException('Doesn\'t have valid contentType');
    }
  }

  @override
  Future<Result<Map<int, String>>> fetchChapterImages(ChapterID chapterId) async {
    if (!supports(RequestType.images)) {
      return super.fetchChapterImages(chapterId);
    }

    return await scraper.makeRequest<Map<int, String>>(RequestType.images.string, [chapterId.toJson()]);
  }

  @override
  Future<Result<Map<int, String>>> fetchChapterImagesUrl(String url) async {
    if (!supports(RequestType.imagesUrl)) {
      return super.fetchChapterImagesUrl(url);
    }

    return await scraper.makeRequest<Map<int, String>>(RequestType.imagesUrl.string, [url]);
  }

  @override
  Future<Result<List<Chapter>>> fetchChapters(ID id) async {
    if (!supports(RequestType.chapters)) {
      return super.fetchChapters(id);
    }

    final Result<List> chapters = await scraper.makeRequest<List>(RequestType.chapters.string, [id.toJson()]);

    if (chapters.fail) {
      return const Result.fail();
    }

    if (computeEnabled) {
      computeDecorator.start();

      try {
        //I currently am only using computer here since lists of chapters can have a lot of data to be processed
        final List<Chapter> response = await computeDecorator.compute<List<Chapter>, List<Map<String, dynamic>>>(
            Chapter.chaptersFromJson, chapters.data!.cast<Map<String, dynamic>>());
        computeDecorator.end();
        return Result.pass(response);
      } catch (e, stack) {
        computeDecorator.end();
        log2('Error parsing chapter list computer:', e);
        log(stack);
        //if compute fails, we cancel the return
        return const Result.fail();
      }
    }

    try {
      return Result.pass(List<Chapter>.from(chapters.data!.map((value) => Chapter.fromJson(value))));
    } catch (e, stack) {
      log2('Error parsing chapter list:', e);
      log(stack);
      return const Result.fail();
    }
  }

  @override
  Future<Result<Post>> fetchPostUrl(String url) async {
    if (!supports(RequestType.postUrl)) {
      return super.fetchPostUrl(url);
    }

    final Result post = await scraper.makeRequest(RequestType.postUrl.string, [url]);

    if (post.fail) {
      return const Result.fail();
    }

    try {
      return Result.pass(Post.fromJson(Map<String, dynamic>.from(post.data)));
    } catch (e, stack) {
      log2('Error parsing post data:', e);
      log(stack);
      return const Result.fail();
    }
  }

  @override
  Future<Result<Post>> fetchPost(ID id) async {
    if (!supports(RequestType.post)) {
      return super.fetchPost(id);
    }

    final Result post = await scraper.makeRequest(RequestType.post.string, [id.toJson()]);

    if (post.fail && post.data == null) {
      return const Result.fail();
    }

    try {
      return Result.pass(Post.fromJson(Map<String, dynamic>.from(post.data)));
    } catch (e, stack) {
      log2('Error parsing post data:', e);
      log(stack);
      return const Result.fail();
    }
  }

  @override
  Future<Result<List<CatalogEntry>>> fetchCatalog({int page = 0}) async {
    late final RequestType requestType;

    //Always will try and use multicatalog first
    if (supports(RequestType.catalogMulti)) {
      requestType = RequestType.catalogMulti;
    } else if (supports(RequestType.catalog)) {
      requestType = RequestType.catalog;
    } else {
      return super.fetchCatalog();
    }

    final Result<List> entries = await scraper.makeRequest<List>(requestType.string, [page]);

    if (entries.fail) {
      return const Result.fail();
    }

    try {
      return Result.pass(List<CatalogEntry>.from(entries.data!.map((entry) => CatalogEntry.fromJson(entry))));
    } catch (e, stack) {
      log2('Error fetching catalog:', e);
      log(stack);
      return const Result.fail();
    }
  }
}
