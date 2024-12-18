import '../dot_input/dot_input.dart';
import '../interpreter.dart';
import 'statement.dart';

//TOOD: look into better handling of noops for expanded vs non-expanded if statement outputs
class IfStatement extends Statement {
  final DotInput condition;

  const IfStatement(this.condition);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    final StatementReturnValue result = await condition.execute(context, interpreter);

    final noop = result.noop || result.result != true;
    return (name: '', result: context, wasExpanded: false, noop: noop);
  }
}
