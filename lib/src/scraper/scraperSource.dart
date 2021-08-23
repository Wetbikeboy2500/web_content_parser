import 'dart:io';

import 'package:yaml/yaml.dart';

import '../util/RequestType.dart';

class ScraperSource {
  static Map<String, ScraperSource> _globalSources = {};

  ///Returns a global scrapper by name
  ///
  ///Throws an [Exception] if [name] doesn't for a global scrapper
  static ScraperSource scrapper(String name) {
    if (_globalSources.containsKey(name)) {
      return _globalSources[name]!;
    }

    throw Exception('Scapper source does not exist');
  }

  ///Creates a scrapper that is added to global and can be referenced without having the object
  ///
  ///This is good for defining your scripts on start-up to later be used
  ScraperSource.global(String input, Directory directory, {required FileType fileType}) {
    //decode yaml
    Map yaml = loadYaml(input) as Map;
    print(yaml);
    //make sure it meets requirements (source, baseurl, subdomain, version, programTarget, functions)
    //add functions (type, file, entry)
    //add to global scraper source by name
    //create references for files based on directory
    return;
  }

  ///Creates a scrapper
  ScraperSource(String input, Directory directory, {required FileType fileType}) {
    //decode yaml
    //add functions
    return;
  }

  //TODO: have a cache system for loaded hetu files
}

enum FileType { json, yaml }

class Request {
  final RequestType type;
  final File file;
  final String entry;
  Request({required this.type, required this.file, required this.entry});
}
