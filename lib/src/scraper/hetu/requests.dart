import 'package:hetu_script/hetu_script.dart';
import 'package:http/http.dart';

import '../../util/ResultExtended.dart';
import '../generic/scrapeFunctions.dart';

///Hetu post request
///
///Returns a response object wrapped with a result as a map
Future<Map<String, dynamic>> postRequestHetu(
  HTEntity entity, {
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  List<HTType> typeArgs = const <HTType>[],
}) async {
  final Map<String, String>? headers =
      (namedArgs.containsKey('headers')) ? namedArgs['headers'] as Map<String, String> : null;
  return await postRequest(positionalArgs[0], positionalArgs[1], headers);
}


//TODO: make a lite version that just returns body and status which would be better for caching
Future<Response?> getRequestHetu(
  HTEntity entity, {
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  List<HTType> typeArgs = const <HTType>[],
}) async {
  //set any custom headers if provided
  final Map<String, String>? headers =
      (namedArgs.containsKey('headers')) ? namedArgs['headers'] as Map<String, String> : null;

  return getRequest(positionalArgs[0], headers);
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