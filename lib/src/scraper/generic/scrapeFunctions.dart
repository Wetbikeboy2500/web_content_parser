//This file is to define custom functions to scrape site that other scripts or directly integrated systems can also use

//TODO: build a tmp page cache(build in) and long page cache(developer defined) system. Tmp page cache for when two request need to be made for the same resource

import 'dart:async';
import 'package:web_content_parser/parser.dart';
import 'package:web_content_parser/src/util/log.dart';
import 'package:web_content_parser/src/util/parseUriResult.dart';
import '../../util/ResultExtended.dart';

import '../headless/headless.dart';

import '../../util/Result.dart';
import '../../util/firstWhereResult.dart';

import 'package:http/http.dart';

Future<Map<String, dynamic>> postRequest(String url, Object? body, Map<String, String>? headers) async {
  final Result<Uri> uri = UriResult.parse(url);

  if (uri.fail) {
    return ResultExtended.toJson(const Result.fail());
  }

  try {
    final Response result = await post(
      uri.data!,
      headers: headers,
      body: body,
    );
    return ResultExtended.toJson(Result.pass(result));
  } catch (e, stack) {
    log2('Post failed: ', e, level: const LogLevel.error());
    log(stack, level: const LogLevel.debug());
    return ResultExtended.toJson(const Result.fail());
  }
}

final Map<String, Completer<Response>> _getCache = {};

Future<Response?> getRequest(String url, Map<String, String>? headers) async {
  //get the request url to a standard format
  final Uri uri = Uri.parse(url);
  final String uriString = uri.toString();

  //return a cached element if it exists
  final Completer<Response>? cachedRequest = _getCache[uriString];
  if (cachedRequest != null) {
    return cachedRequest.future;
  }

  //make sure we make a completer for the request asap
  final Completer<Response> request = Completer<Response>();
  _getCache[uriString] = request;

  //make the request
  final Response r = await get(uri, headers: headers);

  request.complete(r);

  //schedule a cache clear
  Timer(WebContentParser.cacheTime, () => _getCache.remove(uriString));

  //return result
  return r;
}

final Map<String, Completer<Result<String>>> _getDynamicCache = {};

///Provides a standard interface for dynamic requests along with request caching
Future<Result<String>> getDynamicPage(String url) async {
  final Result<Headless> headless =
      WebContentParser.headlessBrowsers.firstWhereResult((element) => element.isSupported);
  //means headless exists for the current platform
  if (headless.pass) {
    //allow to use requsts that are or have been made
    final Completer<Result<String>>? cachedRequest = _getDynamicCache[url];
    if (cachedRequest != null) {
      return cachedRequest.future;
    }

    //Create this for other requests to listen to a future
    final Completer<Result<String>> task = Completer<Result<String>>();
    _getDynamicCache[url] = task;

    final result = await headless.data!.getHtml(url);

    //completes the futures
    task.complete(result);

    //schedule a cache clear
    Timer(WebContentParser.cacheTime, () => _getDynamicCache.remove(url));

    //still need to return the actual result since task.future is not returned for the orginal request
    return result;
  }
  //generic fail
  return const Result.fail();
}
