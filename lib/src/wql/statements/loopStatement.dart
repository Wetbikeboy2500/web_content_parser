import '../interpreter/parseStatements.dart';
import '../suboperations/operator.dart';
import '../../../web_content_parser_full.dart';

class OperatorOrStatement {
  final Operator? operation;
  final Statement? statement;

  const OperatorOrStatement(this.operation, this.statement);
}

class LoopStatement extends Statement {
  final Operator item;

  final List<Statement> statements;

  const LoopStatement(this.item, this.statements);

  factory LoopStatement.fromTokens(List tokens) {
    return LoopStatement(Operator.fromTokensNoAlias(tokens[1]), parseStatements(tokens[3]));
  }

  @override
  Future<void> execute(Interpreter interpreter, dynamic context) async {
    interpreter.pushLocal();

    final List<dynamic> items = (await item.getValue(context, interpreter, custom: SetStatement.functions)).value;

    for (final item in items) {
      for (final statement in statements) {
          await statement.execute(interpreter, item);
      }
    }

    interpreter.popLocal();
  }
}
