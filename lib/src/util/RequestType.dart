///All the different request types
enum RequestType {
  POST,
  POSTURL,
  IMAGES,
  IMAGESURL,
  CATALOG,
  CATALOGMULTI,
  CHAPTERS
}

///Converts string to request type for parsed sources
const requestMap = <String, RequestType>{
  'post': RequestType.POST,
  'post-url': RequestType.POSTURL,
  'imgs': RequestType.IMAGES,
  'imgs-url': RequestType.IMAGESURL,
  'catalog': RequestType.CATALOG,
  'catalog-multi': RequestType.CATALOGMULTI,
  'chapter': RequestType.CHAPTERS
};