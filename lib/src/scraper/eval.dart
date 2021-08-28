import 'dart:async';
import 'dart:io';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser show parse;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:hetu_script/hetu_script.dart';
import 'package:web_content_parser/src/scraper/scrapeFunctions.dart';

Map<String, Function> _externalFunction = {
  'querySelector': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    positionalArgs[0] as Node;
    return positionalArgs[0].querySelector(positionalArgs[1] as String);
  },
  'querySelectorAll': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    positionalArgs[0] as Node;
    return positionalArgs[0].querySelectorAll(positionalArgs[1] as String);
  },
  'getText': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    positionalArgs[0] as Node;
    return positionalArgs[0].text;
  },
  'fetchHtml': getRequest,
  'getRequest': getRequest,
  'postRequest': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return http.post(Uri.parse(positionalArgs[0]), body: positionalArgs[1]);
  },
  'parseBody': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return parser.parse(positionalArgs[0].body);
  },
  'joinUrl': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return path.url.joinAll(List<String>.from(positionalArgs[0]));
  },
  'getStatusCode': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].statusCode;
  },
  'getAttribute': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].attributes[positionalArgs[1] as String];
  },
  'toLowerCase': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].toLowerCase();
  },
  'dateTimeYear': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return DateTime(int.parse(positionalArgs[0]));
  },
  'dateTimeAgo': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    var time = positionalArgs[0];
    Duration ago;
    if (time.contains('mins ago') || time.contains('min ago')) {
      ago = Duration(minutes: int.parse(time.substring(0, time.indexOf('min'))));
    } else if (time.contains('hour ago') || time.contains('hours ago')) {
      ago = Duration(hours: int.parse(time.substring(0, time.indexOf('hour'))));
    } else if (time.contains('day ago') || time.contains('days ago')) {
      ago = Duration(days: int.parse(time.substring(0, time.indexOf('day'))));
    } else {
      return DateFormat('MMMM dd, yyyy', 'en_US').parse(time);
    }

    return DateTime.now().subtract(ago);
  },
  'dateTimeNow': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return DateTime.now();
  },
  'toMapStringDynamic': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return Map<String, dynamic>.from(positionalArgs[0]);
  },
  'toMapIntString': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return Map<int, String>.from(positionalArgs[0]);
  },
  'trimList': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].map((e) => e.trim()).toList();
  },
  'reversed': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].reversed.toList();
  },
  'getPathSegments': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return Uri.parse(positionalArgs[0]).pathSegments;
  },
  'convertToString': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].toString();
  },
  'contains': ({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].contains(positionalArgs[1]);
  },
};

///Insert a new external function that can be imported into a script
///
///[name] Function name
///[func] Function to be run. This shold follow the format of other functions that have been defined for external functions
void insertFunction(String name, Function func) => _externalFunction[name] = func;

///Evaluates hetu script files
///
///This includes already made external functions to be used and a system for calling async functions
dynamic eval(File file,
    {String functionName = 'main', String workingDirectory = '/script', List args = const []}) async {
  Hetu hetu = Hetu(sourceProvider: DefaultSourceProvider(workingDirectory: workingDirectory));

  await hetu.init(externalFunctions: _externalFunction);

  await hetu.eval(file.readAsStringSync());

  late Future Function(String, List<dynamic>) _eval;

  //Define the eval script for recursion
  _eval = (name, _args) async {
    //invokes specific functions by name to be run
    var response = hetu.invoke(
      name,
      positionalArgs: _args,
    );

    //If the return is a map, it could be for an async function to be called
    //Returned maps for async functions must have a target and data key
    if (response is Map && response.containsKey('target') && response.containsKey('data')) {
      //List of arguments to be passed to next function
      final List nextData = [];

      if (response['data'] is List) {
        //calling multiple async functions to resolve
        for (var data in response['data']) {
          nextData.add(await data);
        }
      } else {
        //Calling one async function to resolve
        nextData.add(await response['data']);
      }

      //Call next function through eval by target name with data passed to it
      return await _eval(response['target'], nextData);
    }

    //Simply returns the final result if not async
    return response;
  };

  return await _eval(functionName, args);
}
