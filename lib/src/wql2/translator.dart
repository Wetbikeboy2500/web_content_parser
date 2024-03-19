import 'package:petitparser/petitparser.dart';

import 'dot_input/dot_input.dart';
import 'dot_input/list_access.dart';
import 'dot_input/operation.dart';
import 'interpreter.dart';
import 'statements/eval_statement.dart';
import 'statements/if_statement.dart';
import 'statements/select_statement.dart';
import 'statements/set_statement.dart';
import 'statements/statement.dart';

extension CharWrapper on Parser {
  Parser wrapChars(String ch0, String ch1) => (charTrim(ch0) & this & charTrim(ch1)).pick(1);
}

Parser charTrim(String ch) => char(ch).trim();

Result parse(String input, Interpreter interpreter) {
  final safeChars = patternIgnoreCase('~!@\$%&*_+=/\'"?><|`#a-zA-Z0-9\\-\\^');

  final access = safeChars.plus().flatten().trim();

  final rawInputSingleQuote = pattern("^'").star().flatten().wrapChars("'", "'");

  final literal =
      ((char('l') | char('s') | char('b') | char('n')) & rawInputSingleQuote.trim()).map<LiteralOperation>((items) {
    final value = items[1];
    return LiteralOperation(switch (items[0]) {
      'l' => [],
      's' => (value is String) ? value : value.toString(),
      'n' => (value is num) ? value : num.parse(value),
      'b' => (value is bool) ? value : value.toLowerCase() == 'true',
      _ => throw Exception('Invalid type'),
    });
  });

  final number = (char('-').optional() & digit().plus()).flatten().map<int>((value) => int.parse(value));

  final accessIndexTypes = (number | stringIgnoreCase('first') | stringIgnoreCase('last'))
      .map<int>((value) => value is String ? (value == 'first' ? 0 : -1) : value);

  final arrayAccess = stringIgnoreCase('all').map<AllAccess>((_) => const AllAccess()) |
      stringIgnoreCase('first').map<FirstAccess>((_) => const FirstAccess()) |
      number.map<Index1Access>((value) => Index1Access(value)) |
      stringIgnoreCase('last').map<LastAccess>((_) => const LastAccess()) |
      (accessIndexTypes & charTrim(':') & accessIndexTypes)
          .map<IndexRangeAccess>((value) => IndexRangeAccess(value[0], value[2])) |
      (accessIndexTypes & charTrim(':') & accessIndexTypes & charTrim(':') & number)
          .map<IndexRangeStepAccess>((value) => IndexRangeStepAccess(value[0], value[2], value[4])) |
      stringIgnoreCase('even').map<EvenAccess>((_) => const EvenAccess()) |
      stringIgnoreCase('odd').map<OddAccess>((_) => const OddAccess());

  final digitInput = (arrayAccess.plusSeparated(charTrim(',')))
      .optional()
      .wrapChars('[', ']')
      .map<List<ListAccess>?>((value) => value?.elements.cast<ListAccess>() ?? const [AllAccess()]);

  final mapKey = (access & digitInput.optional()).map((value) => switch (value[0]) {
        '*' => CurrentScopeOperation(value[1]),
        '^' => TopScopeOperation(value[1]),
        _ => KeyOperation(value[0], value[1]),
      });

  final completeParser = undefined();
  final dotInput = undefined();

  final function = (letter().plus().flatten().trim() &
          dotInput.plusSeparated(charTrim(',')).optional().wrapChars('(', ')').map<List<DotInput>>((value) {
            return value?.elements.cast<DotInput>() ?? [];
          }) &
          digitInput.optional())
      .map<FunctionOperation>((value) => FunctionOperation(
            value[0],
            false,
            interpreter.functions[value[0].toLowerCase()] ?? (throw Exception('Function not found: ${value[0]}')),
            value[1],
            value[2],
          ));

  final selectKeys = ((access & charTrim(':')).pick(0).optional() & dotInput).map((value) => (value[0], value[1]));

  final selectStatement = (stringIgnoreCase('select').trim() &
          selectKeys.plusSeparated(charTrim(',')).wrapChars("{", "}").map((value) => value.elements) &
          (stringIgnoreCase('from').trim() & charTrim('{') & dotInput & charTrim('}')).pick(2).optional())
      .map<SelectStatement>((value) => SelectStatement(value[1].cast<(String?, DotInput)>(), value[2]));

  final ifStatement = (stringIgnoreCase('if').trim() &
          dotInput.wrapChars('{', '}') &
          (stringIgnoreCase('else').trim() & completeParser.wrapChars('{', '}')).pick(1).optional())
      .map<IfStatement>((value) => IfStatement(value[1], false, null, value[2]));

  final evalStatement = (stringIgnoreCase('eval').trim() & completeParser.wrapChars('{', '}'))
      .map<EvalStatement>((value) => EvalStatement(value[1]));

  final statements = ((selectStatement | ifStatement | evalStatement) & digitInput.optional())
      .map((value) => StatementOperation(value[0], value[1]));

  dotInput.set(literal.map((value) => DotInput([value])) |
      (function | statements | mapKey).plusSeparated(charTrim('.')).map<DotInput>((dynamic value) {
        if (value.elements[0] is FunctionOperation) {
          final function = value.elements[0] as FunctionOperation;
          value.elements[0] =
              FunctionOperation(function.name, true, function.function, function.arguments, function.listAccess);
        }

        return DotInput(value.elements.cast<Operation>());
      }));

  final accessStatement = (access & charTrim('=') & dotInput).map((value) => SetStatement(value[0], value[2]));

  final topIf = (stringIgnoreCase('if').trim() &
          dotInput.wrapChars('(', ')') &
          completeParser.wrapChars('{', '}') &
          (stringIgnoreCase('else').trim() & completeParser.wrapChars('{', '}')).optional())
      .map((value) => IfStatement(value[1], true, value[2], value[3]));

  completeParser.set((accessStatement | topIf | dotInput)
      .optional()
      .plusSeparated(charTrim(';'))
      .map<List<Statement>>((value) => value.elements.nonNulls.toList().cast<Statement>()));

  return completeParser.parse(input);
}
