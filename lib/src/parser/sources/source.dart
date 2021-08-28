import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:io';

//source interfaces
import './parseSource.dart';
import './sourceTemplate.dart';
//models
import '../json/catalogEntry.dart';
import '../json/chapter.dart';
import '../json/id.dart';
import '../json/chapterID.dart';
import '../json/post.dart';
//utils
import '../../util/EmptyRequest.dart';
import '../../util/FetchReturn.dart';
import '../../util/ParseError.dart';
import '../../util/RequestType.dart';

///Returns only post data for the requested id
///
///This interfaces with all loaded sources and searchs for data return
Future<FetchReturn<Post>> fetchPost(ID id) async {
  if (sources.containsKey(id.source) && sources[id.source]!.supports(RequestType.post)) {
    try {
      Post post = await sources[id.source]!.fetchPost(id);
      return FetchReturn.pass(post);
    } on EmptyRequest {
      print('An empty request was made for post data');
    } on ParseError {
      //
    } catch (e, stack) {
      print('Error getting post data: $e');
      print(stack);
    }
  } else {
    print('Unable to find source ${id.source}');
  }
  return FetchReturn.fail();
}

///Returns post data if it can match the url
///
///[url] this is the url to search to determine the post being searched for
Future<FetchReturn<Post>> fetchPostUrl(String url) async {
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
        Post p = await s.fetchPostUrl(url);
        return FetchReturn.pass(p);
      } on StateError {
        print('No series match url: $url');
      } on EmptyRequest {
        print('An empty request was made for post data');
      } on ParseError {
        //
      } catch (e, stack) {
        print('Error getting post data by url: $e');
        print(stack);
      }
    } else {
      print('Found no allowed sources');
    }
  } catch (e, stack) {
    print('Error in getting post by url: $e');
    print(stack);
  }
  return FetchReturn.fail();
}

///Returns chapter list info for given id
///
///[id] unique id for source to get chapters from
Future<FetchReturn<List<Chapter>>> fetchChapters(ID id) async {
  if (sources.containsKey(id.source) && sources[id.source]!.supports(RequestType.chapters)) {
    try {
      List<Chapter> chapters = await sources[id.source]!.fetchChapters(id);
      //sort the list by chapterindex
      chapters.sort((a, b) => a.chapterID.index - b.chapterID.index);
      return FetchReturn.pass(chapters);
    } on EmptyRequest {
      print('An empty request was made for chapter list data');
    } on ParseError {
      //
    } catch (e, stack) {
      print('Error getting chapter list info: $e');
      print(stack);
    }
  } else {
    print('Unable to find source ${id.source}');
  }
  return FetchReturn.fail();
}

///Requests chapter images based only on url
///
///This looks for mapping the given host part of url to the source to be matched
///It is possible to encode custom urls that you can modify later
Future<FetchReturn<Map<int, String>>> fetchChapterImagesUrl(String url) async {
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
        print('Fetching chapter images');
        Map<int, String> images = await s.fetchChapterImagesUrl(url);
        return FetchReturn.pass(images);
      } on StateError {
        print('No sources match chapter image download');
      } on EmptyRequest {
        print('An empty request was made for fetch chapter images');
      } on ParseError {
        //
      }
    } else {
      print('Found no allowed sources');
    }
  } catch (e, stack) {
    print('Error in getting chapter images: $e');
    print(stack);
  }
  return FetchReturn.fail();
}

///Requests chapter images based on ChapterID
///
///Chapter id info should have already been defined by the source
Future<FetchReturn<Map<int, String>>> fetchChapterImages(ChapterID chapterID) async {
  try {
    if (sources.containsKey(chapterID.id.source) && sources[chapterID.id.source]!.supports(RequestType.images)) {
      try {
        SourceTemplate s = sources[chapterID.id.source]!;
        print('Fetching chapter images');
        Map<int, String> images = await s.fetchChapterImages(chapterID);
        return FetchReturn.pass(images);
      } on EmptyRequest {
        print('An empty request was made for fetch chapter images');
      } on ParseError {
        //
      }
    } else {
      print('Found no source for chapter images: ${chapterID.id.source}');
    }
  } catch (e, stack) {
    print('Error in getting chapter images: $e');
    print(stack);
  }
  return FetchReturn.fail();
}

///Request catalog for the source
///
///Sources suport a single call catalog or a multicatalog
///[page] starts at 0
///To determine if a source supports catalog call [sourceSupportsCatalog]
///To determine if a source supports multicatalog call [sourceSupportsMultiCatalog]
Future<FetchReturn<List<CatalogEntry>>> fetchCatalog(String source, {int page = 0}) async {
  if (sources.containsKey(source)) {
    SourceTemplate s = sources[source]!;
    if (s.supports(RequestType.catalog) || s.supports(RequestType.catalogMulti)) {
      try {
        List<CatalogEntry> entries = await sources[source]!.fetchCatalog(page: page);
        return FetchReturn.pass(entries);
      } on EmptyRequest {
        print('Empty request was made for getting catalog');
      } on ParseError {
        //
      } catch (e, stack) {
        print('Error in getting catalog: $e');
        print(stack);
      }
    } else {
      print('Does not support catalog: $source');
    }
  } else {
    print('Invalid source: $source');
  }

  return FetchReturn.fail();
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
  const supportedProgramTypes = ['hetu'];

  List<FileSystemEntity> files = dir.listSync(recursive: true).where((a) => p.extension(a.path) == '.json').toList();
  for (var file in files) {
    try {
      Map<String, dynamic> j = jsonDecode(File(file.path).readAsStringSync()) as Map<String, dynamic>;
      if (j.containsKey('programType') && supportedProgramTypes.contains(j['programType'])) {
        if (j.containsKey('source')) {
          if (j.containsKey('requests') && j['requests'].length != 0) {
            List<Request> requests = [];

            for (Map req in j['requests']) {
              if (req.containsKey('type') && req.containsKey('file') && requestMap.containsKey(req['type'])) {
                requests.add(Request(
                    type: requestMap[req['type']]!,
                    file: File(p.join(file.parent.path, req['file'])),
                    entry: req.containsKey('entry') ? req['entry'] : 'main'));
              } else {
                print('No valid type found');
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
            print('No requests found');
          }
        } else {
          //TODO: add exception
          print('Missing source declaration');
        }
      } else {
        //TODO: add exception
        print('Unsupported program');
      }
    } catch (e, stack) {
      print('Error loading in a json file: $e');
      print(stack);
    }
  }
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
        'request': source.requests,
        'subdomain': source.subdomain,
        'baseurl': source.baseurl,
        'programType': source.programType,
        'dir': source.dir,
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
