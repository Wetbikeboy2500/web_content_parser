import 'Result.dart';

extension ResultReturns<T> on Iterable<T> {
  ///Finds the first element that passes [test]
  ///
  ///Instead of returning null or throwing and error, [Result] will be failed indicating if the search passed or failed.
  Result<T> firstWhereResult(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return Result<T>.pass(element);
    }
    return const Result.fail();
  }
}