import '../interpreter.dart';
import 'statement.dart';

class EvalStatement extends Statement {
  final List<Statement> statements;
  const EvalStatement(this.statements);

  @override
  StatementReturn execute(dynamic context, Interpreter interpreter) async {
    await interpreter.runStatementsWithContext(statements, context, true);
    return (name: '', result: context, wasExpanded: false, noop: false);
  }
}