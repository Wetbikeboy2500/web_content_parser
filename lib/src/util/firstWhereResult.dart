import 'Result.dart';

extension ResultReturns<T> on Iterable<T> {
  Result<T> firstWhereResult(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return Result<T>.pass(element);
    }
    return const Result.fail();
  }
}