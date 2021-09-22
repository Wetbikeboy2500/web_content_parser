// ignore_for_file: avoid_print

import '../../web_content_parser.dart';

///Logs info for the app based on if the package should be verbose
void log(Object? object) {
  if (WebContentParser.verbose) {
    print(object);
  }
}
