import 'dart:io';

import '../util/Result.dart';
import 'interpreter/interpreter.dart';
import 'interpreter/parseAndTokenize.dart';
import 'interpreter/parseStatements.dart';

Future<Result<Map<String, dynamic>>> runWQL(String code,
    {Map<String, dynamic> parameters = const {}, bool throwErrors = false}) async {
  final Interpreter interpreter = Interpreter();
  interpreter.setValues(parameters);
  try {
    await interpreter.runStatements(parseStatements(parseAndTokenize(code)));
  } catch (e) {
    if (throwErrors) {
      rethrow;
    }
    return const Result.fail();
  }
  return Result.pass(interpreter.values);
}
