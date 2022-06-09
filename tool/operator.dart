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

    for (final operation in names) {
      //this might cause issues or unexpected issues
      if (operation.name == '*') {
        continue;
      }

      //select a value
      value = value.map((e) {
        print(e);
        if (firstLevel && custom.containsKey(operation.name)) {
          return custom[operation.name]!(this, e);
        }

        return e[operation.name];
      }).toList();

      firstLevel = false;

      //try and get the values as a list based on the selector
      if (operation.listAccess != null) {
        if (operation.listAccess!.trim() == '[]') {
          //join all the sublists to create a master list
          value = value.reduce((value, element) => [...value, ...element]);
        } else if (operation.listAccess!.trim() == '[0]') {
          value = value[0];
        } else {
          print('Specialized list access is not supported yet');
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
