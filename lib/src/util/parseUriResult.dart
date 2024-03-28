import 'package:web_query_framework_util/util.dart';

extension UriResult on Uri {
  static Result<Uri> parse(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return const Fail();
    }

    return Pass(uri);
  }
}