import 'Result.dart';
import 'log.dart';

///Useful helps for when dealing with different result outcomes
///
///These are put into there own extension namespace since these may not be agnostic for design
///Some of these call will log issues to console to find errors
extension ResultExtended<T> on Result<T> {

  ///Determines if a result fails when an error is throw
  ///
  ///[unsafeFunction] function ran when
  static Result<T> unsafe<T>(T Function() unsafeFunction, {String errorMessage = ''}) {
    try {
      return Result.pass(unsafeFunction());
    } catch (e, stack) {
      log('$errorMessage:$e');
      log(stack);
      return const Result.fail();
    }
  }

  static Future<Result<T>> unsafeAsync<T>(Future<T> Function() unsafeFunction, {String errorMessage = ''}) async {
    try {
      return Result.pass(await unsafeFunction());
    } catch (e, stack) {
      log('$errorMessage:$e');
      log(stack);
      return const Result.fail();
    }
  }
}