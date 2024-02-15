import 'dart:async';
import 'dart:math';

import 'package:web_content_parser/src/util/log.dart';

import '../interpreter.dart';
import '../statements/statement.dart';
import 'dot_input.dart';
import 'list_access.dart';

enum OperationType {
  literal,
  key,
  function,
  statement,
  scope,
}

sealed class Operation {
  final OperationType type;
  final List<ListAccess>? listAccess;
  Operation(this.type, this.listAccess);
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter);
}

class LiteralOperation extends Operation {
  final dynamic value;
  LiteralOperation(this.value, ListAccess listAccess) : super(OperationType.literal, null);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) => value;
}

class KeyOperation extends Operation {
  final String key;
  KeyOperation(this.key, List<ListAccess>? listAccess) : super(OperationType.key, listAccess);
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
  FunctionOperation(this.name, this.function, this.arguments, List<ListAccess>? listAccess)
      : super(OperationType.function, listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) async {
    //get all arguments for the function call
    final List<({dynamic value, bool wasExpanded})> args = [];
    int maxLengthOfMerge = -1;
    for (final argument in arguments) {
      final result = await argument.execute(input, interpreter);
      if (result.noop) {
        return null;
      }
      maxLengthOfMerge = max(result.result is List ? result.result.length : 1, maxLengthOfMerge);
      args.add((value: result.result, wasExpanded: result.wasExpanded));
    }

    //If any are expanded, merge other values with it
    final List<dynamic> functionValueCallsArgs = [];

    for (int i = 0; i < maxLengthOfMerge; i++) {
      final List<dynamic> values = [];
      for (final arg in args) {
        switch (arg) {
          case (value: final List<dynamic> value, wasExpanded: true):
            if (i < value.length) {
              values.add(value[i]);
            }
            break;
          case (value: final dynamic value, wasExpanded: false):
            values.add(value);
            break;
        }
      }
      functionValueCallsArgs.add(values);
    }

    //Call the function with the arguments
    if (functionValueCallsArgs.isEmpty) {
      return function(const []);
    } else {
      final List<dynamic> results = [];
      for (final value in functionValueCallsArgs) {
        //TODO: add a way to mark functions as async or none-async
        results.add(await function(value));
      }
      return results;
    }
  }
}

class StatementOperation extends Operation {
  final Statement statement;
  StatementOperation(this.statement, List<ListAccess>? listAccess) : super(OperationType.statement, listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) => statement.execute(input, interpreter);
}

enum ScopeOperationType {
  current,
  top,
}

class ScopeOperation extends Operation {
  final ScopeOperationType scopeType;
  ScopeOperation(this.scopeType, List<ListAccess>? listAccess) : super(OperationType.scope, listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, Interpreter interpreter) {
    switch (scopeType) {
      case ScopeOperationType.current:
        return input;
      case ScopeOperationType.top:
        return interpreter.values;
    }
  }
}
