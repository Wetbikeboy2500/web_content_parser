import 'dart:io';

import '../util/Result.dart';

import '../util/log.dart';

import './eval.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import '../util/RequestType.dart';

class ScraperSource {
  static final Map<String, ScraperSource> _globalSources = {};

  final Map<String, Request> requests = {};

  late final Map<String, dynamic> info;

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
  factory ScraperSource.global(String input, Directory directory) {
    ScraperSource source = ScraperSource(input, directory);

    //add to global scraper source by name
    _globalSources[source.info['source']] = source;

    return source;
  }

  ///Creates a scrapper
  ScraperSource(String input, Directory directory) {
    try {
      //decode yaml
      Map<String, dynamic> yaml = Map<String, dynamic>.from(loadYaml(input));
      log(yaml);
      //make sure it meets requirements (source, baseurl, subdomain, version, programTarget, functions)
      const requiredAttributes = ['source', 'baseUrl', 'subdomain', 'version', 'programType', 'requests'];
      if (!requiredAttributes.every((element) => yaml.containsKey(element))) {
        log('Missing fields');
        throw FormatException('Missing fields');
      }

      //save all yaml into info
      info = yaml;

      //get all allowed functions
      final List requests = yaml['requests'] as List;
      requests.removeWhere((value) {
        value as Map;
        return !value.containsKey('type') || !value.containsKey('file') || !value.containsKey('entry');
      });
      //add functions (type, file, entry)
      for (final request in requests) {
        this.requests[request['type']] = Request(
            type: requestMap(request['type']),
            file: File(p.join(directory.path, request['file'])),
            entry: request['entry']);
      }
    } catch (e, stack) {
      log('Parsing error for global source $e');
      log(stack);
      throw FormatException('Failed to parse source');
    }
  }

  Future<Result<T>> makeRequest<T>(String name, List arguments) async {
    if (requests.containsKey(name)) {
      final Request r = requests[name]!;
      try {
        return Result<T>.pass(await eval(
          r.file,
          functionName: r.entry,
          args: arguments,
          workingDirectory: r.file.parent.path,
        ));
      } catch (e, stack) {
        log('Error running eval: $e');
        log(stack);
      }
    }

    return Result<T>.fail();
  }

  //TODO: have a cache system for loaded hetu files
}

class Request {
  final RequestType type;
  final File file;
  final String entry;
  const Request({required this.type, required this.file, required this.entry});
}
