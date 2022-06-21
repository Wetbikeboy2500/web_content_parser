import 'package:petitparser/petitparser.dart';
import '../interpreter/interpreter.dart';
import '../parserHelper.dart';
import 'statement.dart';
import '../operator.dart';

class SelectStatement extends Statement {
  final List<Operator> operators;
  final Operator from;
  final String? into;
  final String? selector;

  const SelectStatement({required this.operators, required this.from, this.into, this.selector});

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
        from = const Operator([OperationName('*', null)], null);
      } else {
        throw Exception('Not supported');
      }
    } else {
      from = Operator.fromTokensNoAlias(tokens[3]);
    }

    //select selector if exists
    late final String? selector;

    if (tokens.last != null) {
      selector = tokens.last.last;
    } else {
      selector = null;
    }

    return SelectStatement(operators: operators, from: from, into: into, selector: selector);
  }

  static Parser getParser() {
    return stringIgnoreCase('select').trim().token() &
        inputs &
        stringIgnoreCase('from').trim() &
        input & //TODO: change this into a single input parser
        (stringIgnoreCase('into').trim() & name).optional() & //TODO: change this into a single input parser
        (stringIgnoreCase('where').trim().token() & stringIgnoreCase('selector is').trim() & rawInput).optional();
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    dynamic value = from.getValue(interpreter.values).value.first;

    bool expand = false;

    //run where
    if (selector != null) {
      if (value is List) {
        value = value.map((e) => e.querySelectorAll(selector)).toList();
      } else {
        value = value.querySelectorAll(selector);
      }
      expand = true;
    }

    late final List returns = [];

    final List<MapEntry> mergeLists = [];
    final List<MapEntry> values = [];

    for (final op in operators) {
      final MapEntry entry = op.getValue(
        value,
        //TODO: add a test function to make check if there is a valid object being used
        custom: {
          'innerHTML': (Operator op1, dynamic value) {
            return value.innerHtml;
          },
          'name': (Operator op1, dynamic value) {
            return value.localName;
          },
          'outerHTML': (Operator op1, dynamic value) {
            return value.outerHtml;
          },
          'attribute': (Operator op1, dynamic value) {
            return value.attributes[op1.names.last.name];
          },
          'text': (Operator op1, dynamic value) {
            return value.txt;
          }
        },
        expand: expand,
      );

      //classify the type of the values
      if (entry.value.length > 1) {
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
            returns.add({entry.key: entry.value[i]});
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

    //populate the values that everything needs. This occurs after the merged values to make sure everything works correctly
    for (final entry in values) {
      for (int i = 0; i < returns.length; i++) {
        returns[i][entry.key] = entry.value.first;
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
