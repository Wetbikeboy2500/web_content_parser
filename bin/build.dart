
import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/wql/wql.dart';

void main(List<String> args) {
  const wql ='''
  SET document TO getRequest(s'https://google.com');
  SET status TO getStatusCode(^.document);
  IF status EQUALS n'200':
      SET html TO parseBody(^.document);
      SELECT
        *.attribute(s'style') as style,
        *.attribute(s'id') as id
      FROM html.querySelectorAll(s'div')[]
      INTO return;
  ENDIF;''';

  loadWQLFunctions();

  runWQL(wql).then((value) {
    print(value.data?['return']);
  });
}