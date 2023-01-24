import 'package:web_content_parser/web_content_parser_full.dart';

//Tests exceptions for missing sources and subdomain stuff
class BlankSource extends SourceTemplate {
  BlankSource()
      : super(
          version: 0,
          requestTypes: {
            RequestType.catalog,
            RequestType.catalogMulti,
            RequestType.chapters,
            RequestType.images,
            RequestType.imagesUrl,
            RequestType.post,
            RequestType.postUrl,
          },
          source: 'blank',
          baseurl: 'test.test',
        );
}
