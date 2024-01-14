import 'dart:async';
import 'dart:collection';

import 'dart:io' show Platform;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:web_content_parser/headless.dart';
import 'package:web_content_parser/web_content_parser_full.dart';

class MobileHeadless extends Headless {
  @override
  bool get isSupported => Platform.isAndroid;

  bool running = false;

  HeadlessInAppWebView? headless;

  final Queue<Function> requests = Queue();

  final Map<String, Map<String, String>> _cookies = {};
  final Map<String, String> _idToHost = {};

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
    //TODO: by default, don't load unnecassary files (css, images, fonts, etc)
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
                    log2('Failed to save cookies', e, level: const LogLevel.error());
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
  Future<Result<String>> getHtml(String url, String? id) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return Future.value(const Result.fail());
    }

    if (id != null) {
      _idToHost[id] = uri.host;
    }

    final Completer<Result<String>> completer = Completer();

    runQueue(completer, uri);

    return completer.future;
  }

  Future<Result<Map<String, String>>> getCookies(String url) async {
    final uri = UriResult.parse(url);

    if (uri.fail) {
      return const Fail();
    }

    final Map<String, String>? cookies = _cookies[uri.data!.host];

    if (cookies != null) {
      return Result.pass(cookies);
    }

    return const Fail();
  }

  @override
  Future<Result<Map<String, String>>> getCookiesForUrl(String url) {
    return getCookies(url);
  }

  @override
  Future<Result<Map<String, String>>> getCookiesForId(String id) {
    final String? host = _idToHost[id];

    if (host == null) {
      return Future.value(const Result.fail());
    }

    return getCookies(host);
  }
}
