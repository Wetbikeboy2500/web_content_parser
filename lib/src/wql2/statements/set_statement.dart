import 'package:web_content_parser/src/wql2/dot_input/dot_input.dart';
import 'package:web_content_parser/src/wql2/interpreter.dart';

import './statement.dart';

class SetStatement extends Statement {
  final String access;
  final DotInput value;

  SetStatement(this.access, this.value);

  @override
  StatementReturn execute(dynamic context, Interpreter interpreter) async {
    interpreter.setValue(access, await value.getValue(context, interpreter, custom: {}));
    return const (name: '', result: null, wasExpanded: false, noop: false);
  }
}