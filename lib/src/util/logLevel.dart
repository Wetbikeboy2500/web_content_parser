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