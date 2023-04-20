import '../statements/statement.dart';

class Interpreter {
  final Map<String, dynamic> _values = {};

  Map<String, dynamic> get values => _values;

  void setValues(Map<String, dynamic> values) {
    _values.addAll(values);
  }

  void setValue(String name, dynamic value) {
    if (name.startsWith('_') && localStack.isNotEmpty) {
      localStack.last[name] = value;
      return;
    }

    _values[name] = value;
  }

  dynamic getValue(String name) {
    if (name.startsWith('_') && localStack.isNotEmpty) {
      for (int i = localStack.length - 1; i >= 0; i--) {
        if (localStack[i].containsKey(name)) {
          return localStack[i][name];
        }
      }
    }

    return _values[name];
  }

  final List<Map<String, dynamic>> localStack = [];

  void pushLocal() {
    localStack.add({});
  }

  void popLocal() {
    localStack.removeLast();
  }

  Future<void> runStatements(List<Statement> statements) async {
    for (var statement in statements) {
      await statement.execute(this, values);
    }
  }
}