import '../dot_input/dot_input.dart';
import '../interpreter.dart';
import './statement.dart';

class SetStatement extends Statement {
  final String access;
  final DotInput value;

  SetStatement(this.access, this.value);

  @override
  StatementReturn execute(dynamic context, Interpreter interpreter) async {
    final result = await value.execute(context, interpreter);

    if (result.noop) {
      return const (name: '', result: null, wasExpanded: false, noop: true);
    }

    interpreter.setValue(access, result.result);
    return const (name: '', result: null, wasExpanded: false, noop: false);
  }
}