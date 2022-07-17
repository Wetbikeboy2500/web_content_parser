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
      names.add(OperationName(
        name: tokens.first.last,
        rawValue: true,
        value: _parseRawValue(tokens.first.first, tokens.first.last),
        listAccess: null,
      ));
    } else {
      for (final List nameList in tokens.first) {
        names.add(OperationName(
          name: nameList.first,
          rawValue: false,
          listAccess: nameList.last,
        ));
      }
    }

    return Operator(names, alias);
  }

  factory Operator.fromTokensNoAlias(dynamic tokens) {
    assert(tokens is List || tokens is String);
    final List<OperationName> names = [];

    if (tokens is List && tokens.first is Token) {
      names.add(OperationName(
        name: tokens.last,
        rawValue: true,
        value: _parseRawValue(tokens.first, tokens.last),
        listAccess: null,
      ));
    } else if (tokens.first is String) {
      names.add(OperationName(
        name: tokens.first,
        rawValue: false,
        listAccess: null,
      ));
    } else {
      for (final List nameList in tokens) {
        names.add(OperationName(
          name: nameList.first,
          rawValue: false,
          listAccess: nameList.last,
        ));
      }
    }

    return Operator(names, null);
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

  MapEntry<String, List<dynamic>> getValue(dynamic context,
      {Map<String, Function> custom = const {}, bool expand = false}) {
    if (names.first.rawValue) {
      return MapEntry(alias ?? names.first.name, [names.first.value]);
    }

    late List value;
    if (expand) {
      value = context;
    } else {
      value = [context];
    }

    //keeps track of if level of access is still the first level (attribute.name) <- attribute is first level
    bool firstLevel = true;

    bool end = false;

    for (final operation in names) {
      //end the loop if a top level operation ran.
      //TODO: make a skip for top level functions to allow potentially chaining them if it could be useful
      if (end) {
        break;
      }

      //this might cause issues or unexpected issues
      if (operation.name == '*') {
        continue;
      } else {
        //select a value
        value = value.map((e) {
          if (firstLevel && custom.containsKey(operation.name)) {
            end = true;
            return custom[operation.name]!(this, e);
          }

          if (e is Map) {
            return e[operation.name];
          } else {
            return e;
          }
        }).toList();
      }

      firstLevel = false;

      //TODO: allow list access to have keywords ex: [first] [last] [all]

      //try and get the values as a list based on the selector
      if (operation.listAccess != null) {
        if (operation.listAccess!.trim() == '[]') {
          //join all the sublists to create a master list
          value = value.reduce((value, element) => [...(value ?? const []), ...(element ?? const [])]);
        } else if (operation.listAccess!.trim() == '[0]') {
          value = value[0];
        } else {
          log('Specialized list access is not supported yet');
        }
      }
    }

    return MapEntry(alias ?? names.last.name, value);
  }
}

class OperationName {
  final String name;
  final bool rawValue;
  final dynamic? value;
  final String? listAccess;

  const OperationName({required this.name, required this.rawValue, this.value, this.listAccess});
}
