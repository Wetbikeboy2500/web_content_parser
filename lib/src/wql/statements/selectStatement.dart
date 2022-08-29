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
  final String? selector;
  final LogicalSelector? when;

  const SelectStatement({required this.operators, required this.from, this.into, this.selector, this.when});

  factory SelectStatement.fromTokens(List tokens) {
    //select operators
    final List<Operator> operators = [];

    for (final List operatorTokens in tokens[1]) {
      operators.add(Operator.fromTokens(operatorTokens));
    }

    //select into if exists
    late final String? into;
    if (tokens[4] != null) {
      into = tokens[4].last;
    } else {
      into = null;
    }

    //select from
    late final Operator from;
    if (tokens[3] is String) {
      if (tokens[3].trim() == '*') {
        from = const Operator([OperationName(name: '*', type: OperationType.access, listAccess: null)], null);
      } else {
        throw Exception('Not supported');
      }
    } else {
      from = Operator.fromTokensNoAlias(tokens[3]);
    }

    //select selector if exists
    late final String? selector;

    if (tokens[5] != null) {
      selector = tokens[5].last;
    } else {
      selector = null;
    }

    //get when conditions
    late final LogicalSelector? when;

    if (tokens[6] != null) {
      when = LogicalSelector(tokens[6].last);
    } else {
      when = null;
    }

    return SelectStatement(operators: operators, from: from, into: into, selector: selector, when: when);
  }

  static Parser getParser() {
    return stringIgnoreCase('select').trim().token() &
        inputs &
        stringIgnoreCase('from').trim() &
        input & //TODO: change this into a single input parser
        (stringIgnoreCase('into').trim() & name).optional() & //TODO: change this into a single input parser
        (stringIgnoreCase('where').trim().token() & stringIgnoreCase('selector is').trim() & rawInput).optional() &
        (stringIgnoreCase('when').trim().token() & LogicalSelector.getParser()).optional();
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    dynamic value = (await from.getValue(interpreter.values, interpreter, custom: SetStatement.functions)).value;

    //this is relevant for the getValue on the operators to know if it is being passed a list to modify or a elements within a list to modify
    bool expand = false;

    if ((value.length > 1 || from.names.last.listAccess?.trim() == '[]')) {
      expand = true;
    } else {
      value = value.first;
    }

    //run where
    if (selector != null) {
      dynamic querySelect(dynamic given) {
        if (given is Map) {
          if (!given.containsKey('element')) {
            throw Exception('No element found in map for selector');
          }

          return given['element'].querySelectorAll(selector);
        } else {
          return given.querySelectorAll(selector);
        }
      }

      if (value is List) {
        value = value.map((e) => querySelect(e)).expand((element) => element).toList();
      } else {
        value = querySelect(value);
      }
      expand = true;
    }

    //run when
    if (when != null) {
      if (value is List) {
        //filter by the when condition per element
        int index = 0;
        while (index < value.length) {
          if (!(await when!.evaluate(value[index], interpreter))) {
            value.removeAt(index);
            index--;
          }
          index++;
        }
      } else if (!(await when!.evaluate(value, interpreter))) {
        //clear value if it doesn't meet the when condition
        value = [];
      }
    }

    late final List returns = [];

    final List<MapEntry> mergeLists = [];
    final List<MapEntry> values = [];

    for (final op in operators) {
      final MapEntry entry = await op.getValue(
        value,
        interpreter,
        //TODO: add a test function to make check if there is a valid object being used
        custom: SetStatement.functions,
        expand: expand,
      );

      //classify the type of the values
      if (op.alias == null && (entry.value.length > 1 || op.names.last.listAccess?.trim() == '[]')) {
        mergeLists.add(entry);
      } else if (entry.value.isNotEmpty) {
        values.add(entry);
      }
    }

    //create a list of only the merge values
    for (final entry in mergeLists) {
      for (int i = 0; i < entry.value.length; i++) {
        if (i == returns.length) {
          if (entry.value[i] is Map) {
            returns.add(entry.value[i]);
          } else {
            returns.add(<String, dynamic>{entry.key: entry.value[i]});
          }
        } else {
          if (entry.value[i] is Map) {
            returns[i].addAll(entry.value[i]);
          } else {
            returns[i][entry.key] = entry.value[i];
          }
        }
      }
    }

    //sort by decreasing length to make sure values populate correctly
    values.sort((a, b) => b.value.length.compareTo(a.value.length));

    //populate the values that everything needs. This occurs after the merged values to make sure everything works correctly
    for (final entry in values) {
      //match value length
      while (returns.length < entry.value.length) {
        returns.add(Map<String, dynamic>());
      }
      //if a single value, duplicate
      if (entry.value.length > 1) {
        for (int i = 0; i < entry.value.length; i++) {
          returns[i][entry.key] = entry.value[i];
        }
      } else {
        //add the values by key to value
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
