
import 'sourceBuilder.dart';
import 'statement.dart';

class ConditionalStatement extends Statement {
  final List<Statement> truthful;
  final List<Statement>? falsy;
  final List<String> operand1;
  final List<String> operand2;
  final String operation;

  const ConditionalStatement(this.truthful, this.falsy, this.operand1, this.operand2, this.operation);

  factory ConditionalStatement.fromTokens(List tokens) {
    final List<String> operand1 = List<String>.from(tokens[1][2]);
    final List<String> operand2 = List<String>.from(tokens[3][2]);
    final String operation = tokens[2].value.toLowerCase();

    final List<Statement> truthful = parseStatements(tokens[5]);

    List<Statement>? falsy;

    if (tokens[6] != null) {
      falsy = parseStatements(tokens[6][1]);
    }

    return ConditionalStatement(truthful, falsy, operand1, operand2, operation);
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    //get values
    dynamic currentValue1 = interpreter.getValue(operand1[0]);
    for (final String value in operand1.sublist(1)) {
      if (currentValue1 is Map) {
        currentValue1 = currentValue1[value];
      } else {
        throw Exception('Cannot access a non-map value');
      }
    }
    dynamic currentValue2 = interpreter.getValue(operand2[0]);
    for (final String value in operand2.sublist(1)) {
      if (currentValue2 is Map) {
        currentValue2 = currentValue2[value];
      } else {
        throw Exception('Cannot access a non-map value');
      }
    }

    //check if statement is truthy
    if (operation == 'is') {
      if (currentValue1 == currentValue2) {
        for (final Statement statement in truthful) {
          await statement.execute(interpreter);
        }
      } else if (falsy != null) {
        for (final Statement statement in falsy!) {
          await statement.execute(interpreter);
        }
      }
    } else if (operation == 'is not') {
      if (currentValue1 != currentValue2) {
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
}