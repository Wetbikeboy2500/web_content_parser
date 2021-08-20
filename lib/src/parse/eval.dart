import 'dart:async';
import 'dart:io';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser show parse;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:hetu_script/hetu_script.dart';

dynamic eval(File file,
    {String functionName = 'main', String workingDirectory = '/script', List args = const []}) async {

  Hetu hetu = Hetu(sourceProvider: DefaultSourceProvider(workingDirectory: workingDirectory));

  await hetu.init(
    externalFunctions: {
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
      'fetchHtml': ({
        List<dynamic> positionalArgs = const [],
        Map<String, dynamic> namedArgs = const {},
        List<HTType> typeArgs = const <HTType>[],
      }) {
        return http.get(Uri.parse(positionalArgs[0]));
      },
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
    },
  );

  await hetu.eval(file.readAsStringSync());

  late Future Function(String, List<dynamic>) _eval;

  _eval = (name, _args) async {
    var response = hetu.invoke(
      name,
      positionalArgs: _args,
    );

    if (response is Map) {
      if (response.containsKey('target') && response.containsKey('data')) {
        List nextData = [];

        if (response['data'] is List) {
          for (var data in response['data']) {
            nextData.add(await data);
          }
        } else {
          nextData.add(await response['data']);
        }

        return await _eval(response['target'], nextData);
      }
    }

    return response;
  };

  return await _eval(functionName, args);
}
