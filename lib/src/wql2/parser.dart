import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/src/wql2/dot_input/dot_input.dart';
import 'package:web_content_parser/src/wql2/statements/set_statement.dart';

import 'logicalSelector.dart';
import 'statements/if_statement.dart';

void main() {
  // String input = '''getRequest(s'https://github.com/topics').if{*.getStatusCode() EQUALS n'200'}''';
  String input = '''
      if (a equals s'1') {

      }''';
  /* String input = '''
      result = getRequest(s'https://github.com/topics')
      .if{*.getStatusCode() EQUALS n'200'} else {}
      .parseBody().querySelectorAll(s'.py-4.border-bottom')[].select{
        name: *.querySelector(s'.f3').text().trim(),
        description: *.querySelector(s'.f5').text().trim(),
        url: joinUrl(s'https://github.com', *.querySelector(s'a').attribute(s'href'))
      };

      result = select {
        name: *.querySelector(s'.f3').text().trim(),
        description: *.querySelector(s'.f5').text().trim(),
        url: joinUrl(s'https://github.com', *.querySelector(s'a').attribute(s'href'))
      } from {
        getRequest(s'https://github.com/topics')
        .if{ *.getStatusCode() EQUALS n'200' }
      };'''; */

  //don't allow square brackets, round brackets, curly brackets, semi-colon, colon, and comma
  final safeChars = patternIgnoreCase('~!@\$%&*_+=/\'"?><|`#a-zA-Z0-9') | char('-') | char('^');

  final access = safeChars.plus().flatten().trim();

  final rawInputSingleQuote = (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

  final arrayIndex =
      (stringIgnoreCase('first') | stringIgnoreCase('last')).token().trim() |
      (char('-').optional() & digit().plus().flatten()).flatten().trim();

  final arrayAccess =
      (stringIgnoreCase('all') | stringIgnoreCase('even') | stringIgnoreCase('odd')).token().trim() |
      (arrayIndex & char(':').trim() & arrayIndex & char(':').trim() & digit().star().flatten().trim()) |
      (arrayIndex & char(':').trim() & arrayIndex) |
      arrayIndex;

  final digitInput = (char('[').trim() & (arrayAccess.plusSeparated(char(',').trim())).optional() & char(']').trim()).pick(1);

  final completeParser = undefined();
  final dotInput = undefined();

  final terms = dotInput & (stringIgnoreCase('matches') | stringIgnoreCase('contains') | stringIgnoreCase('startsWith') | stringIgnoreCase('endsWith') | stringIgnoreCase('equals')).token().trim() & dotInput;

  final logicalOperation = undefined();
  final andClause = undefined();
  final parenClause = undefined();

  final or = (andClause & stringIgnoreCase('or').token().trim() & logicalOperation);
  logicalOperation.set(or | andClause);

  final and = (parenClause & stringIgnoreCase('and').token().trim() & andClause);
  andClause.set(and | parenClause);

  final paren = (char('(').trim() & logicalOperation & char(')').trim()).map((values) => values[1]);
  parenClause.set(paren | terms);

  final literal = (char('l') | char('s') | char('b') | char('n')).token() & rawInputSingleQuote.trim();

  final function = letter().plus().flatten().trim() & (char('(').trim() & dotInput.plusSeparated(char(',').trim()).optional() & char(')').trim()).pick(1);

  final selectStatement = stringIgnoreCase('select').token().trim() & (char('{').trim() & ((access & char(':').token().trim()).optional() & dotInput).plusSeparated(char(',').trim()) & char('}').trim()).pick(1) & (stringIgnoreCase('from').trim() & char('{').trim() & dotInput & char('}').trim()).pick(2).optional();

  final ifStatement = stringIgnoreCase('if').token().trim()
    & (char('{').trim() & logicalOperation & char('}').trim()).pick(1)
    & (stringIgnoreCase('else').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1)).optional();

  final loopStatement = stringIgnoreCase('loop').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1);

  final evalStatement = stringIgnoreCase('eval').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1);

  final statements = selectStatement | ifStatement | loopStatement | evalStatement;

  dotInput.set(literal | ((statements | function | access) & digitInput.optional()).plusSeparated(char('.').trim()));

  completeParser.set((
    (access & char('=').token().trim() & dotInput)
    | stringIgnoreCase('if').token().trim()
      & (char('(').trim() & logicalOperation & char(')').trim()).pick(1)
      & (char('{').trim() & completeParser & char('}').trim()).pick(1)
      & (stringIgnoreCase('else').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1)).optional()
    | dotInput
  ).optional().plusSeparated(char(';').trim()));

  final parsed = completeParser.parse(input);

  switch (parsed) {
    case Success(value: final value):
      // print('Success: $value');
      parseToObjects(value);
    case Failure(message: final message, position: final position):
      print('Failure at $position: $message');
  }
}

List<Object> parseToObjects(SeparatedList baseList) {
  final List<Object> items = [];

  for (final element in baseList.elements) {
    if (element == null) {
      continue;
    }

    switch (element) {
      case [final String access, final Token equals, final SeparatedList value]:
        assert(equals.value == '=');
        items.add(SetStatement(access, DotInput.fromTokens(value)));
        break;
      case [final Token ifToken, final List logicalOperation, final SeparatedList body, final List? elseList]:
        assert(ifToken.value == 'if');

        List<Object>? elseBodyStatements;

        if (elseList case [Token(), final SeparatedList elseBody]) {
          elseBodyStatements = parseToObjects(elseBody);
        }

        items.add(IfStatement(LogicalSelector(logicalOperation), true, parseToObjects(body), elseBodyStatements));

        break;
      case final SeparatedList elements:
        items.add(DotInput.fromTokens(elements));
        break;
    }
  }
    return items;
}