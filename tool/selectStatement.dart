import 'package:html/dom.dart';
import 'package:petitparser/petitparser.dart';

import 'parserHelper.dart';
import 'sourceBuilder.dart';
import 'statement.dart';
import 'operator.dart' as op;

class SelectStatement extends Statement {
  final TokenType operation;
  final String from;
  final String? selector;
  final String? into;
  final List<Operator> operators;
  final List<Operator>? transformations;

  const SelectStatement(this.operation, this.operators, this.from, this.selector, this.into, {this.transformations});

  factory SelectStatement.fromTokens(List tokens) {
    print(tokens);
    //select operators
    final List<op.Operator> operators = [];

    for (final List operatorTokens in tokens[1]) {
      operators.add(op.Operator.fromTokens(operatorTokens));
    }

    //select into if exists
    late final String? into;
    if (tokens[4] != null) {
      into = tokens[4].last;
    } else {
      into = null;
    }

    //select from
    final String from = tokens[3];

    //select selector if exists

    return const SelectStatement(TokenType.Selector, [], '', '', '');
  }

  static Parser getParser() {
    return stringIgnoreCase('select').trim().token() &
        inputs &
        stringIgnoreCase('from').trim() &
        name & //TODO: change this into a single input parser
        (stringIgnoreCase('into').trim() & name).optional() & //TODO: change this into a single input parser
        (stringIgnoreCase('where').trim().token() & stringIgnoreCase('selector is').trim() & rawInput).optional();
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    late final dynamic data;
    if (from == '*') {
      data = interpreter.values;
    } else {
      data = interpreter.getValue(from);
    }

    if (data == null) {
      throw Exception('No data found for $from');
    }

    late final List<dynamic> elements;

    if (data is Document || data is Element) {
      if (selector == null) {
        elements = [data];
      } else {
        elements = data.querySelectorAll(selector);
      }
    } else if (data is Map) {
      elements = [data];
    } else if (data is List) {
      if (data.isNotEmpty) {
        if ((data.first is Element || data.first is Document) && selector != null) {
          elements = data.map((e) => e.querySelectorAll(selector)).expand((element) => element).toList();
        } else {
          elements = data;
        }
      } else {
        elements = [];
      }
    } else {
      throw Exception('Data is not an Element');
    }

    if (operators.length == 1 && operators.first.type == TokenType.All) {
      //using an all selector so we just take every and through it into a list
      if (into != null) {
        interpreter.setValue(into!, elements);
      }
    } else {
      final List<Map> results = [];

      for (var element in elements) {
        final Map<String, dynamic> values = {};
        for (var select in operators) {
          late final dynamic value;
          if (element is Element) {
            value = interpreter.getProperty(element, select.type, select.meta);
          } else if (element is Map) {
            if (select.type == TokenType.Value) {
              value = element[select.meta];
            } else {
              throw Exception('Must use value selector when accessing maps');
            }
          } else {
            throw Exception('Data is not an Element nor Map');
          }

          if (select.alias == null && select.type == TokenType.Value) {
            values[select.meta!] = value;
          } else {
            values[select.alias ?? select.type.name.substring(0, 1).toLowerCase() + select.type.name.substring(1)] =
                value;
          }
        }
        results.add(values);
      }

      if (into != null) {
        interpreter.setValue(into!, results);
      }
    }
  }

  //create to string
  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();

    buffer.write('$operation ');

    for (Operator operator in operators) {
      buffer.write('${operator.type}');

      if (operator.meta != null) {
        buffer.write('(${operator.meta})');
      }

      if (operator.alias != null) {
        buffer.write(' as ${operator.alias}');
      }

      buffer.write(', ');
    }

    buffer.write('from $from');

    if (selector != null) {
      buffer.write(' where $selector');
    }

    if (into != null) {
      buffer.write(' into $into');
    }

    if (transformations != null) {
      buffer.write(' with ');

      for (Operator operator in transformations!) {
        buffer.write('${operator.type}');

        if (operator.meta != null) {
          buffer.write('(${operator.meta})');
        }

        if (operator.alias != null) {
          buffer.write(' as ${operator.alias}');
        }

        buffer.write(', ');
      }
    }

    return buffer.toString();
  }
}
