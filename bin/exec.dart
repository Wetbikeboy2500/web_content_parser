import 'dart:io';

import 'package:web_content_parser/src/wql2/wql2.dart';
import 'package:web_content_parser/web_content_parser_full.dart';
import 'package:web_query_framework_util/util.dart';

///Execute a file written in WQL
///Usage: dart bin/exec.dart <file>

void main(List<String> args) {
  if (args.isEmpty) {
    stdout.writeln('Usage: dart bin/exec.dart <file>');
    return;
  }

  final file = File(args[0]);
  file.readAsString()
    .then((content) {
      loadWQLFunctions();

      WQL.run(content)
        .then((value) {
          if (value case Pass()) {
            for (final MapEntry(:key, :value) in value.data.entries) {
              stdout.writeln('$key: $value');
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