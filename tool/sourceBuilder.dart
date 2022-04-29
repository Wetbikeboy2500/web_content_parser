import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import 'package:petitparser/petitparser.dart';

//This file is for testing purposes only. The goal is to try and develop a rebust system for selecting elements from a website correctly.

void main() {
  sourceBuilder(File('./test/samples/scraper/test2.html').readAsStringSync());
}

void sourceBuilder(String html) {
  print(html);

  //decode string as html
  Document document = parse(html);

  //get user input
  //final String? command = stdin.readLineSync();

  //SELECT innerHTML AS name FROM p WHERE SELECTOR IS 'body > p:nth-child(4)'

  final valueMatcher = patternIgnoreCase('~!@\$%&*()_+=,./\';:"?><[]{}|`#a-z0-9') | char('-') | char('^');

  final value = (valueMatcher).plus().flatten().trim();

  final valueStringMatcher = (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

  final select = stringIgnoreCase('select').trim().token();

  final alias = (stringIgnoreCase('as').trim().token() & letter().plus().flatten().trim()).optional();

  final innerHTML = stringIgnoreCase('innerHTML').trim().token();
  final outerHTML = stringIgnoreCase('outerHTML').trim().token();
  final nameSelect = stringIgnoreCase('name').trim().token();
  final attribute = stringIgnoreCase('attribute').token() & char('.').token() & value;
  final valueAccess = stringIgnoreCase('attribute').token() & char('.').token() & value;

  final from = stringIgnoreCase('from').trim().token();

  final where = stringIgnoreCase('where').trim().token();

  final name = letter().plus().flatten().trim();

  final nameValue = name & char('.').token() & value;

  //TODO: I will need to revise the syntax for the comparisons
  final into = stringIgnoreCase('into').trim().token() &
      name.trim() &
      (where & nameValue & char('=') & nameValue).trim().optional();

  final selectorIs =
      stringIgnoreCase('selector is').trim().token() & (valueStringMatcher | (valueMatcher).plus().flatten().trim());

  final inputSelectors =
      ((char('*').token() | innerHTML | attribute | nameSelect | outerHTML) & alias).separatedBy(char(',').token());

  final inputSelectorsName = ((char('*').token() | innerHTML | attribute | nameSelect | outerHTML | valueAccess) & alias)
      .separatedBy(char(',').token());

  final query = select & //Start of the selct
      inputSelectors & //alias for naming
      into.optional() &
      from & //marks next part
      name & //this represents the variable to extract from (this could be a document, element, etc.)
      (where & selectorIs).optional();

  final transform = stringIgnoreCase('transform').trim().token();

  final transformOperations = stringIgnoreCase('trim').trim().token() |
      stringIgnoreCase('lowercase').trim().token() |
      stringIgnoreCase('uppercase').trim().token() |
      stringIgnoreCase('concat').trim().token();

  final queryTransform = transform &
      inputSelectorsName &
      stringIgnoreCase('in').trim().token() &
      name &
      stringIgnoreCase('with').trim().token() &
      transformOperations.separatedBy(char(',').token()) &
      alias.optional();

  final allQueries = (query | queryTransform).separatedBy(char(';').token());

  final values0 = query.parse("SELECT innerHTML AS name FROM p WHERE SELECTOR IS 'body > p:nth-child(4)'");
  final values1 = query.parse('SELECT innerHTML FROM p WHERE SELECTOR IS p:nth-child(3)');
  final values2 = query.parse("SELECT attribute.data-id AS id from document WHERE SELECTOR IS 'body > p:nth-child(4)'");
  final values3 =
      query.parse("SELECT name AS random, innerHTML INTO doc from document WHERE SELECTOR IS 'body > p:nth-child(3)'");

  final values4 = allQueries.parse([
    "SELECT attribute.data-id AS id from document WHERE SELECTOR IS 'body > p:nth-child(4)'",
    "SELECT name AS random, innerHTML INTO doc from document WHERE SELECTOR IS 'body > p:nth-child(3)'"
        "TRANSFORM name IN doc WITH TRIM, LOWERCASE"
  ].join(';'));

  //print(values4);

  final v = allQueries.parse("TRANSFORM name IN doc WITH TRIM, LOWERCASE");
  final inew = Interpreter();
  if (v.isSuccess) {
    List<Statement> statements = inew.processAll(v.value);
    //print all statements
    for (var statement in statements) {
      print(statement);
    }
  } else {
    print(v.message);
  }

  return;

  /*
      TRANSFORM name IN doc WITH TRIM, LOWERCASE
      TRANSFORM first, last IN doc WITH TRIM, LOWERCASE, CONCAT AS name
      This would chnage the name on every map within the doc variable
      */

  print(values0);
  print(values1);
  print(values2);
  print(values3);

  print(document.querySelectorAll("body > p:nth-child(3)"));

  Interpreter i = Interpreter();
  if (values3.isSuccess) {
    var s = i.process(values3.value);
    i.setValue('document', document);
    i.runSelect(s);
    print(i.getValue('doc'));
  }
}

enum TokenType {
  Select,
  InnerHTML,
  Name,
  OuterHTML,
  All,
  Attribute,
  Dot,
  Alias,
  From,
  Where,
  Selector,
  Value,
  End,
  In,
  Transform,
  Trim,
  Lowercase,
  Uppercase,
  Concat,
  Unknown
}

enum State {
  Select,
  Transform,
  In,
  Into,
  From,
  Where,
  With,
  Unknown,
}

class Interpreter {
  final Map<String, dynamic> _values = {};

  void setValue(String name, dynamic value) {
    _values[name] = value;
  }

  dynamic getValue(String name) {
    return _values[name];
  }

  dynamic getProperty(Element element, TokenType property, [String? meta]) {
    switch (property) {
      case TokenType.InnerHTML:
        return element.innerHtml;
      case TokenType.Name:
        return element.localName;
      case TokenType.OuterHTML:
        return element.outerHtml;
      case TokenType.All:
        return element;
      case TokenType.Attribute:
        return element.attributes[meta];
      default:
        return [];
    }
  }

  void runSelect(Statement statement) {
    dynamic data = _values[statement.from];
    if (data == null) {
      throw Exception('No data found for ${statement.from}');
    }

    late final List<Element> elements;

    if (data is Document || data is Element) {
      if (statement.selector == null) {
        elements = [data];
      } else {
        elements = data.querySelectorAll(statement.selector);
      }
    } else {
      throw Exception('Data is not an Element');
    }

    final List<Map> results = [];

    for (var element in elements) {
      final Map<String, dynamic> values = {};
      for (var select in statement.operators) {
        values[select.alias ?? select.type.name] = getProperty(element, select.type);
      }
      results.add(values);
    }

    if (statement.into != null) {
      setValue(statement.into!, results);
    }
  }

  void runTransform(Statement statement) {
    //from
    dynamic data = _values[statement.from];
    if (data == null) {
      throw Exception('No data found for ${statement.from}');
    }

    //select
    final List<dynamic> values = [];
    for (Operator select in statement.operators) {
      switch (select.type) {
        case TokenType.Value:
          values.add(data[select.type]);
          break;
      }
    }

    for (var transform in statement.operators) {
      switch (transform.type) {
        case TokenType.Trim:
          values.forEach((value) => value = value.trim());
          break;
        case TokenType.Lowercase:
          values.forEach((value) => value = value.toLowerCase());
          break;
        case TokenType.Uppercase:
          values.forEach((value) => value = value.toUpperCase());
          break;
        case TokenType.Concat:
          values.forEach((value) => value = value.toString() + value.toString());
          break;
        default:
          throw Exception('Unknown transform ${transform.type}');
      }
    }
  }

  List<Statement> processAll(List values) {
    final List<Statement> statements = [];
    for (var value in values) {
      if (value is Token) {
        continue;
      }

      statements.add(process(value));
    }
    return statements;
  }

  Statement process(List values) {
    State currentState = State.Unknown;

    TokenType? operation = null;

    List<Operator>? transformations;

    final List<Operator> selections = [];
    String? requestFrom;
    String? selector;
    String? into;

    print(values);

    for (var data in values) {
      if (data == null) {
        continue;
      }

      if (data is Token && (data.value as String).toLowerCase() == 'select') {
        currentState = State.Select;
        operation = TokenType.Select;
        continue;
      } else if (data is Token && (data.value as String).toLowerCase() == 'transform') {
        currentState = State.Transform;
        operation = TokenType.Transform;
        continue;
      } else if (data is Token && (data.value as String).toLowerCase() == 'in') {
        currentState = State.In;
        continue;
      } else if (data is Token && (data.value as String).toLowerCase() == 'from') {
        currentState = State.From;
        continue;
      } else if (data is Token && (data.value as String).toLowerCase() == 'with') {
        currentState = State.With;
        continue;
      } else if (data is List && data[0] is Token && (data[0].value as String).toLowerCase() == 'into') {
        currentState = State.Into;
      } else if (data is List && data[0] is Token && (data[0].value as String).toLowerCase() == 'where') {
        currentState = State.Where;
      }

      if (operation == null) {
        throw Exception('No operation found');
      }

      switch (currentState) {
        case State.Unknown:
          throw Exception('Invalid starting syntax');
        case State.Select:
          for (dynamic operators in data) {
            if (operators is Token && operators.value == ',') {
              continue;
            }

            late TokenType type;
            String? alias;
            String? meta;

            List items = operators;

            if (operators.first is List) {
              items = operators.first;
            }

            if (items[0] is Token) {
              switch ((items[0].value as String).toLowerCase()) {
                case 'innerhtml':
                  type = TokenType.InnerHTML;
                  break;
                case 'outerhtml':
                  type = TokenType.OuterHTML;
                  break;
                case 'name':
                  type = TokenType.Name;
                  break;
                case '*':
                  type = TokenType.All;
                  break;
                case 'attribute':
                  type = TokenType.Attribute;
                  meta = items[2];
                  break;
                default:
                  throw Exception('Invalid token for operator');
              }
            } else {
              throw Exception('Invalid operator');
            }

            if (operators.last is List &&
                operators.last.first is Token &&
                operators.last.first.value.toLowerCase() == 'as') {
              alias = operators.last.last;
            }

            selections.add(Operator(
              type,
              alias: alias,
              meta: meta,
            ));
          }
          break;
        case State.Transform:
          for (dynamic operators in data) {
            if (operators is Token && operators.value == ',') {
              continue;
            }

            late TokenType type;
            String? alias;
            String? meta;

            List items = operators;

            if (operators.first is List) {
              items = operators.first;
            }

            if (items[0] is Token) {
              switch ((items[0].value as String).toLowerCase()) {
                case 'innerhtml':
                  type = TokenType.InnerHTML;
                  break;
                case 'outerhtml':
                  type = TokenType.OuterHTML;
                  break;
                case 'name':
                  type = TokenType.Name;
                  break;
                case '*':
                  type = TokenType.All;
                  break;
                case 'attribute':
                  type = TokenType.Attribute;
                  meta = items[2];
                  break;
                default:
                  type = TokenType.Value;
                  meta = items[0].value as String;
              }
            } else {
              throw Exception('Invalid operator');
            }

            if (operators.last is List &&
                operators.last.first is Token &&
                operators.last.first.value.toLowerCase() == 'as') {
              alias = operators.last.last;
            }

            selections.add(Operator(
              type,
              alias: alias,
              meta: meta,
            ));
          }
          break;
        case State.Into:
          into = data[1];
          break;
        case State.In:
        case State.From:
          requestFrom = data;
          break;
        case State.Where:
          selector = data.last.last;
          break;
        case State.With:
          //loop through tokens in data
          for (dynamic operators in data) {
            if (operators is Token && operators.value == ',') {
              continue;
            }
            late TokenType type;
            String? alias;
            String? meta;

            late List items;

            if (operators is List) {
              items = operators;
            } else {
              items = [operators];
            }

            switch ((items[0].value as String).toLowerCase()) {
              case 'trim':
                type = TokenType.Trim;
                break;
              case 'lowercase':
                type = TokenType.Lowercase;
                break;
              case 'uppercase':
                type = TokenType.Uppercase;
                break;
              case 'concat':
                type = TokenType.Concat;
                if (items.last is List && items.last.first is Token && items.last.first.value.toLowerCase() == 'as') {
                  alias = items.last.last;
                }
                break;
            }

            transformations ??= [];

            transformations.add(Operator(
              type,
              alias: alias,
              meta: meta,
            ));
          }
          break;
      }
    }

    if (operation == null) {
      throw Exception('Invalid operation');
    }

    if (requestFrom == null) {
      throw Exception('Invalid from or selector');
    }

    return Statement(operation, selections, requestFrom, selector, into, transformations: transformations);
  }
}

class Operator {
  final TokenType type;
  final String? alias;
  final String? meta;

  const Operator(this.type, {this.alias, this.meta});
}

class Statement {
  final TokenType operation;
  final String from;
  final String? selector;
  final String? into;
  final List<Operator> operators;
  final List<Operator>? transformations;

  const Statement(this.operation, this.operators, this.from, this.selector, this.into, {this.transformations});

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


/*
parse and tokenize
convert to statements
run statements
*/