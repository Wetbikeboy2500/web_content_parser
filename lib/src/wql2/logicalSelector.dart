import 'package:petitparser/petitparser.dart';
import './interpreter.dart';
import 'dot_input/dot_input.dart';

class LogicalSelector {
  final List tokens;

  const LogicalSelector(this.tokens);

  Future<({bool result, bool noop})> evaluate(dynamic context, Interpreter interpreter) async {
    Future<({bool noop, bool result})> _eval(List value) async {
      value[1] = (value[1] is Token) ? (value[1] as Token).value : value[1];

      if (value[1] != 'or' && value[1] != 'and') {
        final first = DotInput.fromTokens(value[0]);
        final second = DotInput.fromTokens(value[2]);

        late final dynamic firstValue;
        late final dynamic secondValue;

        final (result: dynamic firstResult, wasExpanded: bool firstWasExpanded, noop: bool firstNoop, name: _) = await first.execute(context, interpreter);

        if (firstNoop) {
          return const (result: false, noop: true);
        }

        assert(firstWasExpanded == false || firstResult is List, 'First result was expanded but not a list');

        firstValue = (firstWasExpanded) ? firstResult.first : firstResult;

        final (result: dynamic secondResult, wasExpanded: bool secondWasExpanded, noop: bool secondNoop, name: _) = await second.execute(context, interpreter);

        if (secondNoop) {
          return const (result: false, noop: true);
        }

        assert(secondWasExpanded == false || secondResult is List, 'Second result was expanded but not a list');

        secondValue = (secondWasExpanded) ? secondResult.first : secondResult;

        return switch(value[1].toLowerCase()) {
          'matches' => (result: firstValue.querySelector(secondValue) != null, noop: false),
          'contains' => (result: firstValue.contains(secondValue) as bool, noop: false),
          'startswith' => (result: firstValue.startsWith(secondValue) as bool, noop: false),
          'endswith' => (result: firstValue.endsWith(secondValue) as bool, noop: false),
          'equals' => (result: firstValue == secondValue, noop: false),
          _ => const (result: false, noop: false),
        };
      }

      if (value[1].toLowerCase() == 'or') {
        final (result: bool first, noop: bool firstNoop) = await _eval(value[0]);

        if (firstNoop) {
          return const (result: false, noop: true);
        }

        if (first) {
          return (result: true, noop: false);
        }

        final (result: bool second, noop: bool secondNoop) = await _eval(value[2]);

        if (secondNoop) {
          return const (result: false, noop: true);
        }

        return (result: first || second, noop: false);
      }

      if (value[1].toLowerCase() == 'and') {
        final (result: bool first, noop: bool firstNoop) = await _eval(value[0]);

        if (firstNoop) {
          return const (result: false, noop: true);
        }

        if (!first) {
          return const (result: false, noop: false);
        }

        final (result: bool second, noop: bool secondNoop) = await _eval(value[2]);

        if (secondNoop) {
          return const (result: false, noop: true);
        }

        return (result: first && second, noop: false);
      }

      throw Exception('Unknown operator: ${value[1]}');
    }

    return _eval(tokens);
  }
}
