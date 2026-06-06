import 'dart:io';

class HaLoopbackServer {
  final HttpServer _server;
  final int port;

  HaLoopbackServer._(this._server, this.port);

  static Future<HaLoopbackServer> bind() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return HaLoopbackServer._(server, server.port);
  }

  String get clientId => 'http://127.0.0.1:$port/';
  String get redirectUri => 'http://127.0.0.1:$port/callback';

  Future<({String code, String state})> waitForCode() async {
    await for (final request in _server) {
      if (request.uri.path == '/callback') {
        final code = request.uri.queryParameters['code'];
        final state = request.uri.queryParameters['state'];

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(
            '<html><body><h1>Authentication complete</h1>'
            '<p>You can close this tab and return to the app.</p>'
            '</body></html>',
          );
        await request.response.close();
        await _server.close();

        if (code != null && state != null) {
          return (code: code, state: state);
        }
        throw StateError('Callback missing code or state parameters');
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    }
    throw StateError('Server closed before receiving callback');
  }
}
