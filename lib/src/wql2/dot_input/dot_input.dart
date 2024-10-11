import '../interpreter.dart';
import '../statements/else_statement.dart';
import '../statements/eval_statement.dart';
import '../statements/if_statement.dart';
import '../statements/select_statement.dart';
import '../statements/statement.dart';
import 'list_access.dart';
import 'operation.dart';

class DotInput extends Statement {
  final List<Operation> operations;

  DotInput(this.operations);

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    dynamic currentValue = context;
    bool wasExpanded = false;

    final operationsLength = operations.length;
    int i = 0;

    Future<({dynamic result, bool noop})> getValue(Operation operation, dynamic value) async {
      if (operation is ScopeOperation) {
        return (result: await operation.process(context, context, interpreter), noop: false);
      } else if (operation is StatementOperation) {
        if (operation.statement is ElseStatement) {
          return (result: value, noop: false);
        }

        final StatementReturnValue statementResult = await operation.process(value, context, interpreter);

        if (statementResult.noop) {
          //run the else if that exists for the next op
          if (i + 1 < operationsLength) {
            final nextOperation = operations[i + 1];
            if (nextOperation is StatementOperation && nextOperation.statement is ElseStatement) {
              await nextOperation.process(context, context, interpreter);
            }
          }

          return (result: null, noop: true);
        } else {
          return (result: statementResult.result, noop: false);
        }
      } else {
        return (result: await operation.process(value, context, interpreter), noop: false);
      }
    }

    for (i = 0; i < operationsLength; i++) {
      final operation = operations[i];

      if (wasExpanded && operation is! ScopeOperation) {
        final List<dynamic> allExpandedResults = [];

        assert(currentValue is List<dynamic>);

        for (final value in currentValue) {
          final result = await getValue(operation, value);
          if (result.noop) {
            continue;
          }

          if (operation is StatementOperation && operation.statement is SelectStatement) {
            allExpandedResults.addAll(result.result);
          } else {
            allExpandedResults.add(result.result);
          }
        }

        currentValue = allExpandedResults;
      } else {
        final result = await getValue(operation, currentValue);
        if (result.noop) {
          return (name: '', result: null, wasExpanded: false, noop: true);
        }
        currentValue = result.result;
      }

      if (operation is! KeyOperation && wasExpanded) {
        wasExpanded = false;
      }

      if (operation.listAccess != null) {
        try {
          for (final listAccess in operation.listAccess!) {
            currentValue = listAccess.process(currentValue);
          }
          if (operation.listAccess!.last is AllAccess) {
            wasExpanded = true;
          }
        } catch (_) {
          //TODO: add a optional warning here when running in debug mode

          if (i + 1 < operationsLength) {
            final nextOperation = operations[i + 1];
            if (nextOperation is StatementOperation && nextOperation.statement is ElseStatement) {
              await nextOperation.process(context, context, interpreter);
            }
          }

          return (name: '', result: null, wasExpanded: false, noop: true);
        }
      }
    }

    final String name = switch (operations.last) {
      final KeyOperation keyOperation => keyOperation.key,
      final FunctionOperation functionOperation => functionOperation.name,
      final CurrentScopeOperation _ => '*',
      final TopScopeOperation _ => '^',
      final StatementOperation statementOperation => switch (statementOperation.statement) {
          final IfStatement _ => 'if',
          final SelectStatement _ => 'select',
          final EvalStatement _ => 'eval',
          final Statement _ => '',
        },
      final LiteralOperation _ => '',
    };

    return (name: name, result: currentValue, wasExpanded: wasExpanded, noop: false);
  }
}
