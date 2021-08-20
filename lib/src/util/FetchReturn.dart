import 'package:web_content_parser/src/util/FetchStatus.dart';

///Wraps result data to determine if it can be trusted
///
///[status] FetchStatus.PASS or FetchStatus.ERROR
///[data] data this wraps around
///
///Can call [pass] or [fail] for shortcuts on the status
///If data is passing, it can be trusted to be the correct data type and results
class FetchReturn<T1> {
  final FetchStatus status;
  final T1? data;

  FetchReturn({required this.status, this.data});

  bool get pass => FetchStatus.PASS == status;
  bool get fail => FetchStatus.ERROR == status;
}