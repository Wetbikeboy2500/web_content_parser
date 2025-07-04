import 'dart:io';

import 'package:web_query_framework/src/wql2/wql2.dart';
import 'package:web_query_framework/web_query_framework_full.dart';
import 'package:web_query_framework_util/util.dart';

///Execute a file written in WQL
///Usage: dart bin/terminal/terminal.dart <file>
void main(List<String> args) {
  if (args.isEmpty) {
    stdout.writeln('Usage: dart bin/terminal/terminal.dart <file>');
    return;
  }

  args = args.toList();

  bool output = true;
  if (args.contains('--no-output')) {
    output = false;
    args.remove('--no-output');
  }

  final file = File(args[0]);
  file.readAsString()
    .then((content) {
      loadWQLFunctions();
      loadTerminalFunctions();

      WQL.run(content)
        .then((value) {
          if (!output) {
            return;
          }

          if (value case Pass()) {
            if (value.data is Map) {
              for (final MapEntry(:key, :value) in value.data.entries) {
                stdout.writeln('$key: $value');
              }
            } else {
              stdout.writeln(value.data);
            }
          } else if (value case Fail()) {
            stderr.writeln(value);
          }
        })
        .catchError((e) {
          stderr.writeln(e);
        });
    })
    .catchError((e) {
      stderr.writeln(e);
    });
}

void loadTerminalFunctions() {
  final functions = <String, Function>{
    'fileexists': (args) => File(args[0]).exists(),
    'readfile': (args) => File(args[0]).readAsString(),
    'processrun': (args) => Process.run(args[0], [...args.skip(1)]),
    'processstart': (args) => Process.start(args[0], [...args.skip(1)]),
  };

  WQL.functions = {
    ...WQL.functions,
    ...functions,
  };
}