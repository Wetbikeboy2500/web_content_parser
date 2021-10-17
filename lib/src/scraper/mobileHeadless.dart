import 'dart:async';

import 'dart:io' show Platform;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'headless.dart';
import '../util/Result.dart';

class MobileHeadless extends Headless {
  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<Result> getHtml(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return Future.value(const Result.fail());
    }

    final Completer<Result> completer = Completer();

    //TODO: move this into a queue system to not spin off and keep recreating webviews
    //TODO: allow other methods, but get cookies first
    final HeadlessInAppWebView headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: uri),
      onProgressChanged: (controller, number) {
        if (number == 100) {
          if (!completer.isCompleted) {
            controller.getHtml().then((value) {
              completer.complete(Result.pass(value));
            });
          }
        }
      },
      onLoadError: (controller, link, number, output) {
        if (!completer.isCompleted) {
          controller.getHtml().then((value) {
            completer.complete(const Result.fail());
          });
        }
      },
      onLoadHttpError: (controller, link, number, output) {
        if (!completer.isCompleted) {
          controller.getHtml().then((value) {
            completer.complete(const Result.fail());
          });
        }
      },
    );

    headless.run();

    return completer.future;
  }
}
