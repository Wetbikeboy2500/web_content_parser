import 'dart:async';

import 'package:petitparser/petitparser.dart';
import 'package:web_content_parser/src/util/log.dart';

import '../interpreter.dart';
import '../statements/statement.dart';

enum OperationType {
  literal,
  key,
  function,
  statement,
}

sealed class Operation {
  final OperationType type;
  Operation(this.type);
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter);
}

class LiteralOperation extends Operation {
  final dynamic value;
  LiteralOperation(this.value) : super(OperationType.literal);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) => value;
}

class KeyOperation extends Operation {
  final String key;
  KeyOperation(this.key) : super(OperationType.key);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) {
    if (input is Map && input.containsKey(key)) {
      return input[key];
    } else {
      log2('Cannot access value of non-map type with key: ', key, level: const LogLevel.warn());
      return null;
    }
  }
}

class FunctionOperation extends Operation {
  final String name;
  final Function function;
  final List<DotInput> arguments;
  FunctionOperation(this.name, this.function, this.arguments) : super(OperationType.function);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) => function(input);
}

class StatementOperation extends Operation {
  final Statement statement;
  StatementOperation(this.statement) : super(OperationType.statement);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) => statement.execute(input, interpreter);
}

class DotInput extends Statement {
  final List<Operation> operations = [];

  factory DotInput.fromTokens(SeparatedList tokens) {
    throw UnimplementedError();
  }

  @override
  StatementReturn execute(context, Interpreter interpreter) async {
    dynamic currentValue = context;
    bool wasExpanded = false;

    for (final operation in operations) {
      final result = await operation.process(currentValue, interpreter);
      currentValue = result;
    }



    return (name: '', result: currentValue, wasExpanded: wasExpanded, noop: false);
  }
}
