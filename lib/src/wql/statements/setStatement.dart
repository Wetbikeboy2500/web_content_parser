import 'dart:convert';

import 'package:petitparser/parser.dart';

import '../interpreter/interpreter.dart';
import '../suboperations/logicalSelector.dart';
import '../suboperations/operator.dart';
import '../parserHelper.dart';
import 'statement.dart';

class SetStatement extends Statement {
  final String target;
  final Operator operation;
  final LogicalSelector? when;

  const SetStatement(this.target, this.operation, {this.when});

  factory SetStatement.fromTokens(List tokens) {
    final String target = tokens[1];

    final Operator operation = Operator.fromTokensNoAlias(tokens[3]);

    //get when conditions
    late final LogicalSelector? when;

    if (tokens[4] != null) {
      when = LogicalSelector(tokens[4].last);
    } else {
      when = null;
    }

    return SetStatement(target, operation, when: when);
  }

  static Parser getParser() {
    return stringIgnoreCase('set').trim().token() &
        name &
        stringIgnoreCase('to').trim().token() &
        input &
        (stringIgnoreCase('when').trim().token() & LogicalSelector.getParser()).optional();
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
      final List result = [];
      for (final item in args) {
        if (item is List) {
          result.addAll(item);
        } else {
          result.add(item);
        }
      }
      return result.join('');
    },
    'last': (args) {
      final dynamic arg = (args[0] is List && args[0].first is List) ? args[0].first : args[0];
      return arg.last;
    },
    'count': (args) {
      final dynamic arg0 = (args[0] is List && args[0].isNotEmpty && args[0].first is List) ? args[0].first : args[0];
      return arg0.length;
    },
    'split': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      return arg.split(arg1);
    },
    'indexof': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      return arg.indexOf(arg1);
    },
    'indexofstartingat': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      final dynamic arg2 = (args[2] is List) ? args[2].first : args[2];
      return arg.indexOf(arg1, arg2);
    },
    'substring': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      final dynamic arg2 = (args[2] is List) ? args[2].first : args[2];
      return arg.substring(arg1, arg2);
    },
    'replaceall': (args) {
      final dynamic arg = (args[0] is List) ? args[0].first : args[0];
      final dynamic arg1 = (args[1] is List) ? args[1].first : args[1];
      final dynamic arg2 = (args[2] is List) ? args[2].first : args[2];
      return arg.replaceAll(arg1, arg2);
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
    'isempty': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      return arg0.isEmpty;
    },
    'tostring': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      return arg0.toString();
    },
    'lowercase': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      return arg0.toLowerCase();
    },
    'uppercase': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];
      return arg0.toUpperCase();
    },
    'json': (args) {
      final dynamic arg0 = (args[0] is List) ? args[0].first : args[0];

      dynamic localJson;

      if (arg0 is String) {
        localJson = json.decode(arg0);
      } else {
        localJson = arg0;
      }

      if (args.length > 1) {
        for (var i = 1; i < args.length - 1; i += 2) {
          final dynamic selector = args[i];
          final dynamic value = args[i + 1];

          final split = selector.split('.');
          var current = localJson;
          for (var i = 0; i < split.length; i++) {
            if (i == split.length - 1) {
              current[split[i]] = value;
            } else {
              current = current[split[i]];
            }
          }
        }
      }

      return localJson;
    }
  };

  @override
  Future<void> execute(Interpreter interpreter, dynamic context) async {
    if (when != null) {
      final whenResult = await when!.evaluate(context, interpreter);
      if (whenResult == false) {
        return;
      }
    }

    final value = (await operation.getValue(context, interpreter, custom: functions)).value;

    //set the value
    interpreter.setValue(target, value.first);
  }
}
