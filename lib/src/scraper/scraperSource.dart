import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/util/parseYaml.dart';
import 'package:web_content_parser/src/wql2/wql2.dart';
import 'package:web_query_framework_util/util.dart';

import '../util/RequestType.dart';
import '../util/ResultExtended.dart';
import '../util/log.dart';

const wql2 = 'wql.2';

class ScraperSource {
  ///Stores references to the global sources by name
  static final Map<String, ScraperSource> _globalSources = {};

  ///Supported programs that can be run
  static final Set<String> supportedProgramTypes = {wql2};

  ///Scraping requests that this object can run
  final Map<String, Request> requests;

  ///Yaml file info convert and stored
  final Map<String, dynamic> info;

  ///Main directory this extension is stored in
  final Directory directory;

  ///Returns a global scrapper by name
  ///
  ///Returns null if [name] doesn't exist for a global scrapper
  static ScraperSource? scrapper(String name) => _globalSources[name];

  ///Creates a scrapper that is added to global and can be referenced without having the object
  ///
  ///This is good for defining your scripts on start-up to later be used
  static Result<ScraperSource> global(String input, Directory directory) {
    final (:source, :errorMessage) = createScraperSource(input, directory);

    if (source == null || (errorMessage?.isNotEmpty ?? false)) {
      log2('Error creating global source:', errorMessage, level: const LogLevel.error());
      return const Fail();
    }

    //add to global scraper source by name
    _globalSources[source.info['source']] = source;

    return Pass(source);
  }

  ///Creates a scrapper
  ScraperSource(this.directory, this.info, this.requests);

  static ({ScraperSource? source, String? errorMessage}) createScraperSource(String input, Directory directory) {
    try {
      final Map<String, dynamic> yaml = parseYaml(input);

      const requireKeys = ['source', 'requests', 'version', 'programType'];

      for (final key in requireKeys) {
        if (!yaml.containsKey(key)) {
          throw Exception('$key is not defined');
        }
      }

      if (!supportedProgramTypes.contains(yaml['programType'])) {
        throw const FormatException('Unknown global program type');
      }

      final String globalProgramType = yaml['programType'] as String;

      final Map<String, Request> validRequests = {};

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
          log2('Unknown local program type', localProgramType, level: const LogLevel.warn());
          continue;
        }

        validRequests[request['type']] = Request(
          type: requestMap(request['type']),
          file: File(p.join(directory.path, request['file'])),
          entry: request['entry'] ?? '',
          compiled: request['compiled'] ?? false,
          programType: localProgramType ?? globalProgramType,
        );
      }

      return (source: ScraperSource(directory, yaml, validRequests), errorMessage: null);
    } catch (e, stack) {
      log2('Parsing error for global source:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return (source: null, errorMessage: e.toString());
    }
  }

  static bool _loadedWQLFunctions = false;

  Future<Result<T>> makeRequest<T>(
    String name,
    Map<String, dynamic> arguments, {
    Map<String, Function> functions = const {},
  }) async {
    log2('Make request: ', name, level: const LogLevel.info());
    final Request? r = requests[name];

    if (r != null) {
      //ensure that the request file exists
      if (!(await r.file.exists())) {
        log2('Request file does not exist', r.file.path, level: const LogLevel.warn());
        return const Fail();
      }

      if (r.programType == wql2) {
        if (!_loadedWQLFunctions) {
          loadWQLFunctions();
          _loadedWQLFunctions = true;
        }

        return await ResultExtended.unsafeAsync<T>(
          () async {
            final String code = await r.file.readAsString();
            final result = await WQL.run(code, context: arguments, functions: functions);
            if (result case Pass<Map<String, dynamic>>(data: final data)) {
              if (data['return'] is! T) {
                throw Exception('Return type is not correct');
              }

              return data['return'];
            }

            throw Exception('Fail state was no re-thrown');
          },
          errorMessage: 'Error running WQL',
        );
      }
    }

    return const Fail();
  }

  //TODO: have a cache system for loaded WQL files, this could also be used for saving already parsed files
}

class Request {
  final RequestType type;
  final File file;
  final String entry;
  final bool compiled;
  final String programType;
  const Request({
    required this.type,
    required this.file,
    required this.entry,
    required this.programType,
    this.compiled = false,
  });
}
