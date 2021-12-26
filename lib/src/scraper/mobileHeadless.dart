import 'dart:async';
import 'dart:collection';

import 'dart:io' show Platform;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_content_parser/src/util/log.dart';
import 'package:web_content_parser/src/util/parseUriResult.dart';
import 'headless.dart';
import '../util/Result.dart';

class MobileHeadless extends Headless {
  @override
  bool get isSupported => Platform.isAndroid;

  bool running = false;

  HeadlessInAppWebView? headless;

  final Queue<Function> requests = Queue();

  final Map<String, Map<String, String>> _cookies = {};

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

  void runQueue(Completer<Result<String>> completer, Uri uri) {
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
            controller.getHtml().then((value) async {
              if (!completer.isCompleted) {
                if (value == null) {
                  completer.complete(const Result.fail());
                } else {
                  try {
                    //save good request cookies
                    final String cookies = await controller.evaluateJavascript(source: 'document.cookie') as String;

                    final Iterable<List<String>> splitCookies =
                        cookies.split(';').map<List<String>>((cookie) => cookie.trim().split('='));

                    final Map<String, String> tmpCookies = {};
                    for (final l in splitCookies) {
                      if (l.length == 2) {
                        tmpCookies[l[0]] = l[1];
                      }
                    }
                    _cookies[uri.host] = tmpCookies;
                  } catch (e) {
                    log2('Failed to save cookies', e);
                  }

                  completer.complete(Result.pass(value));
                }
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
  Future<Result<String>> getHtml(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return Future.value(const Result.fail());
    }

    final Completer<Result<String>> completer = Completer();

    runQueue(completer, uri);

    return completer.future;
  }

  Future<Result<Map<String, String>>> getCookies(String url) async {
    final uri = UriResult.parse(url);

    if (uri.fail) {
      return const Result.fail();
    }

    final Map<String, String>? cookies = _cookies[uri.data!.host];

    if (cookies != null) {
      return Result.pass(cookies);
    }

    return const Result.fail();
  }
}
