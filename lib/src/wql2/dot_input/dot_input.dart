import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/src/wql2/dot_input/operation.dart';

import '../interpreter.dart';
import '../statements/statement.dart';
import 'list_access.dart';

class DotInput extends Statement {
  final List<Operation> operations = [];

  factory DotInput.fromTokens(SeparatedList tokens) {
    throw UnimplementedError();
  }

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    dynamic currentValue = context;
    bool wasExpanded = false;

    Future<({dynamic result, bool noop})> getValue(Operation operation, dynamic value) async {
      if (operation is ScopeOperation) {
        return (result: await operation.process(context, interpreter), noop: false);
      } else if (operation is StatementOperation) {
        final StatementReturnValue statementResult = await operation.process(value, interpreter);

        if (statementResult.noop) {
          return (result: null, noop: true);
        } else {
          return (result: statementResult.result, noop: false);
        }
      } else {
        return (result: await operation.process(value, interpreter), noop: false);
      }
    }

    for (final operation in operations) {
      if (wasExpanded && operation.type != OperationType.scope) {
        final List<dynamic> allExpandedResults = [];

        assert(currentValue is List<dynamic>);

        for (final value in currentValue) {
          final result = await getValue(operation, value);
          if (result.noop) {
            continue;
          }
          allExpandedResults.add(result.result);
        }

        currentValue = allExpandedResults;
      } else {
        final result = await getValue(operation, currentValue);
        if (result.noop) {
          return (name: '', result: null, wasExpanded: false, noop: true);
        }
        currentValue = result.result;
      }

      if (operation.type != OperationType.key && wasExpanded) {
        wasExpanded = false;
      }

      if (operation.listAccess != null) {
        for (final listAccess in operation.listAccess!) {
          currentValue = listAccess.process(currentValue);
        }
        if (operation.listAccess!.last.type == ListAccessType.all) {
          wasExpanded = true;
        }
      }
    }

    return (name: '', result: currentValue, wasExpanded: wasExpanded, noop: false);
  }
}
