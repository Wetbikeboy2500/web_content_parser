///All the different request types
enum RequestType {
  post,
  postUrl,
  images,
  imagesUrl,
  catalog,
  catalogMulti,
  chapters
}

///Don't have to write the same comparison all the time
extension RequestMethods on RequestType {
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
}

///Converts string to request type for parsed sources
const requestMap = <String, RequestType>{
  'post': RequestType.post,
  'postUrl': RequestType.postUrl,
  'images': RequestType.images,
  'imagesUrl': RequestType.imagesUrl,
  'catalog': RequestType.catalog,
  'catalogMulti': RequestType.catalogMulti,
  'chapters': RequestType.chapters
};