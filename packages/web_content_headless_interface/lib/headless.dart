import '../../util/Result.dart';

abstract class Headless {
  bool get isSupported => false;

  /// Returns the HTML of the page at the given [url].
  /// If [id] is provided, any cached data will be associated with it.
  Future<Result<String>> getHtml(String url, String? id);

  /// Returns the cookies for the page at the given [url].
  Future<Result<Map<String, String>>> getCookiesForUrl(String url);

  /// Returns the cookies for the page with the given [id].
  Future<Result<Map<String, String>>> getCookiesForId(String id);
}