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

  final query = stringIgnoreCase('select').trim().token() & //Start of the selct
      stringIgnoreCase('innerHTML').trim().token() & //property to extract
      (stringIgnoreCase('as').trim().token() & letter().plus().flatten().trim()).optional() & //alias for naming
      stringIgnoreCase('from').trim().token() & //marks next part
      letter()
          .plus()
          .flatten()
          .trim() & //this represents the variable to extract from (this could be a document, element, etc.)
      stringIgnoreCase('where').trim().token() & //Where clause
      stringIgnoreCase('selector is').trim().token() &
      ((char("'") & pattern("^'").star().flatten() & char("'")) |
          (patternIgnoreCase('~!@\$%&*()_+=,./\';:"?><[]{}|`#a-z0-9') | char('-') | char('^')).plus().flatten().trim());

  final values0 = query.parse("SELECT innerHTML AS name FROM p WHERE SELECTOR IS 'body > p:nth-child(4)'");
  final values = query.parse('SELECT innerHTML FROM p WHERE SELECTOR IS p:nth-child(3)');

  print(values0);

  //validate execution path
  if (values0.isSuccess) {
    checkTokens(
      null,
      values0.value.map((element) {
        if (element is List) {
          if (element.first == "'" && element.last == "'") {
            return element.sublist(1, element.length - 1);
          }
        }

        return element;
      }).toList(),
    );
  }
}

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
        default:
          stdout.writeln('Unexpected token: ${data.value}');
          token = TokenType.Unknown;
      }
    } else {
      token = TokenType.Value;
    }

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

enum TokenType { Select, InnerHTML, Alias, From, Where, Selector, Value, End, Unknown }

const Map<TokenType, List<TokenType>> expected = {
  TokenType.Select: [TokenType.InnerHTML],
  TokenType.InnerHTML: [TokenType.Alias, TokenType.From],
  TokenType.Alias: [TokenType.Value],
  TokenType.Value: [TokenType.InnerHTML, TokenType.From, TokenType.End, TokenType.Where],
  TokenType.From: [TokenType.Value],
  TokenType.Selector: [TokenType.Value],
  TokenType.Where: [TokenType.Selector],
};
