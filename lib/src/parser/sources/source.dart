import '../../util/ResultExtended.dart';
import '../../scraper/scraper.dart';
import '../../util/firstWhereResult.dart';
import '../../scraper/scraperSource.dart';
import '../../util/log.dart';
import '../../webContentParser.dart';
import 'dart:io';

//source interfaces
import 'parseSource.dart';
import 'sourceTemplate.dart';
//models
import '../json/catalogEntry.dart';
import '../json/chapter.dart';
import '../json/id.dart';
import '../json/chapterID.dart';
import '../json/post.dart';
//utils
import '../../util/Result.dart';
import '../../util/RequestType.dart';

///Returns only post data for the requested id
///
///This interfaces with all loaded sources and searchs for data return
Future<Result<Post>> fetchPost(ID id) async {
  final SourceTemplate? source = sources[id.source];
  if (source != null && source.supports(RequestType.post)) {
    //try catch since can't trust source methods
    try {
      return await source.fetchPost(id);
    } catch (e, stack) {
      log('High level error getting post data: $e');
      log(stack);
    }
  } else {
    log('Unable to find source ${id.source}');
  }
  return const Result.fail();
}

///Returns post data if it can match the url
///
///[url] this is the url to search to determine the post being searched for
Future<Result<Post>> fetchPostUrl(String url) async {
  final Uri? u = Uri.tryParse(url);

  if (u == null) {
    log('Error parsing url: $url');
    return const Result.fail();
  }

  //compile list of all allowed sources for chapter image downloading
  //TODO: could cache this until a new source is added
  final List<SourceTemplate> allowedPostByURL = [];
  for (SourceTemplate a in sources.values) {
    if (a.supports(RequestType.postUrl)) {
      allowedPostByURL.add(a);
    }
  }

  //find the source that support the url for the image downaloding
  if (allowedPostByURL.isNotEmpty) {
    final Result<SourceTemplate> s = allowedPostByURL.firstWhereResult((a) => u.host.contains(a.host));

    if (s.pass) {
      try {
        return await s.data!.fetchPostUrl(url);
      } catch (e, stack) {
        log('High level error fetching post url: $e');
        log(stack);
      }
    } else {
      log('No series match url: $url');
    }
  } else {
    log('Found no allowed sources');
  }

  return const Result.fail();
}

///Returns chapter list info for given id
///
///[id] unique id for source to get chapters from
Future<Result<List<Chapter>>> fetchChapters(ID id) async {
  final SourceTemplate? source = sources[id.source];
  if (source != null && source.supports(RequestType.chapters)) {
    try {
      final Result<List<Chapter>> result = await source.fetchChapters(id);

      if (result.fail) {
        log('Failed fetching chapters');
        return const Result.fail();
      }

      final List<Chapter> chapters = result.data!;

      //sort the list by chapterindex
      chapters.sort((a, b) => a.chapterID.index - b.chapterID.index);
      return Result.pass(chapters);
    } catch (e, stack) {
      log('Error getting chapter list info: $e');
      log(stack);
    }
  } else {
    log('Unable to find source ${id.source}');
  }
  return const Result.fail();
}

///Requests chapter images based only on url
///
///This looks for mapping the given host part of url to the source to be matched
///It is possible to encode custom urls that you can modify later
Future<Result<Map<int, String>>> fetchChapterImagesUrl(String url) async {
  final Uri? u = Uri.tryParse(url);

  if (u == null) {
    log('Error parsing url: $url');
    return const Result.fail();
  }

  //compile list of all allowed sources for chapter image downloading
  final List<SourceTemplate> allowedImageDownload = [];
  for (SourceTemplate a in sources.values) {
    if (a.supports(RequestType.imagesUrl)) {
      allowedImageDownload.add(a);
    }
  }

  if (allowedImageDownload.isEmpty) {
    log('Found no allowed sources');
    return const Result.fail();
  }

  //find the source that support the url for the image downaloding
  final Result<SourceTemplate> s = allowedImageDownload.firstWhereResult((a) => u.host.contains(a.host));

  if (s.fail) {
    log('No sources match chapter image download');
    return const Result.fail();
  }

  try {
    log('Fetching chapter images');
    return await s.data!.fetchChapterImagesUrl(url);
  } catch (e, stack) {
    log('Error in getting chapter images url: $e');
    log(stack);
  }
  return const Result.fail();
}

///Requests chapter images based on ChapterID
///
///Chapter id info should have already been defined by the source
Future<Result<Map<int, String>>> fetchChapterImages(ChapterID chapterID) async {
  try {
    final SourceTemplate? s = sources[chapterID.id.source];
    if (s != null && s.supports(RequestType.images)) {
      log('Fetching chapter images');
      return await s.fetchChapterImages(chapterID);
    } else {
      log('Found no source for chapter images: ${chapterID.id.source}');
    }
  } catch (e, stack) {
    log('Error in getting chapter images: $e');
    log(stack);
  }
  return const Result.fail();
}

///Request catalog for the source
///
///Sources suport a single call catalog or a multicatalog
///[page] starts at 0
///To determine if a source supports catalog call [sourceSupportsCatalog]
///To determine if a source supports multicatalog call [sourceSupportsMultiCatalog]
Future<Result<List<CatalogEntry>>> fetchCatalog(String source, {int page = 0}) async {
  final SourceTemplate? s = sources[source];
  if (s != null) {
    if (s.supports(RequestType.catalog) || s.supports(RequestType.catalogMulti)) {
      try {
        return await s.fetchCatalog(page: page);
      } catch (e, stack) {
        log('Error in getting catalog: $e');
        log(stack);
      }
    } else {
      log('Does not support catalog: $source');
    }
  } else {
    log('Invalid source: $source');
  }

  return const Result.fail();
}

///Determines if the source supports a specific type of request
///
///[source] The source to search and test for
///[type] The RequestType to test
bool sourceSupports(String source, RequestType type) {
  final SourceTemplate? template = sources[source];
  return template != null && template.supports(type);
}

///Load scraper sources from all yaml(.yaml or .yml) files in a directory.
///
///[dir] is directory to be searched recursively for yaml config files.
///
///Supports loading multiple sources at once inside a directory.
void loadExternalParseSources(Directory dir) {
  final List<ScraperSource> scrapers = loadExternalScarperSources(dir);
  for (final scraper in scrapers) {
    try {
      //pass scraper to the parse interface
      final ParseSource source = ParseSource(scraper);
      //add the new source
      addSource(source.source, source);
    } catch (e, stack) {
      log('Error loading external source: $e');
      log(stack);
    }
  }
}

///Adds a source object
///
///[name] unique name to identify the source
///[source] object built off of source template
///
///Source will only by overriden if version number is higher than the currently used source.
void addSource(String name, SourceTemplate source) {
  final SourceTemplate? currentSource = sources[name];
  if (currentSource != null) {
    //overwrite previous version only if added source is newer
    if (currentSource.version < source.version) {
      sources[name] = source;
    }
  } else {
    sources[name] = source;
  }
}

///Gets info for a source
///
///[name] unique name to identify the source.
///Includes {'parse': true/false} to let you know if this is a parsed source or not which has different information.
///Throws ['Unknown source'] if name does not exist.
Result<Map<String, dynamic>> getSourceInfo(String name) {
  final dynamic source = sources[name];
  if (source != null) {
    if (source is ParseSource) {
      return Result.pass({
        'parse': true,
        'source': source.source,
        'version': source.version,
        'request': source.scraper.requests,
        'subdomain': source.subdomain,
        'baseurl': source.baseurl,
        'programType': source.programType,
      });
    } else if (source is SourceTemplate) {
      return Result.pass({
        'parse': false,
        'source': source.source,
        'version': source.version,
        'baseurl': source.baseurl,
        'subdomain': source.subdomain,
      });
    }
  }

  return const Result.fail();
}

///Stores all source object
Map<String, SourceTemplate> sources = {};
