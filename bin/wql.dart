import 'dart:async';
import 'dart:convert';

import 'package:js_bindings/js_bindings.dart';
import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/wql/statements/setStatement.dart';
import 'package:web_content_parser/src/wql/wql.dart';
import 'package:web_content_parser/util.dart';

void main() {
  replaceFunctions();

  final WebSocket ws = WebSocket('ws://localhost:4040/ws');

  ws.addEventListener('open', (event) {
    ws.send('Hello from client!');
  });

  ws.addEventListener('message', (event) async {
    event = event as MessageEvent;
    final data = event.data;
    String message = '';
    try {
      final json = jsonDecode(data);

      if (json['event'] == 'execute') {
        late final Result response;

        try {
          final result = await runWQL(json['code'], parameters: json['params'], throwErrors: true);

          if (result.pass) {
            response = Result.pass(result.data!['return']);
          } else {
            response = const Result.fail();
            message = 'Failed without throwing';
          }
        } catch (e, stack) {
          window.console.error(e);
          window.console.error(stack);
          message = '$e $stack';
          response = const Result.fail();
        }

        ws.send(jsonEncode({
          'event': 'result',
          'data': ResultExtended.toJson(response),
          'message': message,
        }));
      }
    } catch (e) {
      window.console.error(e);
    }
  });
}

void replaceFunctions() {
  loadWQLFunctions();

  SetStatement.functions['getdocument'] = (args) {
    return window.document;
  };
}
