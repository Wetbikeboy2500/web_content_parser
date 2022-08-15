// ignore_for_file: avoid_print

import '../../web_content_parser.dart';

//TODO: switch to an advanced enum
class LogLevel {
  final int level;
  const LogLevel._(this.level);

  /// Indicates don't log anything. Depends on implementation detail
  const LogLevel.silent() : this._(-1);
  /// Debug information that is only useful for developers
  const LogLevel.debug() : this._(0);
  /// Important information to be logged which can indicate execution path
  const LogLevel.info() : this._(1);
  /// For warnings that come from checks that avoid errors
  const LogLevel.warn() : this._(2);
  /// For errors that are caught and not expected
  const LogLevel.error() : this._(3);
}

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
