import 'package:html/parser.dart';
import 'package:petitparser/core.dart';
import 'package:web_content_parser/scraper.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;

import 'sourceBuilder.dart';
import 'statement.dart';

class SetStatement extends Statement {
  final String into;
  final String function;
  final List<String> arguments;

  const SetStatement(this.into, this.function, this.arguments);

  factory SetStatement.fromTokens(List tokens) {
    final String into = tokens[1];
    final String function = tokens[3].toLowerCase();
    final List<String> arguments = [];

    for (dynamic token in tokens[5]) {
      if (token is Token && token.value == ',') {
        continue;
      }

      arguments.add(token);
    }

    return SetStatement(into, function, arguments);
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    //gets the args to pass along
    final List args = [];
    for (final arg in arguments) {
      args.add(interpreter.getValue(arg));
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
      default:
        throw UnsupportedError('Unsupported function: $function');
    }

    //set the value
    interpreter.setValue(into, value);
  }
}
