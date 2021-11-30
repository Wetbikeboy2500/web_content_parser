///All the different request types
enum RequestType { unknown, post, postUrl, images, imagesUrl, catalog, catalogMulti, chapters }

///Don't have to write the same comparison all the time
extension RequestMethods on RequestType {
  ///[this] equals [RequestType.unknown]
  bool get unknown => this == RequestType.unknown;

  ///[this] equals [RequestType.post]
  bool get post => this == RequestType.post;

  ///[this] equals [RequestType.postUrl]
  bool get postUrl => this == RequestType.postUrl;

  ///[this] equals [RequestType.images]
  bool get images => this == RequestType.images;

  ///[this] equals [RequestType.imagesUrl]
  bool get imagesUrl => this == RequestType.imagesUrl;

  ///[this] equals [RequestType.catalog]
  bool get catalog => this == RequestType.catalog;

  ///[this] equals [RequestType.catalogMulti]
  bool get catalogMulti => this == RequestType.catalogMulti;

  ///[this] equals [RequestType.chapters]
  bool get chapters => this == RequestType.chapters;

  ///Converts [this] to a valid string for request map
  String get string => _requestMapInverse[this]!;
}

///Maps [request] to to a [RequestType]
///If the type doesn't exist, it will return [RequestType.unknown]
RequestType requestMap(String request) {
  return _requestMap[request] ?? RequestType.unknown;
}

///Converts string to request type for parsed sources
const _requestMap = <String, RequestType>{
  'unknown': RequestType.unknown,
  'post': RequestType.post,
  'postUrl': RequestType.postUrl,
  'images': RequestType.images,
  'imagesUrl': RequestType.imagesUrl,
  'catalog': RequestType.catalog,
  'catalogMulti': RequestType.catalogMulti,
  'chapters': RequestType.chapters
};

///Inverse map of request type to string for quick lookup
const _requestMapInverse = <RequestType, String>{
  RequestType.unknown: 'unknown',
  RequestType.post: 'post',
  RequestType.postUrl: 'postUrl',
  RequestType.images: 'images',
  RequestType.imagesUrl: 'imagesUrl',
  RequestType.catalog: 'catalog',
  RequestType.catalogMulti: 'catalogMulti',
  RequestType.chapters: 'chapters'
};
