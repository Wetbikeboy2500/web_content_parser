// ignore_for_file: avoid_print

import '../../web_content_parser.dart';

///Logs info for the app based on if the package should be verbose
void log(Object? object) {
  if (WebContentParser.verbose) {
    print(object);
  }
}

void log2(Object? object, Object? object2) {
  if (WebContentParser.verbose) {
    print('$object$object2');
  }
}

void log3(Object? object, Object? object2, Object? object3) {
  if (WebContentParser.verbose) {
    print('$object$object2$object3');
  }
}