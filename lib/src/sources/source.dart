import 'dart:convert';
import 'dart:io';

import 'package:web_content_parser/web_content_parser.dart';
import 'package:web_content_parser/src/json/catalogEntry.dart';
import 'package:web_content_parser/src/json/chapter.dart';
import 'package:web_content_parser/src/json/id.dart';
import 'package:web_content_parser/src/json/post.dart';
import 'package:web_content_parser/src/sources/parseSource.dart';
import 'package:web_content_parser/src/util/EmptyRequest.dart';
import 'package:web_content_parser/src/util/FetchReturn.dart';
import 'package:web_content_parser/src/util/FetchStatus.dart';
import 'package:web_content_parser/src/util/ParseError.dart';
import 'package:web_content_parser/src/util/RequestType.dart';
import 'package:path/path.dart' as p;

///Returns only post data for the requested id
///
///This interfaces with all loaded sources and searchs for data return
Future<FetchReturn<Post>> getPostData(ID id) async {
  if (sources.containsKey(id.source) && sources[id.source]!.supports(RequestType.POST)) {
    try {
      Post post = await sources[id.source]!.fetchPostData(id);
      return FetchReturn(
        status: FetchStatus.PASS,
        data: post,
      );
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
  return FetchReturn(status: FetchStatus.ERROR);
}

///Returns post data if it can match the url
///
///[url] this is the url to search to determine the post being searched for
Future<FetchReturn<Post>> getPostDataURL(String url) async {
  try {
    final Uri u = Uri.parse(url);

    //compile list of all allowed sources for chapter image downloading
    List<SourceTemplate> allowedPostByURL = [];
    for (SourceTemplate a in sources.values) {
      if (a.supports(RequestType.POSTURL)) {
        allowedPostByURL.add(a);
      }
    }

    //find the source that support the url for the image downaloding
    if (allowedPostByURL.isNotEmpty) {
      try {
        SourceTemplate s = allowedPostByURL.firstWhere((a) => u.host.contains(a.host()));
        Post p = await s.fetchPostDataURL(url);
        return FetchReturn(
          status: FetchStatus.PASS,
          data: p,
        );
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
  return FetchReturn(status: FetchStatus.ERROR);
}

///Returns chapter list info for given id
///
///[id] unique id for source to get chapters from
Future<FetchReturn<List<Chapter>>> getChapterListData(ID id) async {
  if (sources.containsKey(id.source) && sources[id.source]!.supports(RequestType.CHAPTERS)) {
    try {
      List<Chapter> chapters = await sources[id.source]!.fetchChapterList(id);
      //sort the list by chapterindex
      chapters.sort((a, b) => a.chapterID.index - b.chapterID.index);
      return FetchReturn(
        status: FetchStatus.PASS,
        data: chapters,
      );
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
  return FetchReturn(status: FetchStatus.ERROR);
}

///Requests chapter images based only on url
///
///This looks for mapping the given host part of url to the source to be matched
///It is possible to encode custom urls that you can modify later
Future<FetchReturn<Map<int, String>>> getChapterImagesURL(String url) async {
  try {
    final Uri u = Uri.parse(url);

    //compile list of all allowed sources for chapter image downloading
    List<SourceTemplate> allowedImageDownload = [];
    for (SourceTemplate a in sources.values) {
      if (a.supports(RequestType.IMAGESURL)) {
        allowedImageDownload.add(a);
      }
    }

    //find the source that support the url for the image downaloding
    if (allowedImageDownload.isNotEmpty) {
      try {
        SourceTemplate s = allowedImageDownload.firstWhere((a) => u.host.contains(a.host()));
        print('Fetching chapter images');
        Map<int, String> images = await s.fetchChapterImagesURL(url);
        return FetchReturn(
          status: FetchStatus.PASS,
          data: images,
        );
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
  return FetchReturn(status: FetchStatus.ERROR);
}

///Requests chapter images based on ChapterID
///
///Chapter id info should have already been defined by the source
Future<FetchReturn<Map<int, String>>> getChapterImages(ChapterID chapterID) async {
  try {
    if (sources.containsKey(chapterID.id.source) && sources[chapterID.id.source]!.supports(RequestType.IMAGES)) {
      try {
        SourceTemplate s = sources[chapterID.id.source]!;
        print('Fetching chapter images');
        Map<int, String> images = await s.fetchChapterImages(chapterID);
        return FetchReturn(
          status: FetchStatus.PASS,
          data: images,
        );
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
  return FetchReturn(status: FetchStatus.ERROR);
}

///Request catalog for the source
///
///Sources suport a single call catalog or a multicatalog
///[page] starts at 0
///To determine if a source supports catalog call [sourceSupportsCatalog]
///To determine if a source supports multicatalog call [sourceSupportsMultiCatalog]
Future<FetchReturn<List<CatalogEntry>>> getCatalog(String source, {int page = 0}) async {
  if (sources.containsKey(source)) {
    SourceTemplate s = sources[source]!;
    if (s.supports(RequestType.CATALOG) || s.supports(RequestType.CATALOGMULTI)) {
      try {
        List<CatalogEntry> entries = await sources[source]!.fetchCatalog(page: page);
        return FetchReturn(
          status: FetchStatus.PASS,
          data: entries,
        );
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

  return FetchReturn(status: FetchStatus.ERROR);
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
