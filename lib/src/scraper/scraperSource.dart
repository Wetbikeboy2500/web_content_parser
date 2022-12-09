import 'dart:io';

import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/util/parseYaml.dart';
import 'package:web_content_parser/src/wql/wql.dart';

import '../util/ResultExtended.dart';

import '../util/Result.dart';

import '../util/log.dart';

import 'package:path/path.dart' as p;

import '../util/RequestType.dart';

class ScraperSource {
  ///Stores references to the global sources by name
  static final Map<String, ScraperSource> _globalSources = {};

  ///Supported programs that can be run
  static final Set<String> supportedProgramTypes = {'wql'};

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
  //TODO: make the logic cleaner and more modular
  ScraperSource(String input, this.directory) {
    try {
      final Map<String, dynamic> yaml = parseYaml(input);

      if (!yaml.containsKey('source')) {
        throw Exception('Source is not defined');
      }

      if (!yaml.containsKey('requests')) {
        throw Exception('Requests are not defined');
      }

      if (!yaml.containsKey('version')) {
        throw Exception('Version is not defined');
      }

      if (!yaml.containsKey('programType')) {
        throw Exception('ProgramType is not defined');
      }

      if (!supportedProgramTypes.contains(yaml['programType'])) {
        throw const FormatException('Unknown global program type');
      }

      final String globalProgramType = yaml['programType'] as String;

      //save all yaml into info
      info = yaml;

      //add functions (type, file, entry)
      for (final request in yaml['requests']) {
        if (!request.containsKey('type')) {
          log2('No type included', request, level: const LogLevel.warn());
          continue;
        }

        if (!request.containsKey('file')) {
          log2('No file included', request, level: const LogLevel.warn());
          continue;
        }

        final String? localProgramType = request['programType'] as String?;

        if (localProgramType != null && !supportedProgramTypes.contains(localProgramType)) {
          throw const FormatException('Unknown local program type');
        }

        requests[request['type']] = Request(
          type: requestMap(request['type']),
          file: File(p.join(directory.path, request['file'])),
          entry: request['entry'] ?? '',
          compiled: request['compiled'] ?? false,
          programType: localProgramType ?? globalProgramType,
        );
      }
    } catch (e, stack) {
      log2('Parsing error for global source', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      throw const FormatException('Failed to parse source');
    }
  }

  static bool _loadedWQLFunctions = false;

  Future<Result<T>> makeRequest<T>(String name, List<MapEntry<String, dynamic>> arguments) async {
    log2('Make request: ', name, level: const LogLevel.info());
    final Request? r = requests[name];

    if (r != null) {
      //ensure that the request file exists
      if (!(await r.file.exists())) {
        log2('Request file does not exist', r.file.path, level: const LogLevel.warn());
        return const Result.fail();
      }

      if (r.programType == 'wql') {
        if (!_loadedWQLFunctions) {
          loadWQLFunctions();
          _loadedWQLFunctions = true;
        }

        return await ResultExtended.unsafeAsync<T>(
          () async {
            final String code = await r.file.readAsString();
            final parameters = Map.fromEntries(arguments);
            final result = await runWQL(code, parameters: parameters, throwErrors: true);
            if (result.pass) {
              return result.data!['return'];
            }

            throw Exception('Fail state was no re-thrown');
          },
          errorMessage: 'Error running WQL',
        );
      }
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
  const Request(
      {required this.type, required this.file, required this.entry, required this.programType, this.compiled = false});
}
