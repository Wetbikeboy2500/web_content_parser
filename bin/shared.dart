import 'package:web_content_parser/util.dart';

class Request {
  final String uid;
  final String code;
  final Map<String, dynamic> params;

  Request(this.uid, this.code, this.params);

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      json['uid'] as String,
      json['code'] as String,
      json['params'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event': 'request',
      'uid': uid,
      'code': code,
      'params': params,
    };
  }

  static bool isRequest(Map<String, dynamic> json) {
    return json['event'] == 'request';
  }
}

class Response {
  final String uid;
  final Result<Map<String, dynamic>> data;

  Response(this.uid, this.data);

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      json['uid'] as String,
      ResultExtended.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event': 'response',
      'uid': uid,
      'data': ResultExtended.toJson(data),
    };
  }

  static bool isResponse(Map<String, dynamic> json) {
    return json['event'] == 'response';
  }
}

class StatusResponse {
  final List<String> queue;
  final List<(String, String)> results;

  StatusResponse(this.queue, this.results);

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      (json['queue'] as List<dynamic>).cast<String>(),
      (json['results'] as List<dynamic>).cast<(String, String)>(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event': 'status',
      'queue': queue,
      'results': results,
    };
  }

  static bool isStatusResponse(Map<String, dynamic> json) {
    return json['event'] == 'status';
  }
}

class Confirmation {
  final String uid;
  final bool success;

  Confirmation(this.uid, this.success);

  factory Confirmation.fromJson(Map<String, dynamic> json) {
    return Confirmation(
      json['uid'] as String,
      json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event': 'confirmation',
      'uid': uid,
      'success': success,
    };
  }

  static bool isConfirmation(Map<String, dynamic> json) {
    return json['event'] == 'confirmation';
  }
}