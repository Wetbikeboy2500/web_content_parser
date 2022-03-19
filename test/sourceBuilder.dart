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

  final valueStringMatcher = char("'") & pattern("^'").star().flatten() & char("'");

  final query = stringIgnoreCase('select').trim().token() & //Start of the selct
      (stringIgnoreCase('innerHTML').trim().token() |
          stringIgnoreCase('attribute').token() &
              char('.').token() &
              (valueMatcher).plus().flatten().trim()) & //property to extract
      (stringIgnoreCase('as').trim().token() & letter().plus().flatten().trim()).optional() & //alias for naming
      stringIgnoreCase('from').trim().token() & //marks next part
      letter()
          .plus()
          .flatten()
          .trim() & //this represents the variable to extract from (this could be a document, element, etc.)
      stringIgnoreCase('where').trim().token() & //Where clause
      stringIgnoreCase('selector is').trim().token() &
      ((valueStringMatcher) | (valueMatcher).plus().flatten().trim());

  final values0 = query.parse("SELECT innerHTML AS name FROM p WHERE SELECTOR IS 'body > p:nth-child(4)'");
  final values1 = query.parse('SELECT innerHTML FROM p WHERE SELECTOR IS p:nth-child(3)');
  final values2 = query.parse("SELECT attribute.data-id AS id from document WHERE SELECTOR IS 'body > p:nth-child(4)'");

  print(values0);
  print(values1);
  print(values2);

  //INTO syntax for creating associated objects
  //create a list of Map or add a new key/value to list of maps just by index
  //This would need to have all the lengths of FROM to be the same to work properly

  //validate execution path
  if (values0.isSuccess) {
    final Interpreter interpreter = Interpreter();

    interpreter.checkTokens(
      null,
      values0.value.map((element) {
        if (element is List && element.length == 3) {
          if (element.first == "'" && element.last == "'") {
            return element.sublist(1, element.length - 1);
          }
        }

        return element;
      }).toList(),
    );

    print(interpreter.tokens);

    interpreter.parse();
  }
}

class CompleteToken {
  final String value;
  final TokenType type;

  const CompleteToken(this.value, this.type);

  @override
  String toString() {
    return 'CompleteToken{value: $value, type: $type}';
  }
}

enum TokenType { Select, InnerHTML, Name, OuterHTML, Attribute, Dot, Alias, From, Where, Selector, Value, End, Unknown }

const Map<TokenType, List<TokenType>> expected = {
  TokenType.Select: [TokenType.InnerHTML, TokenType.Name, TokenType.OuterHTML, TokenType.Attribute],
  TokenType.Attribute: [TokenType.Dot],
  TokenType.Dot: [TokenType.Value],
  TokenType.InnerHTML: [TokenType.Alias, TokenType.From],
  TokenType.Name: [TokenType.Alias, TokenType.From],
  TokenType.OuterHTML: [TokenType.Alias, TokenType.From],
  TokenType.Alias: [TokenType.Value],
  TokenType.Value: [TokenType.InnerHTML, TokenType.From, TokenType.End, TokenType.Where],
  TokenType.From: [TokenType.Value],
  TokenType.Selector: [TokenType.Value],
  TokenType.Where: [TokenType.Selector],
};

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

  final List<CompleteToken> tokens = [];

  TokenType checkTokens(TokenType? current, List values) {
    for (var data in values) {
      if (data is List) {
        current = checkTokens(current, data);
        continue;
      }

      print(data);

      //determine what the token is
      late TokenType token;
      if (data is Token) {
        switch ((data.value as String).toLowerCase()) {
          case 'select':
            token = TokenType.Select;
            break;
          case 'as':
            token = TokenType.Alias;
            break;
          case 'from':
            token = TokenType.From;
            break;
          case 'where':
            token = TokenType.Where;
            break;
          case 'selector is':
            token = TokenType.Selector;
            break;
          case 'innerhtml':
            token = TokenType.InnerHTML;
            break;
          case 'attribute':
            token = TokenType.Attribute;
            break;
          case '.':
            token = TokenType.Dot;
            break;
          default:
            stdout.writeln('Unexpected token: ${data.value}');
            token = TokenType.Unknown;
        }
      } else {
        token = TokenType.Value;
      }

      //makes a nice list of tokens
      tokens.add(CompleteToken(TokenType.Value == token ? data : data.value, token));

      if (current == null) {
        //needs to be a starting type
        if (token == TokenType.Select) {
          current = token;
        }
      } else {
        //need to check the token matches the expected
        final List<TokenType>? expectedOptions = expected[current];

        if (expectedOptions == null) {
          stdout.writeln('Unexpected token: $current');
          return TokenType.Unknown;
        }

        if (!expectedOptions.contains(token)) {
          stdout.writeln('Unexpected token in sequence: $current $data');
          return TokenType.Unknown;
        }

        current = token;
      }
    }

    return current ?? TokenType.Unknown;
  }

  ///Parses the tokens into a query
  ///
  ///This is trying to move through different states for a select statement.
  ///This has a lot more room to be improved
  parse() {
    //what are the values trying to be retieved?
    //what are their aliases?
    if (tokens.removeAt(0).type != TokenType.Select) {
      throw Exception('Expected SELECT');
    }

    var current = tokens.removeAt(0);

    List<SelectorData> operations = [];

    while (current.type != TokenType.From && tokens.isNotEmpty) {
      final TokenType token = current.type;
      current = tokens.removeAt(0);
      if (current.type == TokenType.Alias) {
        operations.add(SelectorData(token, alias: tokens.removeAt(0).value));
        current = tokens.removeAt(0);
      } else {
        operations.add(SelectorData(token));
      }
    }

    //What document or element is the request for?
    if (current.type != TokenType.From) {
      throw Exception('Expected FROM');
    }

    final String request = tokens.removeAt(0).value;

    //What selector is being used?
    List<String> selectors = [];

    if (tokens.isNotEmpty && tokens.removeAt(0).type == TokenType.Where) {
      current = tokens.removeAt(0);
      while (tokens.isNotEmpty) {
        if (current.type == TokenType.Selector) {
          current = tokens.removeAt(0);
          selectors.add(current.value);
        }

        if (tokens.isNotEmpty) {
          tokens.removeAt(0);
        }
      }
    }

    print(operations);
    print(request);
    print(selectors);
  }
}

class SelectorData {
  final String? alias;
  final TokenType type;

  const SelectorData(this.type, {this.alias});

  @override
  String toString() {
    return 'SelectorData{alias: $alias, type: $type}';
  }
}

class SelectOperation {
  List<SelectorData> operations = [];
  List<String> selectors = [];
}
