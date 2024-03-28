///Base class for all results
sealed class Result<T> {
  const Result();
}

///Passing result
///
///Check for this using `is Pass` or `case Pass<T>()`
///[data] is the data passing result data
class Pass<T> extends Result<T> {
  final T data;

  const Pass(this.data);
}

///Failing result
///
///Check for this using `is Fail` or `case Fail<T>()`
class Fail<T> extends Result<T> {
  const Fail();
}