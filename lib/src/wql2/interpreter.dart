import 'statements/statement.dart';

class Interpreter {
  final Map<String, dynamic> functions;

  Interpreter(this.functions);

  final Map<String, dynamic> _values = {};

  Map<String, dynamic> _currentStackCached = {};

  void _recomputeStackCache() {
    if (localStack.isEmpty) {
      _currentStackCached = _values;
      return;
    }

    if (localStack.length == 1) {
      _currentStackCached = {
        ..._values,
        ...localStack.first
      };
      return;
    }

    _currentStackCached = {
      ..._values,
      ...localStack.reduce((value, element) => {...value, ...element})
    };
  }

  Map<String, dynamic> get values => _currentStackCached;

  void setValues(Map<String, dynamic> values) {
    _values.addAll(values);
    _recomputeStackCache();
  }

  void setValue(String name, dynamic value) {
    if (name.startsWith('_') && localStack.isNotEmpty) {
      localStack.last[name] = value;
      _recomputeStackCache();
      return;
    }

    _values[name] = value;
    _recomputeStackCache();
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
    _recomputeStackCache();
  }

  Future<({bool noop})> runStatements(List<Statement> statements) async {
    return runStatementsWithContext(statements, values);
  }

  Future<({bool noop})> runStatementsWithContext(List<Statement> statements, dynamic context) async {
    pushLocal();
    for (final statement in statements) {
      final result = await statement.execute(context, this);
      if (result.noop) {
        popLocal();
        return const (noop: true);
      }
    }
    popLocal();
    return const (noop: false);
  }
}