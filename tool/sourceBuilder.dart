// ignore_for_file: avoid_print

import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:path/path.dart';

import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/scraper.dart';

//This file is for testing purposes only. The goal is to try and develop a rebust system for selecting elements from a website correctly.

void main() {
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

  final code = '''
    if status is 200:
      DEFINE url STRING 'https://google.com';
      SET document TO getRequest WITH url;
      SET status TO getStatusCode WITH document;
      SET html TO parseBody WITH document;
      SELECT innerHTML as title INTO title FROM html WHERE SELECTOR IS 'title';
    else:
      DEFINE url STRING 'https://google.com';
    endif;
    ''';
  /* "SELECT name AS random, innerHTML INTO doc FROM document WHERE SELECTOR IS 'body > p:nth-child(3)'",
    "TRANSFORM value.random, value.innerHTML IN doc WITH CONCAT AS new",
    "SELECT value.new INTO return FROM doc",
    "DEFINE stringVal STRING 'hello world'",
    "DEFINE intVal INT 23",
    "DEFINE boolVal BOOL true",
    "SELECT value.stringVal, value.intVal INTO newObject FROM *", */

  print(code);

  final i = Interpreter();
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
  Set,
  Define, //get name
  Define1, //get type
  Define2, //get value
  In,
  Into,
  To,
  From,
  Where,
  With,
  With1, //for set operation
  Unknown,
}

class Interpreter {
  final Map<String, dynamic> _values = {};

  Map<String, dynamic> get values => _values;

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
  //Do not allow commas or semicolons or colons for value matcher
  final valueMatcher = patternIgnoreCase('~!@\$%&*()_+=./\'"?><[]{}|`#a-z0-9') | char('-') | char('^');

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
      name & //this represents the variable to extract from (this could be a document, element, etc.)
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

  final allQueries =
      ((query | queryTransform | queryDefine | querySet | conditional) & char(';').token().trim()).pick(0).star();

  final conditionalQuery = stringIgnoreCase('if').trim().token() &
      name &
      stringIgnoreCase('is').trim().token() &
      (valueStringMatcher | (valueMatcher).plus().flatten().trim()) &
      char(':').trim().token() &
      allQueries &
      (stringIgnoreCase('else:').trim().token() & allQueries).optional() &
      stringIgnoreCase('endif').trim().token();

  conditional.set(conditionalQuery);

  final parsed = allQueries.parse(input);

  if (parsed.isFailure) {
    return const [];
  }

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

    //TODO: separate all the different statements by their operation when complexity is too high
    if (data is Token && (data.value as String).toLowerCase() == 'select') {
      currentState = State.Select;
      operation = TokenType.Select;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'set') {
      currentState = State.Set;
      operation = TokenType.Set;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'if') {
      return parseConditional(tokens);
    } else if (data is Token && (data.value as String).toLowerCase() == 'transform') {
      currentState = State.Transform;
      operation = TokenType.Transform;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'define') {
      currentState = State.Define;
      operation = TokenType.Define;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'in') {
      currentState = State.In;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'to') {
      currentState = State.To;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'from') {
      currentState = State.From;
      continue;
    } else if (data is Token && (data.value as String).toLowerCase() == 'with') {
      if (operation == TokenType.Set) {
        currentState = State.With1;
      } else {
        currentState = State.With;
      }
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
      case State.Set:
        into = data;
        break;
      case State.To:
        requestFrom = data;
        break;
      case State.Define:
        //name
        into = data;
        currentState = State.Define1;
        break;
      case State.Define1:
        //type
        selector = (data.value as String).toLowerCase();
        currentState = State.Define2;
        break;
      case State.Define2:
        //raw value
        requestFrom = data;
        break;
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
      case State.With1:
        for (dynamic operators in data) {
          if (operators is Token && operators.value == ',') {
            continue;
          }

          selections.add(Operator(
            TokenType.Value,
            meta: operators,
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
    return SelectStatement(operation, selections, requestFrom, selector, into, transformations: transformations);
  } else if (operation == TokenType.Transform) {
    return TransformStatement(operation, selections, requestFrom, selector, into, transformations: transformations);
  } else if (operation == TokenType.Define) {
    return DefineStatement(operation, selections, requestFrom, selector, into, transformations: transformations);
  } else if (operation == TokenType.Set) {
    return SetStatement(operation, selections, requestFrom, selector, into, transformations: transformations);
  } else {
    throw Exception('Invalid operation');
  }
}

ConditionalStatement parseConditional(List tokens) {
  final String operand1 = tokens[1];
  final String operand2 = tokens[3];
  final String operation = tokens[2].value;

  final List<Statement> truthful = parseStatements(tokens[5]);

  List<Statement>? falsy;

  if (tokens[6] != null) {
    falsy = parseStatements(tokens[6][1]);
  }

  return ConditionalStatement(truthful, falsy, operand1, operand2, operation);
}

class Statement {
  const Statement();

  Future<void> execute(Interpreter interpreter) async {
    throw Exception('Not implemented');
  }
}

class SelectStatement extends Statement {
  final TokenType operation;
  final String from;
  final String? selector;
  final String? into;
  final List<Operator> operators;
  final List<Operator>? transformations;

  const SelectStatement(this.operation, this.operators, this.from, this.selector, this.into, {this.transformations});

  @override
  Future<void> execute(Interpreter interpreter) async {
    late final dynamic data;
    if (from == '*') {
      data = interpreter.values;
    } else {
      data = interpreter.getValue(from);
    }

    if (data == null) {
      throw Exception('No data found for $from');
    }

    late final List<dynamic> elements;

    if (data is Document || data is Element) {
      if (selector == null) {
        elements = [data];
      } else {
        elements = data.querySelectorAll(selector);
      }
    } else if (data is Map) {
      elements = [data];
    } else if (data is List) {
      if (data.isNotEmpty) {
        elements = data;
      } else {
        elements = [];
      }
    } else {
      throw Exception('Data is not an Element');
    }

    final List<Map> results = [];

    for (var element in elements) {
      final Map<String, dynamic> values = {};
      for (var select in operators) {
        late final dynamic value;
        if (element is Element) {
          value = interpreter.getProperty(element, select.type);
        } else if (element is Map) {
          if (select.type == TokenType.Value) {
            value = element[select.meta];
          } else {
            throw Exception('Must use value selector when accessing maps');
          }
        } else {
          throw Exception('Data is not an Element nor Map');
        }

        if (select.alias == null && select.type == TokenType.Value) {
          values[select.meta!] = value;
        } else {
          values[select.alias ?? select.type.name.substring(0, 1).toLowerCase() + select.type.name.substring(1)] =
              value;
        }
      }
      results.add(values);
    }

    if (into != null) {
      interpreter.setValue(into!, results);
    }
  }

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

class TransformStatement extends SelectStatement {
  const TransformStatement(TokenType operation, List<Operator> operators, String from, String? selector, String? into,
      {List<Operator>? transformations})
      : super(operation, operators, from, selector, into, transformations: transformations);

  @override
  Future<void> execute(Interpreter interpreter) async {
    //from
    final dynamic data = interpreter.getValue(from);
    if (data == null) {
      throw Exception('No data found for $from');
    }

    //add the specific values to transform
    List<String> values = [];
    for (Operator select in operators) {
      Map<String, dynamic> objectValues = {};
      switch (select.type) {
        case TokenType.Value:
          /* if (data is Map) {
            objectValues[select.meta!] = data[select.meta];
          } else if (data is List && data.isNotEmpty && data.first is Map) {
            for (final Map d in data) {
              objectValues[select.meta!] = d[select.meta!];
            }
          } */
          values.add(select.meta!);
          break;
        default:
        //do nothing
      }
    }

    //loop through all the data
    for (var d in data) {
      //TODO: add an into
      //TODO: support as for transforms that work on map
      for (final value in values) {
        final dynamic storedValue = d[value];
        for (final Operator transform in transformations ?? []) {
          switch (transform.type) {
            case TokenType.Trim:
              d[transform.alias ?? value] = storedValue.trim();
              break;
            case TokenType.Lowercase:
              d[transform.alias ?? value] = storedValue.toLowerCase();
              break;
            case TokenType.Uppercase:
              d[transform.alias ?? value] = storedValue.toUpperCase();
              break;
            case TokenType.Concat:
              //make sure value exists
              d[transform.alias ?? value] ??= '';
              //fail if not string
              if (d[transform.alias ?? value] is! String) {
                throw Exception('Cannot concatenate a non string value');
              }
              //join strings
              if (storedValue is String) {
                d[transform.alias ?? value] += storedValue;
              } else {
                d[transform.alias ?? value] = storedValue.toString();
              }
              break;
            default:
              throw Exception('Unknown transform ${transform.type}');
          }
        }
      }
    }

    interpreter.setValue(from, data);
  }
}

class DefineStatement extends SelectStatement {
  const DefineStatement(TokenType operation, List<Operator> operators, String from, String? selector, String? into,
      {List<Operator>? transformations})
      : super(operation, operators, from, selector, into, transformations: transformations);

  @override
  Future<void> execute(Interpreter interpreter) async {
    if (into == null) {
      throw ArgumentError('No into specified.');
    }

    dynamic value = from;

    switch (selector) {
      case 'string':
        value = value.toString();
        break;
      case 'int':
        value = int.parse(value.toString());
        break;
      case 'bool':
        value = value.toString() == 'true';
        break;
      default:
        throw ArgumentError('Unknown type.');
    }

    interpreter.setValue(into!, value);
  }
}

class SetStatement extends SelectStatement {
  const SetStatement(TokenType operation, List<Operator> operators, String from, String? selector, String? into,
      {List<Operator>? transformations})
      : super(operation, operators, from, selector, into, transformations: transformations);

  @override
  Future<void> execute(Interpreter interpreter) async {
    final into = this.into;
    final function = from.toLowerCase();
    final arguments = operators;

    //gets the args to pass along
    final List args = [];
    for (final arg in arguments) {
      args.add(interpreter.getValue(arg.meta!));
    }

    //runs the function
    late dynamic value;

    switch (function) {
      case 'getrequest':
        //for the second argument, we are going to assume it is a map within a list
        value = await getRequest(
          args[0],
          (args.length > 1) ? args[1].first : const <String, String>{},
        );
        break;
      case 'getrequestdynamic':
        value = await getDynamicPage(args[0]);
        break;
      case 'postrequest':
        value = await postRequest(
          args[0],
          args[1].first,
          (args.length > 2) ? args[2].first : const <String, String>{},
        );
        break;
      case 'parse':
        value = parse(args[0].first);
        break;
      case 'getstatuscode':
        value = args[0].statusCode;
        break;
      case 'parsebody':
        value = parse(args[0].body);
        break;
      default:
        throw UnsupportedError('Unsupported function: $function');
    }

    //set the value
    interpreter.setValue(into!, value);
  }
}

class ConditionalStatement extends Statement {
  final List<Statement> truthful;
  final List<Statement>? falsy;
  final String operand1;
  final String operand2;
  final String operation;

  const ConditionalStatement(this.truthful, this.falsy, this.operand1, this.operand2, this.operation);

  @override
  Future<void> execute(Interpreter interpreter) async {
    //check if statement is truthy
    //execute truthy if true
    //execute falsy if false
    for (final statement in truthful) {
      await statement.execute(interpreter);
    }
  }
}
