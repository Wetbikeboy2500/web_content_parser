import 'dart:io';

import 'package:path/path.dart' as p;
import '../util/log.dart';

import 'scraperSource.dart';

void loadExternalScraperSourcesGlobal(Directory dir) {
  final List<FileSystemEntity> files = dir.listSync(recursive: true).where((a) => p.extension(a.path) == '.yml' || p.extension(a.path) == '.yaml').toList();
  for (final fileEntity in files) {
    try {
      //get file contents
      final file = File(fileEntity.path);
      //load scraper
      ScraperSource.global(file.readAsStringSync(), file.parent);
    } catch (e, stack) {
      log('Error loading external global source: $e');
      log(stack);
    }
  }
}

List<ScraperSource> loadExternalScarperSources(Directory dir) {
  final List<FileSystemEntity> files = dir.listSync(recursive: true).where((a) => p.extension(a.path) == '.yml' || p.extension(a.path) == '.yaml').toList();
  final List<ScraperSource> scrapers = [];
  for (final fileEntity in files) {
    try {
      //get file contents
      final file = File(fileEntity.path);
      //load scraper
      ScraperSource scraper = ScraperSource(file.readAsStringSync(), file.parent);
      //add for return
      scrapers.add(scraper);
    } catch (e, stack) {
      log('Error loading external source: $e');
      log(stack);
    }
  }

  return scrapers;
}