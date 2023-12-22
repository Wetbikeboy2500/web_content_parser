import 'dart:convert';

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
      final List? listAccess = nameList.last;

      if (listAccess != null && listAccess[1] == null) {
        listAccess[1] = SeparatedList([const Token('all', '', 0, 0)], []);
      }

      //support for functions
      if (firstIdentifier is List) {
        assert(firstIdentifier.first is String);
        names.add(OperationName(
          name: firstIdentifier.first,
          type: OperationType.function,
          value: firstIdentifier.last?.map((value) => Operator.fromTokensNoAlias(value)).toList(),
          listAccess: listAccess?[1]?.elements,
        ));
      } else {
        names.add(OperationName(
          name: nameList.first,
          type: OperationType.access,
          listAccess: listAccess?[1]?.elements,
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
          final ({MapEntry<String, List> result, bool wasExpanded}) operationResult =
              (await param.getValue(context, interpreter, custom: custom));
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
        // Select a value through map access
        final List<dynamic> newValues = [];
        for (final element in value) {
          if (element is Map && element.containsKey(operation.name)) {
            newValues.add(element[operation.name]);
          } else {
            log2('Cannot access value of non-map type with key: ', operation.name, level: const LogLevel.warn());
            newValues.add(null);
          }
        }

        value = newValues;
      }

      topLevel = false;

      //TODO: allow list access to have keywords ex: [first] [last] [all]

      //try and get the values as a list based on the selector
      if (operation.listAccess != null) {
        for (final access in operation.listAccess!) {
          switch (access) {
            case final List l:
              int getIndex(String value) {
                switch (value) {
                  case 'first':
                    return 0;
                  case 'last':
                    return value.length - 1;
                  default:
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed > value.length || parsed < -value.length) {
                      log2('Invalid list access index', parsed, level: const LogLevel.warn());
                      return 0;
                    } else if (parsed < 0) {
                      return value.length + parsed;
                    } else {
                      return parsed;
                    }
                }
              }
              switch (l) {
                case [final a, ':', final b, ':', final c]:
                  final int start = getIndex(a);
                  final int end = getIndex(b);
                  final int? step = int.tryParse(c);

                  if (step == null) {
                    log2('Invalid step', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  if (start < 0 || end < 0 || step == 0) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  if (start > end && step > 0) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  if (start < end && step < 0) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  if (start >= value.length || end >= value.length) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;

                  }

                  final List<dynamic> newValues = [];

                  if (value.isNotEmpty) {
                    if (start < end) {
                      for (int i = start; i <= end; i += step) {
                        newValues.add(value[i]);
                      }
                    } else {
                      for (int i = start; i >= end; i += step) {
                        newValues.add(value[i]);
                      }
                    }
                  }

                  value = newValues;
                  wasExpanded = false;
                  break;
                case [final a, ':', final b]:
                  final int start = getIndex(a);
                  final int end = getIndex(b);
                  final int step = 1;

                  if (start < 0 || end < 0 || step == 0) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  if (start > end && step > 0) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  if (start < end && step < 0) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  if (start >= value.length || end >= value.length) {
                    log2('Invalid list access index', [start, end, step], level: const LogLevel.warn());
                    value = [null];
                    wasExpanded = false;
                    break;
                  }

                  final List<dynamic> newValues = [];

                  if (value.isNotEmpty) {
                    if (start < end) {
                      for (int i = start; i <= end; i += step) {
                        newValues.add(value[i]);
                      }
                    } else {
                      for (int i = start; i >= end; i -= step) {
                        newValues.add(value[i]);
                      }
                    }
                  }

                  value = newValues;
                  wasExpanded = false;
                  break;
              }
              break;
            case final String s:
              final parsed = int.tryParse(s);
              if (parsed == null || parsed > value.length || parsed < -value.length) {
                log2('Invalid list access index', parsed, level: const LogLevel.warn());
                value = [null];
              } else if (parsed < 0) {
                value = [value[value.length + parsed]];
              } else {
                print(wasExpanded);
                value = [value[parsed]];
              }
              wasExpanded = false;
              break;
            case Token(value: final String v):
              switch (v.toLowerCase()) {
                case 'first':
                  if (value.isEmpty) {
                    value = [null];
                  } else {
                    value = [value.first];
                  }
                  wasExpanded = false;
                  break;
                case 'last':
                  if (value.isEmpty) {
                    value = [null];
                  } else {
                    value = [value.last];
                  }
                  wasExpanded = false;
                  break;
                case 'even':
                  final List<dynamic> newValues = [];
                  for (int i = 0; i < value.length; ++i) {
                    if (i % 2 == 0) {
                      newValues.add(value[i]);
                    }
                  }
                  value = newValues;
                  wasExpanded = false;
                  break;
                case 'odd':
                  final List<dynamic> newValues = [];
                  for (int i = 0; i < value.length; ++i) {
                    if (i % 2 == 1) {
                      newValues.add(value[i]);
                    }
                  }
                  value = newValues;
                  wasExpanded = false;
                  break;
                case 'all':
                  final List<dynamic> newValues = [];
                  for (final element in value) {
                    if (element is List) {
                      newValues.addAll(element);
                    } else {
                      newValues.add(element);
                    }
                  }
                  value = newValues;
                  wasExpanded = true;
                  break;
                default:
                  log2('Unknown list access type', v, level: const LogLevel.warn());
              }
              break;
            default:
              log2('Unknown list access type', access, level: const LogLevel.warn());
          }
        }
      }
    }

    print(jsonEncode(value));
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
  final List? listAccess;

  const OperationName({required this.name, required this.type, this.value, this.listAccess});
}
