// ignore_for_file: avoid_print

import '../../web_content_parser.dart';

export 'logLevel.dart';

///Log one object
void log(Object? object, {level = const LogLevel.debug()}) {
  if (WebContentParser.verbose.level != const LogLevel.silent().level && level.level >= WebContentParser.verbose.level) {
    print(object);
  }
}

///Log two objects
void log2(Object? object, Object? object2, {level = const LogLevel.debug()}) {
  if (WebContentParser.verbose.level != const LogLevel.silent().level && level.level >= WebContentParser.verbose.level) {
    print('$object$object2');
  }
}

///Log three objects
void log3(Object? object, Object? object2, Object? object3, {level = const LogLevel.debug()}) {
  if (WebContentParser.verbose.level != const LogLevel.silent().level && level.level >= WebContentParser.verbose.level) {
    print('$object$object2$object3');
  }
}
