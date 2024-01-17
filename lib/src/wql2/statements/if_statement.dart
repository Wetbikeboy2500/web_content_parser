import '../interpreter.dart';
import '../logicalSelector.dart';

import 'statement.dart';

class IfStatement extends Statement {
  final LogicalSelector selector;
  final bool topLevel;
  final List<Object>? statements;
  final List<Object>? elseIfs;

  IfStatement(this.selector, this.topLevel, this.statements, this.elseIfs);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    if (await selector.evaluate(context, interpreter)) {
      if (statements != null) {
        await interpreter.runStatements(statements!);
      }
      return (name: '', result: context, wasExpanded: false, noop: false);
    } else {
      if (elseIfs != null) {
        await interpreter.runStatements(elseIfs!);
      }
      return (name: '', result: null, wasExpanded: false, noop: false);
    }
  }
}
