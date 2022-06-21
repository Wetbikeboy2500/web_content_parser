
import 'package:petitparser/petitparser.dart';

import '../statements/conditionalStatement.dart';
import '../statements/defineStatement.dart';
import '../statements/selectStatement.dart';
import '../statements/setStatement.dart';
import '../statements/statement.dart';

/// Runs all the statements in the list.
/// This will produce a list of statement which can then be run for their different contexts
List<Statement> parseStatements(List tokens) {
  final List<Statement> statements = [];
  for (var value in tokens) {
    //skipping for semicolons
    if (value is Token) {
      continue;
    }

    statements.add(parseStatement(value));
  }
  return statements;
}

Statement parseStatement(List tokens) {
  for (var data in tokens) {
    if (data == null) {
      continue;
    }

    if (data is Token) {
      final String op = (data.value as String).toLowerCase();

      switch (op) {
        case 'define':
          return DefineStatement.fromTokens(tokens);
        case 'select':
          return SelectStatement.fromTokens(tokens);
        case 'set':
          return SetStatement.fromTokens(tokens);
        case 'if':
          return ConditionalStatement.fromTokens(tokens);
      }
    }
  }
  throw Exception('No operation found');
}