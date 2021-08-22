import 'dart:io';

class ScraperSource {
  static Map<String, ScraperSource> _globalSources = {};

  static ScraperSource scrapper(String name) {
    if (_globalSources.containsKey(name)) {
      return _globalSources[name]!;
    }

    throw Exception('Scapper source does not exist');
  }

  ///Creates a scrapper that is added to global and can be referenced without having the object
  ///
  ///This is good for defining your scripts on start-up to later be used
  ScraperSource.global(String yaml, Directory directory) {
    //decode yaml
    //make sure it meets requirements (source, baseurl, subdomain, version, programTarget, functions)
    //add functions (type, file, entry)
    //add to global scraper source by name
    //create references for files based on directory
    return;
  }

  ///Creates a scrapper
  ScraperSource(String yaml, Directory directory) {
    //decode yaml
    //add functions
    return;
  }

  //TODO: have a cache system for loaded hetu files
}