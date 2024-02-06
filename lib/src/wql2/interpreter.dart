import 'statements/statement.dart';

class Interpreter {
  final Map<String, dynamic> functions;

  Interpreter(this.functions);

  final Map<String, List<(int, dynamic)>> _values = {};

  //TODO: make the cache recompute based on the actual values changed
  Map<String, dynamic>? _cache;

  void _recomputeCache() {
    final Map<String, dynamic> result = {};

    for (final entry in _values.entries) {
      result[entry.key] = entry.value.last.$2;
    }

    _cache = result;
  }

  Map<String, dynamic> get values {
    if (_cache != null) {
      return _cache!;
    }

    _recomputeCache();
    return _cache!;
  }

  void setValue(String name, dynamic value) {
    if (name.startsWith('_') && localStack.isNotEmpty) {
      localStack.last.add(name);
      final stackValue = (localStack.length - 1, value);
      if (_values.containsKey(name)) {
        final List<(int, dynamic)> stack = _values[name]!;
        if (stack.last.$1 == localStack.length - 1) {
          stack[stack.length - 1] = stackValue;
        } else {
          stack.add(stackValue);
        }
      } else {
        _values[name] = [stackValue];
      }
      _recomputeCache();
      return;
    }

    _values[name] = [(0, value)];
    _recomputeCache();
  }

  dynamic getValue(String name) {
    return _values[name]?.last.$2;
  }

  final List<Set<String>> localStack = [];

  void pushLocal() {
    localStack.add({});
  }

  void popLocal() {
    final stackOffset = localStack.length - 1;

    assert(stackOffset != -1);

    if (stackOffset == 0) {
      for (final name in localStack.last) {
        _values.remove(name);
      }
    } else {
      for (final name in localStack.last) {
        final item = _values[name]?.last;

        assert(item != null);
        if (item != null) {
          assert(item.$1 == stackOffset);
          _values[name]!.removeLast();
        }
      }
    }

    localStack.removeLast();
    _recomputeCache();
  }

  Future<({bool noop})> runStatements(List<Statement> statements) async {
    return runStatementsWithContext(statements, values, false);
  }

  Future<({bool noop})> runStatementsWithContext(List<Statement> statements, dynamic context, bool allowNoopEscape) async {
    pushLocal();
    for (final statement in statements) {
      final result = await statement.execute(context, this);
      if (result.noop && allowNoopEscape) {
        popLocal();
        return const (noop: true);
      }
    }
    popLocal();
    return const (noop: false);
  }
}