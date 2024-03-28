import '../util/log.dart';
import 'interpreter/interpreter.dart';
import 'interpreter/parseAndTokenize.dart';
import 'interpreter/parseStatements.dart';

@Deprecated('Use WQL2 instead')
Future<Result<Map<String, dynamic>>> runWQL(String code,
    {Map<String, dynamic> parameters = const {}, bool throwErrors = false, bool verbose = false}) async {
  final Interpreter interpreter = Interpreter();
  interpreter.setValues(parameters);
  try {
    await interpreter.runStatements(parseStatements(parseAndTokenize(code)));
  } catch (e, stack) {
    if (throwErrors) {
      log(stack, level: const LogLevel.error());
      rethrow;
    }
    log(e, level: const LogLevel.error());
    log(stack, level: const LogLevel.debug());
    return const Fail();
  }
  return Pass(interpreter.values);
}
