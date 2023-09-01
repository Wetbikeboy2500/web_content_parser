import 'dart:async';
import 'dart:convert';

import 'package:js/js.dart';
import 'package:js_bindings/js_bindings.dart';
import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/wql/statements/setStatement.dart';
import 'package:web_content_parser/src/wql/wql.dart';
import 'package:web_content_parser/util.dart';

// ignore: non_constant_identifier_names
@JS('GM_setValue')
external void setValue(String key, String value);

// ignore: non_constant_identifier_names
@JS('GM_getValue')
external String? getValue(String key);

// enum State {
//   unknown,
//   // Ready to accept a request for a URL
//   ready,
//   // Redriected back due to a request being resolved for a URL
//   resolve,
//   // Executes the given code for a URL
//   execute,
// }

// void main() {
//   //TODO: need to work around some sites preventing ws connection.

//   State readyState = State.unknown;

//   if (window.location.href == 'http://localhost:4040/ready') {
//     readyState = State.ready;
//   } else if (window.location.href == 'http://localhost:4040/resolve') {
//     readyState = State.resolve;
//   } else {
//     if (GM_getValue('target_url') == window.location.href) {
//       readyState = State.execute;
//     }
//   }

//   replaceFunctions();

//   final WebSocket ws = WebSocket('ws://localhost:4040/ws');

//   ws.addEventListener('open', (event) {
//     ws.send(jsonEncode({
//       'event': 'status',
//       'state': readyState.name,
//     }));
//   });

//   ws.addEventListener('message', (event) async {
//     event = event as MessageEvent;
//     final data = event.data;
//     String message = '';
//     try {
//       final json = jsonDecode(data);

//       if (json['event'] == 'execute') {
//         late final Result response;

//         try {
//           final result = await runWQL(json['code'], parameters: json['params'], throwErrors: true);

//           if (result.pass) {
//             response = Result.pass(result.data!['return']);
//           } else {
//             response = const Result.fail();
//             message = 'Failed without throwing';
//           }
//         } catch (e, stack) {
//           window.console.error(e);
//           window.console.error(stack);
//           message = '$e $stack';
//           response = const Result.fail();
//         }

//         ws.send(jsonEncode({
//           'event': 'result',
//           'data': ResultExtended.toJson(response),
//           'message': message,
//         }));
//       }
//     } catch (e) {
//       window.console.error(e);
//     }
//   });
// }

const websocketUrl = 'ws://localhost:4040/ws';

void main2() {
  if (onReadyPage()) {
    //establish connection
    final WebSocket ws = WebSocket(websocketUrl);

    ws.addEventListener('open', (event) {
      //send current queue and results
      getValue('queue');
      getValue('results');
    });

    ws.addEventListener('message', (event) {
      try {
        final message = decodeEvent(event);
        //check to see if result already exists

        //or save message to queue

        //redirect to the target page
      } catch (e, stack) {
        window.console.error(e);
        window.console.error(stack);
      }
    });
  } else if (onScrapePage()) {
    initalizeWQL();

    //get request to run

    //run request

    //save the results

    //return back to the ready page
  }
}

void initalizeWQL() {
  loadWQLFunctions();
  SetStatement.functions['getdocument'] = (args) => window.document;
}

Map<String, dynamic> decodeEvent(Event event) {
  return jsonDecode((event as MessageEvent).data);
}

List<String> getQueue() {
  return [];
}

List<(String, String)> getResults() {
  return [];
}

bool saveQueue() {
  return true;
}

bool saveRequests() {
  return true;
}

bool onReadyPage() {
  return window.location.href == 'http://localhost:4040/ready';
}

bool onScrapePage() {
  //get queue urls
  //check if current url is in queue

  return false;
}

// uid, request object
// uid, result object
