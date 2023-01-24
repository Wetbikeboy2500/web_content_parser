import 'dart:async';

import 'package:computer/computer.dart';
import './computeDecorator.dart';

class ComputerDecorator implements ComputeDecorator {
  final _computer = Computer.create();
  int _running = 0;

  ///Number of workers to be made for compute calls
  int workers = 2;

  Timer? _finalTimer;

  ///Time after a data conversion finishes to close all isolates. They are kept open for performance.
  int computeCooldownMilliseconds = 5000;

  @override
  Future<T> compute<T, E>(Function func, E value) {
    return _computer.compute<E, T>(func, param: value);
  }

  @override
  void end() {
    if (_running > 0) {
      _running--;
    }
    if (_running == 0 && (_finalTimer == null || !_finalTimer!.isActive)) {
      //5 second grace period before the computer is killed
      _finalTimer = Timer(const Duration(seconds: 5), () {
        if (_running == 0) {
          _computer.turnOff();
        }
      });
    }
  }

  @override
  void start() {
    _running++;
    if (!_computer.isRunning) {
      _computer.turnOn(workersCount: workers);
    }
  }
}
