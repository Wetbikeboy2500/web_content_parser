
import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/src/wql/statements/runStatement.dart';

import '../suboperations/logicalSelector.dart';
import '../statements/selectStatement.dart';
import '../statements/setStatement.dart';

/// Tokenized a string into a list of tokens.
/// This defines the grammar of the language as well.
List parseAndTokenize(String input) {
  //Do not allow commas or semicolons or colons or periods for value matcher
  final valueMatcher = patternIgnoreCase('~!@\$%&*()_+=/\'"?><[]{}|`#a-z0-9') | char('-') | char('^');

  //allow any character except for the ' in the string since it is the terminating character
  final valueStringMatcher = (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

  final name = letter().plus().flatten().trim() | char('*').trim();

  final define = stringIgnoreCase('define').trim().token();

  final type = stringIgnoreCase('string').trim().token() |
      stringIgnoreCase('int').trim().token() |
      stringIgnoreCase('bool').trim().token();

  final queryDefine = define & name & type & (valueStringMatcher | (valueMatcher).plus().flatten().trim());

  final conditional = undefined();

  final allQueries = ((SelectStatement.getParser() |
              queryDefine |
              SetStatement.getParser() |
              RunStatement.getParser() |
              conditional) &
          char(';').token().trim())
      .pick(0)
      .star();

  final conditionalQuery = stringIgnoreCase('if').trim().token() &
      LogicalSelector.getParser() &
      char(':').trim().token() &
      allQueries &
      (stringIgnoreCase('else:').trim().token() & allQueries).optional() &
      stringIgnoreCase('endif').trim().token();

  conditional.set(conditionalQuery);

  final parsed = allQueries.parse(input);

  if (parsed.isFailure) {
    return const [];
  }

  return parsed.value;
}