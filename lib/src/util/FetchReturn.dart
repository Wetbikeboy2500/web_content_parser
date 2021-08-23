import './FetchStatus.dart';

///Wraps result data to determine if it can be trusted
///
///Can call [pass] or [fail] for shortcuts on the status
///If data is passing, it can be trusted to be the correct data type and results
class FetchReturn<T1> {
  ///Status of whatever fetch was made. [FetchStatus.pass] or [FetchStatus.fail]
  final FetchStatus status;
  ///Data this class wraps around
  final T1? data;

  ///Passing fetch
  ///
  ///[status] is set to [FetchStatus.pass]
  FetchReturn.pass(this.data) : status = FetchStatus.pass;

  ///Failing fetch
  ///
  ///[status] is set to [FetchStatus.fail]
  ///[data] is set to null
  const FetchReturn.fail() : status = FetchStatus.fail, data = null;

  ///Is [status] [FetchStatus.pass]
  bool get pass => FetchStatus.pass == status;
  ///Is [status] [FetchStatus.fail]
  bool get fail => FetchStatus.fail == status;
}
