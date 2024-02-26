import '../dot_input/dot_input.dart';
import '../interpreter.dart';
import 'statement.dart';

class SelectStatement {
  final List<(String? name, DotInput input)> select;
  final DotInput? from;

  SelectStatement(this.select, this.from);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    bool isCollection = false;

    if (from != null) {
      final result = await from!.execute(context, interpreter);
      if (result.noop) {
        return const (name: '', result: null, wasExpanded: false, noop: true);
      }
      context = result.result;
      isCollection = result.wasExpanded;
    }

    List<dynamic> results = [];

    if (isCollection) {

    } else {

    }

    return (name: '', result: results, wasExpanded: false, noop: false);
  }
}