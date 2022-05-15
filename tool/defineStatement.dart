
import 'sourceBuilder.dart';
import 'statement.dart';

class DefineStatement extends Statement {
  final String name;
  final String type;
  final String value;

  const DefineStatement(this.name, this.type, this.value);

  factory DefineStatement.fromTokens(List tokens) {
    final String name = tokens[1];
    final String type = (tokens[2].value as String).toLowerCase();
    final String value = tokens[3];

    return DefineStatement(name, type, value);
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    dynamic value = this.value;

    switch (type) {
      case 'string':
        value = value.toString();
        break;
      case 'int':
        value = int.parse(value.toString());
        break;
      case 'bool':
        value = value.toString() == 'true';
        break;
      default:
        throw ArgumentError('Unknown type.');
    }

    interpreter.setValue(name, value);
  }
}
