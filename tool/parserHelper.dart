import 'package:petitparser/petitparser.dart';

//Shared parser options

Parser get name => letter().plus().flatten().trim();

Parser get digitInput => (char('[').trim().token() &
        digit().star().flatten().optional() &
        (char(':') & digit().star().flatten()).optional() &
        char(']').trim().token())
    .flatten();

Parser get inputs => (input.trim() & (stringIgnoreCase('as').trim() & name).pick(1).optional())
    .separatedBy(char(','), includeSeparators: false);

Parser get input => (safeChars.plus().flatten().trim() & digitInput.optional()).separatedBy(char('.'), includeSeparators: false);

//don't allow square brackets, semi-colon, colon, and comma
Parser get safeChars => patternIgnoreCase('~!@\$%&*()_+=/\'"?><{}|`#a-zA-Z0-9') | char('-') | char('^');

Parser get rawInputSingleQuote => (char("'") & pattern("^'").star().flatten() & char("'")).pick(1);

Parser get rawInput => (rawInputSingleQuote | safeChars.plus().flatten()).trim();
