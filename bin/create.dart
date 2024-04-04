import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as p;
import 'package:web_content_parser/web_content_parser_full.dart';

void main(List<String> args) {
  createPackage(args.first, Directory.current);
}

///Create a web scraping package
///[name] the name of the package being created
///[dir] the directory that the package will be created in
void createPackage(String name, Directory dir) {
  final projectDir = Directory('${dir.path}/$name');

  if (projectDir.existsSync()) {
    //check if the directory is empty
    if (projectDir.listSync().isNotEmpty) {
      stdout.writeln('Directory is not empty');
      return;
    }
  } else {
    //create directory
    projectDir.createSync(recursive: true);
  }

  String? answer;
  //continue to read line until answer is y or n
  while (answer != 'y' && answer != 'n') {
    stdout.write('Do you want to create a parser (Additional information needed)? [y/n] ');
    answer = stdin.readLineSync()?.toLowerCase();
  }

  final bool createParser = answer == 'y';

  stdout.write('name: ($name) ');
  stdin.readLineSync() ?? name;

  String? baseUrl;

  if (createParser) {
    //get baseurl until not null
    while (baseUrl == null) {
      stdout.write('baseUrl: [required] ');
      final String? value = stdin.readLineSync();
      baseUrl = (value ?? '').isEmpty ? null : value;
    }
  }

  String? subdomain;

  if (createParser) {
    stdout.write('subdomain: (null) ');
    final String? value = stdin.readLineSync();
    subdomain = (value ?? '').isEmpty ? null : value;
  }

  String? contentType;

  if (createParser) {
    stdout.write('contentType: (imageSeries) ');
    final String? value = stdin.readLineSync();
    contentType = (value ?? '').isEmpty ? 'imageSeries' : value;
  }

  //get version number
  int version = 0;
  stdout.write('version: (0) ');
  try {
    final String? value = stdin.readLineSync();
    version = int.parse((value ?? '').isEmpty ? '0' : value!);
  } catch (e) {
    stdout.writeln('Invalid version number');
    return;
  }

  String? programType;
  while (programType != 'wql') {
    stdout.write('programType: [wql] ');
    programType = stdin.readLineSync();
  }

  String optional = '';

  if (createParser) {
    optional = '''\nbaseUrl: $baseUrl\nsubdomain: $subdomain\ncontentType: $contentType''';
  }

  //create the base yaml file
  File('${projectDir.path}/$name.yaml')
      .writeAsStringSync('''source: $name$optional\nversion: $version\nprogramType: $programType\nrequests:''');
}

void createRequest(String name, Directory dir) {
  final files = dir.listSync();

  final List<File> yamlFiles = [];

  for (final file in files) {
    if (file is File) {
      final ext = p.extension(file.path);
      if (ext == '.yaml' || ext == '.yml') {}
    }
  }

  //output all the yaml files paths with a number
  for (final file in yamlFiles) {
    stdout.writeln('${yamlFiles.indexOf(file)}: ${file.path}');
  }

  //promt user to select a file by number
  int index = -1;
  while (index < 0 || index >= yamlFiles.length) {
    stdout.write('Select a file: [0-${yamlFiles.length - 1}] ');
    try {
      final String? value = stdin.readLineSync();
      index = int.parse((value ?? '').isEmpty ? '-1' : value!);
    } catch (e) {
      stdout.writeln('Invalid number');
    }
  }

  final File selectedFile = yamlFiles[index];
  yamlFiles.clear();

  //get program type
  String? programType;
  while (programType != 'wql') {
    stdout.write('programType: [wql] ');
    programType = stdin.readLineSync();
  }
  //get required file
  String? file;
  while (file == null) {
    stdout.write('fileName: [required] ');
    final String? value = stdin.readLineSync();
    file = (value ?? '').isEmpty ? null : value;
  }
  //get type
  RequestType? type;
  while (type == null || type == RequestType.unknown) {
    stdout.write('type: [required] ');
    final String? value = stdin.readLineSync();
    type = requestMap(value ?? '');
  }

  final Map<String, dynamic> yaml = parseYaml(selectedFile.readAsStringSync());

  //add requets to the parsed yaml item
  yaml['requests'] ??= [];
  yaml['requests'].add({
    'programType': programType,
    'fileName': file,
    'type': type.toString().split('.').last,
  });

  //write the yaml file
  selectedFile.writeAsStringSync(json2yaml(yaml));
}
