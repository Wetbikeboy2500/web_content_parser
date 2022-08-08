import '../suboperations/logicalSelector.dart';
import '../interpreter/interpreter.dart';
import '../interpreter/parseStatements.dart';
import 'statement.dart';

class ConditionalStatement extends Statement {
  final List<Statement> truthful;
  final List<Statement>? falsy;
  final LogicalSelector conditional;

  const ConditionalStatement(this.truthful, this.falsy, this.conditional);

  factory ConditionalStatement.fromTokens(List tokens) {
    final conditional = LogicalSelector(tokens[1]);

    final List<Statement> truthful = parseStatements(tokens[3]);

    List<Statement>? falsy;

    if (tokens[4] != null) {
      falsy = parseStatements(tokens[4][1]);
    }

    return ConditionalStatement(truthful, falsy, conditional);
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    if (conditional.evaluate(interpreter.values, interpreter)) {
      for (final Statement statement in truthful) {
        await statement.execute(interpreter);
      }
    } else if (falsy != null) {
      for (final Statement statement in falsy!) {
        await statement.execute(interpreter);
      }
    }
  }
}
