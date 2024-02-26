import '../dot_input/dot_input.dart';
import '../interpreter.dart';
import 'statement.dart';

class LoopStatement extends Statement {
  final DotInput argument;
  final List<Statement>? statements;

  LoopStatement(this.argument, this.statements);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    final result = await argument.execute(context, interpreter);

    if (result.noop) {
      return const (name: '', result: null, wasExpanded: false, noop: true);
    }

    assert(result.result is List<dynamic>);

    for (final newContext in result.result) {
      await interpreter.runStatementsWithContext(statements!, newContext, true);
    }

    return (name: '', result: context, wasExpanded: false, noop: false);
  }
}
