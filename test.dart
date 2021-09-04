// ignore_for_file: avoid_print

import 'dart:io';

main(List<String> args) {
  if (args.contains('clean')) {
    clean();
    return;
  }

  List<FileSystemEntity> files = Directory('lib').listSync(recursive: true);
  files.removeWhere((element) =>
      element.path.endsWith('web_content_parser.dart') ||
      element.path.endsWith('g.dart') ||
      !element.path.endsWith('.dart'));
  List<String> paths = files
      .map((e) => "import 'package:web_content_parser/${e.path.replaceAll('\\', '/').replaceFirst('lib/', '')}';")
      .toList();
  File testFile = File('test/web_content_parser_test.dart');
  List<String> lines = testFile.readAsLinesSync();
  int index = lines.indexWhere((element) => element.startsWith('import \'package:web_content_parser'));
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
  List<File> files = [
    File('test/tmp.dart'),
    File('test/tmp.dart.vm.json'),
  ];

  for (var file in files) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
