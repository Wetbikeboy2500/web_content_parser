import 'package:petitparser/petitparser.dart';

import 'sourceBuilder.dart';
import 'statement.dart';

class PackStatement extends Statement {
  final Map<String, List<String>> valueSelectors;
  final String into;

  const PackStatement(this.valueSelectors, this.into);

  factory PackStatement.fromTokens(List tokens) {
    final Map<String, List<String>> valueSelectors = {};

    for (var i = 1; i < tokens.length; i++) {
      final String key = tokens[i];
      final List<String> selectors = [];

      i++;
      while (i < tokens.length && tokens[i] != 'into') {
        selectors.add(tokens[i]);
        i++;
      }

      valueSelectors[key] = selectors;
    }

    final String into = tokens[tokens.length - 1];

    print('valueSelectors: $valueSelectors');
    print('into: $into');

    return PackStatement(valueSelectors, into);
  }

  static Parser getParser() {
    final name = letter().plus().flatten().trim();

    return stringIgnoreCase('pack').token() &
        (name.separatedBy(char('.'), includeSeparators: false) & (stringIgnoreCase('as').trim() & name).optional())
            .separatedBy(char(','), includeSeparators: false) &
        stringIgnoreCase('into') &
        name;
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    //get the values of each selector
    final values = <String, dynamic>{};
    for (var valueSelector in valueSelectors.entries) {
      //starting value
      dynamic value = interpreter.getValue(valueSelector.value.first);
      if (value == null) {
        throw Exception('No data found for ${valueSelector.value.first}');
      }

      //get additional values if any
      for (var i = 1; i < valueSelector.value.length; i++) {
        if (value is Map) {
          value = value[valueSelector.value[i]];
        } else {
          throw Exception('Cannot access a non-map value');
        }
      }

      values[valueSelector.key] = value;
    }

    print(values);
  }
}
