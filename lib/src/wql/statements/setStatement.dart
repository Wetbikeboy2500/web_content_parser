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
  final LogicalSelector? whenClause;

  const SetStatement(this.target, this.operation, {this.whenClause});

  factory SetStatement.fromTokens(List tokens) {
    final [_, String target, __, operation, whenClause] = tokens;

    return SetStatement(
      target,
      Operator.fromTokensNoAlias(operation),
      whenClause: whenClause != null ? LogicalSelector(whenClause.last) : null,
    );
  }

  static Parser getParser() {
    return stringIgnoreCase('set').trim().token() &
        name &
        stringIgnoreCase('to').trim().token() &
        input &
        (stringIgnoreCase('when').trim().token() & LogicalSelector.getParser()).optional();
  }

  //TODO: Look into how this could affect performance for small operations
  //One idea would be to also sort the keys and then use binary search to find the index for the initial index
  //Objects could also share their function definitions when the objects are built rather than at runtime
  //From this, there could be a 'compiled' version which requires all functions to be defined before hand
  static List<String> keys = [];
  static List<Function> values = [];
  static Function? getFunctionByIndex(int index) {
    return values[index];
  }

  static (Function?, int) getFunction(String key) {
    final index = keys.indexOf(key);
    if (index == -1) {
      return (null, -1);
    }
    return (values[index], index);
  }

  static void convertFunctionsMapToSplitArray() {
    keys = functions.keys.toList();
    values = functions.values.toList();
  }

  static Map<String, Function> functions = {
    'increment': (args) {
      dynamic arg0 = args[0];
      if (arg0 is String) {
        arg0 = num.parse(arg0);
      }
      return arg0 + 1;
    },
    'decrement': (args) {
      dynamic arg0 = args[0];
      if (arg0 is String) {
        arg0 = num.parse(arg0);
      }
      return arg0 - 1;
    },
    'trim': (args) {
      return args[0].trim();
    },
    'merge': (args) {
      final List results = [];
      for (dynamic l in args) {
        if (l is List) {
          results.addAll(l);
        } else {
          results.add(l);
        }
      }
      return results;
    },
    'mergekeyvalue': (args) {
      final value1 = (args[0] is List) ? args[0] : [args[0]];
      final value2 = (args[1] is List) ? args[1] : [args[1]];
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
      return args[0].last;
    },
    'count': (args) {
      return args[0].length;
    },
    'split': (args) {
      return args[0].split(args[1]);
    },
    'indexof': (args) {
      return args[0].indexOf(args[1]);
    },
    'indexofstartingat': (args) {
      return args[0].indexOf(args[1], args[2]);
    },
    'substring': (args) {
      return args[0].substring(args[1], args[2]);
    },
    'replaceall': (args) {
      return args[0].replaceAll(args[1], args[2]);
    },
    'createrange': (args) {
      final List<int> output = [];
      for (int i = args[0]; i < args[1]; i++) {
        output.add(i);
      }
      return output;
    },
    'reverse': (args) {
      return args[0].reversed.toList();
    },
    'itself': (args) {
      return args[0];
    },
    'print': (args) {
      // ignore: avoid_print
      print(args.join(', '));
      return null;
    },
    'isnull': (args) {
      return args[0] == null;
    },
    'isempty': (args) {
      return args[0].isEmpty;
    },
    'tostring': (args) {
      return args[0].toString();
    },
    'lowercase': (args) {
      return args[0].toLowerCase();
    },
    'uppercase': (args) {
      return args[0].toUpperCase();
    },
    'json': (args) {
      final arg0 = args[0];

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
    if (whenClause != null) {
      final whenResult = await whenClause!.evaluate(context, interpreter);
      if (whenResult == false) {
        return;
      }
    }

    final value = (await operation.getValue(context, interpreter, custom: functions)).result.value;

    //set the value
    interpreter.setValue(target, value.first);
  }
}
