import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('Usage: server.dart <port>');
    exit(1);
  }

  late final int port;

  try {
    port = int.parse(args[0]);
  } catch (e) {
    stdout.writeln('Invalid port');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Listening on localhost:${server.port}');

  bool filterErrors = false;

  final sockets = <WebSocket>[];

  stdin.echoMode = false;
  stdin.lineMode = false;

  WebSocket? externalServer;

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

      if (externalServer != null) {
        externalServer!.add(request);
      } else {
        for (final socket in sockets) {
          if (socket.closeCode == null) {
            socket.add(request);
          }
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
    } else if (char == 'p') {
      //setup a client for a web socket connection
      if (externalServer == null) {
        WebSocket.connect('ws://localhost:4040/server').then((socket) {
          externalServer = socket;
        });
      }
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
        try {
          final response = jsonDecode(message);
          if (response['event'] == 'result' && response['data']['pass'] == false) {
            if (filterErrors) {
              return;
            }
          }
        } catch (e) {
          // ignore
        }
        stdout.writeln(message);
      }, onDone: () {
        sockets.remove(socket);
        stdout.writeln('Client disconnected');
      });
    } else if (request.uri.path == '/server') {
      final socket = await WebSocketTransformer.upgrade(request);
      stdout.writeln('Client connected to external server!');

      socket.listen((event) {
        for (final socket in sockets) {
          if (socket.closeCode == null) {
            socket.add(event);
          }
        }
      }, onDone: () {
        stdout.writeln('Client disconnected from external server');
      });
    } else if (request.uri.path == '/ready') {
      request.response.statusCode = HttpStatus.ok;
      request.response.write('Ready!');
      request.response.close();
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  });

  stdout.writeln(
      'Press q to exit. Press r to run code. Press s to see socket status. Press f to filter errors. Press p to connect to external client.');
}
