//Make sure to keep this as the first import
// ignore_for_file: unused_import, prefer_final_locals, prefer_const_constructors

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/shared/util.dart';
import 'package:web_content_parser/web_content_parser_full.dart';

import 'dart:io';
import 'package:test/test.dart';

import 'package:html/dom.dart';
import 'package:html/parser.dart';

import 'blank.dart';
import 'heroku.dart';

import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  group('Utility', () {
    test('Enable log', () {
      WebContentParser.verbose = true;
      expect(WebContentParser.verbose, isTrue);
    });
    test('Passing Result', () {
      Result<String> f = Result<String>.pass('Test');
      expect(f.pass, isTrue);
      expect(f.fail, isFalse);
      expect(f.data, equals('Test'));
    });
    test('Passing Result Nullable With Null', () {
      Result<String?> f = Result<String?>.pass(null);
      expect(f.pass, isTrue);
      expect(f.data, null);
    });
    test('Passing Result Nullable With String', () {
      Result<String?> f = Result<String?>.pass('Test');
      expect(f.pass, isTrue);
      expect(f.data, equals('Test'));
    });
    test('Failing Result', () {
      Result<String> f = Result<String>.fail();
      expect(f.pass, isFalse);
      expect(f.fail, isTrue);
      expect(f.data, equals(null));
    });
    test('RequestType extension comparisons', () {
      expect(RequestType.catalog.catalog, isTrue);
      expect(RequestType.post.post, isTrue);
      expect(RequestType.postUrl.postUrl, isTrue);
      expect(RequestType.images.images, isTrue);
      expect(RequestType.imagesUrl.imagesUrl, isTrue);
      expect(RequestType.catalog.catalog, isTrue);
      expect(RequestType.catalogMulti.catalogMulti, isTrue);
      expect(RequestType.chapters.chapters, isTrue);
      expect(RequestType.unknown.unknown, isTrue);
    });

    test('RequestType string conversions', () {
      expect(requestMap('post').post, isTrue);
      expect(requestMap('postUrl').postUrl, isTrue);
      expect(requestMap('images').images, isTrue);
      expect(requestMap('imagesUrl').imagesUrl, isTrue);
      expect(requestMap('catalog').catalog, isTrue);
      expect(requestMap('catalogMulti').catalogMulti, isTrue);
      expect(requestMap('chapters').chapters, isTrue);
      expect(requestMap('unknown').unknown, isTrue);
      expect(requestMap('').unknown, isTrue);
    });

    test('RequestType extension string', () {
      expect(requestMap(RequestType.catalog.string).catalog, isTrue);
      expect(requestMap(RequestType.post.string).post, isTrue);
      expect(requestMap(RequestType.postUrl.string).postUrl, isTrue);
      expect(requestMap(RequestType.images.string).images, isTrue);
      expect(requestMap(RequestType.imagesUrl.string).imagesUrl, isTrue);
      expect(requestMap(RequestType.catalog.string).catalog, isTrue);
      expect(requestMap(RequestType.catalogMulti.string).catalogMulti, isTrue);
      expect(requestMap(RequestType.chapters.string).chapters, isTrue);
      expect(requestMap(RequestType.unknown.string).unknown, isTrue);
    });

    test('ResultExtended toJson', () {
      Result r = const Result.fail();
      Map<String, dynamic> values = ResultExtended.toJson(r);
      expect(
        {
          'data': null,
          'pass': false,
          'fail': true,
        },
        equals(values),
      );
    });

    test('ResultExtended unsafe fail', () {
      // ignore: always_declare_return_types
      unsafe() {
        throw 'error';
      }

      Result r = ResultExtended.unsafe(unsafe);
      expect(r.fail, isTrue);
    });
    test('ResultExtended unsafe pass', () {
      // ignore: always_declare_return_types
      unsafe() {
        return 'test';
      }

      Result r = ResultExtended.unsafe(unsafe);
      expect(r.pass, isTrue);
      expect(r.data, equals('test'));
    });
    test('ResultExtended unsafe async fail', () async {
      Result<String> r = await ResultExtended.unsafeAsync(() => Future.delayed(Duration(milliseconds: 0), () {
            throw 'error';
          }));
      expect(r.fail, isTrue);
    });
    test('ResultExtended unsafe async pass', () async {
      Result<String> r = await ResultExtended.unsafeAsync(() => Future.delayed(Duration(milliseconds: 0), () {
            return 'test';
          }));
      expect(r.pass, isTrue);
      expect(r.data, equals('test'));
    });
    test('ParseUriResult fail', () {
      Result<dynamic> r = UriResult.parse('http ://');
      expect(r.fail, isTrue);
    });
    test('ParseUriResult pass', () {
      Result<dynamic> r = UriResult.parse('http://');
      expect(r.pass, isTrue);
    });
  });

  group('Generic data', () {
    test('Create ID', () {
      ID id = ID(id: 'test', source: 'testing');
      expect(id.uid, equals('testing:test'));
    });

    test('Create ID from JSON', () {
      ID id = ID.fromJson({
        'id': 'test',
        'source': 'testing',
      });
      expect(id.uid, equals('testing:test'));
    });

    test('Convert ID to JSON', () {
      ID id = ID(id: 'test', source: 'testing');
      expect(id.toJson(), equals({'id': 'test', 'source': 'testing', 'uid': 'testing:test'}));
    });

    test('IDs equal', () {
      ID id = ID(id: 'test', source: 'testing');
      ID id1 = ID(id: 'test', source: 'testing');
      expect(id, equals(id1));
    });
    test('IDs not equal', () {
      ID id = ID(id: 'test', source: 'testing');
      ID id1 = ID(id: 'test3', source: 'testing');
      expect(id, isNot(equals(id1)));
    });
    test('Create ChapterID', () {
      ChapterID id = ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'));
      expect(id.uid, equals('testing:test:0'));
    });
    test('Create ChapterID from json', () {
      ChapterID id = ChapterID.fromJson({
        'url': '',
        'index': '0',
        'id': ID(id: 'test', source: 'testing'),
      });
      expect(id.uid, equals('testing:test:0'));
    });
    test('ChapterID equals', () {
      ChapterID id = ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'));
      ChapterID id1 = ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'));
      expect(id, equals(id1));
    });
    test('ChapterID not equals', () {
      ChapterID id = ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'));
      ChapterID id1 = ChapterID(url: '', index: 1, id: ID(id: 'test', source: 'testing'));
      expect(id, isNot(equals(id1)));
    });
  });

  group('Scraper', () {
    test('Parse Yaml to Map', () {
      final Map<String, dynamic> map = parseYaml('''
                                  source: testSource
                                  baseUrl: testSource.com
                                  subdomain: null
                                  version: 1
                                  contentType: seriesImage
                                  programType: hetu0.3
                                  requests:
                                    - type: post
                                      file: fetch.ht
                                      entry: main
                                      compiled: true
                                    - type: postUrl
                                      file: fetch.ht
                                      entry: url
                                  ''');
      expect(
          map,
          equals({
            'source': 'testSource',
            'baseUrl': 'testSource.com',
            'subdomain': null,
            'version': 1,
            'contentType': 'seriesImage',
            'programType': 'hetu0.3',
            'requests': [
              {
                'type': 'post',
                'file': 'fetch.ht',
                'entry': 'main',
                'compiled': true,
              },
              {
                'type': 'postUrl',
                'file': 'fetch.ht',
                'entry': 'url',
              },
            ],
          }));
    });

    test('Load yaml file', () {
      WebContentParser.verbose = true;

      List<ScraperSource> scrapers = loadExternalScarperSources(Directory('test/samples/scraper'));
      //have one scraper
      expect(scrapers.length, equals(1));
      //scraper has 8 requests
      expect(scrapers[0].requests.length, equals(8));
      //info is correct
      expect(
        scrapers[0].info,
        equals(<String, dynamic>{
          'source': 'testSource',
          'baseUrl': 'testSource.com',
          'subdomain': null,
          'version': 1,
          'contentType': 'seriesImage',
          'programType': 'hetu0.3',
          'requests': [
            {
              'type': 'post',
              'file': 'fetch.ht',
              'entry': 'main',
              'compiled': true,
            },
            {
              'type': 'postUrl',
              'file': 'fetch.ht',
              'entry': 'url',
            },
            {
              'type': 'chapters',
              'file': 'chapterlist.ht',
              'entry': 'main',
            },
            {
              'type': 'images',
              'file': 'fetchImages.ht',
              'entry': 'main',
            },
            {
              'type': 'imagesUrl',
              'file': 'fetchImages.ht',
              'entry': 'url',
            },
            {
              'type': 'catalogMulti',
              'file': 'catalog.ht',
              'entry': 'main',
            },
            {
              'type': 'test',
              'file': 'test.ht',
              'entry': 'main',
            },
            {
              'type': 'test2',
              'file': 'test.wql',
              'programType': 'wql',
            },
          ],
        }),
      );
    });
    test('Invalid global load', () {
      ScraperSource? result = ScraperSource.scrapper('invalid');
      expect(result, isNull);
    });
    test('Load global scraper source and run Hetu entry', () async {
      WebContentParser.verbose = true;

      loadExternalScraperSourcesGlobal(Directory('test/samples/scraper'));

      ScraperSource? result = ScraperSource.scrapper('testSource');

      expect(result, isNotNull);

      //override current fetchhtml so it can work with local files
      insertFunction('fetchHtml', (
        HTEntity entity, {
        List<dynamic> positionalArgs = const [],
        Map<String, dynamic> namedArgs = const {},
        List<HTType> typeArgs = const <HTType>[],
      }) async {
        return await File(positionalArgs[0]).readAsString();
      });

      Result<List> response =
          await result!.makeRequest<List>('test', [MapEntry('path', 'test/samples/scraper/test.html')]);

      expect(response.pass, isTrue);

      expect(response.data, equals(['Some testing text', 'Some testing text']));
    });
    test('Load global scraper source and run WQL entry', () async {
      WebContentParser.verbose = true;

      loadExternalScraperSourcesGlobal(Directory('test/samples/scraper'));

      ScraperSource? result = ScraperSource.scrapper('testSource');

      expect(result, isNotNull);

      //override setstatement function to work with loading a file
      /* SetStatement.functions['getrequest'] = (args) async {
        return await File(args[0].first).readAsString();
      }; */

      Result<List> response =
          await result!.makeRequest<List>('test2', [MapEntry('path', 'test/samples/scraper/test.html')]);

      expect(response.pass, isTrue);

      expect(response.data, equals(['Some testing text', 'Some testing text']));
    });
  });

  group('Parser', () {
    group('Undefined source', () {
      test('Source supports', () {
        bool supports = sourceSupports('', RequestType.catalog);
        expect(supports, isFalse);
      });

      test('Get source info', () {
        Result r = getSourceInfo('');
        expect(r.fail, isTrue);
      });

      test('Get post', () async {
        Result<Post> post = await fetchPost(ID(source: '', id: ''));
        expect(post.fail, isTrue);
      });
      test('Get post url', () async {
        Result<Post> post = await fetchPostUrl('');
        expect(post.fail, isTrue);
      });
      test('Get chapters', () async {
        Result<List<Chapter>> chapter = await fetchChapters(ID(source: '', id: ''));
        expect(chapter.fail, isTrue);
      });
      test('Get chapter images', () async {
        Result<Map<int, String>> chapter =
            await fetchChapterImages(ChapterID(url: '', index: 0, id: ID(source: '', id: '')));
        expect(chapter.fail, isTrue);
      });
      test('Get chapter images url', () async {
        Result<Map<int, String>> chapter = await fetchChapterImagesUrl('');
        expect(chapter.fail, isTrue);
      });
    });

    group('Blank source with request types enabled', () {
      addSource('blank', BlankSource());

      ID id = ID(id: '', source: 'blank');

      test('Fail get catalog', () async {
        Result<List<CatalogEntry>> catalog = await fetchCatalog('blank');
        expect(catalog.fail, isTrue);
      });
      test('Fail get post', () async {
        Result<Post> post = await fetchPost(id);
        expect(post.fail, isTrue);
      });
      test('Fail get post url with valid url', () async {
        Result<Post> post = await fetchPostUrl('test.test');
        expect(post.fail, isTrue);
      });
      test('Fail get post url with invalid url', () async {
        Result<Post> post = await fetchPostUrl('test.com');
        expect(post.fail, isTrue);
      });
      test('Fail get chapter', () async {
        Result<List<Chapter>> chapter = await fetchChapters(id);
        expect(chapter.fail, isTrue);
      });
      test('Fail get chapter images', () async {
        Result<Map<int, String>> images = await fetchChapterImages(ChapterID(url: '', index: 0, id: id));
        expect(images.fail, isTrue);
      });
      test('Fail get chapter images url', () async {
        Result<Map<int, String>> images = await fetchChapterImagesUrl('test.test');
        expect(images.fail, isTrue);
      });
      test('Get correct info', () {
        Result<Map<String, dynamic>> info = getSourceInfo('blank');
        expect(info.pass, isTrue);
        expect(
          info.data,
          equals(<String, dynamic>{
            'parse': false,
            'source': 'blank',
            'version': 0,
            'baseurl': 'test.test',
            'subdomain': null,
          }),
        );
      });
    });

    //TODO: revise testing for external sources and parsed sources
    /*group('External sources', () {
      test('Load external sources', () {
        loadExternalSource(Directory('bin'));
        expect(sources.length, greaterThan(1));
      });
    });*/

    group('Basic source info', () {
      //load env
      load();

      if (env['BASE'] == null && env['SUB'] == null) {
        throw 'Source needs to be defined in .env';
      }

      addSource('test', TestSource(env['BASE']!, env['SUB']!));

      test('Source exists', () {
        expect(sources, contains('test'));
      });

      test('Source doesn\'t support catalog', () {
        bool supports = sourceSupports('test', RequestType.catalog);
        expect(supports, equals(false));
      });

      test('Source doesn\'t support multi catalog', () {
        bool supports = sourceSupports('test', RequestType.catalogMulti);
        expect(supports, equals(false));
      });

      test('Source supports post', () {
        bool supports = sourceSupports('test', RequestType.post);
        expect(supports, isTrue);
      });

      test('Source supports post url', () {
        bool supports = sourceSupports('test', RequestType.postUrl);
        expect(supports, isTrue);
      });

      test('Source supports chapter list', () {
        bool supports = sourceSupports('test', RequestType.chapters);
        expect(supports, isTrue);
      });

      test('Get post', () async {
        Result<Post> p = await fetchPost(ID(id: '1', source: 'test'));
        expect(p.pass, isTrue);
      });

      test('Get post url', () async {
        Result<Post> p = await fetchPostUrl('${env["SOURCE"]}/manga/get/1');
        expect(p.pass, isTrue);
      });

      test('Post to json', () async {
        Result<Post> p = await fetchPost(ID(id: '1', source: 'test'));
        expect(p.data?.toJson(), isMap);
      });

      test('Fail post', () async {
        Result<Post> p = await fetchPost(ID(id: '0', source: 'test'));
        expect(p.fail, isTrue);
      });

      test('Get chapter list', () async {
        Result<List<Chapter>> chapters = await fetchChapters(ID(id: '1', source: 'test'));
        expect(chapters.pass, isTrue);
      });
      test('Get chapter list not empty', () async {
        Result<List<Chapter>> chapters = await fetchChapters(ID(id: '1', source: 'test'));
        expect(chapters.data, isNotEmpty);
      });
    });
  });

  //Tests the features of the source builder language
  group('Source Builder', () {
    test('Get basic information', () async {
      Document document = parse(File('./test/samples/scraper/test2.html').readAsStringSync());

      final code = '''
        SELECT name AS random, innerHTML FROM document INTO doc WHERE SELECTOR IS 'body > p';
        DEFINE firstname STRING hello;
        SELECT doc[], firstname FROM * into doctwo;
        SELECT doc[].random, doc[].innerHTML, firstname FROM * INTO docthree;
      ''';

      final values = await runWQL(code, parameters: {'document': document});
      expect(values['doctwo'], equals(values['docthree']));
      expect(
          values['doctwo'],
          equals([
            {'random': 'p', 'innerHTML': ' Some testing text 1 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 2 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 3 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 4 ', 'firstname': 'hello'},
          ]));
    });
    //TODO: add tests for set statement functions
    test('increment', () async {
      final code = '''
        DEFINE number INT 0;
        SET number TO increment WITH number;
      ''';

      final values = await runWQL(code);

      expect(values['number'], equals(1));
    });
    test('decrement', () async {
      final code = '''
        DEFINE number INT 0;
        SET number TO decrement WITH number;
      ''';

      final values = await runWQL(code);

      expect(values['number'], equals(-1));
    });
    test('concat', () async {
      final code = '''
        DEFINE first STRING hello;
        DEFINE second STRING ' world';
        SET output TO concat WITH first, second;
      ''';

      final values = await runWQL(code);

      expect(values['output'], equals('hello world'));
    });
  });
}
