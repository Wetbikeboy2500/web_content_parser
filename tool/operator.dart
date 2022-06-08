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

    for (final List nameList in tokens.first) {
      names.add(OperationName(nameList.first, nameList.last));
    }

    return Operator(names, alias);
  }

  dynamic getValue() {

  }
}

class OperationName {
  final String name;
  final String? listAccess;

  const OperationName(this.name, this.listAccess);
}
