import 'dart:math';

import '../dot_input/dot_input.dart';
import '../interpreter.dart';
import 'statement.dart';

class SelectStatement extends Statement {
  final List<(String? name, DotInput input)> select;
  final DotInput? from;

  const SelectStatement(this.select, this.from);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    bool isCollection = false;

    if (from != null) {
      final result = await from!.execute(context, interpreter);
      if (result.noop) {
        return const (name: '', result: null, wasExpanded: false, noop: true);
      }
      context = result.result;
      isCollection = result.wasExpanded;
    }

    final List<Map<String, dynamic>> results = [];

    if (isCollection) {
      for (final newContext in context) {
        results.addAll(await _parseContext(newContext, interpreter));
      }
    } else {
      _parseContext(context, interpreter);
    }

    return (name: '', result: results, wasExpanded: false, noop: false);
  }

  Future<List<Map<String, dynamic>>> _parseContext(context, interpreter) async {
    final List<(String?, bool, bool, dynamic)> results = [];
    int maxLength = 1;

    for (final (name, input) in select) {
      final result = await input.execute(context, interpreter);
      if (result.wasExpanded && !result.noop) {
        maxLength = max(result.result.length, maxLength);
      }

      results.add((name ?? result.name, result.wasExpanded, result.noop, result));
    }

    final List<Map<String, dynamic>> resultsMap = [];

    for (int i = 0; i < maxLength; i++) {
      final Map<String, dynamic> values = {};
      for (final result in results) {
        switch (result) {
          case (final String? name, true, final bool noop, final dynamic value):
            if (noop) {
              continue;
            }

            if (name != null && name.isNotEmpty) {
              values[name] = value;
            } else if (i < value.length) {
              values[''] = value[i];
            }
            break;
          case (final String? name, false, final bool noop, final dynamic value):
            if (noop) {
              continue;
            }

            values[name ?? ''] = value;
            break;
        }
      }
      resultsMap.add(values);
    }

    return resultsMap;
  }
}