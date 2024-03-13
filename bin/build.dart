
import 'package:web_content_parser/src/scraper/wql/wqlFunctions.dart';
import 'package:web_content_parser/src/wql/statements/setStatement.dart';
import 'package:web_content_parser/src/wql/wql.dart';
import 'package:web_content_parser/util.dart';

void main(List<String> args) {
  /* const wql ='''
  SET document TO getRequest(s'https://google.com');
  SET status TO getStatusCode(^.document);
  IF status EQUALS n'200':
      SET html TO parseBody(^.document);
      SELECT
        *.attribute(s'style') as style,
        *.attribute(s'id') as id
      FROM html.querySelectorAll(s'div')[]
      INTO return;
  ENDIF;'''; */
  const wql ='''
  SELECT
    *.querySelector(s'.f3').text().trim() as name,
    *.querySelector(s'.f5').text().trim() as description,
    joinUrl(s'https://github.com', *.querySelector(s'a').attribute(s'href')) as url
  FROM getRequest().parse().querySelectorAll(s'.py-4.border-bottom')[]
  INTO return;''';


  WebContentParser.cacheTime = const Duration(seconds: 0);

  loadWQLFunctions();

  var document = '''
      <!DOCTYPE html>
      <html>
        <head>
          <title>Test</title>
        </head>
        <body>
    ''';

    for (int i = 0; i < 1000; i++) {
      document += '''
          <div class="py-4 border-bottom">
            <div class="f3">Name</div>
            <div class="f5">Description</div>
            <a href="/topics">Link</a>
          </div>
      ''';
    }

    document += '''
        </body>
      </html>
    ''';

  SetStatement.functions['getrequest'] = (args) {
    return document;
  };

  Stopwatch stopwatch = Stopwatch()..start();

  //141204 µs

  runWQL(wql).then((value) {
    print('Benchmark 1: exec');
    print('  Time: ${stopwatch.elapsedMicroseconds} µs');
    if (value case Pass()) {
     //print(value.data['return']);
    } else {
     print('Failed');
    }
  });
}

///
///Benchmark 1: exec
///  Time (mean ± σ):     393.9 µs ± 173.4 µs    [User: 133.7 µs, System: 0.0 µs]
///  Range (min … max):     0.0 µs … 594.5 µs    20 runs
///
/// Benchmark 1: ./build.exe
///  Time (mean ± σ):     418.8 ms ±  33.1 ms    [User: 46.5 ms, System: 20.9 ms]
///  Range (min … max):   368.6 ms … 494.6 ms    20 runs