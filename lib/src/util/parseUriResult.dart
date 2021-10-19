import 'Result.dart';

extension UriResult on Uri {
  static Result<Uri> parse(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return const Result.fail();
    }

    return Result.pass(uri);
  }
}