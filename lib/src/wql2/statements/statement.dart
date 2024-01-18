import '../interpreter.dart';

/// [result] is a list of values if the statement was expanded
typedef StatementReturn = Future<({String name, dynamic result, bool wasExpanded, bool noop})>;

abstract class Statement {
  StatementReturn execute(dynamic context, Interpreter interpreter);
}