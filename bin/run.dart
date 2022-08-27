import 'dart:convert';
import 'dart:io';

import 'package:web_content_parser/scraper.dart';
import 'package:web_content_parser/src/scraper/scraper.dart';

import 'package:path/path.dart' as path;
import 'package:web_content_parser/src/util/log.dart';

///Example: dart bin/run.dart ./test/samples/wql google text
///TODO: add a verbose option
void main(List<String> args) {
  WebContentParser.verbose = const LogLevel.debug();
  late final List<MapEntry<String, dynamic>> entries;

  if (args.length > 3) {
    entries = args.skip(3).map((e) {
      final List<String> split = e.split('=');
      String key = split[0];
      dynamic value = split.skip(1).join('');
      if (key.endsWith('[num]')) {
        value = num.parse(value);
        key = key.substring(0, key.length - 5);
      }
      return MapEntry(key, value);
    }).toList();
  } else {
    entries = [];
  }

  String filePath = path.join(Directory.current.path, args[0]);
  filePath = path.normalize(filePath);

  run(args[1], Directory(filePath), args[2], entries);
}

///Run requests for script sources
void run(String projectName, Directory dir, String type, List<MapEntry<String, dynamic>> arguments) async {
  final List<ScraperSource> sources = loadExternalScarperSources(dir);

  if (sources.isNotEmpty) {
    try {
      final r =
          await sources.firstWhere((element) => element.info['source'] == projectName).makeRequest(type, arguments);
      if (r.pass) {
        //encode json
        final String json = jsonEncode(r.data);
        //output the json to command line
        stdout.writeln(json);
      }
    } catch (e) {
      stderr.writeln(e);
      //Silent error
    }
  }
}
