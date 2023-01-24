abstract class ComputeDecorator {
  void start();
  void end();
  Future<T> compute<T, E>(Function func, E value);
}