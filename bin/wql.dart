import 'dart:convert';

import 'package:js_bindings/bindings/all_bindings.dart';
import 'package:js_bindings/js_bindings.dart';
import 'package:web_content_parser/src/util/ResultExtended.dart';
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
    try {
      final json = jsonDecode(data);

      if (json['event'] == 'execute') {
        final result = await runWQL(json['code'], parameters: json['params']);

        late final Result response;

        if (result.pass) {
          response = Result.pass(result.data!['return']);
        } else {
          response = const Result.fail();
        }

        ws.send(jsonEncode({
          'event': 'result',
          'data': ResultExtended.toJson(response),
        }));
      }
    } catch (e) {
      print(e);
    }
  });
}

void replaceFunctions() {
    SetStatement.functions['getdocument'] = (args) {
    return window.document;
  };

  SetStatement.functions['queryselector'] = (args) {
    final Element? arg0 = (args[0] is List) ? args[0].first : args[0];
    final String arg1 = (args[1] is List) ? args[1].first : args[1];
    if (arg0 == null) {
      return null;
    }
    return arg0.querySelector(arg1);
  };

  SetStatement.functions['queryselectorall'] = (args) {
    final Element? arg0 = (args[0] is List) ? args[0].first : args[0];
    final String arg1 = (args[1] is List) ? args[1].first : args[1];
    if (arg0 == null) {
      return null;
    }
    return arg0.querySelectorAll(arg1);
  };

  SetStatement.functions['text'] = (args) {
    final Element? arg0 = (args[0] is List) ? args[0].first : args[0];
    return arg0?.textContent;
  };

  SetStatement.functions['innerhtml'] = (args) {
    final Element? arg0 = (args[0] is List) ? args[0].first : args[0];
    return arg0?.innerHTML;
  };

  SetStatement.functions['outerhtml'] = (args) {
    final Element? arg0 = (args[0] is List) ? args[0].first : args[0];
    return arg0?.outerHTML;
  };

  SetStatement.functions['attribute'] = (args) {
    final Element? arg0 = (args[0] is List) ? args[0].first : args[0];
    final String arg1 = (args[1] is List) ? args[1].first : args[1];
    if (arg0 == null) {
      return null;
    }
    return arg0.attributes.getNamedItem(arg1)?.value;
  };

  SetStatement.functions['name'] = (args) {
    final Element? arg0 = (args[0] is List) ? args[0].first : args[0];
    return arg0?.localName;
  };
}