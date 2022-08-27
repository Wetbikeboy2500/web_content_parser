import 'dart:io';

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
    answer = stdin.readLineSync();
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
    stdout.write('contentType: (seriesImage) ');
    final String? value = stdin.readLineSync();
    contentType = (value ?? '').isEmpty ? 'seriesImage' : value;
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
  while (programType != 'hetu0.3' && programType != 'wql') {
    stdout.write('programType: [hetu0.3/wql] ');
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
  final projectDir = Directory('${dir.path}/$name');
  //type, file, entry, compiled, programType
  //get program type
  String? programType;
  while (programType != 'hetu0.3' && programType != 'wql') {
    stdout.write('programType: [hetu0.3/wql] ');
    programType = stdin.readLineSync();
  }
  //get required file
  String? file;
  while (file == null) {
    stdout.write('baseUrl: [required] ');
    final String? value = stdin.readLineSync();
    file = (value ?? '').isEmpty ? null : value;
  }

  //get entry if program type is hetu0.3

  //get compiled if program type is hetu0.3. default false
}
