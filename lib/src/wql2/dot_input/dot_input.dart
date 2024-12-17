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

    Future<bool> runElseIfNextOperation() async {
      if (i + 1 < operationsLength) {
        final nextOperation = operations[i + 1];
        if (nextOperation is StatementOperation && nextOperation.statement is ElseStatement) {
          await nextOperation.process(context, context, interpreter);
          return true;
        }
      }

      return false;
    }

    Future<({dynamic result, bool noop})> getValue(Operation operation, dynamic value) async {
      try {
        if (operation is ScopeOperation) {
          return (result: await operation.process(context, context, interpreter), noop: false);
        } else if (operation is StatementOperation) {
          if (operation.statement is ElseStatement) {
            return (result: value, noop: false);
          }

          final StatementReturnValue statementResult = await operation.process(value, context, interpreter);

          if (statementResult.noop) {
            //TODO: test how this compiles down
            final bool handledByElse = await runElseIfNextOperation();
            assert(() {
              if (!handledByElse) {
                // ignore: avoid_print
                print('Warning: Statement returned no result and caused a noop');
              }
              return true;
            }());
            return (result: null, noop: true);
          } else {
            return (result: statementResult.result, noop: false);
          }
        } else {
          return (result: await operation.process(value, context, interpreter), noop: false);
        }
      } catch (e) {
        final bool handledByElse = await runElseIfNextOperation();
        assert(() {
          if (!handledByElse) {
            if (operation is FunctionOperation) {
              // ignore: avoid_print
              print('Warning: Could not call function ${operation.name}. Caused a noop.');
            } else {
              // ignore: avoid_print
              print('Warning: Could not get value at $operation. Caused a noop.');
            }
            // ignore: avoid_print
            print(e);
          }
          return true;
        }());
        return (result: null, noop: true);
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
        late final dynamic result;

        if (i == 0 && operation is KeyOperation) {
          result = await getValue(operation, interpreter.values);
        } else {
          result = await getValue(operation, currentValue);
        }

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
        } catch (err, stack) {
          assert(() {
            // ignore: avoid_print
            print('Warning: Could not access list at $operation');
            // ignore: avoid_print
            print(err);
            // ignore: avoid_print
            print(stack);
            return true;
          }());

          await runElseIfNextOperation();
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
