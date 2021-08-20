import 'package:web_content_parser/web_content_parser.dart';

//Tests exceptions for missing sources and subdomain stuff
class BlankSource extends SourceTemplate {
  BlankSource()
      : super(
          version: 0,
          requestTypes: {
            RequestType.CATALOG,
            RequestType.CATALOGMULTI,
            RequestType.CHAPTERS,
            RequestType.IMAGES,
            RequestType.IMAGESURL,
            RequestType.POST,
            RequestType.POSTURL,
          },
          source: 'blank',
          baseurl: 'test.test');
}
