import '../util/log.dart';

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

    if (tokens.first is String) {
      names.add(OperationName(tokens.first, null));
    } else {
      for (final List nameList in tokens.first) {
        names.add(OperationName(nameList.first, nameList.last));
      }
    }

    return Operator(names, alias);
  }

  factory Operator.fromTokensNoAlias(List tokens) {
    final List<OperationName> names = [];

    if (tokens.first is String) {
      names.add(OperationName(tokens.first, null));
    } else {
      for (final List nameList in tokens) {
        names.add(OperationName(nameList.first, nameList.last));
      }
    }

    return Operator(names, null);
  }

  MapEntry<String, List<dynamic>> getValue(dynamic context,
      {Map<String, Function> custom = const {}, bool expand = false}) {
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

          return e[operation.name];
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
  final String? listAccess;

  const OperationName(this.name, this.listAccess);
}
