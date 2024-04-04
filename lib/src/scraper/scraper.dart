import 'dart:io';

import 'package:path/path.dart' as p;

import '../util/log.dart';
import 'scraperSource.dart';

///Loads an external sources
///
///It will first find all .yml or .yaml files in [dir]
///It will then go through and attempt to convert them into a [ScraperSource] using the global constructor
///All successful conversions to [ScraperSource] can then be accessed through [ScraperSource.scrapper(name)]
Future loadExternalScraperSourcesGlobal(Directory dir) async {
  final List<FileSystemEntity> files = dir
      .listSync(recursive: true)
      .where((a) => p.extension(a.path) == '.yml' || p.extension(a.path) == '.yaml')
      .toList();
  for (final fileEntity in files) {
    try {
      //get file contents
      final file = File(fileEntity.path);
      //load scraper
      ScraperSource.global(await file.readAsString(), file.parent);
    } catch (e, stack) {
      log2('Error loading external global source:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
    }
  }
}

///Loads an external sources
///
///It will first find all .yml or .yaml files in [dir]
///It will then go through and attempt to convert them into a [ScraperSource]
///All successful conversions to [ScraperSource] will be returned as a [List<ScraperSource>]
Future<List<ScraperSource>> loadExternalScarperSources(Directory dir) async {
  final List<FileSystemEntity> files = dir
      .listSync(recursive: true)
      .where((a) => p.extension(a.path) == '.yml' || p.extension(a.path) == '.yaml')
      .toList();
  final List<ScraperSource> scrapers = [];
  for (final fileEntity in files) {
    try {
      //get file contents
      final file = File(fileEntity.path);
      //load scraper
      final (:source, :errorMessage) = ScraperSource.createScraperSource(await file.readAsString(), file.parent);

      if (source == null || (errorMessage?.isNotEmpty ?? false)) {
        log2('Error creating source:', errorMessage, level: const LogLevel.error());
        continue;
      }

      //add for return
      scrapers.add(source);
    } catch (e, stack) {
      log2('Error loading external source:', e, level: const LogLevel.error());
      log(stack, level: const LogLevel.debug());
    }
  }

  return scrapers;
}
