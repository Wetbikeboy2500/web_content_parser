import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/src/wql/statements/setStatement.dart';
import './interpreter.dart';
import 'dot_input/dot_input.dart';

class LogicalSelector {
  final List tokens;

  const LogicalSelector(this.tokens);

  Future<bool> evaluate(dynamic context, Interpreter interpreter) async {
    Future<bool> _eval(List value) async {
      value[1] = (value[1] is Token) ? (value[1] as Token).value : value[1];

      if (value[1] != 'or' && value[1] != 'and') {
        final first = DotInput.fromTokens(value[0]);
        final second = DotInput.fromTokens(value[2]);

        final firstValue = (await first.getValue(context, interpreter, custom: SetStatement.functions)).result.value.first;
        final secondValue = (await second.getValue(context, interpreter, custom: SetStatement.functions)).result.value.first;

        switch(value[1].toLowerCase()) {
          case 'matches':
            return firstValue.querySelector(secondValue) != null;
          case 'contains':
            return firstValue.contains(secondValue);
          case 'startswith':
            return firstValue.startsWith(secondValue);
          case 'endswith':
            return firstValue.endsWith(secondValue);
          case 'equals':
            return firstValue == secondValue;
        }
      }

      if (value[1].toLowerCase() == 'or') {
        final bool first = await _eval(value[0]);
        if (first) {
          return true;
        }
        final bool second = await _eval(value[2]);
        return first || second;
      }

      if (value[1].toLowerCase() == 'and') {
        final bool first = await _eval(value[0]);
        if (!first) {
          return false;
        }
        final bool second = await _eval(value[2]);
        return first && second;
      }

      throw Exception('Unknown operator: ${value[1]}');
    }

    return _eval(tokens);
  }
}
