import 'dart:async';

import 'package:path/path.dart';
import 'package:puppeteer/puppeteer.dart';
import '../scraper/headless.dart';
import '../util/ResultExtended.dart';

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
  void shutdown() async {
    await browser?.close();
    browser = null;
    context = null;
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
