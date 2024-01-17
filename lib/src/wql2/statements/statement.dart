import '../interpreter.dart';

typedef StatementReturn = Future<({String name, dynamic result, bool wasExpanded, bool noop})>;

abstract class Statement {
  StatementReturn execute(dynamic context, Interpreter interpreter);
}