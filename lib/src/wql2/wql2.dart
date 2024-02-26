class WQL {
  static Map<String, Function> functions = {
    'increment': (args) => (args[0] !is num) ? num.parse(args[0]) + 1 : args[0] + 1,
    'decrement': (args) => (args[0] !is num) ? num.parse(args[0]) - 1 : args[0] - 1,
    'trim': (args) => args[0].trim(),
    'merge': (args) => args.expand((l) => (l is List) ? l : [l]).toList(),
    'concat': (args) => args.join(),
    'last': (args) => args[0].last,
    'first': (args) => args[0].first,
    'length': (args) => args[0].length,
    'split': (args) => args[0].split(args[1]),
    'indexof': (args) => args[0].indexOf(args[1]),
    'contains': (args) => args[0].contains(args[1]),
    'indexofstartingat': (args) => args[0].indexOf(args[1], args[2]),
    'substring': (args) => args[0].substring(args[1], args[2]),
    'replaceall': (args) => args[0].replaceAll(args[1], args[2]),
    'createrange': (args) => List<int>.generate(args[1] - args[0], (i) => args[0] + i),
    'reverse': (args) => args[0].reversed.toList(),
    'itself': (args) => args[0],
    // ignore: avoid_print
    'print': (args) => print(args.join(', ')),
    'isnull': (args) => args[0] == null,
    'not': (args) => !args[0],
    'and': (args) => args[0] && args[1],
    'or': (args) => args[0] || args[1],
    'equals': (args) => args[0] == args[1],
  };
}