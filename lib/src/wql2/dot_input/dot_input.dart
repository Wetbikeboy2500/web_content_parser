import 'package:petitparser/petitparser.dart';

import '../interpreter.dart';
import '../parser.dart';
import '../statements/eval_statement.dart';
import '../statements/if_statement.dart';
import '../statements/select_statement.dart';
import '../statements/statement.dart';
import '../wql2.dart';
import 'list_access.dart';
import 'operation.dart';

class DotInput extends Statement {
  final List<Operation> operations;

  DotInput(this.operations);

  factory DotInput.fromTokens(List tokens) {
    final List<Operation> operations = [];

    switch (tokens) {
      case [final Token type, final dynamic value]:
        operations.add(_parseLiteral(type, value));
        break;
      default:
        for (final List operation in tokens) {
          switch (operation) {
            case [final String key, final SeparatedList? listAccess]:
              List<ListAccess>? listAccesses;
              if (listAccess != null) {
                listAccesses = _parseListAccess(listAccess.elements);
              }

              operations.add(switch (key) {
                '*' => ScopeOperation(ScopeOperationType.current, listAccesses),
                '^' => ScopeOperation(ScopeOperationType.top, listAccesses),
                _ => KeyOperation(key, listAccesses),
              });
              break;
            case [final List function, final SeparatedList? listAccess]:
              List<ListAccess>? listAccesses;
              if (listAccess != null) {
                listAccesses = _parseListAccess(listAccess.elements);
              }

              if (function.first is! Token) {
                final List<DotInput> arguments = [];

                for (final argument in function[1]?.elements ?? []) {
                  argument.add(DotInput.fromTokens(argument));
                }

                final Function? func = WQL.functions[function.first.toLowerCase()];

                if (func == null) {
                  throw Exception('Function not found: ${function.first}');
                }

                operations.add(FunctionOperation(function.first, func, arguments, listAccesses));
              } else {
                //statement
                print('Statement $function');

                switch (function.first.value) {
                  case 'if':
                    switch (function) {
                      case [final Token ifToken, final SeparatedList condition, final List? elseList]:
                        assert(ifToken.value == 'if');
                        operations.add(
                          StatementOperation(
                            IfStatement(
                              DotInput.fromTokens(condition.elements),
                              false,
                              null,
                              (elseList == null) ? null : parseToObjects(elseList),
                            ),
                            listAccesses,
                          ),
                        );
                        break;
                      default:
                        throw Exception('Invalid if operation: $function');
                    }
                    break;
                  case 'select':
                    switch (function) {
                      case [final Token selectToken, final SeparatedList select, final SeparatedList? from]:
                        assert(selectToken.value == 'select');

                        DotInput? fromInput;

                        if (from != null) {
                          fromInput = DotInput.fromTokens(from.elements);
                        }
                        break;
                      default:
                        print(function.last);
                        throw Exception('Invalid select operation: $function');
                    }
                    break;
                  case 'eval':
                    switch (function) {
                      case [final Token evalToken, final SeparatedList eval]:
                        assert(evalToken.value == 'eval');

                        final List<Statement> evalOperations = parseToObjects(eval.elements);

                        break;
                      default:
                        throw Exception('Invalid eval operation: $function');
                    }
                    break;
                  default:
                    throw Exception('Invalid operation: ${function.first.value}');
                }
              }
              break;
            default:
              throw Exception('Invalid operation: $operation');
          }
        }
    }

    return DotInput(operations);
  }

  static LiteralOperation _parseLiteral(Token type, dynamic value) {
    return LiteralOperation(switch (type.value) {
      'l' => [],
      's' => (value is String) ? value : value.toString(),
      'n' => (value is num) ? value : num.parse(value),
      'b' => (value is bool) ? value : value.toLowerCase() == 'true',
      _ => throw Exception('Invalid type: $type'),
    });
  }

  static List<ListAccess> _parseListAccess(List listAccess) {
    final List<ListAccess> accesses = [];

    if (listAccess.isEmpty) {
      accesses.add(AllAccess());
      return accesses;
    }

    for (final access in listAccess) {
      assert(access != null);

      switch (access) {
        case final Token token:
          accesses.add(switch (token.value) {
            'all' => AllAccess(),
            'first' => FirstAccess(),
            'last' => LastAccess(),
            'even' => EvenAccess(),
            'odd' => OddAccess(),
            _ => throw Exception('Invalid list access: $token')
          });
          break;
        case final String index:
          accesses.add(Index1Access(int.parse(index)));
          break;
        case [final dynamic start, ':', final dynamic end]:
          late final int startIndex;
          if (start is Token) {
            startIndex = switch (start.value) {
              'first' => 0,
              'last' => -1,
              _ => throw Exception('Invalid list access: $start'),
            };
          } else {
            startIndex = int.parse(start);
          }

          late final int endIndex;
          if (end is Token) {
            endIndex = switch (end.value) {
              'first' => 0,
              'last' => -1,
              _ => throw Exception('Invalid list access: $end'),
            };
          } else {
            endIndex = int.parse(end);
          }

          accesses.add(IndexRangeAccess(startIndex, endIndex));
          break;
        case [final dynamic start, ':', final dynamic end, ':', final String step]:
          late final int startIndex;
          if (start is Token) {
            startIndex = switch (start.value) {
              'first' => 0,
              'last' => -1,
              _ => throw Exception('Invalid list access: $start'),
            };
          } else {
            startIndex = int.parse(start);
          }

          late final int endIndex;
          if (end is Token) {
            endIndex = switch (end.value) {
              'first' => 0,
              'last' => -1,
              _ => throw Exception('Invalid list access: $end'),
            };
          } else {
            endIndex = int.parse(end);
          }

          accesses.add(IndexRangeStepAccess(startIndex, endIndex, int.parse(step)));
          break;
        default:
          throw Exception('Invalid list access: $access');
      }
    }

    return accesses;
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

    final String name = switch (operations.last) {
      final KeyOperation keyOperation => keyOperation.key,
      final FunctionOperation functionOperation => functionOperation.name,
      final ScopeOperation scopeOperation => scopeOperation.scopeType == ScopeOperationType.current ? '*' : '^',
      final StatementOperation statementOperation => switch (statementOperation.statement) {
          final IfStatement _ => 'if',
          final SelectStatement _ => 'select',
          final EvalStatement _ => 'eval',
          _ => '',
        },
      _ => '',
    };

    return (name: name, result: currentValue, wasExpanded: wasExpanded, noop: false);
  }
}
