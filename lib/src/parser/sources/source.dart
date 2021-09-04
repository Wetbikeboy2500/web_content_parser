import 'package:path/path.dart' as p;
import '../../util/log.dart';
import '../../webContentParser.dart';
import 'dart:convert';
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
  if (sources.containsKey(id.source) && sources[id.source]!.supports(RequestType.post)) {
    try {
      return await sources[id.source]!.fetchPost(id);
    } catch (e, stack) {
      log('Error getting post data: $e');
      log(stack);
    }
  } else if (WebContentParser.verbose) {
    log('Unable to find source ${id.source}');
  }
  return Result.fail();
}

///Returns post data if it can match the url
///
///[url] this is the url to search to determine the post being searched for
Future<Result<Post>> fetchPostUrl(String url) async {
  try {
    final Uri u = Uri.parse(url);

    //compile list of all allowed sources for chapter image downloading
    List<SourceTemplate> allowedPostByURL = [];
    for (SourceTemplate a in sources.values) {
      if (a.supports(RequestType.postUrl)) {
        allowedPostByURL.add(a);
      }
    }

    //find the source that support the url for the image downaloding
    if (allowedPostByURL.isNotEmpty) {
      try {
        SourceTemplate s = allowedPostByURL.firstWhere((a) => u.host.contains(a.host()));
        return await s.fetchPostUrl(url);
      } on StateError {
        log('No series match url: $url');
      } catch (e, stack) {
        log('Error getting post data by url: $e');
        log(stack);
      }
    } else {
      log('Found no allowed sources');
    }
  } catch (e, stack) {
    log('Error in getting post by url: $e');
    log(stack);
  }
  return Result.fail();
}

///Returns chapter list info for given id
///
///[id] unique id for source to get chapters from
Future<Result<List<Chapter>>> fetchChapters(ID id) async {
  if (sources.containsKey(id.source) && sources[id.source]!.supports(RequestType.chapters)) {
    try {
      Result<List<Chapter>> result = await sources[id.source]!.fetchChapters(id);

      if (result.fail) {
        return Result.fail();
      }

      List<Chapter> chapters = result.data!;

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
  return Result.fail();
}

///Requests chapter images based only on url
///
///This looks for mapping the given host part of url to the source to be matched
///It is possible to encode custom urls that you can modify later
Future<Result<Map<int, String>>> fetchChapterImagesUrl(String url) async {
  try {
    final Uri u = Uri.parse(url);

    //compile list of all allowed sources for chapter image downloading
    List<SourceTemplate> allowedImageDownload = [];
    for (SourceTemplate a in sources.values) {
      if (a.supports(RequestType.imagesUrl)) {
        allowedImageDownload.add(a);
      }
    }

    //find the source that support the url for the image downaloding
    if (allowedImageDownload.isNotEmpty) {
      try {
        SourceTemplate s = allowedImageDownload.firstWhere((a) => u.host.contains(a.host()));
        log('Fetching chapter images');
        return await s.fetchChapterImagesUrl(url);
      } on StateError {
        log('No sources match chapter image download');
      }
    } else {
      log('Found no allowed sources');
    }
  } catch (e, stack) {
    log('Error in getting chapter images url: $e');
    log(stack);
  }
  return Result.fail();
}

///Requests chapter images based on ChapterID
///
///Chapter id info should have already been defined by the source
Future<Result<Map<int, String>>> fetchChapterImages(ChapterID chapterID) async {
  try {
    if (sources.containsKey(chapterID.id.source) && sources[chapterID.id.source]!.supports(RequestType.images)) {
      SourceTemplate s = sources[chapterID.id.source]!;
      log('Fetching chapter images');
      return await s.fetchChapterImages(chapterID);
    } else {
      log('Found no source for chapter images: ${chapterID.id.source}');
    }
  } catch (e, stack) {
    log('Error in getting chapter images: $e');
    log(stack);
  }
  return Result.fail();
}

///Request catalog for the source
///
///Sources suport a single call catalog or a multicatalog
///[page] starts at 0
///To determine if a source supports catalog call [sourceSupportsCatalog]
///To determine if a source supports multicatalog call [sourceSupportsMultiCatalog]
Future<Result<List<CatalogEntry>>> fetchCatalog(String source, {int page = 0}) async {
  if (sources.containsKey(source)) {
    SourceTemplate s = sources[source]!;
    if (s.supports(RequestType.catalog) || s.supports(RequestType.catalogMulti)) {
      try {
        return await sources[source]!.fetchCatalog(page: page);
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

  return Result.fail();
}

///Determines if the source supports a specific type of request
///
///[source] The source to search and test for
///[type] The RequestType to test
bool sourceSupports(String source, RequestType type) {
  return sources.containsKey(source) && sources[source]!.supports(type);
}

///Load parsed extensions for all json files within a directory
///
///[dir] is directory to be searched recursively for json files
///Supports loading multiple json sources at once
void loadExternalSource(Directory dir) {
  //We can use this to expand supported versions/iterations and prevent running none-backwards compatible code
  /*const supportedProgramTypes = ['hetu'];

  List<FileSystemEntity> files = dir.listSync(recursive: true).where((a) => p.extension(a.path) == '.json').toList();
  for (var file in files) {
    try {
      Map<String, dynamic> j = jsonDecode(File(file.path).readAsStringSync()) as Map<String, dynamic>;
      if (j.containsKey('programType') && supportedProgramTypes.contains(j['programType'])) {
        if (j.containsKey('source')) {
          if (j.containsKey('requests') && j['requests'].length != 0) {
            List<Request> requests = [];

            for (Map req in j['requests']) {
              if (req.containsKey('type') && req.containsKey('file')) {
                requests.add(Request(
                    type: requestMap(req['type']),
                    file: File(p.join(file.parent.path, req['file'])),
                    entry: req.containsKey('entry') ? req['entry'] : 'main'));
              } else {
                log('No valid type found');
              }
            }

            addSource(
              j['source'],
              ParseSource(
                source: j['source'],
                requests: requests,
                version: j['version'],
                baseurl: j['baseurl'],
                subdomain: j['subdomain'],
                programType: j['programType'],
                dir: file.parent.path,
              ),
            );
          } else {
            log('No requests found');
          }
        } else {
          log('Missing source declaration');
        }
      } else {
        log('Unsupported program');
      }
    } catch (e, stack) {
      log('Error loading in a json file: $e');
      log(stack);
    }
  }*/
}

///Adds a source object
///
///[name] unique name to identify the source
///[source] object built off of source template
///Source will only by overriden if version number is higher than the currently used source
void addSource(String name, SourceTemplate source) {
  if (sources.containsKey(name)) {
    //overwrite previous version only if added source is newer
    if (sources[name]!.version < source.version) {
      sources[name] = source;
    }
  } else {
    sources[name] = source;
  }
}

///Gets info for a source
///
///[name] unique name to identify the source
///Includes {'parse': true/false} to let you know if this is a parsed source or not which has different information
///Throws ['Unknown source'] if name does not exist
Map<String, dynamic> getSourceInfo(String name) {
  if (sources.containsKey(name)) {
    dynamic source = sources[name];
    if (source is ParseSource) {
      return {
        'parse': true,
        'source': source.source,
        'version': source.version,
        'request': source.scraper.requests,
        'subdomain': source.subdomain,
        'baseurl': source.baseurl,
        'programType': source.programType,
      };
    } else if (source is SourceTemplate) {
      return {
        'parse': false,
        'source': source.source,
        'version': source.version,
        'baseurl': source.baseurl,
        'subdomain': source.subdomain,
      };
    }
  }

  throw Exception('Unknown source');
}

///Stores all source object
Map<String, SourceTemplate> sources = {};
