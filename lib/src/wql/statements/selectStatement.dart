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
    final matches = input & stringIgnoreCase('matches').trim() & input;
    final contains = input & stringIgnoreCase('contains').trim() & input;
    final startsWith = input & stringIgnoreCase('startsWith').trim() & input;
    final endsWith = input & stringIgnoreCase('endsWith').trim() & input;
    final equals = input & stringIgnoreCase('equals').trim() & input;

    final terms = matches | contains | startsWith | endsWith | equals;

    final term = undefined();
    final andClause = undefined();
    final parenClause = undefined();

    final Parser or = (andClause & stringIgnoreCase('or').trim() & term);
    term.set(or | andClause);

    final Parser and = (parenClause & stringIgnoreCase('and').trim() & andClause);
    andClause.set(and | parenClause);

    final Parser paren = (char('(').trim() & term & stringIgnoreCase(')').trim()).map((values) => values[1]);
    ;
    parenClause.set(paren | terms);

    final logicalSelector = term.end();

    return stringIgnoreCase('select').trim().token() &
        inputs &
        stringIgnoreCase('from').trim() &
        input & //TODO: change this into a single input parser
        (stringIgnoreCase('into').trim() & name).optional() & //TODO: change this into a single input parser
        (stringIgnoreCase('where').trim().token() & logicalSelector).optional();
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    dynamic value = from.getValue(interpreter.values).value.first;

    bool expand = false;

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
            return value.text;
          }
        },
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

    //sort by decreasing length to make sure values populate correctly
    values.sort((a, b) => b.value.length.compareTo(a.value.length));

    //populate the values that everything needs. This occurs after the merged values to make sure everything works correctly
    for (final entry in values) {
      //match value length
      while (returns.length < entry.value.length) {
        returns.add({});
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
