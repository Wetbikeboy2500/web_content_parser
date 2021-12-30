//This file is to define custom functions to scrape site that other scripts or directly integrated systems can also use

//TODO: build a tmp page cache(build in) and long page cache(developer defined) system. Tmp page cache for when two request need to be made for the same resource

import 'dart:async';

import 'package:hetu_script/hetu_script.dart';
import 'package:web_content_parser/parser.dart';
import 'package:web_content_parser/src/util/log.dart';
import 'package:web_content_parser/src/util/parseUriResult.dart';
import '../util/ResultExtended.dart';

import '../scraper/headless.dart';

import '../util/Result.dart';
import '../util/firstWhereResult.dart';

import 'package:http/http.dart';

///Hetu post request
///
///Returns a response object wrapped with a result as a map
Future<Map<String, dynamic>> postRequest(
  HTEntity entity, {
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  List<HTType> typeArgs = const <HTType>[],
}) async {
  final Result<Uri> uri = UriResult.parse(positionalArgs[0]);

  if (uri.fail) {
    return ResultExtended.toJson(const Result.fail());
  }

  final Map<String, String>? headers =
      (namedArgs.containsKey('headers')) ? namedArgs['headers'] as Map<String, String> : null;

  try {
    final result = await post(
      uri.data!,
      headers: headers,
      body: positionalArgs[1],
    );

    return ResultExtended.toJson(Result.pass(result));
  } catch (e) {
    log2('Post failed: ', e);
    return ResultExtended.toJson(const Result.fail());
  }
}

final Map<String, Completer<Response>> _getCache = {};

//TODO: make a lite version that just returns body and status which would be better for caching
Future<Response?> getRequest(
  HTEntity entity, {
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  List<HTType> typeArgs = const <HTType>[],
}) async {
  //get the request url to a standard format
  final Uri uri = Uri.parse(positionalArgs[0]);
  final String uriString = uri.toString();

  //return a cached element if it exists
  final Completer<Response>? cachedRequest = _getCache[uriString];
  if (cachedRequest != null) {
    return cachedRequest.future;
  }

  //make sure we make a completer for the request asap
  final Completer<Response> request = Completer<Response>();
  _getCache[uriString] = request;

  //set any custom headers if provided
  final Map<String, String>? headers =
      (namedArgs.containsKey('headers')) ? namedArgs['headers'] as Map<String, String> : null;

  //make the request
  final Response r = await get(uri, headers: headers);

  request.complete(r);

  //schedule a cache clear
  Timer(WebContentParser.cacheTime, () => _getCache.remove(uriString));

  //return result
  return r;
}

Future<Map<String, dynamic>> getDynamicPageHetu(
  HTEntity entity, {
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  List<HTType> typeArgs = const <HTType>[],
}) async {
  final String url = positionalArgs[0];

  return ResultExtended.toJson(await getDynamicPage(url));
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
