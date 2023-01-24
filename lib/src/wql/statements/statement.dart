import '../interpreter/interpreter.dart';

class Statement {
  const Statement();

  Future<void> execute(Interpreter interpreter) async {
    throw UnimplementedError();
  }
}