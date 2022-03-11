import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

//This file is for testing purposes only. The goal is to try and develop a rebust system for selecting elements from a website correctly.

void main() {
  sourceBuilder(File('test/samples/scraper/test2.html').readAsStringSync());
}

void sourceBuilder(String html) {
  //decode string as html
  Document document = parse(html);
  final List<Element> items = iterate(document.documentElement?.children, 0, 0);

  bool exit = false;

  final Set<Element> selected = {};

  while (!exit) {
    stdout.writeln('Enter the number of the item you want to see');
    final int? lineNumber = int.tryParse(stdin.readLineSync() ?? '');
    if (lineNumber != null) {
      if (lineNumber < 0 || lineNumber >= items.length) {
        stdout.writeln('Line number out of range. Exiting');
        exit = true;
      } else {
        final Element item = items[lineNumber];
        stdout.writeln(item.localName);
        stdout.writeln('0: cancel 1: select 2: inspect');
        final int? choice = int.tryParse(stdin.readLineSync() ?? '');
        if (choice != null) {
          switch (choice) {
            case 0:
              //do nothing
              break;
            case 1:
              //select
              selected.add(item);
              break;
            case 2:
              //inspect
              //output all attributes
              item.attributes.forEach((key, value) {
                stdout.writeln('$key: $value');
              });
              //output id
              stdout.writeln('id: ${item.id}');
              //output classes
              stdout.writeln('classes: ${item.classes}');
              //output text
              stdout.writeln('text: ${item.text}');
              //output parents
              final List<Element> parents = [];
              Element? parent = item.parent;
              while (parent != null) {
                parents.add(parent);
                parent = parent.parent;
              }
              parents.reversed.forEach((element) {
                stdout.write(element.localName ?? '' + ' > ');
              });
              stdout.write('\n');
              break;
            default:
              stdout.writeln('Invalid choice');
              exit = true;
          }
        }
      }
    }
  }

  //TODO: determine what selection to use on each item and data relation
}

List<Element> iterate(List<Element>? elements, int level, int globalIndex) {
  if (elements == null) {
    return <Element>[];
  }

  int index = globalIndex;

  final List<Element> items = [];

  for (Element element in elements) {
    //get the element's id
    String id = element.id;
    //get the element's class
    String className = element.className;
    //get the element's text
    String text = element.text;
    //get the element's tag name
    String? tagName = element.localName;

    //replace all new line and tab characters with a space
    text = text.replaceAll(RegExp(r'[\n\t]'), ' ');
    //replace whitespace greater than one space with a single space
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    //remove leading whitespace
    text = text.replaceAll(RegExp(r'^\s+'), '');

    stdout.writeln(index.toString() +
        '-' +
        level.toString() +
        ':\t' +
        (List.generate(level, (index) => '| ').join('') +
            (tagName ?? '') +
            '\t\t<' +
            id +
            '>' +
            '[' +
            className +
            '] ' +
            text));

    items.add(element);

    index++;

    items.addAll(iterate(element.children, level + 1, index));
  }

  return items;
}
