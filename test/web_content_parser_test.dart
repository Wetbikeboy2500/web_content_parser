//Make sure to keep this as the first import
// ignore_for_file: unused_import

import 'package:web_content_parser/web_content_parser.dart';

import 'dart:io';
import 'package:test/test.dart';

import 'blank.dart';
import 'heroku.dart';

import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  group('Utility', () {
    test('Passing FetchReturn', () {
      FetchReturn<String> f = FetchReturn<String>.pass('Test');
      expect(f.pass, isTrue);
      expect(f.data, equals('Test'));
    });
    test('Failing FetchReturn', () {
      FetchReturn<String> f = FetchReturn<String>.fail();
      expect(f.pass, isFalse);
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
    });

    test('RequestType string conversions', () {
      expect(requestMap['post']!.post, isTrue);
      expect(requestMap['postUrl']!.postUrl, isTrue);
      expect(requestMap['images']!.images, isTrue);
      expect(requestMap['imagesUrl']!.imagesUrl, isTrue);
      expect(requestMap['catalog']!.catalog, isTrue);
      expect(requestMap['catalogMulti']!.catalogMulti, isTrue);
      expect(requestMap['chapters']!.chapters, isTrue);
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
    //
  });

  group('Parser', () {
    group('Undefined source', () {
      test('Source supports', () {
        bool supports = sourceSupports('', RequestType.catalog);
        expect(supports, isFalse);
      });

      test('Get source info', () {
        expect(() => getSourceInfo(''), throwsException);
      });

      test('Get post', () async {
        FetchReturn<Post> post = await fetchPost(ID(source: '', id: ''));
        expect(post.fail, isTrue);
      });
      test('Get post url', () async {
        FetchReturn<Post> post = await fetchPostUrl('');
        expect(post.fail, isTrue);
      });
      test('Get chapters', () async {
        FetchReturn<List<Chapter>> chapter = await fetchChapters(ID(source: '', id: ''));
        expect(chapter.fail, isTrue);
      });
      test('Get chapter images', () async {
        FetchReturn<Map<int, String>> chapter =
            await fetchChapterImages(ChapterID(url: '', index: 0, id: ID(source: '', id: '')));
        expect(chapter.fail, isTrue);
      });
      test('Get chapter images url', () async {
        FetchReturn<Map<int, String>> chapter = await fetchChapterImagesUrl('');
        expect(chapter.fail, isTrue);
      });
    });

    group('Blank source with request types enabled', () {
      addSource('blank', BlankSource());

      ID id = ID(id: '', source: 'blank');

      test('Fail get catalog', () async {
        FetchReturn<List<CatalogEntry>> catalog = await fetchCatalog('blank');
        expect(catalog.fail, isTrue);
      });
      test('Fail get post', () async {
        FetchReturn<Post> post = await fetchPost(id);
        expect(post.fail, isTrue);
      });
      test('Fail get post url with valid url', () async {
        FetchReturn<Post> post = await fetchPostUrl('test.test');
        expect(post.fail, isTrue);
      });
      test('Fail get post url with invalid url', () async {
        FetchReturn<Post> post = await fetchPostUrl('test.com');
        expect(post.fail, isTrue);
      });
      test('Fail get chapter', () async {
        FetchReturn<List<Chapter>> chapter = await fetchChapters(id);
        expect(chapter.fail, isTrue);
      });
      test('Fail get chapter images', () async {
        FetchReturn<Map<int, String>> images = await fetchChapterImages(ChapterID(url: '', index: 0, id: id));
        expect(images.fail, isTrue);
      });
      test('Fail get chapter images url', () async {
        FetchReturn<Map<int, String>> images = await fetchChapterImagesUrl('test.test');
        expect(images.fail, isTrue);
      });
      test('Get correct info', () {
        Map<String, dynamic> info = getSourceInfo('blank');
        expect(
          info,
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
        FetchReturn<Post> p = await fetchPost(ID(id: '1', source: 'test'));
        expect(p.pass, isTrue);
      });

      test('Get post url', () async {
        FetchReturn<Post> p = await fetchPostUrl('${env["SOURCE"]}/manga/get/1');
        expect(p.pass, isTrue);
      });

      test('Post to json', () async {
        FetchReturn<Post> p = await fetchPost(ID(id: '1', source: 'test'));
        expect(p.data?.toJson(), isMap);
      });

      test('Fail post', () async {
        FetchReturn<Post> p = await fetchPost(ID(id: '0', source: 'test'));
        expect(p.fail, isTrue);
      });

      test('Get chapter list', () async {
        FetchReturn<List<Chapter>> chapters = await fetchChapters(ID(id: '1', source: 'test'));
        expect(chapters.pass, isTrue);
      });
      test('Get chapter list not empty', () async {
        FetchReturn<List<Chapter>> chapters = await fetchChapters(ID(id: '1', source: 'test'));
        expect(chapters.data, isNotEmpty);
      });
    });
  });
}
