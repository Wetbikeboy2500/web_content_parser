import '../interpreter.dart';
import 'statement.dart';

class EvalStatement extends Statement {
  final List<Statement> statements;
  EvalStatement(this.statements);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    await interpreter.runStatementsWithContext(statements, context, true);
    return const (name: '', result: context, wasExpanded: false, noop: false);
  }
}