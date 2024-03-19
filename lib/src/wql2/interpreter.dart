import 'statements/statement.dart';

class Interpreter {
  final Map<String, dynamic> functions;

  Interpreter(this.functions);

  //These keep track of context _values
  final List<Map<String, ({dynamic current, bool hasPrevious, dynamic previous})>> _contextStack = [];
  final Map<String, dynamic> _values = {};

  Map<String, dynamic> get values => _values;

  void setValue(String name, dynamic value) {
    if (name == '^') {
      assert(value is Map<String, dynamic>);
      _values.removeWhere((key, value) => !key.startsWith('_'));
      _values.addAll(value);
      return;
    } else if (name.startsWith('_')) {
      assert(_contextStack.isNotEmpty);
      bool hasPrevious = false;
      dynamic previous;

      if (_values.containsKey(name) && !_contextStack.last.containsKey(name)) {
        hasPrevious = true;
        previous = _values[name];
      }

      _contextStack.last[name] = (current: value, hasPrevious: hasPrevious, previous: previous);
    }

    _values[name] = value;
  }

  dynamic getValue(String name) => _values[name];

  void pushLocalContext() => _contextStack.add({});

  void popLocalContext() {
    for (final stackValue in _contextStack.last.entries) {
      if (stackValue.value.hasPrevious) {
        _values[stackValue.key] = stackValue.value.previous;
      } else {
        _values.remove(stackValue.key);
      }
    }

    _contextStack.removeLast();
  }

  Future<({bool noop})> runStatements(List<Statement> statements, Map<String, dynamic> context) async {
    pushLocalContext();
    for (final entry in context.entries) {
      setValue(entry.key, entry.value);
    }
    await runStatementsWithContext(statements, values, false);
    popLocalContext();
    return const (noop: false);
  }

  Future<({bool noop})> runStatementsWithContext(List<Statement> statements, dynamic context, bool allowNoopEscape) async {
    pushLocalContext();
    for (final statement in statements) {
      final result = await statement.execute(context, this);
      if (result.noop && allowNoopEscape) {
        popLocalContext();
        return const (noop: true);
      }
    }
    popLocalContext();
    return const (noop: false);
  }
}