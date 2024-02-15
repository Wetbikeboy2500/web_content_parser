import '../interpreter.dart';

typedef StatementReturnValue = ({String name, dynamic result, bool wasExpanded, bool noop});

/// [result] is a list of values if the statement was expanded
typedef StatementReturn = Future<StatementReturnValue>;

abstract class Statement {
  StatementReturn execute(dynamic context, Interpreter interpreter);
}