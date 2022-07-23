import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:petitparser/core.dart';
import 'package:petitparser/parser.dart';
import 'package:web_content_parser/scraper.dart';
import 'package:path/path.dart' as path;

import '../interpreter/interpreter.dart';
import '../suboperations/operator.dart';
import '../parserHelper.dart';
import 'statement.dart';

class SetStatement extends Statement {
  final String target;
  final String function;
  final List<Operator> arguments;

  const SetStatement(this.target, this.function, this.arguments);

  factory SetStatement.fromTokens(List tokens) {
    final String target = tokens[1];
    final String function = tokens[3].toLowerCase();

    final List<Operator> arguments = [];

    for (final List operatorTokens in tokens[5]) {
      arguments.add(Operator.fromTokens(operatorTokens));
    }

    return SetStatement(target, function, arguments);
  }

  static Parser getParser() {
    return stringIgnoreCase('set').trim().token() &
        name &
        stringIgnoreCase('to').trim().token() &
        name &
        stringIgnoreCase('with') &
        inputs;
  }

  //TODO: move these outside of the WQL directory since these are for the web_content_parser
  static Map<String, Function> functions = {
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
    'increment': (args) {
      dynamic value = args[0].first;
      if (value is String) {
        value = num.parse(value);
      }
      return value + 1;
    },
    'decrement': (args) {
      dynamic value = args[0].first;
      if (value is String) {
        value = num.parse(value);
      }
      return value - 1;
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
    'trim': (args) {
      return args[0].first.trim();
    },
    'merge': (args) {
      final List results = [];
      for (List l in args) {
        results.addAll(l);
      }
      return results;
    },
    'mergekeyvalue': (args) {
      final value1 = args[0];
      final value2 = args[1];
      final result = {};

      bool stringMap = true;
      bool numMap = true;

      int index = 0;
      for (final key in value1) {
        if (stringMap && key is! String) {
          stringMap = false;
        }

        if (numMap && key is! num) {
          numMap = false;
        }

        result[key] = value2[index];
        index++;
      }

      if (numMap) {
        return Map<int, dynamic>.from(result);
      } else if (stringMap) {
        return Map<String, dynamic>.from(result);
      } else {
        return result;
      }
    },
    'concat': (args) {
      final List results = [];
      for (List l in args) {
        results.addAll(l);
      }
      return results.join('');
    },
    'count': (args) {
      return args[0].first.length;
    },
    'createrange': (args) {
      final List<int> output = [];
      for (int i = args[0].first; i < args[1].first; i++) {
        output.add(i);
      }
      return output;
    },
    'reverse': (args) {
      return args[0].first.reversed.toList();
    },
    'itself': (args) {
      return args[0].first;
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
    }
  };

  @override
  Future<void> execute(Interpreter interpreter) async {
    //gets the args to pass along
    final List args = [];
    for (final arg in arguments) {
      args.add(arg.getValue(interpreter.values).value);
    }

    final Function? func = functions[function];

    if (func == null) {
      throw UnsupportedError('Unsupported function: $function');
    }

    //runs the function
    final dynamic value = await func(args);

    //set the value
    interpreter.setValue(target, value);
  }
}
