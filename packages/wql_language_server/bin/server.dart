// bin/server.dart
import 'dart:io';
import 'package:lsp_server/lsp_server.dart';
import 'package:petitparser/petitparser.dart';

final documents = <String, String>{};

const tokenTypes = [
  'function',
  'variable',
  'string',
  'keyword',
  'operator',
  'type',
  'number',
];

List flattenList(List list) {
  return list.expand((element) => element is List ? flattenList(element) : [element]).toList();
}

void main() async {
  var connection = Connection(stdin, stdout);

  connection.onInitialize((params) async {
    return InitializeResult(
      capabilities: ServerCapabilities(
        textDocumentSync: const Either2.t1(TextDocumentSyncKind.Full),
        completionProvider: CompletionOptions(
          resolveProvider: false,
          triggerCharacters: ['.'],
        ),
        hoverProvider: const Either2.t1(true),
        definitionProvider: const Either2.t1(true),
        documentSymbolProvider: const Either2.t1(true),
        semanticTokensProvider: Either2.t1(
          SemanticTokensOptions(
            legend: SemanticTokensLegend(
              tokenTypes: tokenTypes,
              tokenModifiers: [],
            ),
            full: const Either2.t1(true),
            range: const Either2.t1(false),
          ),
        ),
      ),
    );
  });

  connection.onCompletion((params) async {
    return CompletionList(
      isIncomplete: false,
      items: [
        CompletionItem(
          label: 'increment',
          kind: CompletionItemKind.Function,
          detail: 'Increment a number',
        ),
        CompletionItem(
          label: 'decrement',
          kind: CompletionItemKind.Function,
          detail: 'Decrement a number',
        ),
        CompletionItem(
          label: 'trim',
          kind: CompletionItemKind.Function,
          detail: 'Trim a string',
        ),
        CompletionItem(
          label: 'merge',
          kind: CompletionItemKind.Function,
          detail: 'Merge a list of items',
        ),
        CompletionItem(
          label: 'concat',
          kind: CompletionItemKind.Function,
          detail: 'Joins a list of items into a single string',
        ),
        CompletionItem(
          label: 'add',
          kind: CompletionItemKind.Function,
          detail: 'Add an item to a list or a number',
        ),
        CompletionItem(
          label: 'addAll',
          kind: CompletionItemKind.Function,
          detail: 'Add all items from one list to another',
        ),
        CompletionItem(
          label: 'last',
          kind: CompletionItemKind.Function,
          detail: 'Get the last item from a list',
        ),
        CompletionItem(
          label: 'first',
          kind: CompletionItemKind.Function,
          detail: 'Get the first item from a list',
        ),
        CompletionItem(
          label: 'length',
          kind: CompletionItemKind.Function,
          detail: 'Get the length of a list',
        ),
        CompletionItem(
          label: 'split',
          kind: CompletionItemKind.Function,
          detail: 'Split a string into a list of items',
        ),
        CompletionItem(
          label: 'indexOf',
          kind: CompletionItemKind.Function,
          detail: 'Get the index of an item in a list',
        ),
        CompletionItem(
          label: 'contains',
          kind: CompletionItemKind.Function,
          detail: 'Check if a list contains an item',
        ),
        CompletionItem(
          label: 'indexOfStartingAt',
          kind: CompletionItemKind.Function,
          detail: 'Get the index of an item in a list starting at a specific index',
        ),
        CompletionItem(
          label: 'substring',
          kind: CompletionItemKind.Function,
          detail: 'Get a substring from a string',
        ),
        CompletionItem(
          label: 'replaceAll',
          kind: CompletionItemKind.Function,
          detail: 'Replace all occurrences of a substring in a string',
        ),
        CompletionItem(
          label: 'createRange',
          kind: CompletionItemKind.Function,
          detail: 'Create a range of numbers',
        ),
        CompletionItem(
          label: 'reverse',
          kind: CompletionItemKind.Function,
          detail: 'Reverse a list',
        ),
        CompletionItem(
          label: 'itself',
          kind: CompletionItemKind.Function,
          detail: 'Return the input value',
        ),
        CompletionItem(
          label: 'print',
          kind: CompletionItemKind.Function,
          detail: 'Print the input values',
        ),
        CompletionItem(
          label: 'isNull',
          kind: CompletionItemKind.Function,
          detail: 'Check if a value is null',
        ),
        CompletionItem(
          label: 'not',
          kind: CompletionItemKind.Function,
          detail: 'Negate a boolean value',
        ),
        CompletionItem(
          label: 'and',
          kind: CompletionItemKind.Function,
          detail: 'Logical AND operation',
        ),
        CompletionItem(
          label: 'or',
          kind: CompletionItemKind.Function,
          detail: 'Logical OR operation',
        ),
        CompletionItem(
          label: 'equals',
          kind: CompletionItemKind.Function,
          detail: 'Check if two values are equal',
        ),
        CompletionItem(
          label: 'throw',
          kind: CompletionItemKind.Function,
          detail: 'Throw an exception which will cause a noop',
        ),
      ],
    );
  });

  connection.onHover((params) async {
    return Hover(
      contents: Either2.t1(
        MarkupContent(
          kind: MarkupKind.Markdown,
          value: 'Documentation for the symbol under cursor',
        ),
      ),
    );
  });

  connection.onDocumentSymbol((DocumentSymbolParams params) async {
    final uri = params.textDocument.uri;
    final text = documents[uri.toString()] ?? '';

    final symbols = <SymbolInformation>[];
    final result = parse(text);

    if (result case Success()) {
      //convert semantic tokens to document symbols
      final tokens = flattenList(result.value).whereType<SemanticToken>().toList();

      for (var token in tokens) {
        //base information of off the token type
        final SymbolKind kind = switch (tokenTypes[token.tokenType]) {
          'function' => SymbolKind.Function,
          'variable' => SymbolKind.Variable,
          'string' => SymbolKind.Str,
          'keyword' => SymbolKind.Constant,
          'operator' => SymbolKind.Operator,
          'type' => SymbolKind.Class,
          'number' => SymbolKind.Number,
          _ => SymbolKind.Variable,
        };

        final symbol = SymbolInformation(
          name: tokenTypes[token.tokenType],
          kind: kind,
          location: Location(
            range: Range(
              start: Position(line: token.line, character: token.character),
              end: Position(line: token.line, character: token.character + token.length),
            ),
            uri: uri,
          ),
        );

        symbols.add(symbol);
      }
    }

    return symbols;
  });

  connection.onDidOpenTextDocument((params) async {
    documents[params.textDocument.uri.toString()] = params.textDocument.text;
  });

  connection.onDidChangeTextDocument((params) async {
    if (params.contentChanges.isNotEmpty) {
      List<TextDocumentContentChangeEvent2> contentChanges = params.contentChanges
          .map((e) => TextDocumentContentChangeEvent2.fromJson(e.toJson() as Map<String, dynamic>))
          .toList();

      documents[params.textDocument.uri.toString()] = contentChanges.last.text;

      connection.sendNotification('textDocument/semanticTokens/refresh', {});
    }
  });

  connection.onDidCloseTextDocument((params) async {
    documents.remove(params.textDocument.uri.toString());
  });

  connection.onRequest<SemanticTokens>('textDocument/semanticTokens/full', (params) async {
    var semanticParam = SemanticTokensParams.fromJson(params.value);

    final uri = semanticParam.textDocument.uri;
    final text = documents[uri.toString()] ?? '';

    final result = parse(text);

    final tokens = <SemanticToken>[];

    if (result case Success()) {
      tokens.addAll(flattenList(result.value).whereType<SemanticToken>().toList());
    } else if (result case Failure()) {
      // TODO: handle failure in some way that is not too disruptive
    }

    final data = <int>[];

    int previousLine = 0;
    int previousCharacter = 0;
    for (var token in tokens) {
      data.addAll(token.toLspFormat(previousLine: previousLine, previousCharacter: previousCharacter));
      previousLine = token.line;
      previousCharacter = token.character;
    }

    return SemanticTokens(data: data);
  });

  await connection.listen();
}

extension CharWrapper on Parser {
  Parser wrapChars(String ch0, String ch1) => (charTrim(ch0) & this & charTrim(ch1)).pick(1);
  Parser wrapCharsPreserve(String ch0, String ch1) => (char(ch0) & this & char(ch1)).pick(1);
  Parser toSemanticToken(int tokenType) => map<SemanticToken>((token) {
        return SemanticToken(
          line: token.line,
          character: token.column,
          length: token.length,
          tokenType: tokenType,
          tokenModifiers: 0,
        );
      });
}

SemanticToken toSemanticToken(Token token, int tokenType) {
  return SemanticToken(
    line: token.line,
    character: token.column,
    length: token.length,
    tokenType: tokenType,
    tokenModifiers: 0,
  );
}

Parser charTrim(String ch) => char(ch, '$ch expected').trim();

Result parse(String input) {
  final safeChars = patternIgnoreCase('~!@\$%&*_+=/\'"?><|`#a-zA-Z0-9\\-\\^');

  final access = safeChars.plus().flatten().trim();

  final rawInputSingleQuote = pattern("^'").star().flatten().wrapCharsPreserve("'", "'");

  final literal = ((char('l') | char('s') | char('b') | char('n')) & rawInputSingleQuote.trim())
      .token()
      .map<SemanticToken>((token) {
    return switch (token.value[0]) {
      'l' => toSemanticToken(token, tokenTypes.indexOf('type')),
      's' => toSemanticToken(token, tokenTypes.indexOf('string')),
      'n' => toSemanticToken(token, tokenTypes.indexOf('number')),
      'b' => toSemanticToken(token, tokenTypes.indexOf('keyword')),
      _ => throw Exception('Invalid type'),
    };
  });

  final number = (char('-').optional() & digit().plus()).flatten().map<int>((value) => int.parse(value));

  final accessIndexTypes = (number | stringIgnoreCase('first') | stringIgnoreCase('last'));

  final arrayAccess = (stringIgnoreCase('all') |
          (accessIndexTypes & charTrim(':') & accessIndexTypes & charTrim(':') & number) |
          (accessIndexTypes & charTrim(':') & accessIndexTypes) |
          accessIndexTypes |
          stringIgnoreCase('even') |
          stringIgnoreCase('odd'))
      .token()
      .toSemanticToken(tokenTypes.indexOf('type'));

  final digitInput =
      (arrayAccess.plusSeparated(charTrim(',')).map((value) => value.elements)).optional().wrapChars('[', ']');

  final mapKey = (access.token() & digitInput.optional()).map((value) => switch (value[0].value) {
        '*' => toSemanticToken(value[0], tokenTypes.indexOf('operator')),
        '^' => toSemanticToken(value[0], tokenTypes.indexOf('operator')),
        _ => toSemanticToken(value[0], tokenTypes.indexOf('variable')),
      });

  final completeParser = undefined();
  final dotInput = undefined();

  final function = (letter().plus().flatten().trim().token().toSemanticToken(tokenTypes.indexOf('function')) &
      (dotInput.plusSeparated(charTrim(',')).map((value) => value.elements) & charTrim(',').optional())
          .pick(0)
          .optional()
          .wrapChars('(', ')') &
      digitInput.optional());

  final selectKeys =
      (((rawInputSingleQuote | access).token().toSemanticToken(tokenTypes.indexOf('variable')) & charTrim(':'))
                  .pick(0)
                  .optional() &
              dotInput)
          .map((value) => [value[0], value[1]]);

  final selectStatement = (stringIgnoreCase('select').trim().token().toSemanticToken(tokenTypes.indexOf('keyword')) &
      (selectKeys.plusSeparated(charTrim(',')) & charTrim(',').optional())
          .pick(0)
          .wrapChars("{", "}")
          .map((value) => value.elements) &
      (stringIgnoreCase('from').trim().token().toSemanticToken(tokenTypes.indexOf('keyword')) &
              charTrim('{') &
              dotInput &
              charTrim('}'))
          .optional());

  final ifStatement = (stringIgnoreCase('if').trim().token().toSemanticToken(tokenTypes.indexOf('keyword')) &
      dotInput.wrapChars('{', '}'));

  final evalStatement = (stringIgnoreCase('eval').trim().token().toSemanticToken(tokenTypes.indexOf('keyword')) &
      completeParser.wrapChars('{', '}'));

  final elseStatement = (stringIgnoreCase('else').trim().token().toSemanticToken(tokenTypes.indexOf('keyword')) &
      completeParser.wrapChars('{', '}'));

  final statements = ((selectStatement | ifStatement | evalStatement | elseStatement) & digitInput.optional());

  dotInput.set(literal | (function | statements | mapKey).plusSeparated(charTrim('.')).map((value) => value.elements));

  final accessStatement = (access.token().toSemanticToken(tokenTypes.indexOf('variable')) &
      charTrim('=').token().toSemanticToken(tokenTypes.indexOf('operator')) &
      dotInput);

  completeParser.set((accessStatement | dotInput | whitespace().star().flatten().map((value) => null))
      .plusSeparated(charTrim(';'))
      .map((value) => value.elements));

  return completeParser.end('Input suddenly ends').parse(input);
}

class SemanticToken {
  late final int line;
  late final int character;
  final int length;
  final int tokenType;
  final int tokenModifiers;

  SemanticToken({
    required int line,
    required int character,
    required this.length,
    required this.tokenType,
    required this.tokenModifiers,
  }) {
    this.line = line - 1;
    this.character = character - 1;
  }

  // Convert to LSP format (deltaLine, deltaStart, length, tokenType, tokenModifiers)
  List<int> toLspFormat({int previousLine = 0, int previousCharacter = 0}) {
    final deltaLine = line - previousLine;
    final deltaStart = previousLine == line ? character - previousCharacter : character;

    return [deltaLine, deltaStart, length, tokenType, tokenModifiers];
  }
}
