import 'package:petitparser/petitparser.dart';

import '../scraper/wql/wqlFunctions.dart';
import 'dot_input/dot_input.dart';
import 'statements/if_statement.dart';
import 'statements/set_statement.dart';
import 'statements/statement.dart';

void main() {
  loadWQLFunctions();
  String input = '''
      result = s'hello';

      *;

      if (result.equals(s'1')) {

      };

      result = getRequest(s'https://github.com/topics')[];
      result = getRequest(s'https://github.com/topics')[all,1];
      result = getRequest(s'https://github.com/topics')[1:-1];
      result = getRequest(s'https://github.com/topics')[1:1:1];
      result = getRequest(s'https://github.com/topics')[1:last:1];

      result = name;

      result = getRequest(s'https://github.com/topics')
      .if{*.getStatusCode().equals(n'200')} else {}
      .if{*.getStatusCode().equals(n'200')}
      .parseBody().querySelectorAll(s'.py-4.border-bottom')[].select{
        name: *.querySelector(s'.f3').text().trim(),
        description: *.querySelector(s'.f5').text().trim(),
        url: joinUrl(s'https://github.com', *.querySelector(s'a').attribute(s'href'))
      }.loop{}.eval{};

      result = select {
        name: *.querySelector(s'.f3').text().trim(),
        description: *.querySelector(s'.f5').text().trim(),
        url: joinUrl(s'https://github.com', *.querySelector(s'a').attribute(s'href'))
      } from {
        getRequest(s'https://github.com/topics')
        .if{ *.getStatusCode().equals(n'200') }
      };''';

  // TODO: add ? to allow null when a noop occurs from a statement

  //don't allow square brackets, round brackets, curly brackets, semi-colon, colon, and comma
  final safeChars = patternIgnoreCase('~!@\$%&*_+=/\'"?><|`#a-zA-Z0-9') | char('-') | char('^');

  final access = safeChars.plus().flatten().trim();

  final rawInputSingleQuote = (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

  final arrayIndex = (stringIgnoreCase('first') | stringIgnoreCase('last')).token().trim() |
      (char('-').optional() & digit().plus().flatten()).flatten().trim();

  final arrayAccess = (stringIgnoreCase('all') | stringIgnoreCase('even') | stringIgnoreCase('odd')).token().trim() |
      (arrayIndex & char(':').trim() & arrayIndex & char(':').trim() & digit().star().flatten().trim()) |
      (arrayIndex & char(':').trim() & arrayIndex) |
      arrayIndex;

  final digitInput =
      (char('[').trim() & (arrayAccess.plusSeparated(char(',').trim())).optional() & char(']').trim()).map((value) => value[1] ?? SeparatedList([], []));

  final completeParser = undefined();
  final dotInput = undefined();

  final literal = (char('l') | char('s') | char('b') | char('n')).token() & rawInputSingleQuote.trim();

  final function = letter().plus().flatten().trim() &
      (char('(').trim() & dotInput.plusSeparated(char(',').trim()).optional() & char(')').trim()).pick(1);

  final selectStatement = stringIgnoreCase('select').token().trim() &
      (char('{').trim() &
              ((access & char(':').token().trim()).optional() & dotInput).plusSeparated(char(',').trim()) &
              char('}').trim())
          .pick(1) &
      (stringIgnoreCase('from').trim() & char('{').trim() & dotInput & char('}').trim()).pick(2).optional();

  final ifStatement = stringIgnoreCase('if').token().trim() &
      (char('{').trim() & dotInput & char('}').trim()).pick(1) &
      (stringIgnoreCase('else').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1))
          .optional();

  final loopStatement =
      stringIgnoreCase('loop').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1);

  final evalStatement =
      stringIgnoreCase('eval').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1);

  final statements = selectStatement | ifStatement | loopStatement | evalStatement;

  dotInput.set(literal | ((statements | function | access) & digitInput.optional()).plusSeparated(char('.').trim()));

  completeParser.set(((access & char('=').token().trim() & dotInput) |
          stringIgnoreCase('if').token().trim() &
              (char('(').trim() & dotInput & char(')').trim()).pick(1) &
              (char('{').trim() & completeParser & char('}').trim()).pick(1) &
              (stringIgnoreCase('else').token().trim() & (char('{').trim() & completeParser & char('}').trim()).pick(1))
                  .optional() |
          dotInput)
      .optional()
      .plusSeparated(char(';').trim()));

  final parsed = completeParser.parse(input);

  switch (parsed) {
    case Success(value: final value):
      // print('Success: $value');
      parseToObjects(value);
    case Failure(message: final message, position: final position):
      print('Failure at $position: $message');
  }
}

List<Statement> parseToObjects(SeparatedList baseList) {
  final List<Statement> items = [];

  for (final element in baseList.elements) {
    if (element == null) {
      continue;
    }

    switch (element) {
      case [final String access, final Token equals, final SeparatedList value]:
        assert(equals.value == '=');
        items.add(SetStatement(access, DotInput.fromTokens(value.elements)));
        break;
      case [final String access, final Token equals, final List value]:
        assert(equals.value == '=');
        items.add(SetStatement(access, DotInput.fromTokens(value)));
        break;
      case [final Token ifToken, final SeparatedList condition, final SeparatedList body, final List? elseList]:
        assert(ifToken.value == 'if');

        List<Statement>? elseBodyStatements;

        if (elseList case [Token(), final SeparatedList elseBody]) {
          elseBodyStatements = parseToObjects(elseBody);
        }

        items.add(
          IfStatement(
            DotInput.fromTokens(condition.elements),
            true,
            parseToObjects(body),
            elseBodyStatements,
          ),
        );

        break;
      case final SeparatedList elements:
        items.add(DotInput.fromTokens(elements.elements));
        break;
      default:
        throw Exception('Invalid operation: $element');
    }
  }
  return items;
}
