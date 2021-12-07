import 'dart:async';
import 'dart:io';
import 'package:hetu_script/binding.dart';
import 'package:hetu_script/value/struct/struct.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser show parse;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:hetu_script/hetu_script.dart';
import 'scrapeFunctions.dart';

///Functions that can be imported and used inside of hetu scripts
///
///This also allows for overridding of functions using the insert function feature
Map<String, HTExternalFunction> _externalFunction = {
  'querySelector': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    positionalArgs[0] as Node;
    return positionalArgs[0].querySelector(positionalArgs[1] as String);
  },
  'querySelectorAll': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    positionalArgs[0] as Node;
    return positionalArgs[0].querySelectorAll(positionalArgs[1] as String);
  },
  'getText': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    positionalArgs[0] as Node;
    return positionalArgs[0].text;
  },
  'fetchHtml': getRequest,
  'getRequest': getRequest,
  'getDynamicPage': getDynamicPageHetu,
  'postRequest': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return http.post(Uri.parse(positionalArgs[0]), body: positionalArgs[1]);
  },
  'parseBody': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return parser.parse(positionalArgs[0].body);
  },
  'parseHtml': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return parser.parse(positionalArgs[0]);
  },
  'joinUrl': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return path.url.joinAll(List<String>.from(positionalArgs[0]));
  },
  'getStatusCode': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].statusCode;
  },
  'getAttribute': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].attributes[positionalArgs[1] as String];
  },
  'toLowerCase': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].toLowerCase();
  },
  'dateTimeYear': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return DateTime(int.parse(positionalArgs[0]));
  },
  'dateTimeAgo': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    final time = positionalArgs[0];
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
  'dateTimeNow': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return DateTime.now();
  },
  'toMapStringDynamic': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    final value = positionalArgs[0];
    if (value is HTStruct) {
      return Map<String, dynamic>.from(value.fields);
    }
    return value;
  },
  'toMapIntString': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    final value = positionalArgs[0];
    if (value is HTStruct) {
      return Map<int, String>.from(value.fields);
    }
    return value;
  },
  'trimList': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].map((e) => e.trim()).toList();
  },
  'reversed': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].reversed.toList();
  },
  'getPathSegments': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return Uri.parse(positionalArgs[0]).pathSegments;
  },
  'convertToString': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    return positionalArgs[0].toString();
  },
  'contains': (
    HTEntity entity, {
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
void insertFunction(String name, HTExternalFunction func) => _externalFunction[name] = func;

///Evaluates hetu script files
///
///This includes already made external functions to be used and a system for calling async functions
///This also accounts for async code through recursive calls when futures are returned in a specific format
//TODO: allow eval to execute compiled hetu scripts. This can be set through an extra parameter supplied through the yaml file
dynamic eval(File file,
    {String functionName = 'main', String workingDirectory = '/script', List args = const []}) async {
  final Hetu hetu = Hetu(sourceContext: HTOverlayContext(root: workingDirectory));

  hetu.init(externalFunctions: _externalFunction);

  await hetu.eval(await file.readAsString());

  late Future Function(String, List<dynamic>) _eval;

  //Define the eval script for recursion
  _eval = (name, _args) async {
    //invokes specific functions by name to be run
    var response = hetu.invoke(
      name,
      positionalArgs: _args,
    );

    //Need the map and less of the Hetu
    if (response is HTStruct) {
      response = response.fields;
    }

    //If the return is a map, it could be for an async function to be called
    //Returned maps for async functions must have a target and data key
    if (response is Map && response.containsKey('target') && response.containsKey('data')) {
      //List of arguments to be passed to next function
      final List nextData = [];

      if (response['data'] is List) {
        //calling multiple async functions to resolve
        for (var data in response['data']) {
          if (data is Future) {
            nextData.add(await data);
          } else {
            nextData.add(data);
          }
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
