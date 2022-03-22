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

  final attribute = stringIgnoreCase('attribute').token() & char('.').token() & value;

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

  final query = select & //Start of the selct
      ((char('*').token() | innerHTML | attribute) & alias).separatedBy(char(',').token()) & //alias for naming
      into.optional() &
      from & //marks next part
      name & //this represents the variable to extract from (this could be a document, element, etc.)
      (where & selectorIs).optional();

  final values0 = query.parse("SELECT innerHTML AS name FROM p WHERE SELECTOR IS 'body > p:nth-child(4)'");
  final values1 = query.parse('SELECT innerHTML FROM p WHERE SELECTOR IS p:nth-child(3)');
  final values2 = query.parse("SELECT attribute.data-id AS id from document WHERE SELECTOR IS 'body > p:nth-child(4)'");
  final values3 = query.parse(
      "SELECT attribute.data-id AS id, innerHTML INTO doc from document WHERE SELECTOR IS 'body > p:nth-child(4)'");

  print(values0);
  print(values1);
  print(values2);
  print(values3);

  Interpreter i = Interpreter();
  if (values0.isSuccess) {
    var s = i.process(values0.value);
    i.run(s);
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
  Unknown
}

enum State { Select, Into, From, Where, Unkown }

class Interpreter {
  final Map<String, dynamic> _values = {};

  void setValue(String name, dynamic value) {
    _values[name] = value;
  }

  dynamic getValue(String name) {
    return _values[name];
  }

  List<Element> querySelector(Element element, String selector) {
    return element.querySelectorAll(selector);
  }

  List<dynamic> getProperty(List<Element> elements, TokenType property) {
    switch (property) {
      case TokenType.InnerHTML:
        return elements.map((element) => element.innerHtml).toList();
      case TokenType.Name:
        return elements.map((element) => element.localName).toList();
      case TokenType.OuterHTML:
        return elements.map((element) => element.outerHtml).toList();
      default:
        return [];
    }
  }

  void run(Statement statement) {
    //TODO: Implement this
  }

  Statement process(List values) {
    State currentState = State.Unkown;

    final List<Operator> selections = [];
    String? requestFrom;
    String? selector;

    for (var data in values) {
      if (data == null) {
        continue;
      }

      if (data is Token && (data.value as String).toLowerCase() == 'select') {
        currentState = State.Select;
        continue;
      } else if (data is Token && (data.value as String).toLowerCase() == 'from') {
        currentState = State.From;
        continue;
      } else if (data is List && data[0] is Token && (data[0].value as String).toLowerCase() == 'into') {
        currentState = State.Into;
      } else if (data is List && data[0] is Token && (data[0].value as String).toLowerCase() == 'where') {
        currentState = State.Where;
      }

      switch (currentState) {
        case State.Unkown:
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
        case State.Into:
          //TODO: process the into stuff once the format is figured out
          break;
        case State.From:
          requestFrom = data;
          break;
        case State.Where:
          selector = data.last.last;
          break;
      }
    }

    if (requestFrom == null || selector == null) {
      throw Exception('Invalid from or selector');
    }

    return Statement(selections, requestFrom, selector);
  }
}

class Operator {
  final TokenType type;
  final String? alias;
  final String? meta;

  const Operator(this.type, {this.alias, this.meta});
}

class Statement {
  final String from;
  final String selector;
  final List<Operator> operators;

  const Statement(this.operators, this.from, this.selector);
}
