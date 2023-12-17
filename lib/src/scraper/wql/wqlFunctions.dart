import 'dart:convert';

import '../../wql/statements/setStatement.dart';
import '../generic/scrapeFunctions.dart';

import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

void loadWQLFunctions() {
  final Map<String, Function> functions = {
    'getrequest': (args) async {
      //for the second argument, we are going to assume it is a map within a list
      return await getRequest(
        args[0].first,
        (args.length > 1) ? args[1].first : const <String, String>{},
      );
    },
    'getdynamicrequest': (args) async {
      if (args[0].length == 2) {
        return await getDynamicPage(args[0].first, id: args[0].last);
      } else {
        return await getDynamicPage(args[0].first);
      }
    },
    'postrequest': (args) async {
      return await postRequest(
        args[0].first,
        args[1].first,
        (args.length > 2) ? Map<String, String>.from(args[2].first) : const <String, String>{},
      );
    },
    'parse': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      return parse(arg);
    },
    'getstatuscode': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      return arg.statusCode;
    },
    'parsebody': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      return parse(arg.body);
    },
    'body': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      return arg.body;
    },
    'joinurl': (args) {
      final List<String> flattened = [];
      for (dynamic arg in args) {
        if (arg is List) {
          flattened.addAll(arg.cast<String>());
        } else {
          flattened.add(arg);
        }
      }
      return path.url.joinAll(flattened);
    },
    'spliturl': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      return path.url.split(arg);
    },
    'decodebasesixtyfour': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      return utf8.decode(base64.decode(arg));
    },
    'getlastsegment': (args) {
      final List arg0 = (args[0] is List) ? args[0] : [args[0]];
      final String? arg1 = (args.length == 1)
          ? null
          : (args[1] is List)
              ? args[1].first
              : args[1];

      final List<String> output = [];
      if (arg1 == null) {
        for (String item in arg0) {
          output.add(Uri.parse(item).pathSegments.lastWhere((element) => element.isNotEmpty, orElse: () => ''));
        }
      } else {
        for (Map item in arg0) {
          output.add(Uri.parse(item[arg1]).pathSegments.lastWhere((element) => element.isNotEmpty, orElse: () => ''));
        }
      }

      return output;
    },
    'datetimeago': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 == null) {
        return DateTime.now();
      }
      try {
        Duration ago;
        if (arg0.contains('mins ago') || arg0.contains('min ago')) {
          ago = Duration(minutes: int.parse(arg0.substring(0, arg0.indexOf('min'))));
        } else if (arg0.contains('hour ago') || arg0.contains('hours ago')) {
          ago = Duration(hours: int.parse(arg0.substring(0, arg0.indexOf('hour'))));
        } else if (arg0.contains('day ago') || arg0.contains('days ago')) {
          ago = Duration(days: int.parse(arg0.substring(0, arg0.indexOf('day'))));
        } else {
          return DateFormat('MMMM dd, yyyy', 'en_US').parse(arg0);
        }

        return DateTime.now().subtract(ago);
      } catch (e) {
        //TODO: revise this to use a safe call and not default to datetime now
        return DateTime.now();
      }
    },
    'datetimenow': (args) {
      return DateTime.now();
    },
    'innerhtml': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 == null) {
        return null;
      }
      return arg0.innerHtml;
    },
    'outerhtml': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 == null) {
        return null;
      }
      return arg0.outerHtml;
    },
    'attribute': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      if (arg0 == null) {
        return null;
      }
      return arg0.attributes[arg1];
    },
    'name': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 == null) {
        return null;
      }
      return arg0.localName;
    },
    'text': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 == null) {
        return null;
      }
      return arg0.text;
    },
    'decode': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 == null) {
        return null;
      }
      return jsonDecode(arg0);
    },
    'encode': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      return jsonEncode(arg0);
    },
    'queryselector': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      if (arg0 == null) {
        return null;
      }
      return arg0.querySelector(arg1);
    },
    'queryselectorall': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      if (arg0 == null) {
        return null;
      }
      return arg0.querySelectorAll(arg1);
    },
  };
  SetStatement.functions = {
    ...functions,
    ...SetStatement.functions,
  };
}
