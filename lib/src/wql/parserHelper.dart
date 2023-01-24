import 'package:petitparser/petitparser.dart';

//Shared parser options

Parser get name => safeChars.plus().flatten().trim();

Parser get digitInput => (char('[').trim().token() &
        digit().star().flatten().optional() &
        (char(':') & digit().star().flatten()).optional() &
        char(']').trim().token())
    .flatten();

Parser get inputs => (input.trim() & (stringIgnoreCase('as').trim() & name).pick(1).optional())
    .separatedBy(char(','), includeSeparators: false);

Parser get input {
  final operator = undefined();

  final literal = (char('l') | char('s') | char('b') | char('n')).token() & rawInputSingleQuote.trim();

  final function = (letter().plus().flatten() &
      (char('(') & operator.separatedBy(char(',').trim(), includeSeparators: false).optional() & char(')'))
          .pick(1));

  final access = safeChars.plus().flatten().trim();

  operator
      .set(literal | ((function | access) & digitInput.optional()).separatedBy(char('.'), includeSeparators: false));

  return operator;
}

//don't allow square brackets, round brackets, semi-colon, colon, and comma
Parser get safeChars => patternIgnoreCase('~!@\$%&*_+=/\'"?><{}|`#a-zA-Z0-9') | char('-') | char('^');

Parser get rawInputSingleQuote => (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

Parser get rawInput => (rawInputSingleQuote | safeChars.plus().flatten()).trim();
