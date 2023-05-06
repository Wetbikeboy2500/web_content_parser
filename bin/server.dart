import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4040);
  stdout.writeln('Listening on localhost:${server.port}');

  await for (HttpRequest request in server) {
    if (request.uri.path == '/ws') {
      // Upgrade an HttpRequest to a WebSocket connection
      final socket = await WebSocketTransformer.upgrade(request);
      stdout.writeln('Client connected!');

      // Listen for incoming messages from the client
      socket.listen((message) {
        stdout.writeln(message);
      }, onDone: () {
        stdout.writeln('Client disconnected');
      });

      final code = '''
      SET document TO getDocument();
      SET return TO document.querySelector(s'title').text();
      ''';

      final requestJson = <String, dynamic>{
        'event': 'execute',
        'code': code,
        'params': <String, dynamic>{},
      };

      socket.add(jsonEncode(requestJson));
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}
