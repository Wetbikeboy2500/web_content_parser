import 'dart:math';

import 'package:petitparser/petitparser.dart';

import 'sourceBuilder.dart';
import 'statement.dart';

class PackStatement extends Statement {
  final Map<String, List> valueSelectors;
  final String into;

  const PackStatement(this.valueSelectors, this.into);

  factory PackStatement.fromTokens(List tokens) {
    final Map<String, List> valueSelectors = {};

    for (List selectTokens in tokens[1]) {
      //either alias or the last value for the named selector
      final String alias = selectTokens.last ??
          ((selectTokens.first.last.last != null) ? selectTokens.first.last.join('') : selectTokens.first.last.first);
      valueSelectors[alias] = selectTokens.first;
    }

    final String into = tokens.last;

    return PackStatement(valueSelectors, into);
  }

  static Parser getParser() {
    final name = letter().plus().flatten().trim();

    final digitInput = (char('[').trim().token() &
            digit().star().flatten().optional() &
            (char(':') & digit().star().flatten()).optional() &
            char(']').trim().token())
        .flatten();

    return stringIgnoreCase('pack').token() &
        ((name & digitInput.optional()).separatedBy(char('.'), includeSeparators: false) &
                (stringIgnoreCase('as').trim() & name).pick(1).optional())
            .separatedBy(char(','), includeSeparators: false) &
        stringIgnoreCase('into') &
        name;
  }

  @override
  Future<void> execute(Interpreter interpreter) async {
    final List<MapEntry<String, List>> mergedLists = [];
    final Map<String, dynamic> mergeValues = {};

    //get all the values
    for (MapEntry entry in valueSelectors.entries) {
      final List selectors = entry.value;
      dynamic value;
      bool hasBeenSet = false;
      bool mergedValues = false;
      for (List select in selectors) {
        if (select[1] == null) {
          mergedValues = false;
          //map access
          if (!hasBeenSet) {
            value = interpreter.getValue(select[0]);
            hasBeenSet = true;
          } else {
            value = value[select[0]];
          }
        } else {
          //list access
          if ((select[1] as String).trim() == '[]') {
            //only merging values if last access was []
            mergedValues = true;
            if (!hasBeenSet) {
              value = interpreter.getValue(select[0]);
              hasBeenSet = true;
            } else {
              value = value[select[0]];
            }
          } else if ((select[1] as String).trim() == '[0]') {
            mergedValues = false;
            //getting then first element of the list
            if (!hasBeenSet) {
              value = interpreter.getValue(select[0])[0];
              hasBeenSet = true;
            } else {
              value = value[select[0]][0];
            }
          } else {
            throw Exception('List access not supported');
          }
        }
      }

      if (mergedValues) {
        mergedLists.add(MapEntry(entry.key, value));
      } else {
        mergeValues[entry.key] = value;
      }
    }

    if (!mergedLists.every((element) => element.value.length == mergedLists.first.value.length)) {
      throw Exception('All lists must be the same length to merge');
    }

    //merge them together
    late final List<Map> output;

    if (mergedLists.isNotEmpty) {
      output = List.generate(mergedLists.first.value.length, (index) => {});
    } else {
      output = [{}];
    }

    for (int i = 0; i < output.length; i++) {
      //TODO: account for lists that are just values. This can switch to useing the alias
      for (MapEntry entries in mergedLists) {
        if (entries.value.first is Map) {
          output[i].addAll(entries.value[i]);
        } else {
          output[i][entries.key] = entries.value[i];
        }
      }
      output[i].addAll(mergeValues);
    }

    //set the value
    interpreter.setValue(into, output);
  }
}
