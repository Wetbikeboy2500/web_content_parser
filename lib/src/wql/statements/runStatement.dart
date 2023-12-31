import 'package:petitparser/parser.dart';
import 'package:web_content_parser/src/util/log.dart';

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
    final [_, function, __, arguments] = tokens;

    final String tmpFunction = function.toLowerCase();

    final List<Operator> tmpArguments = [];

    for (final List operatorTokens in arguments) {
      tmpArguments.add(Operator.fromTokens(operatorTokens));
    }

    if (SetStatement.functions.containsKey(tmpFunction)) {
      return RunStatement(function, SetStatement.functions[tmpFunction], tmpArguments);
    }

    return RunStatement(function, null, tmpArguments);
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
      log2('Unsupported function', function, level: const LogLevel.error());
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
