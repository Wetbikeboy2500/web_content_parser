import 'dart:async';
import 'dart:isolate';

import './computeDecorator.dart';

class IsolateComputer implements ComputeDecorator {
  @override
  Future<T> compute<T, E>(Function func, E value) {
    return Isolate.run(() => func(value));
  }
  @override
  void end() {}
  @override
  void start() {}
}