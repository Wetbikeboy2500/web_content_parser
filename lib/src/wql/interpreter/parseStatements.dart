
import 'package:petitparser/petitparser.dart';

import '../statements/conditionalStatement.dart';
import '../statements/defineStatement.dart';
import '../statements/packStatement.dart';
import '../statements/selectStatement.dart';
import '../statements/setStatement.dart';
import '../statements/statement.dart';
import '../statements/transformStatement.dart';

/// Runs all the statements in the list.
/// This will produce a list of statement which can then be run for their different contexts
List<Statement> parseStatements(List tokens) {
  print(tokens);
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

    if (data is Token && (data.value as String).toLowerCase() == 'pack') {
      return PackStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'select') {
      return SelectStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'set') {
      return SetStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'if') {
      return ConditionalStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'transform') {
      return TransformStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'define') {
      return DefineStatement.fromTokens(tokens);
    } else {
      throw Exception('No operation found');
    }
  }
  throw Exception('No operation found');
}