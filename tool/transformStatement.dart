
// import 'selectStatement.dart';
// import 'sourceBuilder.dart';

// class TransformStatement extends SelectStatement {
//   const TransformStatement(TokenType operation, List<Operator> operators, String from, String? selector, String? into,
//       {List<Operator>? transformations})
//       : super(operation, operators, from, selector, into, transformations: transformations);

//   @override
//   Future<void> execute(Interpreter interpreter) async {
//     //from
//     late dynamic data;
//     if (from == '*') {
//       data = interpreter.values;
//     } else {
//       data = interpreter.getValue(from);
//     }
//     if (data == null) {
//       throw Exception('No data found for $from');
//     }

//     //add the specific values to transform
//     List<String> values = [];
//     for (Operator select in operators) {
//       Map<String, dynamic> objectValues = {};
//       switch (select.type) {
//         case TokenType.Value:
//           values.add(select.meta!);
//           break;
//         default:
//         //do nothing
//       }
//     }

//     if (data is Map) {
//       data = [data];
//     }

//     //loop through all the data
//     for (var d in data) {
//       //TODO: add an into
//       //TODO: support as for transforms that work on map
//       for (final value in values) {
//         final dynamic storedValue = d[value];
//         print(storedValue);
//         for (final Operator transform in transformations ?? []) {
//           switch (transform.type) {
//             case TokenType.Trim:
//               d[transform.alias ?? value] = storedValue.trim();
//               break;
//             case TokenType.Lowercase:
//               d[transform.alias ?? value] = storedValue.toLowerCase();
//               break;
//             case TokenType.Uppercase:
//               d[transform.alias ?? value] = storedValue.toUpperCase();
//               break;
//             case TokenType.Concat:
//               //make sure value exists
//               d[transform.alias ?? value] ??= '';
//               //fail if not string
//               if (d[transform.alias ?? value] is! String) {
//                 throw Exception('Cannot concatenate a non string value');
//               }
//               //join strings
//               if (storedValue is String) {
//                 d[transform.alias ?? value] += storedValue;
//               } else {
//                 d[transform.alias ?? value] += storedValue.toString();
//               }
//               break;
//             default:
//               throw Exception('Unknown transform ${transform.type}');
//           }
//         }
//       }
//     }

//     if (from == '*') {
//       interpreter.setValues(data.first);
//     } else {
//       interpreter.setValue(from, data);
//     }
//   }
// }