import '../dot_input/dot_input.dart';
import '../interpreter.dart';
import 'statement.dart';

class IfStatement extends Statement {
  final DotInput condition;
  final bool topLevel;
  final List<Statement>? statements;
  final List<Statement>? elseIfs;

  IfStatement(this.condition, this.topLevel, this.statements, this.elseIfs);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    final StatementReturnValue result = await condition.execute(context, interpreter);

    if (result.noop) {
      return const (name: '', result: null, wasExpanded: false, noop: true);
    }

    if (result.result == true) {
      if (statements != null) {
        await interpreter.runStatementsWithContext(statements!, context, true);
      }
      return (name: '', result: context, wasExpanded: false, noop: false);
    } else {
      if (elseIfs != null) {
        final (noop: bool noop) = await interpreter.runStatementsWithContext(elseIfs!, context, true);

        if (noop) {
          return const (name: '', result: null, wasExpanded: false, noop: true);
        }
      } else if (topLevel == false) {
        return (name: '', result: context, wasExpanded: false, noop: true);
      }

      return const (name: '', result: null, wasExpanded: false, noop: false);
    }
  }
}
