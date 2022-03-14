import 'dart:async';
import 'dart:io';
import 'package:hetu_script/binding.dart';
import 'package:hetu_script/value/struct/struct.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser show parse;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:hetu_script/hetu_script.dart';
import '../util/log.dart';
import '../../util.dart';
import 'scrapeFunctions.dart';

///Functions that can be imported and used inside of hetu scripts
///
///This also allows for overriding of functions using the insert function feature
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
  'postRequest': postRequest,
  'getDynamicPage': getDynamicPageHetu,
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
    if (positionalArgs.length == 2 &&
        positionalArgs[0] != null &&
        positionalArgs[0] is Node &&
        positionalArgs[1] is String) {
      return ResultExtended.toJson(Result.pass(positionalArgs[0].attributes[positionalArgs[1] as String]));
    } else {
      return ResultExtended.toJson(const Result.fail());
    }
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
    try {
      return DateTime(int.parse(positionalArgs[0]));
    } catch (e) {
      log2('Error dateTimeYear', e);
      return DateTime.now();
    }
  },
  'dateTimeAgo': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    try {
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
    } catch (e) {
      log2('Error occurred parsing time ago:', e);
      //TODO: revise this to use a safe call and not default to datetime now
      return DateTime.now();
    }
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
      return value.toJson();
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
      return value.toJson().map((key, value) => MapEntry<int, String>(int.parse(key), value.toString()));
    }
    return value;
  },
  'toMapStringString': (
    HTEntity entity, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const <HTType>[],
  }) {
    final value = positionalArgs[0];
    if (value is HTStruct) {
      return value.toJson().map((key, value) => MapEntry<String, String>(key, value.toString()));
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
///[func] Function to be run. This should follow the format of other functions that have been defined for external functions
void insertFunction(String name, HTExternalFunction func) => _externalFunction[name] = func;

///Evaluates hetu script files
///
///This includes already made external functions to be used and a system for calling async functions
///This also accounts for async code through recursive calls when futures are returned in a specific format
dynamic eval(
  File file, {
  String functionName = 'main',
  String workingDirectory = '/script',
  List args = const [],
  bool compiled = false,
}) async {
  final Hetu hetu = Hetu(sourceContext: HTOverlayContext(root: workingDirectory));

  hetu.init(externalFunctions: _externalFunction);

  if (compiled) {
    await hetu.loadBytecode(bytes: file.readAsBytesSync(), moduleName: path.basenameWithoutExtension(file.path));
  } else {
    await hetu.eval(await file.readAsString());
  }

  late Future Function(String, List<dynamic>) _eval;

  //Define the eval script for recursion
  _eval = (name, _args) async {
    //invokes specific functions by name to be run
    final response = hetu.invoke(
      name,
      positionalArgs: _args,
    );

    //If the return is a map, it could be for an async function to be called
    //Returned maps for async functions must have a target and data key
    if ((response is Map || response is HTStruct) && response.containsKey('target') && response.containsKey('data')) {
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

    if (response is HTStruct) {
      return response.toJson();
    }

    //Simply returns the final result if not async
    return response;
  };

  return await _eval(functionName, args);
}
