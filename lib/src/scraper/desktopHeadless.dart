import 'dart:async';

import 'package:puppeteer/protocol/network.dart';
import 'package:puppeteer/puppeteer.dart';
import '../util/log.dart';
import '../scraper/headless.dart';
import '../util/firstWhereResult.dart';
import '../util/ResultExtended.dart';
import '../util/parseUriResult.dart';

import 'dart:io' show Platform;

import '../util/Result.dart';

class DesktopHeadless extends Headless {
  @override
  bool get isSupported => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  Browser? browser;
  BrowserContext? context;

  Future<BrowserContext?> startup() async {
    if (browser == null || context == null) {
      browser = await puppeteer.launch(headless: true);
      context = await browser!.createIncognitoBrowserContext();
    }
    return context;
  }

  //TODO: add delay on this like computer system
  //TODO: this will also have issues for concurrent requests
  void shutdown() async {
    await browser?.close();
    browser = null;
    context = null;
  }

  final Map<Uri, List<Cookie>> cookies = {};

  Result<List<Cookie>> getCookies(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      log('Failed get cookies url parse: $url');
      return const Result.fail();
    }

    final Result<MapEntry<Uri, List<Cookie>>> r = cookies.entries.firstWhereResult((element) => element.key.host == uri.host);

    if (r.fail) {
      log('Failed to find cookies for url given: $url');
      return const Result.fail();
    }

    return Result.pass(r.data!.value);
  }

  @override
  Future<Result> getHtml(String url) {
    final Completer<Result> completer = Completer();

    ResultExtended.unsafeAsync(startup).then((value) {
      if (value.fail || value.data == null) {
        if (!completer.isCompleted) {
          shutdown();
          completer.complete(const Result.fail());
        }
        return;
      }

      value.data!.newPage().then((page) async {
        await page.setUserAgent(
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.0 Safari/537.36');
        await page.setJavaScriptEnabled(true);
        await page.goto(url, wait: Until.networkIdle);

        //get cookies
        final uri = UriResult.parse(url);
        if (uri.pass) {
          print(await page.cookies());
          cookies[uri.data!] = await page.cookies();
        }

        final Result r = Result.pass(await page.content);
        shutdown();
        completer.complete(r);
      });
    }).catchError((error) {
      if (!completer.isCompleted) {
        shutdown();
        completer.complete(const Result.fail());
      }
    });

    return completer.future;
  }
}
