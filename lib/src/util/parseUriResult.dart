
extension UriResult on Uri {
  static Result<Uri> parse(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return const Fail();
    }

    return Pass(uri);
  }
}