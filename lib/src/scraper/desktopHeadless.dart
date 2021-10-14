import 'package:web_content_parser/src/scraper/headless.dart';

import 'dart:io' show Platform;

import '../util/Result.dart';

class DesktopHeadless extends Headless {
  @override
  bool get isSupported => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  @override
  Future<Result> getHtml() {
    // TODO: implement getHtml
    throw UnimplementedError();
  }

}