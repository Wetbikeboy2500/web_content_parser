import 'dart:io';

//utils
import 'package:web_query_framework_util/util.dart';

import '../../scraper/scraper.dart';
import '../../scraper/scraperSource.dart';
import '../../util/RequestType.dart';
import '../../util/log.dart';
import '../../util/parseUriResult.dart';
//models
import '../json/catalogEntry.dart';
import '../json/chapter.dart';
import '../json/chapterID.dart';
import '../json/id.dart';
import '../json/post.dart';
//source interfaces
import 'parseSource.dart';
import 'sourceTemplate.dart';

///Returns only post data for the requested id
///
///This interfaces with all loaded sources and searches for data return
Future<Result<Post>> fetchPost(ID id) async {
  final SourceTemplate? source = sources[id.source];
  if (source != null && source.supports(RequestType.post)) {
    //try catch since can't trust source methods
    try {
      return await source.fetchPost(id);
    } catch (e, stack) {
      log2('High level error getting post data:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
    }
  } else {
    log2('Unable to find source', id.source, level: const LogLevel.warn());
  }
  return const Fail();
}

///Returns post data if it can match the url
///
///[url] this is the url to search to determine the post being searched for
Future<Result<Post>> fetchPostUrl(String url) async {
  final u = UriResult.parse(url);

  if (u is! Pass<Uri>) {
    log2('Error parsing url:', url, level: const LogLevel.warn());
    return const Fail();
  }

  SourceTemplate? source;
  //this is for logging
  bool allowedSourcesFound = false;

  //tries to find a matching and supported source
  for (SourceTemplate a in sources.values) {
    if (a.supports(RequestType.postUrl)) {
      allowedSourcesFound = true;
      if (u.data.host.contains(a.host)) {
        source = a;
        break;
      }
    }
  }

  if (!allowedSourcesFound) {
    log('Found no allowed sources', level: const LogLevel.warn());
    return const Fail();
  }

  //find the source that support the url for the images
  if (source == null) {
    log2('No series match url:', url, level: const LogLevel.warn());
    return const Fail();
  }

  try {
    return await source.fetchPostUrl(url);
  } catch (e, stack) {
    log2('High level error fetching post url', e, level: const LogLevel.error());
    log(stack, level: const LogLevel.debug());
  }
  return const Fail();
}

///Returns chapter list info for given id
///
///[id] unique id for source to get chapters from
Future<Result<List<Chapter>>> fetchChapters(ID id) async {
  final SourceTemplate? source = sources[id.source];
  if (source != null && source.supports(RequestType.chapters)) {
    try {
      final Result<List<Chapter>> result = await source.fetchChapters(id);

      if (result is! Pass<List<Chapter>>) {
        log('Failed fetching chapters', level: const LogLevel.warn());
        return const Fail();
      }

      final List<Chapter> chapters = result.data;

      //sort the list by chapter index
      chapters.sort((a, b) => a.chapterID.index - b.chapterID.index);
      return Pass(chapters);
    } catch (e, stack) {
      log2('Error getting chapter list info:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
    }
  } else {
    log2('Unable to find source', id.source, level: const LogLevel.warn());
  }
  return const Fail();
}

///Requests chapter images based only on url
///
///This looks for mapping the given host part of url to the source to be matched
///It is possible to encode custom urls that you can modify later
Future<Result<Map<int, String>>> fetchChapterImagesUrl(String url) async {
  final Uri? u = Uri.tryParse(url);

  if (u == null) {
    log2('Error parsing url:', url, level: const LogLevel.warn());
    return const Fail();
  }

  //compile list of all allowed sources for chapter images
  SourceTemplate? source;
  bool allowedSourcesFound = false;
  for (SourceTemplate a in sources.values) {
    if (a.supports(RequestType.imagesUrl)) {
      allowedSourcesFound = true;
      if (u.host.contains(a.host)) {
        source = a;
        break;
      }
    }
  }

  if (!allowedSourcesFound) {
    log('Found no allowed sources', level: const LogLevel.warn());
    return const Fail();
  }

  if (source == null) {
    log2('No sources match chapter image url', url, level: const LogLevel.warn());
    return const Fail();
  }

  try {
    log('Fetching chapter images', level: const LogLevel.info());
    return await source.fetchChapterImagesUrl(url);
  } catch (e, stack) {
    log2('Error in getting chapter images url:', e, level: const LogLevel.error());
    log(stack, level: const LogLevel.debug());
  }
  return const Fail();
}

///Requests chapter images based on ChapterID
///
///Chapter id info should have already been defined by the source
Future<Result<Map<int, String>>> fetchChapterImages(ChapterID chapterID) async {
  try {
    final SourceTemplate? s = sources[chapterID.id.source];
    if (s != null && s.supports(RequestType.images)) {
      log('Fetching chapter images', level: const LogLevel.info());
      return await s.fetchChapterImages(chapterID);
    } else {
      log2('Found no source for chapter images:', chapterID.id.source, level: const LogLevel.warn());
    }
  } catch (e, stack) {
    log2('Error in getting chapter images:', e, level: const LogLevel.error());
    log(stack, level: const LogLevel.debug());
  }
  return const Fail();
}

///Request catalog for the source
///
///Sources support a single call catalog or a multicatalog
///[page] starts at 0
///[options] catalog options which should be defined source-by-source with variable implementations
///To determine if a source supports catalog call [sourceSupportsCatalog]
///To determine if a source supports multicatalog call [sourceSupportsMultiCatalog]
Future<Result<List<CatalogEntry>>> fetchCatalog(String source,
    {int page = 0, Map<String, dynamic> options = const {}}) async {
  final SourceTemplate? s = sources[source];
  if (s != null) {
    if (s.supports(RequestType.catalog) || s.supports(RequestType.catalogMulti)) {
      try {
        return await s.fetchCatalog(page: page, options: options);
      } catch (e, stack) {
        log2('Error in getting catalog:', e, level: const LogLevel.error());
        log(stack, level: const LogLevel.debug());
      }
    } else {
      log2('Does not support catalog:', source, level: const LogLevel.warn());
    }
  } else {
    log2('Invalid source: ', source, level: const LogLevel.warn());
  }

  return const Fail();
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
Future<void> loadExternalParseSources(Directory dir) async {
  final List<ScraperSource> scrapers = await loadExternalScarperSources(dir);
  for (final scraper in scrapers) {
    try {
      //pass scraper to the parse interface
      final ParseSource source = ParseSource(scraper);
      //add the new source
      addSource(source.source, source);
    } catch (e, stack) {
      log2('Error loading external source:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
    }
  }
}

///Adds a source object
///
///[name] unique name to identify the source
///[source] object built off of source template
///
///Source will only by overridden if version number is higher than the currently used source.
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
      return Pass({
        'parse': true,
        'source': source.source,
        'version': source.version,
        'request': source.scraper.requests,
        'subdomain': source.subdomain,
        'baseurl': source.baseurl,
        'programType': source.programType,
      });
    } else if (source is SourceTemplate) {
      return Pass({
        'parse': false,
        'source': source.source,
        'version': source.version,
        'baseurl': source.baseurl,
        'subdomain': source.subdomain,
      });
    }
  }

  return const Fail();
}

///Stores all source object
Map<String, SourceTemplate> sources = {};
