///Keeps track of the operations that a specific operator has
///
///This is important to standardizing the data access and traversal syntax
class Operator {
  const Operator();

  factory Operator.fromTokens(List tokens) {
    return const Operator();
  }
}