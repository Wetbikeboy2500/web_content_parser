// ignore_for_file: avoid_print

import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/scraper.dart';

import 'conditionalStatement.dart';
import 'defineStatement.dart';
import 'packStatement.dart';
// import 'selectStatement.dart';
import 'selectStatement.dart';
import 'setStatement.dart';
import 'statement.dart';
import 'transformStatement.dart';

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

  final code = '''
    DEFINE firstname STRING hello;
    SELECT name AS random, innerHTML FROM document INTO doc WHERE SELECTOR IS 'body > p';
    SELECT doc[], firstname FROM * into doctwo;
    SELECT doc[].random, doc[].innerHTML, firstname FROM * INTO docthree;
  ''';

  final i = Interpreter();
  i.setValue('document', document);
  i.runStatements(parseStatements(parseAndTokenize(code))).then((value) {
    print(i.values);
  });
}

class Interpreter {
  final Map<String, dynamic> _values = {};

  Map<String, dynamic> get values => _values;

  void setValues(Map<String, dynamic> values) {
    _values.addAll(values);
  }

  void setValue(String name, dynamic value) {
    _values[name] = value;
  }

  dynamic getValue(String name) {
    return _values[name];
  }

  Future<void> runStatements(List<Statement> statements) async {
    for (var statement in statements) {
      await statement.execute(this);
    }
  }
}

/*
parse and tokenize
convert to statements
run statements (this step will be done within an class to allow for scoped)
*/

/// Tokenizes a string into a list of tokens.
/// This defines the grammar of the language as well.
List parseAndTokenize(String input) {
  //Do not allow commas or semicolons or colons or periods for value matcher
  final valueMatcher = patternIgnoreCase('~!@\$%&*()_+=/\'"?><[]{}|`#a-z0-9') | char('-') | char('^');

  //allow any character except for the ' in the string since it is the terminating character
  final valueStringMatcher = (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

  final name = letter().plus().flatten().trim() | char('*').trim();

  final nameValueSeparated =
      stringIgnoreCase('value') & char('.') & name.separatedBy(char('.'), includeSeparators: false);

  final define = stringIgnoreCase('define').trim().token();

  final type = stringIgnoreCase('string').trim().token() |
      stringIgnoreCase('int').trim().token() |
      stringIgnoreCase('bool').trim().token();

  final queryDefine = define & name & type & (valueStringMatcher | (valueMatcher).plus().flatten().trim());

  final conditional = undefined();

  final allQueries = ((SelectStatement.getParser() |
              TransformStatement.getParser() |
              queryDefine |
              SetStatement.getParser() |
              conditional |
              PackStatement.getParser()) &
          char(';').token().trim())
      .pick(0)
      .star();

  final conditionalVariables = (nameValueSeparated);

  //TODO: revise operator to not be so exact
  final conditionalQuery = stringIgnoreCase('if').trim().token() &
      conditionalVariables &
      (stringIgnoreCase('is').trim().token() | stringIgnoreCase('is not').trim().token()) &
      conditionalVariables &
      char(':').trim().token() &
      allQueries &
      (stringIgnoreCase('else:').trim().token() & allQueries).optional() &
      stringIgnoreCase('endif').trim().token();

  conditional.set(conditionalQuery);

  final parsed = allQueries.parse(input);

  if (parsed.isFailure) {
    return const [];
  }

  print(parsed.value);

  return parsed.value;
}

/// Runs all the statements in the list.
/// THis will produce a list of statement which can then be run for their different contexts
List<Statement> parseStatements(List tokens) {
  print(tokens);
  final List<Statement> statements = [];
  for (var value in tokens) {
    //skipping for semicolons
    if (value is Token) {
      continue;
    }

    statements.add(parseStatement(value));
  }
  return statements;
}

Statement parseStatement(List tokens) {
  for (var data in tokens) {
    if (data == null) {
      continue;
    }

    if (data is Token && (data.value as String).toLowerCase() == 'pack') {
      return PackStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'select') {
      return SelectStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'set') {
      return SetStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'if') {
      return ConditionalStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'transform') {
      return TransformStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'define') {
      return DefineStatement.fromTokens(tokens);
    } else {
      throw Exception('No operation found');
    }
  }
  throw Exception('No operation found');
}
