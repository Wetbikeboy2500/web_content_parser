import 'package:petitparser/petitparser.dart';
import 'setStatement.dart';
import '../suboperations/logicalSelector.dart';
import '../interpreter/interpreter.dart';
import '../parserHelper.dart';
import 'statement.dart';
import '../suboperations/operator.dart';

class SelectStatement extends Statement {
  final List<Operator> operators;
  final Operator from;
  final String? into;
  final LogicalSelector? whenClause;

  const SelectStatement({required this.operators, required this.from, this.into, this.whenClause});

  factory SelectStatement.fromTokens(List tokens) {
    final [_, inputs, __, from, into, whenClause] = tokens;

    //select operators
    final List<Operator> operators = [];

    for (final List operatorTokens in inputs) {
      operators.add(Operator.fromTokens(operatorTokens));
    }

    //select from
    late final Operator tmpFrom;
    if (from is! String) {
      tmpFrom = Operator.fromTokensNoAlias(from);
    } else if (from.trim() == '*') {
      tmpFrom = const Operator([OperationName(name: '*', type: OperationType.access, listAccess: null)], null);
    } else {
      throw Exception('Not supported');
    }

    return SelectStatement(
      operators: operators,
      from: tmpFrom,
      into: into?.last,
      whenClause: whenClause != null ? LogicalSelector(whenClause.last) : null,
    );
  }

  static Parser getParser() {
    return stringIgnoreCase('select').trim().token() &
        inputs &
        stringIgnoreCase('from').trim() &
        input &
        (stringIgnoreCase('into').trim() & name).optional() &
        (stringIgnoreCase('when').trim().token() & LogicalSelector.getParser()).optional();
  }

  @override
  Future<void> execute(Interpreter interpreter, dynamic context) async {
    final ({MapEntry result, bool wasExpanded}) valueResult = await from.getValue(
      context,
      interpreter,
      custom: SetStatement.functions,
    );

    //this is relevant for the getValue on the operators to know if it is being passed a list to modify or a elements within a list to modify
    bool expand = false;

    dynamic value;

    if (valueResult.wasExpanded) {
      expand = true;
      value = valueResult.result.value;
    } else {
      value = valueResult.result.value.first;
    }

    //run when
    if (whenClause != null) {
      if (expand) {
        //filter by the when condition per element
        final newValue = [];
        for (final element in value) {
          if (await whenClause!.evaluate(element, interpreter)) {
            newValue.add(element);
          }
        }

        if (newValue.isEmpty) {
          // Exit early
          if (into != null) {
            interpreter.setValue(into!, []);
          }
          return;
        }

        value = newValue;
      } else if (!(await whenClause!.evaluate(value, interpreter))) {
        //clear value if it doesn't meet the when condition
        value = [];

        // Exit early
        if (into != null) {
          interpreter.setValue(into!, []);
        }
        return;
      }
    }

    late final List returns = [];

    final List<MapEntry> mergeLists = [];
    final List<MapEntry> values = [];

    for (final op in operators) {
      MapEntry<String, List<dynamic>>? opResults;
      bool wasExpanded = false;

      for (final singleValue in expand ? value : [value]) {
        final ({MapEntry<String, List<dynamic>> result, bool wasExpanded}) entry = await op.getValue(
          singleValue,
          interpreter,
          //TODO: add a test function to make check if there is a valid object being used
          custom: SetStatement.functions,
        );
        wasExpanded = entry.wasExpanded;

        if (entry.wasExpanded) {
          if (opResults == null) {
            opResults = MapEntry(entry.result.key, entry.result.value);
          } else {
            opResults.value.addAll(entry.result.value);
          }
        } else {
          if (opResults == null) {
            opResults = MapEntry(entry.result.key, [entry.result.value.firstOrNull]);
          } else {
            opResults.value.add(entry.result.value.firstOrNull);
          }
        }
      }

      //classify the type of the values
      if (op.alias == null && wasExpanded) {
        mergeLists.add(opResults!);
      } else if (opResults!.value.isNotEmpty) {
        values.add(opResults);
      }
    }

    final Set<String> seenKeys = {};

    //create a list of only the merge values
    for (final entry in mergeLists) {
      final entryValueLength = entry.value.length;

      final currentMax = returns.length >= entryValueLength ? returns.length : entryValueLength;

      for (int i = 0; i < currentMax; i++) {
        if (i < entryValueLength) {
          if (i == returns.length) {
            late final Map<String, dynamic> newMap;

            if (entry.value[i] is Map) {
              newMap = {...(entry.value[i] as Map)};
            } else {
              newMap = <String, dynamic>{entry.key: entry.value[i]};
            }

            for (final key in seenKeys) {
              newMap[key] = null;
            }

            returns.add(newMap);
          } else {
            if (entry.value[i] is Map) {
              returns[i].addAll(entry.value[i]);
            } else {
              returns[i][entry.key] = entry.value[i];
            }
          }
        } else {
          returns[i][entry.key] = null;
        }
      }

      seenKeys.add(entry.key);
    }

    //sort by decreasing length to make sure values populate correctly
    values.sort((a, b) => b.value.length.compareTo(a.value.length));

    // Populate the values that everything needs. This occurs after the merged values to make sure everything works correctly
    for (final entry in values) {
      final entryValueLength = entry.value.length;

      // Match value length
      while (returns.length < entryValueLength) {
        final newMap = <String, dynamic>{};

        for (final key in seenKeys) {
          newMap[key] = null;
        }

        returns.add(newMap);
      }

      // If a single value, duplicate
      if (entryValueLength > 1) {
        for (int i = 0; i < returns.length; i++) {
          returns[i][entry.key] = i < entryValueLength ? entry.value[i] : null;
        }
      } else {
        // Add the values by key to value
        for (int i = 0; i < returns.length; i++) {
          returns[i][entry.key] = entry.value.first;
        }
      }
    }

    if (into != null) {
      interpreter.setValue(into!, returns);
    }
  }

  //create to string
  @override
  String toString() {
    //TODO: add to string
    return '';
  }
}
