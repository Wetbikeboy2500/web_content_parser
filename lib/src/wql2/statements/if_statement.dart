import '../interpreter.dart';
import '../logicalSelector.dart';
import 'statement.dart';

class IfStatement extends Statement {
  final LogicalSelector selector;
  final bool topLevel;
  final List<Statement>? statements;
  final List<Statement>? elseIfs;

  IfStatement(this.selector, this.topLevel, this.statements, this.elseIfs);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    final (result: bool result, noop: bool noop) = await selector.evaluate(context, interpreter);

    if (noop) {
      return const (name: '', result: null, wasExpanded: false, noop: true);
    }

    if (result) {
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

      return (name: '', result: null, wasExpanded: false, noop: false);
    }
  }
}
