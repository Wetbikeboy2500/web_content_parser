import 'dart:async';
import 'dart:collection';

import 'dart:io' show Platform;

import 'package:puppeteer/protocol/network.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:web_content_parser/headless.dart';
import 'package:web_content_parser/web_content_parser_full.dart';

class DesktopHeadless extends Headless {
  @override
  bool get isSupported => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  bool running = false;

  Browser? browser;
  BrowserContext? context;

  Future<BrowserContext?> startup() async {
    if (browser == null || context == null) {
      browser = await puppeteer.launch(headless: true);
      context = await browser!.createIncognitoBrowserContext();
    }
    return context;
  }

  void shutdown() async {
    await browser?.close();
    browser = null;
    context = null;
  }

  final Map<String, List<Cookie>> _cookies = {};
  final Map<String, String> _idToHost = {};

  Result<List<Cookie>> getCookies(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      log2('Failed get cookies url parse:', url, level: const LogLevel.warn());
      return const Result.fail();
    }

    final List<Cookie>? cookies = _cookies[uri.host];

    if (cookies == null) {
      log2('Failed to find cookies for url given:', url, level: const LogLevel.warn());
      return const Result.fail();
    }

    return Result.pass(cookies);
  }

  final Queue<Function> requests = Queue();

  void startShutdown() {
    if (browser != null && context != null && running == false) {
      Timer(const Duration(seconds: 5), () {
        if (browser != null && context != null && running == false) {
          shutdown();
        }
      });
    }
  }

  void runQueue(Completer<Result<String>> completer, String url, {String? id}) {
    if (running) {
      requests.add(() => runQueue(completer, url, id: id));
      return;
    }

    running = true;

    ResultExtended.unsafeAsync(startup).then((value) {
      if (value.fail || value.data == null) {
        if (!completer.isCompleted) {
          completer.complete(const Result.fail());
        }
        running = false;
        if (requests.isNotEmpty) {
          requests.removeFirst().call();
        } else {
          startShutdown();
        }
        return;
      }

      value.data!.newPage().then((page) async {
        await page.setUserAgent(
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36');

        final uri = UriResult.parse(url);
        if (uri.pass && _cookies.containsKey(uri.data!.host)) {
          if (id != null) {
            _idToHost[id] = uri.data!.host;
          }
          await page.setCookies(_cookies[uri.data!.host]!.map((e) => CookieParam.fromJson(e.toJson())).toList());
        }

        await page.setJavaScriptEnabled(true);
        await page.goto(url, wait: Until.networkIdle);

        //get cookies for update
        if (uri.pass) {
          _cookies[uri.data!.host] = await page.cookies();
        }

        final String? html = await page.content;

        final Result<String> r;

        if (html == null) {
          r = const Result.fail();
        } else {
          r = Result.pass(html);
        }

        completer.complete(r);
        running = false;
        if (requests.isNotEmpty) {
          requests.removeFirst().call();
        } else {
          startShutdown();
        }
      });
    }).catchError((error) {
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

  @override
  Future<Result<String>> getHtml(String url, String? id) {
    final Completer<Result<String>> completer = Completer();

    runQueue(completer, url, id: id);

    return completer.future;
  }

  @override
  Future<Result<Map<String, String>>> getCookiesForUrl(String url) {
    final Result<List<Cookie>> cookies = getCookies(url);
    final Map<String, String> convertedCookies = {};

    if (cookies.pass) {
      for (final Cookie cookie in cookies.data!) {
        convertedCookies[cookie.name] = cookie.value;
      }
      return Future.value(Result.pass(convertedCookies));
    } else {
      return Future.value(const Result.fail());
    }
  }

  @override
  Future<Result<Map<String, String>>> getCookiesForId(String id) {
    final String? host = _idToHost[id];

    if (host == null) {
      return Future.value(const Result.fail());
    }

    return getCookiesForUrl(host);
  }
}
