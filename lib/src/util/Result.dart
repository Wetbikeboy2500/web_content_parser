import './ResultStatus.dart';

///Wraps result data to determine if it can be trusted
///
///Can call [pass] or [fail] for shortcuts on the status
///If data is passing, it can be trusted to be the correct data type and results
class Result<T> {
  ///Status of whatever fetch was made. [FetchStatus.pass] or [FetchStatus.fail]
  final ResultStatus status;

  ///Data this class wraps around
  final T? data;

  ///Passing fetch
  ///
  ///[status] is set to [FetchStatus.pass]
  const Result.pass(T this.data) : status = ResultStatus.pass;

  ///Failing fetch
  ///
  ///[status] is set to [FetchStatus.fail]
  ///[data] is set to null
  const Result.fail()
      : status = ResultStatus.fail,
        data = null;

  ///Is [status] [FetchStatus.pass]
  bool get pass => ResultStatus.pass == status;

  ///Is [status] [FetchStatus.fail]
  bool get fail => ResultStatus.fail == status;
}
