import 'package:petitparser/petitparser.dart';
import '../parserHelper.dart';
import 'operator.dart';

class LogicalSelector {
  final List tokens;

  const LogicalSelector(this.tokens);

  static Parser getParser() {
    final matches = input & stringIgnoreCase('matches').token().trim() & input;
    final contains = input & stringIgnoreCase('contains').token().trim() & input;
    final startsWith = input & stringIgnoreCase('startsWith').token().trim() & input;
    final endsWith = input & stringIgnoreCase('endsWith').token().trim() & input;
    final equals = input & stringIgnoreCase('equals').token().trim() & input;

    final terms = matches | contains | startsWith | endsWith | equals;

    final term = undefined();
    final andClause = undefined();
    final parenClause = undefined();

    final Parser or = (andClause & stringIgnoreCase('or').token().trim() & term);
    term.set(or | andClause);

    final Parser and = (parenClause & stringIgnoreCase('and').token().trim() & andClause);
    andClause.set(and | parenClause);

    final Parser paren = (char('(').trim() & term & stringIgnoreCase(')').trim()).map((values) => values[1]);
    parenClause.set(paren | terms);

    return term;
  }

  bool evaluate(dynamic context) {
    bool _eval(List value) {
      value[1] = (value[1] is Token) ? (value[1] as Token).value : value[1];

      if (value[1] != 'or' && value[1] != 'and') {
        final first = Operator.fromTokensNoAlias(value[0]);
        final second = Operator.fromTokensNoAlias(value[2]);

        final firstValue = first.getValue(context).value.first;
        final secondValue = second.getValue(context).value.first;

        switch(value[1].toLowerCase()) {
          case 'matches':
            return firstValue.querySelector(secondValue) != null;
          case 'contains':
            return firstValue.contains(secondValue);
          case 'startsWith':
            return firstValue.startsWith(secondValue);
          case 'endsWith':
            return firstValue.endsWith(secondValue);
          case 'equals':
            return firstValue == secondValue;
        }
      }

      if (value[1] == 'or') {
        final bool first = _eval(value[0]);
        if (first) {
          return true;
        }
        final bool second = _eval(value[2]);
        return first || second;
      }

      if (value[1] == 'and') {
        final bool first = _eval(value[0]);
        if (!first) {
          return false;
        }
        final bool second = _eval(value[2]);
        return first && second;
      }

      throw Exception('Unknown operator: ${value[1]}');
    }

    return _eval(tokens);
  }
}
