//This file is to define custom functions to scrape site that other scripts or directly integrated systems can also use

//TODO: build a tmp page cache(build in) and long page cache(developer defined) system. Tmp page cache for when two request need to be made for the same resource

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:web_content_parser/parser.dart';
import 'package:web_content_parser/src/util/log.dart';
import 'package:web_content_parser/src/util/parseUriResult.dart';

import '../../util/Result.dart';
import '../../util/ResultExtended.dart';
import '../../util/firstWhereResult.dart';

Future<Map<String, dynamic>> postRequest(String url, Object? body, Map<String, String>? headers) async {
  final Result<Uri> uri = UriResult.parse(url);

  if (uri is! Pass<Uri>) {
    return ResultExtended.toJson(const Fail());
  }

  try {
    final Response result = await post(
      uri.data,
      headers: headers,
      body: jsonEncode(body),
    );
    return ResultExtended.toJson(Pass(result));
  } catch (e, stack) {
    log2('Post failed: ', e, level: const LogLevel.error());
    log(stack, level: const LogLevel.debug());
    return ResultExtended.toJson(const Fail());
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
Future<Result<String>> getDynamicPage(String url, {String? id}) async {
  final Result<Headless> headless =
      WebContentParser.headlessBrowsers.firstWhereResult((element) => element.isSupported);
  //means headless exists for the current platform
  if (headless case Pass<Headless>(data: final data)) {
    //allow to use requests that are or have been made
    final Completer<Result<String>>? cachedRequest = _getDynamicCache[url];
    if (cachedRequest != null) {
      return cachedRequest.future;
    }

    //Create this for other requests to listen to a future
    final Completer<Result<String>> task = Completer<Result<String>>();
    _getDynamicCache[url] = task;

    final result = await data.getHtml(url, id);

    //completes the futures
    task.complete(result);

    //schedule a cache clear
    Timer(WebContentParser.cacheTime, () => _getDynamicCache.remove(url));

    //still need to return the actual result since task.future is not returned for the orginal request
    return result;
  }
  //generic fail
  return const Fail();
}
