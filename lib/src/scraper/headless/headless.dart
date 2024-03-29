import '../../util/Result.dart';

abstract class Headless {
  bool get isSupported => false;

  Future<Result<String>> getHtml(String url);
}