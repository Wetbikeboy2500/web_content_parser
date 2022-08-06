import 'package:petitparser/core.dart';
import 'package:petitparser/parser.dart';

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

  static Map<String, Function> functions = {
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
