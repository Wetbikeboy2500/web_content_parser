import 'dart:io';

import 'package:web_query_framework/src/wql2/wql2.dart';
import 'package:web_query_framework/web_content_parser_full.dart';
import 'package:web_query_framework_util/util.dart';

///Execute a file written in WQL
///Usage: dart bin/exec.dart <file>
void main(List<String> args) {
  if (args.isEmpty) {
    stdout.writeln('Usage: dart bin/exec.dart <file>');
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

      WQL.run(content, functions: {
        'readfile': (args) {
          return File(args[0]).readAsStringSync();
        },
      })
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