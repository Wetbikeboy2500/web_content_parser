import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

void main() {
  sourceBuilder(File('test/samples/scraper/test2.html').readAsStringSync());
}

void sourceBuilder(String html) {
  //decode string as html
  Document document = parse(html);
  iterate(document.documentElement?.children, 0);
}

int index = 0;

List<Element> items = [];

void iterate(List<Element>? elements, int level) {
  if (elements == null) {
    return;
  }

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

    print(index.toString() + ': ' + (List.generate(level, (index) => '| ').join('') + (tagName ?? '') + '-' + text));

    items.add(element);

    index++;

    iterate(element.children, level + 1);
  }
}
