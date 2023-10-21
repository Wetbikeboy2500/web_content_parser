import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:js/js.dart';
import 'package:js_bindings/js_bindings.dart' hide Response, Request;
import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/wql/statements/setStatement.dart';
import 'package:web_content_parser/src/wql/wql.dart';
import 'package:web_content_parser/util.dart';

import 'shared.dart';

// ignore: non_constant_identifier_names
@JS('GM_setValue')
external void setValue(String key, String value);

// ignore: non_constant_identifier_names
@JS('GM_getValue')
external String? getValue(String key);

typedef JSON = Map<String, dynamic>;

///UID, Code, Params
typedef QueueItem = (String, String, Map<String, dynamic>);

const websocketUrl = 'ws://localhost:4040/ws';

void main() {
  if (onReadyPage()) {
    setIsReady(true);

    //establish connection
    final WebSocket ws = WebSocket(websocketUrl);

    ws.addEventListener('open', (event) {
      final status = StatusResponse(getQueue().map((e) => e.$1).toList(), getResults());
      window.console.log('Opening connection and sending status', status);
      ws.send(jsonEncode(status.toJson()));
      setIsReady(false);
    });

    ws.addEventListener('message', (event) {
      window.console.log(event);
      try {
        final message = decodeEvent(event);

        if (Confirmation.isConfirmation(message)) {
          processConfirmation(Confirmation.fromJson(message), ws);
        } else if (Request.isRequest(message)) {
          processRequest(Request.fromJson(message), ws);
        } else {
          window.console.error('Unknown message type');
        }
      } catch (e, stack) {
        window.console.error(e);
        window.console.error(stack);
      }
    });
  } else if (getReady() && onScrapePage()) {
    //get request to run
    final urls = getUrlQueue();

    final request = urls.firstWhere((element) => element.$2 == window.location.href, orElse: () => ('', ''));

    if (request.$1 == '') {
      window.console.error('Failed to find request');
      return;
    }

    //run request
    final queue = getQueue();
    final index = queue.indexWhere((element) => element.$1 == request.$1);

    if (index == -1) {
      window.console.error('Failed to find request in queue');
      return;
    }

    final code = queue[index].$2;
    final params = queue[index].$3;

    initializeWQL();

    runWQL(code, parameters: params, throwErrors: false).then((value) {
      final results = getResults();
      results.add((request.$1, jsonEncode(value)));
      if (!saveRequests(results)) {
        window.console.error('Failed to save results');
        return;
      }
      queue.removeAt(index);
      if (!saveQueue(queue)) {
        window.console.error('Failed to save queue');
        return;
      }
      setIsReady(true);
      //redirect to ready page
      window.location.href = 'http://localhost:4040/ready';
    });
  }
}

void initializeWQL() {
  loadWQLFunctions();
  SetStatement.functions['getdocument'] = (args) => window.document;
  SetStatement.functions['gotopage'] = (args) {
    final urlString = args[0] as String;
    final uid = args[1] as String;
    if (window.location.href == urlString) {
      return true;
    }
    if (!saveToUrlQueue(uid, urlString)) {
      window.console.error('Failed to save url queue');
      return false;
    }
    window.location.href = urlString;
    return false;
  };
}

Map<String, dynamic> decodeEvent(Event event) {
  return jsonDecode((event as MessageEvent).data);
}

bool saveToUrlQueue(String uid, String url) {
  final queue = getUrlQueue();
  //get index for uid if it exists
  final index = queue.indexWhere((element) => element.$1 == uid);
  if (index != -1) {
    queue.removeAt(index);
  }
  queue.add((uid, url));
  return saveUrlQueue(queue);
}

bool saveUrlQueue(List<(String, String)> queue) {
  try {
    setValue('urlQueue', jsonEncode(queue));
    return true;
  } catch (e) {
    window.console.error(e);
    return false;
  }
}

List<(String, String)> getUrlQueue() {
  return jsonDecode(getValue('urlQueue') ?? '[]');
}

List<QueueItem> getQueue() {
  return jsonDecode(getValue('queue') ?? '[]');
}

bool saveQueue(List<QueueItem> queue) {
  try {
    setValue('queue', jsonEncode(queue));
    return true;
  } catch (e) {
    window.console.error(e);
    return false;
  }
}

List<(String, String)> getResults() {
  return jsonDecode(getValue('results') ?? '{}');
}

bool saveRequests(List<(String, String)> results) {
  try {
    setValue('results', jsonEncode(results));
    return true;
  } catch (e) {
    window.console.error(e);
    return false;
  }
}

bool onReadyPage() {
  return window.location.href == 'http://localhost:4040/ready';
}

bool onScrapePage() {
  final queue = getQueue();
  final urlToQueue = getUrlQueue();

  for (final item in urlToQueue) {
    final uid = item.$1;
    final url = item.$2;

    if (window.location.href == url) {
      //TODO: can make this more efficent by returning the index
      final index = queue.indexWhere((element) => element.$1 == uid);
      if (index == -1) {
        window.console.error('Failed to find request in queue');
        return false;
      }
      return true;
    }
  }

  return false;
}

bool getReady() {
  return getValue('ready') == 'true';
}

void setIsReady(bool ready) {
  setValue('ready', ready.toString());
}

void processRequest(Request request, WebSocket ws) {
  final results = jsonDecode(getValue('results') ?? '{}');

  if (results.containsKey(request.uid)) {
    final response = Response(request.uid, results[request.uid]);
    ws.send(response.toJson());
    return;
  }

  final queue = getQueue();
  request.params['uid'] = request.uid;
  queue.add((request.uid, request.code, request.params));
  if (!saveQueue(queue)) {
    window.console.error('Failed to save queue');
    return;
  }
  setIsReady(true);

  initializeWQL();

  runWQL(request.code, parameters: request.params, throwErrors: false);
}

///On confirmation, remove the uid from the queue, results, and url queue if they exist
void processConfirmation(Confirmation confirmation, WebSocket ws) {
  //TODO: also need to take into account whether the confirmation is true or false.
  //if false, still remove everything, but also reply to the server with a rerequest
  //Maybe alos have a retry limit

  final queue = getQueue();
  final queueLength = queue.length;
  queue.removeWhere((element) => element.$1 == confirmation.uid);
  if (queueLength != queue.length) {
    if (!saveQueue(queue)) {
      window.console.error('Failed to save queue');
    }
  }

  final urlQueue = getUrlQueue();
  final urlQueueLength = urlQueue.length;
  urlQueue.removeWhere((element) => element.$1 == confirmation.uid);
  if (urlQueueLength != urlQueue.length) {
    if (!saveUrlQueue(urlQueue)) {
      window.console.error('Failed to save url queue');
    }
  }

  final results = getResults();
  final resultsLength = results.length;
  results.removeWhere((element) => element.$1 == confirmation.uid);
  if (resultsLength != results.length) {
    if (!saveRequests(results)) {
      window.console.error('Failed to save results');
    }
  }
}
