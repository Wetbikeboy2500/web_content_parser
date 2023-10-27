import 'dart:convert';
import 'dart:io';

import 'shared.dart';

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

  late final isClientServer = args.contains('--client-server');

  late final ClientInterface client;

  if (isClientServer) {
    client = ClientInterface(ClientServer(server));
  } else {
    client = ClientInterface(RemoteServer(server));
  }

  client.setup();

  bool filterErrors = false;

  stdin.echoMode = false;
  stdin.lineMode = false;

  WebSocket? externalServer;

  stdin.transform(utf8.decoder).listen((String char) {
    if (char == 'q') {
      server.close();
      exit(0);
    } else if (char == 'r') {
      final code = File('server.wql').readAsStringSync();

      client.runWQL(code);
    } else if (char == 's') {
      stdout.writeln('Socket status:');

      final sockets = client.getSockets();

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
    } else if (char == 'c') {
      stdout.writeln('Clearing queue');
      client.clearQueue();
    }
  });

  /* server.listen((HttpRequest request) async {
    if (request.uri.path == '/ws') {
      
    } else if (request.uri.path == '/ready') {
      request.response.statusCode = HttpStatus.ok;
      request.response.write('Ready!');
      request.response.close();
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }); */

  stdout.writeln(
      'Press q to exit. Press r to run code. Press s to see socket status. Press f to filter errors. Press c to clear queue. Press p to connect to external client.');
}

abstract class Server {
  void start();
  void close();
  Future run(Request request);
  Future clearQueue();
  List<WebSocket> getSockets();
}

class ClientServer implements Server {
  late final HttpServer server;

  bool proxyToRemoteServer = false;

  WebSocket? remoteServer;

  final userscriptServers = <WebSocket>[];

  final int rateLimit = 3;

  ClientServer(this.server);

  void add(dynamic data) {
    if (remoteServer == null) {
      stdout.writeln('Client server not defined');
      //TODO: buffer this data until the client server is reconnected
      return;
    }

    remoteServer!.add(data);
  }

  //Start listening for sockets to maintain a connection with
  @override
  void start() {
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/ws') {
        // Upgrade an HttpRequest to a WebSocket connection
        final socket = await WebSocketTransformer.upgrade(request);

        userscriptServers.add(socket);

        socket.listen((message) {
          //decode request and pass it to the client
          stdout.writeln('Received message: $message');
        }, onDone: () {
          userscriptServers.remove(socket);
          stdout.writeln('Client disconnected');
        });
      } else if (request.uri.path == '/server') {
        final socket = await WebSocketTransformer.upgrade(request);
        stdout.writeln('Client connected to external server!');

        remoteServer = socket;
      } else if (request.uri.path == '/ready') {
        request.response.statusCode = HttpStatus.ok;
        request.response.write('Ready!');
        request.response.close();
      } else {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.close();
      }

      //parse for various other events that can occur

      /* for (final socket in userscriptServers) {
        if (socket.closeCode == null) {
          socket.add(request);
        }
      } */
    });
  }

  @override
  Future<void> run(Request request) async {
    //Takes WQL given by the remote server and dispatches it to the userscript
    //It then resolve the result and sends it back to the remote server
    try {
      for (final socket in userscriptServers) {
        if (socket.closeCode == null) {
          socket.add(jsonEncode(request.toJson()));
        }
      }
    } catch (e, stack) {
      stdout.writeln('Error running request');
      stdout.writeln(e);
      stdout.writeln(stack);
    }
  }

  @override
  List<WebSocket> getSockets() {
    return userscriptServers;
  }

  @override
  void close() {
    server.close();
  }

  @override
  Future clearQueue() async {
    try {
      for (final socket in userscriptServers) {
        if (socket.closeCode == null) {
          socket.add(jsonEncode(ClearQueueRequest()));
        }
      }
    } catch (e, stack) {
      stdout.writeln('Error running request');
      stdout.writeln(e);
      stdout.writeln(stack);
    }
  }
}

///Stores all needed information for driving the operations that a clinet is doing.
///
///The client is a pairing of systems, and the remote is what is sending the requests to the client.
class RemoteServer implements Server {
  late final HttpServer server;

  ClientServer? clientServer;

  RemoteServer(this.server);

  @override
  void start() {}

  @override
  Future run(Request request) {
    throw UnimplementedError();
  }

  @override
  List<WebSocket> getSockets() {
    throw UnimplementedError();
  }

  @override
  void close() {
    server.close();
  }

  @override
  Future clearQueue() {
    // TODO: implement clearQueue
    throw UnimplementedError();
  }
}

//TODO: add a way to clear all the queue items. Maybe this could be done using timestamps to make sure old items are removed
class ClientInterface {
  Server server;

  ClientInterface(this.server);

  void setup() {
    server.start();
  }

  Future runWQL(String wql) {
    final Request request = Request('1', wql, <String, dynamic>{});

    return server.run(request);
  }

  Future clearQueue() {
    return server.clearQueue();
  }

  List<WebSocket> getSockets() {
    return server.getSockets();
  }
}
