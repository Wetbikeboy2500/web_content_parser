import 'package:web_query_framework_util/util.dart';

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
      return Pass(unsafeFunction());
    } catch (e, stack) {
      log2(errorMessage, e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Fail();
    }
  }

  ///Determines if a result fails when an error is throw
  ///
  ///[unsafeFunction] is executed and awaited for
  ///[errorMessage] leading text for the error message sent to the log
  static Future<Result<T>> unsafeAsync<T>(Future<T> Function() unsafeFunction, {String errorMessage = ''}) async {
    try {
      return Pass(await unsafeFunction());
    } catch (e, stack) {
      log2(errorMessage, e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
      return const Fail();
    }
  }

  static Map<String, dynamic> toJson(Result result) {
    if (result is Pass) {
      return {
        'pass': true,
        'fail': false,
        'data': result.data,
      };
    } else {
      return {
        'pass': false,
        'fail': true,
        'data': null,
      };
    }
  }

  static Result<T> fromJson<T>(Map<String, dynamic> json) {
    if (json['pass'] == true) {
      return Pass(json['data'] as T);
    } else {
      return const Fail();
    }
  }
}
