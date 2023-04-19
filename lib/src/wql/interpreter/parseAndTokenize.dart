
import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/src/wql/statements/runStatement.dart';

import '../suboperations/logicalSelector.dart';
import '../statements/selectStatement.dart';
import '../statements/setStatement.dart';

import '../parserHelper.dart' as helpers;

/// Tokenized a string into a list of tokens.
/// This defines the grammar of the language as well.
List parseAndTokenize(String input) {
  final conditionalStatement = undefined();
  final loopStatement = undefined();

  final allStatements = (
    SetStatement.getParser() |
    SelectStatement.getParser() |
    RunStatement.getParser() |
    conditionalStatement |
    loopStatement);

  final allListStatements = (allStatements & char(';').token().trim())
      .pick(0)
      .star();

  final conditionalQuery = stringIgnoreCase('if').trim().token() &
      LogicalSelector.getParser() &
      char(':').trim().token() &
      allListStatements &
      (stringIgnoreCase('else:').trim().token() & allListStatements).optional() &
      stringIgnoreCase('endif').trim().token();

  final loopQuery = stringIgnoreCase('loop').trim().token() &
      helpers.input &
      char(':').trim().token() &
      allListStatements &
      stringIgnoreCase('endloop').trim().token();

  conditionalStatement.set(conditionalQuery);
  loopStatement.set(loopQuery);

  final parsed = allListStatements.parse(input);

  if (parsed.isFailure) {
    return const [];
  }

  return parsed.value;
}