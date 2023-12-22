import 'package:petitparser/petitparser.dart';

Parser get name => safeChars.plus().flatten().trim();

Parser get arrayIndex =>
    stringIgnoreCase('first').trim().token() |
    stringIgnoreCase('last').trim().token() |
    (char('-').optional() & digit().plus().flatten()).flatten();

Parser get arrayAccess =>
    stringIgnoreCase('all').trim().token() |
    stringIgnoreCase('even').trim().token() |
    stringIgnoreCase('odd').trim().token() |
    (arrayIndex & char(':') & arrayIndex & char(':') & digit().star().flatten()) |
    (arrayIndex & char(':') & arrayIndex) |
    arrayIndex;

Parser get digitInput =>
    (char('[').trim().token() & (arrayAccess.plusSeparated(char(',').trim())).optional() & char(']').trim().token());

Parser get inputs => (input.trim() & (stringIgnoreCase('as').trim() & name).pick(1).optional())
    .separatedBy(char(','), includeSeparators: false);

Parser get input {
  final operator = undefined();

  final literal = (char('l') | char('s') | char('b') | char('n')).token() & rawInputSingleQuote.trim();

  final function = (letter().plus().flatten() &
      (char('(') & operator.separatedBy(char(',').trim(), includeSeparators: false).optional() & char(')')).pick(1));

  final access = safeChars.plus().flatten().trim();

  operator
      .set(literal | ((function | access) & digitInput.optional()).separatedBy(char('.'), includeSeparators: false));

  return operator;
}

//don't allow square brackets, round brackets, semi-colon, colon, and comma
Parser get safeChars => patternIgnoreCase('~!@\$%&*_+=/\'"?><{}|`#a-zA-Z0-9') | char('-') | char('^');

Parser get rawInputSingleQuote => (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

Parser get rawInput => (rawInputSingleQuote | safeChars.plus().flatten()).trim();
