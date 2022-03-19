import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import 'package:petitparser/petitparser.dart';

//This file is for testing purposes only. The goal is to try and develop a rebust system for selecting elements from a website correctly.

void main() {
  sourceBuilder(File('./samples/scraper/test2.html').readAsStringSync());
}

void sourceBuilder(String html) {
  print(html);

  //decode string as html
  Document document = parse(html);

  //get user input
  final String? command = stdin.readLineSync();

  //SELECT innerHTML AS name FROM p WHERE SELECTOR IS 'body > p:nth-child(4)'

  final query = stringIgnoreCase('select').trim().token() & //Start of the selct
      letter().plus().flatten().trim() & //property to extract
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

  print(query.parse("SELECT innerHTML AS name FROM p WHERE SELECTOR IS 'body > p:nth-child(4)'"));
  print(query.parse('SELECT innerHTML FROM p WHERE SELECTOR IS p:nth-child(3)'));
}