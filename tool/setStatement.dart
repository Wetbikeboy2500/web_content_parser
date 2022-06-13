import 'package:html/parser.dart';
import 'package:petitparser/core.dart';
import 'package:petitparser/parser.dart';
import 'package:web_content_parser/scraper.dart';
import 'package:path/path.dart' as path;

import 'operator.dart';
import 'parserHelper.dart';
import 'sourceBuilder.dart' hide Operator;
import 'statement.dart';

class SetStatement extends Statement {
  final String target;
  final String function;
  final List<Operator> arguments;

  const SetStatement(this.target, this.function, this.arguments);

  factory SetStatement.fromTokens(List tokens) {
    final String target = tokens[1];
    final String function = tokens[3].toLowerCase();

    final List<Operator> arguments = [];

    for (final List operatorTokens in tokens[5]) {
      arguments.add(Operator.fromTokens(operatorTokens));
    }

    return SetStatement(target, function, arguments);
  }

  static Parser getParser() {
    return stringIgnoreCase('set').trim().token() &
        name &
        stringIgnoreCase('to').trim().token() &
        name &
        stringIgnoreCase('with') &
        inputs;
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    //gets the args to pass along
    final List args = [];
    for (final arg in arguments) {
      args.add(arg.getValue(interpreter.values));
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
      case 'joinurl':
        value = path.url.joinAll(List<String>.from(args));
        break;
      case 'increment':
        value = args[0] + 1;
        break;
      case 'decrement':
        value = args[0] - 1;
        break;
      case 'getlastsegment':
        if (args[0] is String) {
          value = path.url.split(args[0]).last;
        }
        if (args[0] is List && args[0].isNotEmpty && args[0].first is Map) {
          List output = [];
          for (Map item in args[0]) {
            output.add(path.url.split(item['url']).last);
          }
          value = output;
        } else {
          throw Exception('Cannot get last segment of a non string or list');
        }
        break;
      case 'trim':
        value = args[0].trim();
        break;
      default:
        throw UnsupportedError('Unsupported function: $function');
    }

    //set the value
    interpreter.setValue(target, value);
  }
}
