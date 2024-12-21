import 'dart:convert';
import 'dart:io';

import 'package:petitparser/petitparser.dart';
import 'package:web_query_framework_util/util.dart' as wql_result;

import '../util/log.dart';
import 'interpreter.dart';
import 'translator.dart';

class WQL {
  static Map<String, Function> functions = {
    'increment': (args) => (args[0] is! num) ? num.parse(args[0]) + 1 : args[0] + 1,
    'decrement': (args) => (args[0] is! num) ? num.parse(args[0]) - 1 : args[0] - 1,
    'subtract': (args) {
      final arg0 = (args[0] is num) ? args[0] : num.parse(args[0]);
      final arg1 = (args[1] is num) ? args[1] : num.parse(args[1]);
      return arg0 - arg1;
    },
    'divide': (args) {
      final arg0 = (args[0] is num) ? args[0] : num.parse(args[0]);
      final arg1 = (args[1] is num) ? args[1] : num.parse(args[1]);
      return arg0 / arg1;
    },
    'multiply': (args) {
      final arg0 = (args[0] is num) ? args[0] : num.parse(args[0]);
      final arg1 = (args[1] is num) ? args[1] : num.parse(args[1]);
      return arg0 * arg1;
    },
    'abs': (args) => (args[0] is num) ? args[0].abs() : num.parse(args[0]).abs(),
    'min': (args) {
      final arg0 = (args[0] is num) ? args[0] : num.parse(args[0]);
      final arg1 = (args[1] is num) ? args[1] : num.parse(args[1]);
      return arg0 < arg1 ? arg0 : arg1;
    },
    'max': (args) {
      final arg0 = (args[0] is num) ? args[0] : num.parse(args[0]);
      final arg1 = (args[1] is num) ? args[1] : num.parse(args[1]);
      return arg0 > arg1 ? arg0 : arg1;
    },
    'trim': (args) => args[0].trim(),
    'merge': (args) => args.expand((l) => (l is List) ? l : [l]).toList(),
    'flatten': (args) => args[0].expand((l) => (l is List) ? l : [l]).toList(),
    'sort': (args) => args[0].toList()..sort(),
    'concat': (args) => args.join(''),
    'join': (args) => args[0].join(args[1]),
    'add': (args) {
      if (args[0] is List) {
        return args[0]..add(args[1]);
      } else if (args[0] is num || args[0] is String) {
        final arg0 = (args[0] is num) ? args[0] : num.parse(args[0]);
        final arg1 = (args[1] is num) ? args[1] : num.parse(args[1]);
        return arg0 + arg1;
      } else {
        throw ArgumentError('First argument must be a List or a num');
      }
    },
    'addall': (args) => args[0].addAll(args[1]),
    'last': (args) => args[0].last,
    'first': (args) => args[0].first,
    'at': (args) => args[0][args[1]],
    'length': (args) => args[0].length,
    'split': (args) => args[0].split(args[1]),
    'indexof': (args) => args[0].indexOf(args[1]),
    'contains': (args) => args[0].contains(args[1]),
    'indexofstartingat': (args) => args[0].indexOf(args[1], args[2]),
    'substring': (args) => args[0].substring(args[1], args[2]),
    'replaceall': (args) => args[0].replaceAll(args[1], args[2]),
    'allmatches': (args) => RegExp(args[1]).allMatches(args[0]).map((match) => match.group(0)).toList(),
    'hasmatch': (args) => RegExp(args[1]).hasMatch(args[0]),
    'createrange': (args) => List<int>.generate(args[1] - args[0], (i) => args[0] + i),
    'reverse': (args) => args[0].reversed.toList(),
    'itself': (args) => args[0],
    'tostring': (args) => args[0].toString(),
    'toint': (args) => int.parse(args[0]),
    'tonumber': (args) => num.parse(args[0]),
    'print': (args) {
      // ignore: avoid_print
      print(args.join(', '));
      return (args.isNotEmpty) ? args[0] : null;
    },
    'isnull': (args) => args[0] == null,
    'not': (args) => !args[0],
    'and': (args) => args.every((arg) => arg == true),
    'or': (args) => args.any((arg) => arg == true),
    'equals': (args) => args[0] == args[1],
    'greaterthan': (args) => args[0] > args[1],
    'lessthan': (args) => args[0] < args[1],
    'every': (args) => args[0].every((arg) => arg == true),
    'any': (args) => args[0].any((arg) => arg == true),
    'throw': (args) => throw Exception(args.join(' ')),
  };

  static Future<wql_result.Result<dynamic>> run(
    String wql, {
    Map<String, dynamic> context = const {},
    Map<String, Function> functions = const {},
  }) async {
    final interpreter = Interpreter({...WQL.functions, ...functions});
    final parsed = parse(wql, interpreter);

    switch (parsed) {
      case Success(value: final value):
        try {
          final (noop:_, :hasNewContext, :newContext) = await interpreter.runStatements(value, context);

          if (hasNewContext) {
            return wql_result.Pass(newContext);
          }

          return wql_result.Pass(interpreter.values);
        } catch (e, stack) {
          log(e, level: const LogLevel.error());
          log(stack, level: const LogLevel.debug());
          return const wql_result.Fail();
        }
      case Failure():
        assert(() {
          // ignore: avoid_print
          print('${parsed.toPositionString()} ${parsed.message}');
          return true;
        }());
        log(parsed.message, level: const LogLevel.error());
        return const wql_result.Fail();
    }
  }
}
