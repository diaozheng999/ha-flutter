import 'package:ha_flutter/auth/ha_auth_service.dart';

/// Abstraction the HA layer depends on for connection details, decoupling it
/// from the concrete (provider-based) [HaAuthService]. This keeps the HA layer
/// free of any specific auth/state-management dependency and mockable in tests.
abstract class HaConnection {
  /// Base instance URL, e.g. `https://home.example.com` (no trailing slash).
  String get instanceUrl;

  /// Returns a valid bearer token, refreshing first if near expiry.
  Future<String> getAccessToken();

  /// Invoked when the server rejects our credentials (auth_invalid). The host
  /// app should clear tokens and route to the login screen.
  void onAuthInvalid();
}

/// [HaConnection] backed by the app's [HaAuthService].
class AuthServiceConnection implements HaConnection {
  final HaAuthService _auth;

  AuthServiceConnection(this._auth);

  @override
  String get instanceUrl {
    final url = _auth.token?.instanceUrl;
    if (url == null) throw StateError('Not authenticated');
    return url.replaceFirst(RegExp(r'/+$'), '');
  }

  @override
  Future<String> getAccessToken() => _auth.getAccessToken();

  @override
  void onAuthInvalid() => _auth.logout();

  /// Builds the WebSocket URL from the instance URL (http→ws, https→wss).
  Uri get websocketUri {
    final base = Uri.parse(instanceUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(scheme: scheme, path: '/api/websocket');
  }
}
