import 'package:web_content_parser/src/wql/interpreter/interpreter.dart';

import 'interpreter/parseAndTokenize.dart';
import 'interpreter/parseStatements.dart';

Future<Map<String, dynamic>> runWQL(String code, {Map<String, dynamic> parameters = const {}}) async {
  final Interpreter interpreter = Interpreter();
  interpreter.setValues(parameters);
  await interpreter.runStatements(parseStatements(parseAndTokenize(code)));
  return interpreter.values;
}
