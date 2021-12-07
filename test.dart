// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) {
  if (args.contains('clean')) {
    clean();
    return;
  }

  final Iterable<String> paths =
      Directory('lib').listSync(recursive: true).map((e) => e.path.replaceAll('\\', '/')).where((element) {
    if (!element.endsWith('.dart') ||
        element.endsWith('g.dart') ||
        element.endsWith('lib/web_content_parser.dart') ||
        element.endsWith('lib/util.dart') ||
        element.endsWith('lib/scraper.dart') ||
        element.endsWith('lib/parser.dart') ||
        element.endsWith('lib/headless.dart') ||
        element.endsWith('scraper/mobileHeadless.dart') ||
        element.endsWith('scraper/desktopHeadless.dart')) {
      return false;
    }

    return true;
  }).map((e) => "import 'package:web_content_parser/${e.replaceFirst('lib/', '')}';");
  final File testFile = File('test/web_content_parser_test.dart');
  final List<String> lines = testFile.readAsLinesSync();
  final int index = lines.indexWhere((element) => element.startsWith('import \'package:web_content_parser'));
  if (index == -1) {
    print('No import to replace');
    return;
  }
  lines.insertAll(index, paths);
  lines.removeAt(index + paths.length);

  Directory('coverage').createSync();

  File('test/tmp.dart').writeAsStringSync(lines.join('\r\n'));

  Process.runSync('dart', ['test', '--file-reporter', 'json:reports/tests.json', 'test/tmp.dart', '--coverage=.']);
  Process.runSync('dart', [
    'run',
    'coverage:format_coverage',
    '--packages=.packages',
    '-i',
    './test/tmp.dart.vm.json',
    '-l',
    '-o',
    './coverage/lcov.info',
    '--report-on=lib'
  ]);

  clean();
}

void clean() {
  final List<File> files = [
    File('test/tmp.dart'),
    File('test/tmp.dart.vm.json'),
  ];

  for (var file in files) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
