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
      return await getDynamicPage(args[0].first);
    },
    'postrequest': (args) async {
      return await postRequest(
        args[0].first,
        args[1].first,
        (args.length > 2) ? args[2].first : const <String, String>{},
      );
    },
    'parse': (args) {
      return parse(args[0].first);
    },
    'getstatuscode': (args) {
      return args[0].first.statusCode;
    },
    'parsebody': (args) {
      return parse(args[0].first.body);
    },
    'joinurl': (args) {
      return path.url.joinAll(List<String>.from(args.map((e) => e.first)));
    },
    'getlastsegment': (args) {
      final arg = args[0].first;
      if (arg is String) {
        return path.url.split(arg).last;
      }
      if (arg is List && arg.isNotEmpty && arg.first is Map) {
        final List output = [];
        for (Map item in arg) {
          output.add(path.url.split(item[args[1].first]).last);
        }
        return output;
      } else {
        throw Exception('Cannot get last segment of a non string or list');
      }
    },
    'datetimeago': (args) {
      return args[0].map((time) {
        try {
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
          //TODO: revise this to use a safe call and not default to datetime now
          return DateTime.now();
        }
      }).toList();
    },
    'innerHTML': (args) {
      if (args[0] is List) {
        return args[0].first.innerHtml;
      } else {
        //move this outside of this functions list and check the type
        return args[0].innerHtml;
      }
    },
    'outerHTML': (args) {
      if (args[0] is List) {
        return args[0].first.outerHTML;
      } else {
        //move this outside of this functions list and check the type
        return args[0].outerHTML;
      }
    },
    'attribute': (args) {
      if (args[0] is List) {
        return args[0].first.attributes[args[1]];
      } else {
        //move this outside of this functions list and check the type
        return args[0].attributes[args[1]];
      }
    },
    'name': (args) {
      if (args[0] is List) {
        return args[0].first.localName;
      } else {
        //move this outside of this functions list and check the type
        return args[0].localName;
      }
    },
    'text': (args) {
      if (args[0] is List) {
        return args[0].first.text;
      } else {
        //move this outside of this functions list and check the type
        return args[0].text;
      }
    },
  };
  SetStatement.functions = {
    ...functions,
    ...SetStatement.functions,
  };
}
