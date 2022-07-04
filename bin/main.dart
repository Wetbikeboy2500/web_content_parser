import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/src/wql/parserHelper.dart';

void main(List<String> args) {
  final matches = input & stringIgnoreCase('matches').trim() & input;
  final contains = input & stringIgnoreCase('contains').trim() & input;
  final startsWith = input & stringIgnoreCase('startsWith').trim() & input;
  final endsWith = input & stringIgnoreCase('endsWith').trim() & input;
  final equals = input & stringIgnoreCase('equals').trim() & input;

  // final terms = matches | contains | startsWith | endsWith | equals;

  final terms = letter().plus().flatten().trim();

  final term = undefined();
  final andClause = undefined();
  final parenClause = undefined();

  final Parser or = (andClause & stringIgnoreCase('or').trim() & term);
  term.set(or | andClause);

  final Parser and = (parenClause & stringIgnoreCase('and').trim() & andClause);
  andClause.set(and | parenClause);

  final Parser paren = (char('(').trim() & term & stringIgnoreCase(')').trim()).map((values) => values[1]);;
  parenClause.set(paren | terms);

  final logicalSelector = term.end();

  // final p = logicalSelector.parse('input MATCHES input');
  final ops = [
    'true',
    'false',
    'true and false or true',
    'true or false and true',
    'true and (false or true) and false',
    'true and (false or true) or false',
  ];

  evaluate(dynamic value) {
    if (value is String) {
      //switch this to be terms that are parsed
      return value == 'true';
    }

    if (value[1] == 'or') {
      final bool first = evaluate(value[0]);
      if (first) {
        return true;
      }
      final bool second = evaluate(value[2]);
      return first || second;
    }

    if (value[1] == 'and') {
      final bool first = evaluate(value[0]);
      if (!first) {
        return false;
      }
      final bool second = evaluate(value[2]);
      return first && second;
    }
  }

  //test all ops
  for (final op in ops) {
    final p = logicalSelector.parse(op);
    if (p.isSuccess) {
      print('input: ' + p.value.toString());
      print('output: ' + evaluate(p.value).toString());
    } else {
      print(p.message);
    }
  }
}

