import 'dart:io';

import '../util/ResultExtended.dart';

import '../util/Result.dart';

import '../util/log.dart';

import 'eval.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import '../util/RequestType.dart';

class ScraperSource {
  ///Stores references to the global sources by name
  static final Map<String, ScraperSource> _globalSources = {};

  ///Supported programs that can be run
  static final Set<String> supportedProgramTypes = {'hetu0.3'};

  ///Scraping requests that this object can run
  final Map<String, Request> requests = {};

  ///Yaml file info convert and stored
  late final Map<String, dynamic> info;

  ///Main directory this extension is stored in
  final Directory directory;

  ///Returns a global scrapper by name
  ///
  ///Returns null if [name] doesn't exist for a global scrapper
  static ScraperSource? scrapper(String name) => _globalSources[name];

  ///Creates a scrapper that is added to global and can be referenced without having the object
  ///
  ///This is good for defining your scripts on start-up to later be used
  factory ScraperSource.global(String input, Directory directory) {
    final ScraperSource source = ScraperSource(input, directory);

    //add to global scraper source by name
    _globalSources[source.info['source']] = source;

    return source;
  }

  ///Creates a scrapper
  ScraperSource(String input, this.directory) {
    try {
      //decode yaml
      var yaml = loadYaml(input);
      if (yaml is YamlMap) {
        yaml = Map.fromEntries(yaml.entries.map((e) {
          if (e.value is YamlList) {
            return MapEntry(e.key, e.value.map((e) => e is YamlMap ? Map.fromEntries(e.entries) : e).toList());
          }

          return e;
        }));
      }

      //make sure it meets requirements (source, baseurl, subdomain, version, programTarget, functions)
      const requiredAttributes = ['source', 'baseUrl', 'subdomain', 'version', 'programType', 'requests'];
      if (!requiredAttributes.every((element) => yaml.containsKey(element))) {
        log('Missing fields');
        throw const FormatException('Missing fields');
      }

      if (!supportedProgramTypes.contains(yaml['programType'])) {
        throw const FormatException('Unknown global program type');
      }

      final String globalProgramType = yaml['programType'] as String;

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
        String? localProgramType = request['programType'] as String?;

        if (localProgramType != null && !supportedProgramTypes.contains(localProgramType)) {
          throw const FormatException('Unknown local program type');
        }

        this.requests[request['type']] = Request(
          type: requestMap(request['type']),
          file: File(p.join(directory.path, request['file'])),
          entry: request['entry'],
          compiled: request['compiled'] ?? false,
          programType: localProgramType ?? globalProgramType,
        );
      }
    } catch (e, stack) {
      log2('Parsing error for global source', e);
      log(stack);
      throw const FormatException('Failed to parse source');
    }
  }

  Future<Result<T>> makeRequest<T>(String name, List arguments) async {
    log2('Make request: ', name);
    final Request? r = requests[name];
    if (r != null) {
      return await ResultExtended.unsafeAsync<T>(
        () async => await eval(
          r.file,
          functionName: r.entry,
          args: arguments,
          workingDirectory: r.file.parent.path,
          compiled: r.compiled,
        ),
        errorMessage: 'Error running eval',
      );
    }

    return const Result.fail();
  }

  //TODO: have a cache system for loaded hetu files (remove readsync which occurs in the eval)
}

class Request {
  final RequestType type;
  final File file;
  final String entry;
  final bool compiled;
  final String programType;
  const Request({required this.type, required this.file, required this.entry, required this.programType, this.compiled = false});
}
