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
  Future<MapEntry<String, List>> getValue(dynamic context, Interpreter interpreter,
      {required Map<String, Function> custom, bool expand = false}) async {
    if (names.first.type == OperationType.literal) {
      return MapEntry(alias ?? names.first.name, [names.first.value]);
    }

    late List<dynamic> value;
    if (expand) {
      value = List<dynamic>.from(context);
    } else {
      value = List<dynamic>.from([context]);
    }

    bool topLevel = true;

    for (final operation in names) {
      //this might cause issues or unexpected issues
      if (operation.name == '*') {
        topLevel = false;
        continue;
      } else {
        //select a value
        final List<dynamic> newValues = List.generate(value.length, (index) => index);
        for (final index in newValues) {
          final e = value[index];

          if (operation.type == OperationType.function) {
            final operationLength = operation.value?.length ?? 0;
            //map values
            final List<dynamic> values = List.generate(operationLength, (index) => index);
            for (final index2 in values) {
              values[index2] =
                  (await operation.value[index2].getValue(interpreter.values, interpreter, custom: custom)).value;
            }

            if (topLevel) {
              //if top, then the value should be the first value
              newValues[index] = await custom[operation.name.toLowerCase()]!(values);
              continue;
            } else {
              newValues[index] = await custom[operation.name.toLowerCase()]!([e, ...values]);
              continue;
            }
          } else {
            if (e is Map) {
              newValues[index] = e[operation.name];
              continue;
            } else {
              newValues[index] = e;
              continue;
            }
          }
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
        } else if (operation.listAccess!.trim() == '[0]') {
          value = value[0];
        } else {
          log('Specialized list access is not supported yet', level: const LogLevel.warn());
        }
      }
    }

    return MapEntry(alias ?? names.last.name, value);
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
