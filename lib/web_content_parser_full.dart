library web_content_parser;

export './src/webContentParser.dart';

//Parse sources
export 'src/parser/sources/sourceTemplate.dart';
export 'src/parser/sources/computeDecorator.dart';
export 'src/parser/sources/source.dart';
export 'src/parser/json/id.dart';
export 'src/parser/json/chapterID.dart';
export 'src/parser/json/post.dart';
export 'src/parser/json/author.dart';
export 'src/parser/json/chapter.dart';
export 'src/parser/json/catalogEntry.dart';

//Scraper
export 'src/scraper/scraperSource.dart';
export 'src/scraper/scraper.dart';
export 'src/scraper/wql/wqlFunctions.dart';
export 'src/util/parseYaml.dart';

//Utils
export 'src/util/Result.dart';
export 'src/util/ResultExtended.dart';
export 'src/util/RequestType.dart';
export 'src/util/firstWhereResult.dart';
export 'src/util/parseUriResult.dart';
export 'src/util/log.dart';

//WQL
export 'src/wql/wql.dart';
export 'src/wql/statements/setStatement.dart';
export 'src/wql/statements/statement.dart';
export 'src/wql/interpreter/interpreter.dart';