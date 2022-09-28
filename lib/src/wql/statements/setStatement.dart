import 'package:petitparser/core.dart';
import 'package:petitparser/parser.dart';

import '../interpreter/interpreter.dart';
import '../suboperations/operator.dart';
import '../parserHelper.dart';
import 'statement.dart';

class SetStatement extends Statement {
  final String target;
  final Operator operation;

  const SetStatement(this.target, this.operation);

  factory SetStatement.fromTokens(List tokens) {
    final String target = tokens[1];

    final Operator operation = Operator.fromTokensNoAlias(tokens[3]);

    return SetStatement(target, operation);
  }

  static Parser getParser() {
    return stringIgnoreCase('set').trim().token() & name & stringIgnoreCase('to').trim().token() & input;
  }

  static Map<String, Function> functions = {
    'increment': (args) {
      dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 is String) {
        arg0 = num.parse(arg0);
      }
      return arg0 + 1;
    },
    'decrement': (args) {
      dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      if (arg0 is String) {
        arg0 = num.parse(arg0);
      }
      return arg0 - 1;
    },
    'trim': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      return arg0.trim();
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
      final dynamic arg0 = (args[0] is List && args[0].isNotEmpty && args[0].first is List) ? args[0].first : args[0];
      return arg0.length;
    },
    'createrange': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      final List<int> output = [];
      for (int i = arg0; i < arg1; i++) {
        output.add(i);
      }
      return output;
    },
    'reverse': (args) {
      final dynamic arg0 = (args[0] is List && args[0].isNotEmpty && args[0].first is List) ? args[0].first : args[0];
      return arg0.reversed.toList();
    },
    'itself': (args) {
      return (args[0] is List) ? args[0].first : args[0];
    },
    'print': (args) {
      // ignore: avoid_print
      print(args);
      return null;
    },
    'isnull': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      return arg0 == null;
    },
  };

  @override
  Future<void> execute(Interpreter interpreter) async {
    final value = (await operation.getValue(interpreter.values, interpreter, custom: functions)).value;

    //set the value
    interpreter.setValue(target, value.first);
  }
}
