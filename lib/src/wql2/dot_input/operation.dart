import 'dart:async';

import 'package:web_content_parser/src/util/log.dart';

import '../interpreter.dart';
import '../statements/statement.dart';
import 'dot_input.dart';
import 'list_access.dart';

sealed class Operation {
  final List<ListAccess>? listAccess;
  const Operation(this.listAccess);
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter);
}

class LiteralOperation extends Operation {
  final dynamic value;
  const LiteralOperation(this.value) : super(null);
  @override
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter) => value;
}

class KeyOperation extends Operation {
  final String key;
  const KeyOperation(this.key, super.listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter) {
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
  final bool topLevel;
  final Function function;
  final List<DotInput> arguments;
  const FunctionOperation(this.name, this.topLevel, this.function, this.arguments, super.listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter) async {
    //get all arguments for the function call
    final List<({dynamic value, bool wasExpanded})> args = [];
    int maxLengthOfMerge = -1;

    if (!topLevel) {
      args.add((value: input, wasExpanded: false));
      maxLengthOfMerge = 1;
    }

    for (final argument in arguments) {
      final result = await argument.execute(scope, interpreter);
      if (result.noop) {
        return null;
      }

      if (result.wasExpanded && result.result is List && result.result.length > maxLengthOfMerge) {
        maxLengthOfMerge = result.result.length;
      } else if (maxLengthOfMerge == -1) {
        maxLengthOfMerge = 1;
      }

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
      return await function(const []);
    } else if (maxLengthOfMerge == 1) {
      return await function(functionValueCallsArgs[0]);
    } else { //Inputs were expanding and need to return a list of results
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
  const StatementOperation(this.statement, super.listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter) => statement.execute(input, interpreter);
}

sealed class ScopeOperation extends Operation {
  const ScopeOperation(super.listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter);
}

class CurrentScopeOperation extends ScopeOperation {
  const CurrentScopeOperation(super.listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter) => scope;
}

class TopScopeOperation extends ScopeOperation {
  const TopScopeOperation(super.listAccess);
  @override
  FutureOr<dynamic> process(dynamic input, dynamic scope, Interpreter interpreter) => interpreter.values;
}
