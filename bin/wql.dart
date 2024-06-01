import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' hide Request, Response;
import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/wql/statements/setStatement.dart';
import 'package:web_content_parser/src/wql/wql.dart';
import 'package:web_content_parser/util.dart';
import 'package:web_query_framework_util/util.dart';

import 'shared.dart';

// ignore: non_constant_identifier_names
@JS('GM_setValue')
external void setValue(String key, String value);

// ignore: non_constant_identifier_names
@JS('GM_getValue')
external String? getValue(String key);

typedef JSON = Map<String, dynamic>;

const websocketUrl = 'ws://localhost:4040/ws';

void main() {
  if (onReadyPage()) {
    setIsReady(true);

    //establish connection
    final WebSocket ws = WebSocket(websocketUrl);

    ws.onopen = (Event event) {
      final status = StatusResponse(getQueue().map((e) => e.uid).toList(), getResults());
      console.log(['Opening connection and sending status', status].toJSBox);
      ws.send(jsonEncode(status.toJson()).toJS);
      setIsReady(false);
    }.toJS;

    ws.onmessage = (Event event) {
      console.log(event);

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
          console.error('Unknown message type'.toJS);
        }
      } catch (e, stack) {
        console.error(e.toJSBox);
        console.error(stack.toJSBox);
      }
    }.toJS;
  } else if (getReady() && onScrapePage()) {
    console.log('On scrape page'.toJS);

    //get request to run
    final urls = getUrlQueue();

    final request =
        urls.firstWhere((element) => element.url == window.location.href, orElse: () => UrlQueueItem('', ''));

    if (request.uid == '') {
      console.error('Failed to find request'.toJS);
      return;
    }

    //run request
    final queue = getQueue();
    final index = queue.indexWhere((element) => element.uid == request.uid);

    if (index == -1) {
      console.error('Failed to find request in queue'.toJS);
      return;
    }

    final code = queue[index].code;
    final params = queue[index].params;

    initializeWQL();

    console.log('run the wql'.toJS);

    runWQL(code, parameters: params, throwErrors: false).then((value) {
      console.log(['Did request pass?', value is Pass].toJSBox);
      if (value case Pass()) {
        if (value.data.containsKey('return')) {
          console.log(['Data', jsonEncode(value.data['return'])].toJSBox);
        }
      }
      final results = getResults();

      if (value case Pass()) {
        try {
          results[request.uid] = jsonEncode(ResultExtended.toJson(Pass(value.data!['return'])));
        } catch (e) {
          console.error(['Failed to encode result', e].toJSBox);
          results[request.uid] = jsonEncode(ResultExtended.toJson(const Fail()));
        }
      } else {
        results[request.uid] = jsonEncode(ResultExtended.toJson(const Fail()));
      }

      if (!saveRequests(results)) {
        console.error('Failed to save results'.toJS);
        return;
      }
      console.log('Saved results'.toJS);

      queue.removeAt(index);
      if (!saveQueue(queue)) {
        console.error('Failed to save queue'.toJS);
        return;
      }
      console.log('Saved queue'.toJS);
      //TODO: also remove the goto page redirect

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
    print(jsonEncode(args));
    final urlString = (args[0] is List) ? args[0].first : args[0];
    final uid = (args[1] is List) ? args[1].first : args[1];
    if (Uri.parse(window.location.href).toString() == Uri.parse(urlString).toString()) {
      return true;
    }
    if (!saveToUrlQueue(uid, urlString)) {
      console.error('Failed to save url queue'.toJS);
      return false;
    }
    window.location.href = urlString;
    return false;
  };
}

Map<String, dynamic> decodeEvent(Event event) {
  return jsonDecode((event as MessageEvent).data.toString());
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
    console.error(e.toJSBox);
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
    console.error(e.toJSBox);
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
    console.error(e.toJSBox);
    return false;
  }
}

bool onReadyPage() {
  return Uri.parse(window.location.href).toString() == Uri.parse('http://localhost:4040/ready').toString();
}

bool onScrapePage() {
  final queue = getQueue();
  final urlToQueue = getUrlQueue();

  console.log([window.location.href, jsonEncode(urlToQueue)].toJSBox);

  for (final item in urlToQueue) {
    if (Uri.parse(window.location.href).toString() == Uri.parse(item.url).toString()) {
      //TODO: can make this more efficent by returning the index
      final index = queue.indexWhere((element) => element.uid == item.uid);
      if (index == -1) {
        console.error('Failed to find request in queue'.toJS);
        return false;
      }
      console.log('Found request in queue'.toJS);
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
    ws.send(response.toJson().toJSBox);
    return;
  }

  final queue = getQueue();
  queue.removeWhere((element) => element.uid == request.uid);
  request.params['uid'] = request.uid;
  queue.add(QueueItem(request.uid, request.code, request.params));
  if (!saveQueue(queue)) {
    console.error('Failed to save queue'.toJS);
    return;
  }

  final urlQueue = getUrlQueue();
  urlQueue.removeWhere((element) => element.uid == request.uid);
  if (!saveUrlQueue(urlQueue)) {
    console.error('Failed to save url queue but proceeding anyway'.toJS);
  }

  setIsReady(true);

  initializeWQL();

  try {
    runWQL(request.code, parameters: request.params, throwErrors: true).then((value) {
      console.log(['Did request pass?', value is Pass].toJSBox);
      if (value case Pass()) {
        if (value.data.containsKey('return')) {
          console.log(['Data', jsonEncode(value.data['return'])].toJSBox);
        }
      }
    });
  } catch (e, stack) {
    console.error([e, stack].toJSBox);
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
      console.error('Failed to save queue'.toJS);
    }
  }

  final urlQueue = getUrlQueue();
  final urlQueueLength = urlQueue.length;
  urlQueue.removeWhere((element) => element.uid == confirmation.uid);
  if (urlQueueLength != urlQueue.length) {
    if (!saveUrlQueue(urlQueue)) {
      console.error('Failed to save url queue'.toJS);
    }
  }

  final results = getResults();
  final resultsLength = results.length;
  results.removeWhere((key, value) => key == confirmation.uid);
  if (resultsLength != results.length) {
    if (!saveRequests(results)) {
      console.error('Failed to save results'.toJS);
    }
  }
}
