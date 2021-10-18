import 'dart:async';
import 'dart:collection';

import 'dart:io' show Platform;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_content_parser/src/util/ResultExtended.dart';
import 'headless.dart';
import '../util/Result.dart';

class MobileHeadless extends Headless {
  @override
  bool get isSupported => Platform.isAndroid;

  bool running = false;

  HeadlessInAppWebView? headless;

  final Queue<Function> requests = Queue();

  void startShutdown() {
    if (headless != null && running == false) {
      Timer(const Duration(seconds: 5), () {
        if (headless != null && running == false) {
          headless?.dispose();
          headless = null;
        }
      });
    }
  }

  void runQueue(Completer completer, Uri uri) {
    if (running) {
      requests.add(() => runQueue(completer, uri));
      return;
    }

    running = true;

    //make sure headless is disposed before creating another
    headless?.dispose();

    //TODO: allow system to get cookies
    headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: uri),
      onProgressChanged: (controller, number) {
        if (number == 100) {
          if (!completer.isCompleted) {
            controller.getHtml().then((value) {
              if (!completer.isCompleted) {
                completer.complete(Result.pass(value));
                running = false;
                if (requests.isNotEmpty) {
                  requests.removeFirst().call();
                } else {
                  startShutdown();
                }
              }
            });
          }
        }
      },
      onLoadError: (controller, link, number, output) {
        if (!completer.isCompleted) {
          controller.getHtml().then((value) {
            if (!completer.isCompleted) {
              completer.complete(const Result.fail());
              running = false;
              if (requests.isNotEmpty) {
                requests.removeFirst().call();
              } else {
                startShutdown();
              }
            }
          });
        }
      },
      onLoadHttpError: (controller, link, number, output) {
        if (!completer.isCompleted) {
          controller.getHtml().then((value) {
            if (!completer.isCompleted) {
              completer.complete(const Result.fail());
              running = false;
              if (requests.isNotEmpty) {
                requests.removeFirst().call();
              } else {
                startShutdown();
              }
            }
          });
        }
      },
    );

    headless!.run();
  }

  @override
  Future<Result> getHtml(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return Future.value(const Result.fail());
    }

    final Completer<Result> completer = Completer();

    runQueue(completer, uri);

    return completer.future;
  }

  Future<Result<List<Cookie>>> getCookies(String url) async {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return Future.value(const Result.fail());
    }

    return ResultExtended.unsafeAsync(() async => CookieManager().getCookies(url: uri));
  }
}
