import '../interpreter/interpreter.dart';

import '../../util/log.dart';
import 'package:petitparser/petitparser.dart';

//TODO: support strings marked by ' or "
//TODO: support numbers which start as a numeric
//TODO: support boolean values true or false

///Keeps track of the operations that a specific operator has
///
///This is important to standardizing the data access and traversal syntax
class Operator {
  const Operator(this.names, this.alias);

  final List<OperationName> names;

  final String? alias;

  factory Operator.fromTokens(List tokens) {
    final String? alias = tokens.last;

    final List<OperationName> names = [];

    if (tokens.first is List && tokens.first.first is Token) {
      assert(tokens.first.last is String);
      names.add(OperationName(
        name: tokens.first.last,
        type: OperationType.literal,
        value: _parseRawValue(tokens.first.first, tokens.first.last),
        listAccess: null,
      ));
    } else {
      //.first to remove the alias wrapping
      names.addAll(_generateOperatorList(tokens.first));
    }

    return Operator(names, alias);
  }

  factory Operator.fromTokensNoAlias(dynamic tokens) {
    assert(tokens is List || tokens is String);
    final List<OperationName> names = [];

    if (tokens is List && tokens.first is Token) {
      names.add(OperationName(
        name: tokens.last,
        type: OperationType.literal,
        value: _parseRawValue(tokens.first, tokens.last),
        listAccess: null,
      ));
    } else if (tokens.first is String) {
      names.add(OperationName(
        name: tokens.first,
        type: OperationType.access,
        listAccess: null,
      ));
    } else {
      names.addAll(_generateOperatorList(tokens));
    }

    return Operator(names, null);
  }

  static List<OperationName> _generateOperatorList(List tokens) {
    final List<OperationName> names = [];

    for (final List nameList in tokens) {
      final dynamic firstIdentifier = nameList.first;
      final dynamic listAccess = nameList.last;

      //support for functions
      if (firstIdentifier is List) {
        assert(firstIdentifier.first is String);
        names.add(OperationName(
          name: firstIdentifier.first,
          type: OperationType.function,
          value: firstIdentifier.last?.map((value) => Operator.fromTokensNoAlias(value)).toList(),
          listAccess: listAccess,
        ));
      } else {
        names.add(OperationName(
          name: nameList.first,
          type: OperationType.access,
          listAccess: listAccess,
        ));
      }
    }

    return names;
  }

  static dynamic _parseRawValue(Token type, dynamic value) {
    switch (type.value) {
      case 'l':
        return [];
      case 's':
        if (value is String) {
          return value;
        }

        return value.toString();
      case 'b':
        if (value == 'true') {
          return true;
        }

        return false;
      case 'n':
        if (value is num) {
          return value;
        }

        return num.parse(value);
    }
  }

  //TODO: remove custom functions and switch to the wql functions to be allowed
  Future<({MapEntry<String, List> result, bool wasExpanded})> getValue(dynamic context, Interpreter interpreter,
      {required Map<String, Function> custom}) async {
    if (names.first.type == OperationType.literal) {
      return (result: MapEntry(alias ?? names.first.name, [names.first.value]), wasExpanded: false);
    }

    //If expand, then we want to run logic over each element given
    List<dynamic> value = [context];

    bool topLevel = true;
    bool wasExpanded = false;

    for (final operation in names) {
      //this might cause issues or unexpected issues
      if (operation.name == '^') {
        value = [interpreter.values];
        topLevel = false;
        continue;
      } else if (operation.name == '*') {
        topLevel = false;
        continue;
      } else if (operation.type == OperationType.function) {
        //generate the results for each parameter, fill in null if there is no value for mismatched lengths
        final List<Operator> params = (operation.value == null) ? const [] : operation.value.cast<Operator>();

        final List<(List<dynamic>, bool)> results = [];
        int maxLengthOfMultiArgs = 0;

        bool anyWasExpanded = false;

        if (!topLevel) {
          //need to use the value list as one of the parameters
          results.add((value, wasExpanded));
          maxLengthOfMultiArgs = wasExpanded ? value.length : 1;
          anyWasExpanded = wasExpanded;
        }

        for (final param in params) {
          final ({MapEntry<String, List> result, bool wasExpanded}) operationResult = (await param.getValue(context, interpreter, custom: custom));
          final result = operationResult.result;
          if (result.value.length > maxLengthOfMultiArgs) {
            maxLengthOfMultiArgs = result.value.length;
          }

          results.add((result.value, operationResult.wasExpanded));
        }

        //merge the results into equal arg lists
        final mutliArgs = [];
        for (int i = 0; i < maxLengthOfMultiArgs; ++i) {
          final args = [];
          for (int j = 0; j < results.length; ++j) {
            final result = results[j];
            anyWasExpanded = anyWasExpanded || result.$2;
            if (result.$2) {
              args.add(i < result.$1.length ? result.$1[i] : null);
            } else {
              args.add(result.$1.first);
            }
          }
          mutliArgs.add(args);
        }

        final functionCall = custom[operation.name.toLowerCase()]!;

        //Account for a top level function call with no args
        if (mutliArgs.isEmpty) {
          mutliArgs.add(const []);
        }

        final functionResults = [];
        for (final args in mutliArgs) {
          functionResults.add(await functionCall(args));
        }

        wasExpanded = false;
        value = anyWasExpanded ? [functionResults] : functionResults;
      } else {
        //select a value
        final List<dynamic> newValues = List.generate(value.length, (index) => index);
        for (final index in newValues) {
          //When iterating over a list, like [1, 2, 4], e is going to be 1, 2, 4 unwrapped
          final e = value[index];

          /* if (operation.type == OperationType.function) {
            final operationLength = operation.value?.length ?? 0;
            //map values
            final List<dynamic> values = List.generate(operationLength, (index) => index);
            int max = 0;
            for (final index2 in values) {
              values[index2] = (await operation.value[index2].getValue(e, interpreter, custom: custom)).value;
              if (values[index2].length > max) {
                max = values[index2].length;
              }
            }

            print('max $max');

            if (topLevel) {
              //if top, then the value should be the first value
              newValues[index] = await custom[operation.name.toLowerCase()]!(values);
              continue;
            } else {
              newValues[index] = await custom[operation.name.toLowerCase()]!([e, ...values]);
              continue;
            }
          } else { */
            //TODO: might want to consider null cases prevent Dart errors
            if (e is Map) {
              newValues[index] = e[operation.name];
              continue;
            } else {
              newValues[index] = e;
              continue;
            }
          //}
        }

        value = newValues;
      }

      topLevel = false;

      //TODO: allow list access to have keywords ex: [first] [last] [all]

      //try and get the values as a list based on the selector
      if (operation.listAccess != null) {
        if (operation.listAccess!.trim() == '[]') {
          //join all the sublists to create a master list
          value = value.reduce((value, element) => [...(value ?? const []), ...(element ?? const [])]);
          wasExpanded = true;
        } else if (operation.listAccess!.trim() == '[0]') {
          value = value[0];
        } else {
          log('Specialized list access is not supported yet', level: const LogLevel.warn());
        }
      }
    }

    return (result: MapEntry(alias ?? names.last.name, value), wasExpanded: wasExpanded);
  }
}

enum OperationType {
  function,
  literal,
  access,
}

class OperationName {
  final OperationType type;
  final String name;
  final dynamic value;
  final String? listAccess;

  const OperationName({required this.name, required this.type, this.value, this.listAccess});
}
