import 'dart:async';
import 'dart:collection';

import 'package:puppeteer/protocol/network.dart';
import 'package:puppeteer/puppeteer.dart';
import '../../util/log.dart';
import 'headless.dart';
import '../../util/firstWhereResult.dart';
import '../../util/ResultExtended.dart';
import '../../util/parseUriResult.dart';

import 'dart:io' show Platform;

import '../../util/Result.dart';

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

  final Map<Uri, List<Cookie>> cookies = {};

  Result<List<Cookie>> getCookies(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      log2('Failed get cookies url parse:', url);
      return const Result.fail();
    }

    final Result<MapEntry<Uri, List<Cookie>>> r =
        cookies.entries.firstWhereResult((element) => element.key.host == uri.host);

    if (r.fail) {
      log2('Failed to find cookies for url given:', url);
      return const Result.fail();
    }

    return Result.pass(r.data!.value);
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

  void runQueue(Completer<Result<String>> completer, String url) {
    if (running) {
      requests.add(() => runQueue(completer, url));
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
        if (uri.pass && cookies.containsKey(uri.data)) {
          await page.setCookies(cookies[uri.data]!.map((e) => CookieParam.fromJson(e.toJson())).toList());
        }

        await page.setJavaScriptEnabled(true);
        await page.goto(url, wait: Until.networkIdle);

        //get cookies for update
        if (uri.pass) {
          cookies[uri.data!] = await page.cookies();
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
  Future<Result<String>> getHtml(String url) {
    final Completer<Result<String>> completer = Completer();

    runQueue(completer, url);

    return completer.future;
  }
}
