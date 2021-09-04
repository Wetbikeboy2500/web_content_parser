// ignore_for_file: avoid_print

import '../../web_content_parser.dart';

void log(Object? object) {
  if (WebContentParser.verbose) {
    print(object);
  }
}
