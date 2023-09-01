import 'Result.dart';
import 'log.dart';

///Useful helps for when dealing with different result outcomes
///
///These are put into there own extension namespace since these may not be agnostic for design
///Some of these call will log issues to console to find errors
extension ResultExtended<T> on Result<T> {
  ///Determines if a result fails when an error is throw
  ///
  ///[unsafeFunction] is executed
  ///[errorMessage] leading text for the error message sent to the log
  static Result<T> unsafe<T>(T Function() unsafeFunction, {String errorMessage = ''}) {
    try {
      return Result.pass(unsafeFunction());
    } catch (e, stack) {
      log2(errorMessage, e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }

  ///Determines if a result fails when an error is throw
  ///
  ///[unsafeFunction] is executed and awaited for
  ///[errorMessage] leading text for the error message sent to the log
  static Future<Result<T>> unsafeAsync<T>(Future<T> Function() unsafeFunction, {String errorMessage = ''}) async {
    try {
      return Result.pass(await unsafeFunction());
    } catch (e, stack) {
      log2(errorMessage, e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Result.fail();
    }
  }

  static Map<String, dynamic> toJson(Result result) {
    return {
      'data': result.data,
      'pass': result.pass,
      'fail': result.fail,
    };
  }

  static Result<T> fromJson<T>(Map<String, dynamic> json) {
    if (json['pass'] == true) {
      return Result.pass(json['data'] as T);
    } else {
      return const Result.fail();
    }
  }
}
