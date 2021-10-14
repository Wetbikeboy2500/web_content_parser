//This file is to define custom functions to scrape site that other scripts or directly integrated systems can also use

//TODO: build a tmp page cache(build in) and long page cache(developer defined) system. Tmp page cache for when two request need to be made for the same resource

import 'dart:async';

import 'package:web_content_parser/parser.dart';

import '../scraper/headless.dart';

import '../util/Result.dart';
import '../util/firstWhereResult.dart';

import 'package:hetu_script/type/type.dart';
import 'package:http/http.dart';

//TODO: postRequest() {}

/*TODO:
 * I am going to keep this as a const for now as the idea is more for reducing same requests that are close to each other.
 * There is still more that can be done for self-defined cache times.
 * Cache will always be limited by applications total runtime since it will never save to anywhere
 */
const _cacheTimeMilliseconds = 1000;

final Map<String, Completer<Response>> _getCache = {};

//TODO: make a lite version that just returns body and status which would be better for caching
Future<Response?> getRequest({
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  List<HTType> typeArgs = const <HTType>[],
}) async {
  //get the request url to a standard format
  final Uri uri = Uri.parse(positionalArgs[0]);
  final String uriString = uri.toString();

  //return a cached element if it exists
  if (_getCache.containsKey(uriString)) {
    return _getCache[uriString]!.future;
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
  Timer(const Duration(milliseconds: _cacheTimeMilliseconds), () => _getCache.remove(uriString));

  //return result
  return r;
}

Future<Result> getDynamicPage(String url) async {
  final Result<Headless> headless = WebContentParser.headlessBrowsers.firstWhereResult((element) => element.isSupported);
  if (headless.pass) {
    return await headless.data!.getHtml();
  }
  //generic fail
  return headless;
}


