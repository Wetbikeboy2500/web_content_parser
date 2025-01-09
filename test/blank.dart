import 'package:web_query_framework/web_query_framework_full.dart';

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
