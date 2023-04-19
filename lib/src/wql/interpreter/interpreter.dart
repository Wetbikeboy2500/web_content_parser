import '../statements/statement.dart';

class Interpreter {
  final Map<String, dynamic> _values = {};

  Map<String, dynamic> get values => _values;

  void setValues(Map<String, dynamic> values) {
    _values.addAll(values);
  }

  void setValue(String name, dynamic value) {
    _values[name] = value;
  }

  dynamic getValue(String name) {
    return _values[name];
  }

  Future<void> runStatements(List<Statement> statements) async {
    for (var statement in statements) {
      await statement.execute(this, values);
    }
  }
}