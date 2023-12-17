import 'package:petitparser/parser.dart';

import '../interpreter/interpreter.dart';
import '../suboperations/operator.dart';
import '../parserHelper.dart';
import 'setStatement.dart';
import 'statement.dart';

class RunStatement extends Statement {
  final String function;
  final Function? functionReference;
  final List<Operator> arguments;

  const RunStatement(this.function, this.functionReference, this.arguments);

  factory RunStatement.fromTokens(List tokens) {
    final String function = tokens[1].toLowerCase();

    final List<Operator> arguments = [];

    for (final List operatorTokens in tokens[3]) {
      arguments.add(Operator.fromTokens(operatorTokens));
    }

    if (SetStatement.functions.containsKey(function)) {
      return RunStatement(function, SetStatement.functions[function], arguments);
    }

    return RunStatement(function, null, arguments);
  }

  static Parser getParser() {
    return stringIgnoreCase('run').trim().token() &
        name &
        stringIgnoreCase('with') &
        inputs;
  }

  @override
  Future<void> execute(Interpreter interpreter, dynamic context) async {
    if (functionReference == null) {
      throw UnsupportedError('Unsupported function: $function');
    }

    //gets the args to pass along
    final List args = [];
    for (final arg in arguments) {
      args.add((await arg.getValue(context, interpreter, custom: SetStatement.functions)).result.value);
    }

    //runs the function
    await await functionReference!(args);
  }
}
