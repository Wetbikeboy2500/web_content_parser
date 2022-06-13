import 'package:html/dom.dart';
import 'package:petitparser/petitparser.dart';

import 'parserHelper.dart';
import 'sourceBuilder.dart' show Interpreter;
import 'statement.dart';
import 'operator.dart';


//TODO: make transform support set functions. Some will be for single items and others for arrays
class TransformStatement extends Statement {
  final List<Operator> operators;
  final Operator from;
  final String? into;
  final String? selector;

  const TransformStatement({required this.operators, required this.from, this.into, this.selector});

  factory TransformStatement.fromTokens(List tokens) {
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

    return TransformStatement(operators: operators, from: from, into: into, selector: selector);
  }

  static Parser getParser() {
    final alias = (stringIgnoreCase('as').trim().token() & letter().plus().flatten().trim()).optional();
    final transformOperations = (stringIgnoreCase('trim').trim().token() |
            stringIgnoreCase('lowercase').trim().token() |
            stringIgnoreCase('uppercase').trim().token() |
            (stringIgnoreCase('concat').trim().token() & alias))
        .separatedBy(char(',').token());
    return stringIgnoreCase('transform').trim().token() &
        inputs &
        stringIgnoreCase('in').trim() &
        input & //TODO: change this into a single input parser
        stringIgnoreCase('with').trim() &
        transformOperations;
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

    final Map<String, dynamic> values = {};

    for (final op in operators) {
      final MapEntry entry = op.getValue(
        value,
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
          }
        },
        expand: expand,
      );
      values[entry.key] = entry.value;
    }

    print(values);
  }

  //create to string
  @override
  String toString() {
    //TODO: add to string
    return '';
  }
}
