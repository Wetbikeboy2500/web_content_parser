import 'package:petitparser/core.dart';
import 'package:petitparser/parser.dart';

import '../interpreter/interpreter.dart';
import '../suboperations/operator.dart';
import '../parserHelper.dart';
import 'setStatement.dart';
import 'statement.dart';

class RunStatement extends Statement {
  final String function;
  final List<Operator> arguments;

  const RunStatement(this.function, this.arguments);

  factory RunStatement.fromTokens(List tokens) {
    final String function = tokens[1].toLowerCase();

    final List<Operator> arguments = [];

    for (final List operatorTokens in tokens[3]) {
      arguments.add(Operator.fromTokens(operatorTokens));
    }

    return RunStatement(function, arguments);
  }

  static Parser getParser() {
    return stringIgnoreCase('run').trim().token() &
        name &
        stringIgnoreCase('with') &
        inputs;
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    //gets the args to pass along
    final List args = [];
    for (final arg in arguments) {
      args.add((await arg.getValue(interpreter.values, interpreter, custom: SetStatement.functions)).value);
    }

    final Function? func = SetStatement.functions[function];

    if (func == null) {
      throw UnsupportedError('Unsupported function: $function');
    }

    //runs the function
    await await func(args);
  }
}
