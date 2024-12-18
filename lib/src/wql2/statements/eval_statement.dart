import '../interpreter.dart';
import 'statement.dart';

class EvalStatement extends Statement {
  final List<Statement> statements;
  const EvalStatement(this.statements);

  @override
  StatementReturn execute(dynamic context, Interpreter interpreter) async {
    final (noop:_, :hasNewContext, :newContext) = await interpreter.runStatementsWithContext(statements, context, true);

    if (hasNewContext) {
      return (name: '', result: newContext, wasExpanded: false, noop: false);
    }

    return (name: '', result: context, wasExpanded: false, noop: false);
  }
}