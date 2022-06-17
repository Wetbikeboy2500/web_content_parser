// ignore_for_file: avoid_print

import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

//This file is for testing purposes only. The goal is to try and develop a robust system for selecting elements from a website correctly.

void main() {
  /* final i = Interpreter();

  // i.setValue('model', {'hello': 'world'});
  i.setValue('model', {
    'hello': {
      'hello': 'test',
    }
  });

  i.setValue('list', [
    'value'
  ]);

  final parsed = SelectStatement.getParser()
      // .parse('SELECT attribute.style as style, attribute.id as id, url, model[], model[0], * FROM model INTO model');
      .parse('SELECT model.hello.hello as tester, list[0] FROM * INTO model');

  if (parsed.isSuccess) {
    final statement = SelectStatement.fromTokens(parsed.value);
    statement.execute(i);
  } else {
    print(parsed.message);
  }

  return; */
  sourceBuilder(File('./test/samples/scraper/test2.html').readAsStringSync());
}

void sourceBuilder(String html) {
  print(html);

  //decode string as html
  Document document = parse(html);

  //select document.name as doc.random, document.innerHTML as doc.random.innerHTML WHERE SELECTOR IS 'body > p:nth-child(3)'
  //transform doc.random, doc.innerHTML WITH CONCAT AS doc.new
  //define stringVal string value
  //define intVal int 23
  //define boolVal bool true
  //select value.stringVal, value.intVal FROM * INTO newObject
  //define url string 'https://google.com'
  //set var2 to request with url, newObject

  //mutliline string
  /* final code = '''
    if status is 200:
      DEFINE url STRING 'https://google.com';
      DEFINE url STRING 'https://google.com';
    else:
      DEFINE url STRING 'https://google.com';
    endif;
  '''; */

  /* final code = '''
      DEFINE url STRING 'https://google.com';
      SET document TO getRequest WITH url;
      SET status TO getStatusCode WITH document;
      DEFINE passing INT 200;
      IF value.status IS value.passing:
        SET html TO parseBody WITH document;
        SELECT * INTO model FROM html WHERE SELECTOR IS 'div';
        SELECT attribute.style as style, attribute.id as id INTO model FROM model;
        SELECT value.url INTO urlObject FROM *;
        PACK url INTO urlObjectTwo;
        PACK model[], url, urlObject, urlObjectTwo[0] as realUrlObject INTO joined;
      ENDIF;
    '''; */

/*

          select attribute.src into images from titles where select is 'img';
          set id to getLastSegments with urls;
*/

  /* DEFINE page INT 0;
      DEFINE pageParam STRING '?page=';
      SET page TO increment WITH page;
      TRANSFORM value.pageParam, value.page IN * WITH CONCAT AS pageOutput; */
  /* "SELECT name AS random, innerHTML INTO doc FROM document WHERE SELECTOR IS 'body > p:nth-child(3)'",
    "TRANSFORM value.random, value.innerHTML IN doc WITH CONCAT AS new",
    "SELECT value.new INTO return FROM doc",
    "DEFINE stringVal STRING 'hello world'",
    "DEFINE intVal INT 23",
    "DEFINE boolVal BOOL true",
    "SELECT value.stringVal, value.intVal INTO newObject FROM *", */
}


