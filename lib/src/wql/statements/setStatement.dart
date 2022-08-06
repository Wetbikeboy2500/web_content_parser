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

  static Map<String, Function> functions = {};

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
