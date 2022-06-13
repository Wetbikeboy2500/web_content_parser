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

enum TokenType {
  Select,
  Set,
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
  Define,
  Concat,
  If,
  Else,
  Endif,
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

  Future<void> runStatements(List<Statement> statements) async {
    for (var statement in statements) {
      await statement.execute(this);
    }
  }
}

class Operator {
  final TokenType type;
  final String? alias;
  final String? meta;

  const Operator(this.type, {this.alias, this.meta});
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

  final value = (valueMatcher).plus().flatten().trim();

  //allow any character except for the ' in the string since it is the terminating character
  final valueStringMatcher = (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

  final select = stringIgnoreCase(TokenType.Select.name).trim().token();

  //TokenType.Alias
  final alias = (stringIgnoreCase('as').trim().token() & letter().plus().flatten().trim()).optional();

  final innerHTML = stringIgnoreCase(TokenType.InnerHTML.name).trim().token();
  final outerHTML = stringIgnoreCase(TokenType.OuterHTML.name).trim().token();
  final nameSelect = stringIgnoreCase(TokenType.Name.name).trim().token();
  final attribute = stringIgnoreCase(TokenType.Attribute.name).token() & char('.').token() & value;
  final valueAccess = stringIgnoreCase(TokenType.Value.name).token() & char('.').token() & value;

  final from = stringIgnoreCase(TokenType.From.name).trim().token();

  final where = stringIgnoreCase(TokenType.Where.name).trim().token();

  final name = letter().plus().flatten().trim() | char('*').trim();

  final nameValue = name & char('.').token() & value;

  final nameValueSeparated =
      stringIgnoreCase('value') & char('.') & name.separatedBy(char('.'), includeSeparators: false);

  //TODO: I will need to revise the syntax for the comparisons
  final into = stringIgnoreCase('into').trim().token() &
      name.trim() &
      (where & nameValue & char('=') & nameValue).trim().optional();

  final selectorIs =
      stringIgnoreCase('selector is').trim().token() & (valueStringMatcher | (valueMatcher).plus().flatten().trim());

  final inputSelectors =
      ((char('*').token() | innerHTML | attribute | nameSelect | outerHTML | valueAccess.trim()) & alias)
          .separatedBy(char(',').trim().token());

  final query = select & //Start of the selct
      inputSelectors & //alias for naming
      into.optional() &
      from & //marks next part
      (name |
          name.separatedBy(char('.'),
              includeSeparators:
                  false)) & //this represents the variable to extract from (this could be a document, element, etc.)
      (where & selectorIs).optional();

  final transform = stringIgnoreCase('transform').trim().token();

  final transformOperations = stringIgnoreCase('trim').trim().token() |
      stringIgnoreCase('lowercase').trim().token() |
      stringIgnoreCase('uppercase').trim().token() |
      (stringIgnoreCase('concat').trim().token() & alias);

  final queryTransform = transform &
      inputSelectors &
      stringIgnoreCase('in').trim().token() &
      name &
      stringIgnoreCase('with').trim().token() &
      transformOperations.separatedBy(char(',').token()) &
      alias.optional();

  final define = stringIgnoreCase('define').trim().token();

  final type = stringIgnoreCase('string').trim().token() |
      stringIgnoreCase('int').trim().token() |
      stringIgnoreCase('bool').trim().token();

  final queryDefine = define & name & type & (valueStringMatcher | (valueMatcher).plus().flatten().trim());

  final setName = stringIgnoreCase('set').trim().token();
  final to = stringIgnoreCase('to').trim().token();

  final querySet =
      setName & name & to & name & stringIgnoreCase('with').trim().token() & name.separatedBy(char(',').token());

  final conditional = undefined();

  final allQueries = ((SelectStatement.getParser() |
              queryTransform |
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
  State currentState = State.Unknown;

  TokenType? operation;

  List<Operator>? transformations;

  final List<Operator> selections = [];
  String? requestFrom;
  String? selector;
  String? into;

  for (var data in tokens) {
    if (data == null) {
      continue;
    }

    if (data is Token && (data.value as String).toLowerCase() == 'pack') {
      return PackStatement.fromTokens(tokens);
    }

    //TODO: separate all the different statements by their operation when complexity is too high
    if (data is Token && (data.value as String).toLowerCase() == 'select') {
      return SelectStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'set') {
      return SetStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'if') {
      return ConditionalStatement.fromTokens(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'transform') {
      currentState = State.Transform;
      operation = TokenType.Transform;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'define') {
      return DefineStatement.fromTokens(tokens);
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
              case 'value':
                type = TokenType.Value;
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
              case 'value':
                type = TokenType.Value;
                meta = items[2];
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

  if (operation == TokenType.Select) {
    //return SelectStatement(operation, selections, requestFrom, selector, into, transformations: transformations);
  } else if (operation == TokenType.Transform) {
    // return TransformStatement(operation, selections, requestFrom, selector, into, transformations: transformations);
  } else {
    throw Exception('Invalid operation');
  }
  throw Exception();
}
