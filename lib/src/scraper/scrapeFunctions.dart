//This file is to define custom functions to scrape site that other scripts or directly integrated systems can also use

//TODO: build a tmp page cache(build in) and long page cache(developer defined) system. Tmp page cache for when two request need to be made for the same resource

import 'dart:async';

import 'package:hetu_script/type/type.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

//TODO: postRequest() {}

Timer? _removeCache;

/*TODO:
 * I am going to keep this as a const for now as the idea is more for reducing same requests that are close to each other.
 * There is still more that can be done for self-defined cache times.
 * Cache will always be limited by applications total runtime since it will never save to anywhere
 */
const _cacheTimeMilliseconds = 1000;

final Map<String, Tuple2<int, Response>> _getCache = {};

void _cleanGetCache(List<String> uriStrings) {
  print(uriStrings);
  //Remove outdated
  for (final key in uriStrings) {
    _getCache.remove(key);
  }

  //Queue all that still exist to be removed
  if (_getCache.isNotEmpty && (_removeCache == null || !_removeCache!.isActive)) {
    _removeCache = Timer(Duration(milliseconds: _cacheTimeMilliseconds), () => _cleanGetCache(<String>[..._getCache.keys]));
  }
}

//TODO: make a lite version that just returns body and status which would be better for caching
Future<Response> getRequest({
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  List<HTType> typeArgs = const <HTType>[],
}) async {
  final Uri uri = Uri.parse(positionalArgs[0]);
  final String uriString = uri.toString();

  if (_getCache.containsKey(uriString)) {
    if (DateTime.now().millisecondsSinceEpoch - _getCache[uriString]!.item1  >= _cacheTimeMilliseconds) {
      _getCache.remove(uriString);
    } else {
      return _getCache[uriString]!.item2;
    }
  }

  late final Map<String, String>? headers = (namedArgs.containsKey('headers')) ? namedArgs['headers'] as Map<String, String> : null;

  final Response r = await get(uri, headers: headers);

  _getCache[uriString] = Tuple2(DateTime.now().millisecondsSinceEpoch, r);

  if (_removeCache == null || !_removeCache!.isActive) {
    _removeCache = Timer(Duration(milliseconds: _cacheTimeMilliseconds), () => _cleanGetCache([uriString]));
  }

  return r;
}
