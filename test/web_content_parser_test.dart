//Make sure to keep this as the first import
// ignore_for_file: unused_import, prefer_final_locals, prefer_const_constructors

import 'package:web_content_parser/src/parser/sources/computer.dart';
import 'package:web_content_parser/src/wql/statements/loopStatement.dart';
import 'package:web_content_parser/web_content_parser_full.dart';

import 'dart:io';
import 'package:test/test.dart';

import 'package:html/dom.dart';
import 'package:html/parser.dart';

import 'blank.dart';
import 'heroku.dart';

void main() {
  group('Utility', () {
    test('Enable log', () {
      WebContentParser.verbose = const LogLevel.debug();
      expect(WebContentParser.verbose, equals(const LogLevel.debug()));
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
    group('ID', () {
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
    });
    group('ChapterID', () {
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
      test('Create ChapterID from json with json id', () {
        ChapterID id = ChapterID.fromJson({
          'url': '',
          'index': '0',
          'id': {
            'id': 'test',
            'source': 'testing',
          },
        });
        expect(id.uid, equals('testing:test:0'));
      });
      test('ChapterID to json', () {
        ChapterID id = ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'));
        expect(
            id.toJson(),
            equals({
              'url': '',
              'index': 0,
              'id': {'source': 'testing', 'id': 'test', 'uid': 'testing:test'},
              'uid': 'testing:test:0',
            }));
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
    group('Author', () {
      test('Create Author', () {
        Author author = Author(name: 'test', roles: '', first: false);
        expect(author.name, equals('test'));
        expect(author.roles, equals(''));
        expect(author.first, isFalse);
      });
      test('Create Author from json', () {
        Author author = Author.fromJson({
          'name': 'test',
          'roles': '',
          'first': false,
        });
        expect(author.name, equals('test'));
        expect(author.roles, equals(''));
        expect(author.first, isFalse);
      });
      test('Author to json', () {
        Author author = Author(name: 'test', roles: '', first: false);
        expect(author.toJson(), equals({'name': 'test', 'roles': '', 'first': false}));
      });
    });
    group('Catalog entry', () {
      test('Create catalog entry', () {
        final entry = CatalogEntry(
          id: ID(source: 'testing', id: 'test'),
          coverurl: '',
          name: 'Title',
        );

        expect(entry.id, equals(ID(source: 'testing', id: 'test')));
        expect(entry.coverurl, equals(''));
        expect(entry.name, equals('Title'));
      });
      test('Create catalog entry from json', () {
        final entry = CatalogEntry.fromJson({
          'id': ID(source: 'testing', id: 'test'),
          'coverurl': '',
          'name': 'Title',
        });

        expect(entry.id, equals(ID(source: 'testing', id: 'test')));
        expect(entry.coverurl, equals(''));
        expect(entry.name, equals('Title'));
      });
      test('Create catalog entry from json with json id', () {
        final entry = CatalogEntry.fromJson({
          'id': {
            'source': 'testing',
            'id': 'test',
          },
          'coverurl': '',
          'name': 'Title',
        });

        expect(entry.id, equals(ID(source: 'testing', id: 'test')));
        expect(entry.coverurl, equals(''));
        expect(entry.name, equals('Title'));
      });
      test('Convert catalog entry to json', () {
        final entry = CatalogEntry(
          id: ID(source: 'testing', id: 'test'),
          coverurl: '',
          name: 'Title',
        );

        expect(
          entry.toJson(),
          equals({
            'id': {'source': 'testing', 'id': 'test', 'uid': 'testing:test'},
            'coverurl': '',
            'name': 'Title',
          }),
        );
      });
      test('Catalog entry equals', () {
        final entry = CatalogEntry(
          id: ID(source: 'testing', id: 'test'),
          coverurl: '',
          name: 'Title',
        );
        final entry1 = CatalogEntry(
          id: ID(source: 'testing', id: 'test'),
          coverurl: '',
          name: 'Title',
        );

        expect(entry, equals(entry1));
      });
      test('Catalog entry not equals', () {
        final entry = CatalogEntry(
          id: ID(source: 'testing', id: 'test'),
          coverurl: '',
          name: 'Title',
        );
        final entry1 = CatalogEntry(
          id: ID(source: 'testing', id: 'test1'),
          coverurl: '',
          name: 'Title',
        );

        expect(entry, isNot(equals(entry1)));
      });
    });
    group('Chapter', () {
      test('Create chapter', () {
        final chapter = Chapter(
          name: 'Title',
          date: DateTime.now(),
          chapterID: ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')),
        );

        expect(chapter.name, equals('Title'));
        expect(chapter.date, isNotNull);
        expect(chapter.chapterID, equals(ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'))));
      });
      test('Create chapter from json', () {
        final chapter = Chapter.fromJson({
          'name': 'Title',
          'date': DateTime.now().toIso8601String(),
          'chapterID': ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')),
        });

        expect(chapter.name, equals('Title'));
        expect(chapter.date, isNotNull);
        expect(chapter.chapterID, equals(ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'))));
      });
      test('Create chapter from json with json chapterID', () {
        final chapter = Chapter.fromJson({
          'name': 'Title',
          'date': DateTime.now().toIso8601String(),
          'chapterID': {
            'url': '',
            'index': 0,
            'id': ID(id: 'test', source: 'testing'),
          },
        });

        expect(chapter.name, equals('Title'));
        expect(chapter.date, isNotNull);
        expect(chapter.chapterID, equals(ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'))));
      });
      test('Create chapter from json with no date', () {
        final chapter = Chapter.fromJson({
          'name': 'Title',
          'chapterID': ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')),
        });

        expect(chapter.name, equals('Title'));
        expect(chapter.date, isNotNull);
        expect(chapter.chapterID, equals(ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'))));
      });
      test('Create chapter from json with DateTime object', () {
        final chapter = Chapter.fromJson({
          'name': 'Title',
          'date': DateTime.now(),
          'chapterID': ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')),
        });

        expect(chapter.name, equals('Title'));
        expect(chapter.date, isNotNull);
        expect(chapter.chapterID, equals(ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing'))));
      });
      test('Compute chapter to json', () async {
        final computer = ComputerDecorator();
        final chapter = Chapter(
          name: 'Title',
          date: DateTime.now(),
          chapterID: ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')),
        );
        computer.start();
        final json = await Chapter.computeChapterToJson(computer, chapter);
        computer.end();
        expect(json, equals(chapter.toJson()));
      });
      test('Compute chapter from json', () async {
        final computer = ComputerDecorator();
        final json = {
          'name': 'Title',
          'date': DateTime.now().toIso8601String(),
          'chapterID': ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')).toJson(),
          'images': <String, dynamic>{},
          'chapterUpdateState': 'Same',
        };
        computer.start();
        final chapter = await Chapter.computeChapterFromJson(computer, json);
        computer.end();
        expect(chapter.toJson(), equals(json));
      });
      test('Chapters from json', () async {
        final json = [
          {
            'name': 'Title',
            'date': DateTime.now().toIso8601String(),
            'chapterID': ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')).toJson(),
            'images': <String, dynamic>{},
            'chapterUpdateState': 'Same',
          },
          {
            'name': 'Title',
            'date': DateTime.now().toIso8601String(),
            'chapterID': ChapterID(url: '', index: 1, id: ID(id: 'test', source: 'testing')).toJson(),
            'images': <String, dynamic>{},
            'chapterUpdateState': 'Same',
          },
        ];

        final chapters = Chapter.chaptersFromJson(json);

        expect(
          chapters.map((e) => e.toJson()).toList(),
          equals([
            json[0],
            json[1],
          ]),
        );
      });
      test('Compute chapters from json', () async {
        final computer = ComputerDecorator();
        final json = [
          {
            'name': 'Title',
            'date': DateTime.now().toIso8601String(),
            'chapterID': ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')).toJson(),
            'images': <String, dynamic>{},
            'chapterUpdateState': 'Same',
          },
          {
            'name': 'Title',
            'date': DateTime.now().toIso8601String(),
            'chapterID': ChapterID(url: '', index: 1, id: ID(id: 'test', source: 'testing')).toJson(),
            'images': <String, dynamic>{},
            'chapterUpdateState': 'Same',
          },
        ];

        computer.start();
        final chapters = await Chapter.computeChaptersFromJson(computer, json);
        computer.end();

        expect(
          chapters.map((e) => e.toJson()).toList(),
          equals([
            json[0],
            json[1],
          ]),
        );
      });
      test('Computer chapters to json', () async {
        final computer = ComputerDecorator();
        final chapters = [
          Chapter(
            name: 'Title',
            date: DateTime.now(),
            chapterID: ChapterID(url: '', index: 0, id: ID(id: 'test', source: 'testing')),
          ),
          Chapter(
            name: 'Title',
            date: DateTime.now(),
            chapterID: ChapterID(url: '', index: 1, id: ID(id: 'test', source: 'testing')),
          ),
        ];

        computer.start();
        final json = await Chapter.computeChaptersToJson(computer, chapters);
        computer.end();

        expect(
          json,
          equals([
            chapters[0].toJson(),
            chapters[1].toJson(),
          ]),
        );
      });
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
      WebContentParser.verbose = const LogLevel.debug();

      List<ScraperSource> scrapers = loadExternalScarperSources(Directory('test/samples/scraper'));
      //have one scraper
      expect(scrapers.length, equals(1));
      //scraper has 8 requests
      expect(scrapers[0].requests.length, equals(9));
      //info is correct
      expect(
        scrapers[0].info,
        equals(<String, dynamic>{
          'source': 'testSource',
          'version': 1,
          'programType': 'wql',
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
              'type': 'test2',
              'file': 'test.wql',
            },
            {
              'type': 'test3',
              'file': 'test2.wql',
            },
            {
              'type': 'test3_alt',
              'file': 'test2_alt.wql',
            },
            {
              'type': 'test3_new',
              'file': 'test2_new.wql',
            }
          ],
        }),
      );
    });
    test('Invalid global load', () {
      ScraperSource? result = ScraperSource.scrapper('invalid');
      expect(result, isNull);
    });
    test('Load global scraper source and run WQL entry', () async {
      WebContentParser.verbose = const LogLevel.debug();

      loadExternalScraperSourcesGlobal(Directory('test/samples/scraper'));

      ScraperSource? result = ScraperSource.scrapper('testSource');

      expect(result, isNotNull);

      //override setstatement function to work with loading a file
      SetStatement.functions['getrequest'] = (args) async {
        return await File(args[0].first).readAsString();
      };

      Result<List> response =
          await result!.makeRequest<List>('test2', [MapEntry('path', 'test/samples/scraper/test.html')]);

      expect(response.pass, isTrue);

      expect(response.data, equals(['Some testing text', 'Some testing text']));
    });
    test('Load global scraper source and run WQL entry 2', () async {
      WebContentParser.verbose = const LogLevel.debug();

      loadExternalScraperSourcesGlobal(Directory('test/samples/scraper'));

      ScraperSource? result = ScraperSource.scrapper('testSource');

      expect(result, isNotNull);

      //override setstatement function to work with loading a file
      SetStatement.functions['getrequest'] = (args) async {
        return await File(args[0].first).readAsString();
      };

      Result<List> response =
          await result!.makeRequest<List>('test3', [MapEntry('path', 'test/samples/scraper/test.html')]);

      Result<List> responseAlt =
          await result.makeRequest<List>('test3_alt', [MapEntry('path', 'test/samples/scraper/test.html')]);

      Result<List> responseNew =
          await result.makeRequest<List>('test3_new', [MapEntry('path', 'test/samples/scraper/test.html')]);

      expect(response.pass, isTrue);
      expect(responseAlt.pass, isTrue);
      expect(responseNew.pass, isTrue);

      expect(response.data, equals(['Description 1', 'Description 2', 'Description 3']));
      expect(responseAlt.data, equals(['Description 1', 'Description 2', 'Description 3']));
      expect(responseNew.data, equals(['Description 1', 'Description 2', 'Description 3']));
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
      addSource('test', TestSource('example.test', 'test'));

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
      }, skip: true);

      test('Get post url', () async {
        addSource('heroku', TestSource('test.example', 'test'));
        Result<Post> p = await fetchPostUrl('https://test.example.test/manga/get/1');
        expect(p.pass, isTrue);
      }, skip: true);

      test('Post to json', () async {
        Result<Post> p = await fetchPost(ID(id: '1', source: 'test'));
        expect(p.data?.toJson(), isMap);
      }, skip: true);

      test('Fail post', () async {
        Result<Post> p = await fetchPost(ID(id: '0', source: 'test'));
        expect(p.fail, isTrue);
      }, skip: true);

      test('Get chapter list', () async {
        Result<List<Chapter>> chapters = await fetchChapters(ID(id: '1', source: 'test'));
        expect(chapters.pass, isTrue);
      }, skip: true);
      test('Get chapter list not empty', () async {
        Result<List<Chapter>> chapters = await fetchChapters(ID(id: '1', source: 'test'));
        expect(chapters.data, isNotEmpty);
      }, skip: true);
    });
  });

  //Tests the features of the source builder language
  group('Source Builder', () {
    setUp(() {
      loadWQLFunctions();
    });
    test('Do not rethrow error', () async {
      final Result values = await runWQL('SET return TO value[0];', throwErrors: false);

      expect(values.pass, isFalse);
    });
    test('Custom list access not supported', () async {
      final code = '''
        SET value TO l'';
        SET return TO value[0:1];
      ''';

      final Result values = await runWQL(code, throwErrors: false);

      expect(values.pass, isTrue);
    });
    test('Statement unimplemented', () async {
      final statement = Statement();
      expect(() => statement.execute(Interpreter(), null), throwsA(isA<UnimplementedError>()));
    });
    test('Get basic information', () async {
      Document document = parse(File('./test/samples/scraper/test2.html').readAsStringSync());

      final code = '''
        SELECT
          *.name() AS random,
          *.innerHTML()
        FROM document
        INTO doc
        WHERE SELECTOR IS 'body > p';

        SET firstname TO s'hello';

        SELECT
          doc[],
          firstname
        FROM *
        INTO doctwo;

        SELECT
          doc[].random,
          doc[].innerHTML,
          firstname
        FROM *
        INTO docthree;
      ''';

      final Result values = await runWQL(code, parameters: {'document': document}, throwErrors: true);

      expect(values.pass, isTrue);

      expect(values.data!['doctwo'], equals(values.data!['docthree']));
      expect(
          values.data!['doctwo'],
          equals([
            {'random': 'p', 'innerHTML': ' Some testing text 1 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 2 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 3 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 4 ', 'firstname': 'hello'},
          ]));
    });
    test('Get basic information 2', () async {
      Document document = parse(File('./test/samples/scraper/test2.html').readAsStringSync());

      final code = '''
        SELECT *.name() AS random, *.innerHTML() FROM document INTO doc WHERE SELECTOR IS 'body > p';
        SET firstname TO s'hello';
        SELECT doc[].random, doc[].innerHTML, firstname FROM * INTO docthree;
      ''';

      final Result values = await runWQL(code, parameters: {'document': document}, throwErrors: true);

      expect(values.pass, isTrue);

      expect(
          values.data!['docthree'],
          equals([
            {'random': 'p', 'innerHTML': ' Some testing text 1 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 2 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 3 ', 'firstname': 'hello'},
            {'random': 'p', 'innerHTML': ' Some testing text 4 ', 'firstname': 'hello'},
          ]));
    });
    test('Multiple arguments', () async {
      final String code = '''
        SET test TO s'hello';
        SET page TO concat(s'?page=', ^.test);
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);
      expect(values.data!['page'], equals('?page=hello'));
    });
    test('Multiple arguments raw', () async {
      final String code = '''
        SET page TO concat(s'?page=', s'hello');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);
      expect(values.data!['page'], equals('?page=hello'));
    });
    test('Multiple arguments nested', () async {
      final String code = '''
        SET page TO n'0';
        SET url TO joinUrl(s'https://www.example.com/', concat(s'?page=', increment(^.page)));
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);
      expect(values.data!['url'], equals('https://www.example.com/?page=1'));
    });
    test('Multiple arguments nested with select', () async {
      final String code = '''
        SET page TO n'0';
        SELECT concat(s'https://www.example.com/', concat(s'?page=', increment(*))) as url FROM page into url;
        SET url TO url[0].url;
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);
      expect(values.data!['url'], equals('https://www.example.com/?page=1'));
    });
    test('Increment', () async {
      final code = '''
        SET number TO n'0';
        SET number TO number.increment();
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['number'], equals(1));
    });
    test('Decrement', () async {
      final code = '''
        SET number TO n'0';
        SET number TO number.decrement();
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);

      expect(values.data!['number'], equals(-1));
    });
    test('Concat', () async {
      final code = '''
        SET output TO concat(s'hello', s' world');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('hello world'));
    });
    test('Concat list', () async {
      final code = '''
        SET first TO s'he';
        SET second TO s'llo';
        SELECT concat(^.first, ^.second) as out FROM * INTO output;
        SELECT out.concat(s' world') as final FROM output[] INTO output;
        SET output TO output[0].final;
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('hello world'));
    });
    test('Trim', () async {
      final code = '''
        SET output TO trim(s'   hello world   ');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('hello world'));
    });
    test('Itself', () async {
      final code = '''
        SET output TO s'hello world';
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('hello world'));
    });
    test('Create Range', () async {
      final code = '''
        SET output TO createRange(n'0', n'10');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });
    test('Run print', () async {
      SetStatement.functions['print'] = (args) {
        // ignore: avoid_print
        print(args);
      };
      final code = '''
        RUN print WITH n'0', n'10';
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);
    });
    test('Reverse', () async {
      final code = '''
        SET range TO createRange(n'0', n'10');
        SET output TO range.reverse();
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals([9, 8, 7, 6, 5, 4, 3, 2, 1, 0]));
    });
    test('Count', () async {
      final code = '''
        SET range TO createRange(n'0', n'10');
        SET output TO range.count();
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals(10));
    });
    test('Merge Key Value', () async {
      final code = '''
        SET range TO createRange(n'0', n'10');
        SET output TO mergeKeyValue(^.range[], ^.range[]);
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(
          values.data!['output'],
          equals(<int, dynamic>{
            0: 0,
            1: 1,
            2: 2,
            3: 3,
            4: 4,
            5: 5,
            6: 6,
            7: 7,
            8: 8,
            9: 9,
          }));
    });
    test('Merge key value object', () async {
      final code = '''
        SET output TO mergeKeyValue(merge(s'first', s'second')[], merge(n'1', s'third')[]);
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(
          values.data!['output'],
          equals(<String, dynamic>{
            'first': 1,
            'second': 'third',
          }));
    });
    test('Merge and Select', () async {
      final code = '''
        SET range TO createRange(n'0', n'3');
        SELECT mergeKeyValue(*, *) as output, merge(*, *) as output1 FROM range[] INTO output;
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(
          values.data!['output'],
          equals([
            {
              'output': {0: 0},
              'output1': [0, 0]
            },
            {
              'output': {1: 1},
              'output1': [1, 1]
            },
            {
              'output': {2: 2},
              'output1': [2, 2]
            }
          ]));
    });
    test('Merge', () async {
      final code = '''
        SET rangeOne TO createRange(n'0', n'6');
        SET rangeTwo TO createRange(n'6', n'10');
        SET output TO merge(^.rangeOne[], ^.rangeTwo[]);
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });
    test('toString', () async {
      final code = '''
        SET output TO toString(n'10');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('10'));
    });
    test('decode', () async {
      final code = '''
        SET output TO decode(s'{"hello": "world"}');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals({'hello': 'world'}));
    });
    test('encode', () async {
      WebContentParser.verbose = const LogLevel.debug();

      final code = '''
        SET object TO mergeKeyValue(s'hello', s'world');
        SET output TO object.encode();
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('{"hello":"world"}'));
    });
    test('Is Empty', () async {
      final code = '''
        SET output TO isEmpty(l'');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals(true));
    });
    test('Uppercase', () async {
      final code = '''
        SET output TO uppercase(s'hello world');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('HELLO WORLD'));
    });
    test('Lowercase', () async {
      final code = '''
        SET output TO lowercase(s'HELLO WORLD');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('hello world'));
    });
    test('If Statement', () async {
      final code = '''
        IF b'true' equals b'true':
          SET output TO s'passed';
        ENDIF;
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('passed'));
    });
    test('Get last segment', () async {
      final code = '''
        SET url TO s'https://www.example.com/home/testing/';
        SET output TO url.getLastSegment()[0];
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('testing'));
    });
    test('Json', () async {
      final code = '''
        SET output TO json(s'{"hello": "world"}');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals({'hello': 'world'}));
    });
    test('Json Insert', () async {
      final code = '''
        SET output TO json(s'{"hello": "world"}', s'hello', s'Unknown');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals({'hello': 'Unknown'}));
    });
    test('Json Insert Nested', () async {
      final code = '''
        SET output TO json(s'{"hello": {"world": null}}', s'hello.world', s'Unknown');
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals({'hello': {'world': 'Unknown'}}));
    });
    test('Trim Function High Level', () async {
      WebContentParser.verbose = const LogLevel.debug();
      final code = '''
        SET output TO trim(s'   hello world   ');
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('hello world'));
    });
    test('Trim Function Piped Value', () async {
      WebContentParser.verbose = const LogLevel.debug();
      final code = '''
        SET first TO s'   hello world   ';
        SET output TO first.trim();
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);

      expect(values.data!['output'], equals('hello world'));
    });
    test('Select When Contains', () async {
      final code = '''
        SET first TO s'hello';
        SELECT first FROM * INTO matchOutput WHEN first contains s'ell';
        SELECT first FROM * INTO noMatchOutput WHEN first contains s'weird';
        SELECT matchOutput[0], noMatchOutput[0] FROM * INTO output;
        SELECT matchOutput, noMatchOutput FROM * INTO outputList;
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(
          values.data!['output'],
          equals([
            {
              'matchOutput': {'first': 'hello'},
              'noMatchOutput': {
                'first': [],
              }
            }
          ]));
      expect(
          values.data!['outputList'],
          equals([
            {
              'matchOutput': [
                {'first': 'hello'}
              ],
              'noMatchOutput': [
                {
                  'first': [],
                }
              ]
            }
          ]));
    });
    test('Select When StartsWith', () async {
      final code = '''
        SET first TO s'hello';
        SELECT first FROM * INTO matchOutput WHEN first startsWith s'he';
        SELECT first FROM * INTO noMatchOutput WHEN first startsWith s'weird';
        SELECT matchOutput[0], noMatchOutput[0] FROM * INTO output;
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(
        values.data!['output'],
        equals([
          {
            'matchOutput': {'first': 'hello'},
            'noMatchOutput': {
              'first': [],
            }
          }
        ]),
      );
    });
    test('Select When EndsWith', () async {
      final code = '''
        SET first TO s'hello';
        SELECT first FROM * INTO matchOutput WHEN first endsWith s'lo';
        SELECT first FROM * INTO noMatchOutput WHEN first endsWith s'weird';
        SELECT matchOutput[0], noMatchOutput[0] FROM * INTO output;
      ''';

      final Result values = await runWQL(code);

      expect(values.pass, isTrue);

      expect(
        values.data!['output'],
        equals([
          {
            'matchOutput': {'first': 'hello'},
            'noMatchOutput': {
              'first': [],
            }
          }
        ]),
      );
    });
    test('Raw values', () async {
      final code = '''
        SELECT s'hello' as intro, n'25' as number, b'true' as true, l'' as list FROM * INTO return;
      ''';

      final Result values = await runWQL(code, throwErrors: true);

      expect(values.pass, isTrue);

      expect(
          values.data,
          equals({
            'return': [
              {
                'intro': 'hello',
                'number': 25,
                'true': true,
                'list': [],
              }
            ],
          }));
    });
  });
}
