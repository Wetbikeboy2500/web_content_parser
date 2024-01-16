import 'dart:convert';

import 'package:js/js.dart';
import 'package:typings/core.dart' as js;
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

typedef WebSocket = js.WebSocket;

const websocketUrl = 'ws://localhost:4040/ws';

void main() {
  if (onReadyPage()) {
    setIsReady(true);

    //establish connection
    final WebSocket ws = WebSocket(websocketUrl);

    ws.addEventListener.$1(js.WebSocketEventMap.open, (event) {
      final status = StatusResponse(getQueue().map((e) => e.uid).toList(), getResults());
      js.console.log(['Opening connection and sending status', status]);
      ws.send(jsonEncode(status.toJson()));
      setIsReady(false);
    });

    ws.addEventListener.$1(js.WebSocketEventMap.message, (event) {
      js.console.log([event]);
      try {
        final message = decodeEvent(event);

        if (Confirmation.isConfirmation(message)) {
          processConfirmation(Confirmation.fromJson(message), ws);
        } else if (Request.isRequest(message)) {
          processRequest(Request.fromJson(message), ws);
        } else if (ClearQueueRequest.isClearQueueRequest(message)) {
          saveQueue([]);
          saveUrlQueue([]);
          saveRequests({});
        } else {
          js.console.error(['Unknown message type']);
        }
      } catch (e, stack) {
        js.console.error([e]);
        js.console.error([stack]);
      }
    });
  } else if (getReady() && onScrapePage()) {
    js.console.log(['On scrape page']);

    //get request to run
    final urls = getUrlQueue();

    final request =
        urls.firstWhere((element) => element.url == js.window.location.href, orElse: () => UrlQueueItem('', ''));

    if (request.uid == '') {
      js.console.error(['Failed to find request']);
      return;
    }

    //run request
    final queue = getQueue();
    final index = queue.indexWhere((element) => element.uid == request.uid);

    if (index == -1) {
      js.console.error(['Failed to find request in queue']);
      return;
    }

    final code = queue[index].code;
    final params = queue[index].params;

    initializeWQL();

    js.console.log(['run the wql']);

    runWQL(code, parameters: params, throwErrors: false).then((value) {
      js.console.log(['Did request pass?', value is Pass]);
      if (value case Pass()) {
        if (value.data.containsKey('return')) {
          js.console.log(['Data', jsonEncode(value.data['return'])]);
        }
      }
      final results = getResults();

      if (value case Pass()) {
        try {
          results[request.uid] = jsonEncode(ResultExtended.toJson(Pass(value.data!['return'])));
        } catch (e) {
          js.console.error(['Failed to encode result', e]);
          results[request.uid] = jsonEncode(ResultExtended.toJson(const Fail()));
        }
      } else {
        results[request.uid] = jsonEncode(ResultExtended.toJson(const Fail()));
      }

      if (!saveRequests(results)) {
        js.console.error(['Failed to save results']);
        return;
      }
      js.console.log(['Saved results']);

      queue.removeAt(index);
      if (!saveQueue(queue)) {
        js.console.error(['Failed to save queue']);
        return;
      }
      js.console.log(['Saved queue']);
      //TODO: also remove the goto page redirect

      setIsReady(true);
      //redirect to ready page
      js.window.location.href = 'http://localhost:4040/ready';
    });
  }
}

void initializeWQL() {
  loadWQLFunctions();
  SetStatement.functions['getdocument'] = (args) => js.window.document;
  SetStatement.functions['gotopage'] = (args) {
    print(jsonEncode(args));
    final urlString = (args[0] is List) ? args[0].first : args[0];
    final uid = (args[1] is List) ? args[1].first : args[1];
    if (Uri.parse(js.window.location.href).toString() == Uri.parse(urlString).toString()) {
      return true;
    }
    if (!saveToUrlQueue(uid, urlString)) {
      js.console.error(['Failed to save url queue']);
      return false;
    }
    js.window.location.href = urlString;
    return false;
  };
}

Map<String, dynamic> decodeEvent(js.Event event) {
  return jsonDecode((event as js.MessageEvent).data);
}

bool saveToUrlQueue(String uid, String url) {
  final queue = getUrlQueue();
  //get index for uid if it exists
  final index = queue.indexWhere((element) => element.uid == uid);
  if (index != -1) {
    queue.removeAt(index);
  }
  queue.add(UrlQueueItem(uid, url));
  return saveUrlQueue(queue);
}

bool saveUrlQueue(List<UrlQueueItem> queue) {
  try {
    setValue('urlQueue', jsonEncode(queue));
    return true;
  } catch (e) {
    js.console.error([e]);
    return false;
  }
}

class UrlQueueItem {
  final String uid;
  final String url;

  UrlQueueItem(this.uid, this.url);

  static UrlQueueItem fromJson(JSON json) {
    return UrlQueueItem(json['uid'], json['url']);
  }

  JSON toJson() {
    return {'uid': uid, 'url': url};
  }
}

List<UrlQueueItem> getUrlQueue() {
  return List.from(jsonDecode(getValue('urlQueue') ?? '[]')).map((e) => UrlQueueItem.fromJson(e)).toList();
}

List<QueueItem> getQueue() {
  return List.from(jsonDecode(getValue('queue') ?? '[]')).map((e) => QueueItem.fromJson(e)).toList();
}

class QueueItem {
  final String uid;
  final String code;
  final Map<String, dynamic> params;

  QueueItem(this.uid, this.code, this.params);

  static QueueItem fromJson(JSON json) {
    return QueueItem(json['uid'], json['code'], json['params']);
  }

  JSON toJson() {
    return {'uid': uid, 'code': code, 'params': params};
  }
}

bool saveQueue(List<QueueItem> queue) {
  try {
    setValue('queue', jsonEncode(queue));
    return true;
  } catch (e) {
    js.console.error([e]);
    return false;
  }
}

Map<String, String> getResults() {
  return Map.from(jsonDecode(getValue('results') ?? '{}'));
}

bool saveRequests(Map<String, String> results) {
  try {
    setValue('results', jsonEncode(results));
    return true;
  } catch (e) {
    js.console.error([e]);
    return false;
  }
}

bool onReadyPage() {
  return Uri.parse(js.window.location.href).toString() == Uri.parse('http://localhost:4040/ready').toString();
}

bool onScrapePage() {
  final queue = getQueue();
  final urlToQueue = getUrlQueue();

  js.console.log([js.window.location.href, jsonEncode(urlToQueue)]);

  for (final item in urlToQueue) {
    if (Uri.parse(js.window.location.href).toString() == Uri.parse(item.url).toString()) {
      //TODO: can make this more efficent by returning the index
      final index = queue.indexWhere((element) => element.uid == item.uid);
      if (index == -1) {
        js.console.error(['Failed to find request in queue']);
        return false;
      }
      js.console.log(['Found request in queue']);
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

//TODO: if the request is marked as failed in storage, then simply clear result and re-run
void processRequest(Request request, WebSocket ws) {
  final results = getResults();

  if (results.containsKey(request.uid)) {
    final response = Response(request.uid, ResultExtended.fromJson(jsonDecode(results[request.uid]!)));
    ws.send(response.toJson());
    return;
  }

  final queue = getQueue();
  queue.removeWhere((element) => element.uid == request.uid);
  request.params['uid'] = request.uid;
  queue.add(QueueItem(request.uid, request.code, request.params));
  if (!saveQueue(queue)) {
    js.console.error(['Failed to save queue']);
    return;
  }

  final urlQueue = getUrlQueue();
  urlQueue.removeWhere((element) => element.uid == request.uid);
  if (!saveUrlQueue(urlQueue)) {
    js.console.error(['Failed to save url queue but proceeding anyway']);
  }

  setIsReady(true);

  initializeWQL();

  try {
    runWQL(request.code, parameters: request.params, throwErrors: true).then((value) {
      js.console.log(['Did request pass?', value is Pass]);
      if (value case Pass()) {
        if (value.data.containsKey('return')) {
          js.console.log(['Data', jsonEncode(value.data['return'])]);
        }
      }
    });
  } catch (e, stack) {
    js.console.error([e, stack]);
  }
}

///On confirmation, remove the uid from the queue, results, and url queue if they exist
void processConfirmation(Confirmation confirmation, WebSocket ws) {
  //TODO: also need to take into account whether the confirmation is true or false.
  //if false, still remove everything, but also reply to the server with a rerequest
  //Maybe alos have a retry limit

  final queue = getQueue();
  final queueLength = queue.length;
  queue.removeWhere((element) => element.uid == confirmation.uid);
  if (queueLength != queue.length) {
    if (!saveQueue(queue)) {
      js.console.error(['Failed to save queue']);
    }
  }

  final urlQueue = getUrlQueue();
  final urlQueueLength = urlQueue.length;
  urlQueue.removeWhere((element) => element.uid == confirmation.uid);
  if (urlQueueLength != urlQueue.length) {
    if (!saveUrlQueue(urlQueue)) {
      js.console.error(['Failed to save url queue']);
    }
  }

  final results = getResults();
  final resultsLength = results.length;
  results.removeWhere((key, value) => key == confirmation.uid);
  if (resultsLength != results.length) {
    if (!saveRequests(results)) {
      js.console.error(['Failed to save results']);
    }
  }
}
