import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 4040);
  stdout.writeln('Listening on localhost:${server.port}');

  bool filterErrors = false;

  final sockets = <WebSocket>[];

  stdin.echoMode = false;
  stdin.lineMode = false;

  stdin.transform(utf8.decoder).listen((String char) {
    if (char == 'q') {
      server.close();
      exit(0);
    } else if (char == 'r') {
      final code = File('server.wql').readAsStringSync();

      final requestJson = <String, dynamic>{
        'event': 'execute',
        'code': code,
        'params': <String, dynamic>{},
      };

      final request = jsonEncode(requestJson);

      for (final socket in sockets) {
        if (socket.closeCode == null) {
          socket.add(request);
        }
      }
    } else if (char == 's') {
      stdout.writeln('Socket status:');

      if (sockets.isEmpty) {
        stdout.writeln('No sockets connected');
      }

      for (final socket in sockets) {
        stdout.writeln(socket.closeCode ?? 'Connected');
      }
    } else if (char == 'f') {
      filterErrors = !filterErrors;
      stdout.writeln('Filter errors: $filterErrors');
    }
  });

  server.listen((HttpRequest request) async {
    if (request.uri.path == '/ws') {
      // Upgrade an HttpRequest to a WebSocket connection
      final socket = await WebSocketTransformer.upgrade(request);
      stdout.writeln('Client connected!');

      sockets.add(socket);

      // Listen for incoming messages from the client
      socket.listen((message) {
        final response = jsonDecode(message);
        if (response['event'] == 'result' && response['data']['pass'] == false) {
          if (filterErrors) {
            return;
          }
        }
        stdout.writeln(message);
      }, onDone: () {
        sockets.remove(socket);
        stdout.writeln('Client disconnected');
      });
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  });

  stdout.writeln('Press q to exit. Press r to run code. Press s to see socket status. Press f to filter errors.');
}
