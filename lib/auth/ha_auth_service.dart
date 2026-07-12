import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ha_flutter/auth/ha_loopback_server.dart';
import 'package:ha_flutter/auth/ha_oauth_params.dart';
import 'package:ha_flutter/auth/ha_token.dart';
import 'package:ha_flutter/auth/ha_token_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

enum AuthState { unauthenticated, authenticating, authenticated, error }

class HaAuthService extends ChangeNotifier {
  final TokenStorage _storage;

  AuthState _state = AuthState.unauthenticated;
  HaToken? _token;
  int? _lastErrorStatus;
  String? _progressMessage;

  // Per-session OAuth state
  String? _sessionState;
  String? _sessionClientId;
  String? _sessionRedirectUri;

  // Refresh mutex: non-null while a refresh is in flight
  Completer<void>? _refreshCompleter;

  /// Uses a default storage backend; on macOS this is intentionally
  /// an in-memory fallback to bypass keychain entitlement/signing issues.
  HaAuthService({TokenStorage? storage})
      : _storage = storage ?? createDefaultTokenStorage();

  AuthState get state => _state;
  HaToken? get token => _token;
  int? get lastErrorStatus => _lastErrorStatus;
  String? get authProgressMessage => _progressMessage;

  void _setProgress(String message) {
    _progressMessage = message;
    notifyListeners();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final stored = await _storage.read();
    if (stored != null) {
      _token = stored;
      _setState(AuthState.authenticated);
    } else {
      _setState(AuthState.unauthenticated);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Starts the OAuth flow.
  ///
  /// On mobile: returns the authorization URL for the caller to open in a
  /// WebView. The WebView must call [handleCallback] when it intercepts the
  /// redirect.
  ///
  /// On desktop: opens the system browser, awaits the loopback callback, and
  /// completes the full exchange before returning null.
  Future<Uri?> startLogin() async {
    final state = generateState();
    _sessionState = state;

    if (Platform.isAndroid || Platform.isIOS) {
      _sessionClientId = mobileClientId;
      _sessionRedirectUri = mobileRedirectUri;
      _setState(AuthState.authenticating);
      return buildAuthorizationUrl(
        instanceUrl: haInstanceUrl,
        clientId: mobileClientId,
        redirectUri: mobileRedirectUri,
        state: state,
      );
    } else {
      // Desktop: loopback flow
      _setState(AuthState.authenticating);
      _setProgress('Starting local OAuth loopback server...');
      final server = await HaLoopbackServer.bind();
      _sessionClientId = server.clientId;
      _sessionRedirectUri = server.redirectUri;

      final authUrl = buildAuthorizationUrl(
        instanceUrl: haInstanceUrl,
        clientId: server.clientId,
        redirectUri: server.redirectUri,
        state: state,
      );

      _setProgress('Waiting for Home Assistant redirect at ${server.redirectUri}...');
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      _setProgress('Browser opened; waiting for callback...');

      final result = await server.waitForCode();
      _setProgress('Callback received; exchanging authorization code...');
      await handleCallback(result.code, result.state);
      return null;
    }
  }

  // ── Callback & token exchange ─────────────────────────────────────────────

  Future<void> handleCallback(String code, String state) async {
    if (state != _sessionState) {
      _sessionState = null;
      _sessionClientId = null;
      _sessionRedirectUri = null;
      _setProgress('Authentication failed: invalid OAuth state.');
      return;
    }

    final clientId = _sessionClientId!;
    final redirectUri = _sessionRedirectUri!;
    _sessionState = null;
    _sessionClientId = null;
    _sessionRedirectUri = null;

    _setProgress('Exchanging authorization code...');
    try {
      final response = await http
          .post(
            Uri.parse('$haInstanceUrl/auth/token'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'authorization_code',
              'code': code,
              'client_id': clientId,
              'redirect_uri': redirectUri,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Persist the issuing client_id: HA binds the refresh token to it and
        // rejects a refresh presenting a different one (desktop uses a loopback
        // client_id, mobile the app id).
        final token =
            HaToken.fromTokenResponse(json, haInstanceUrl, clientId: clientId);
        await _storage.write(token);
        _token = token;
        _progressMessage = null;
        _setState(AuthState.authenticated);
        return;
      }

      _lastErrorStatus = response.statusCode;
      _setProgress('Authentication failed (${response.statusCode}).');
      return;
    } catch (e) {
      _setProgress('Authentication failed: ${e.toString()}');
      return;
    }
  }

  // ── Token access & refresh ────────────────────────────────────────────────

  /// Returns the current bearer token, refreshing first if near expiry.
  Future<String> getAccessToken() async {
    final token = _token;
    if (token == null) throw StateError('Not authenticated');

    if (token.isNearExpiry) {
      await _doRefresh();
    }

    return _token!.accessToken;
  }

  Future<void> _doRefresh() async {
    // If a refresh is already in flight, piggyback on it.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();
    try {
      final token = _token!;
      final response = await http.post(
        Uri.parse('${token.instanceUrl}/auth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': token.refreshToken,
          // Replay the client_id the token was issued to. HA rejects a refresh
          // whose client_id differs from the issuing one (the previous code
          // always sent mobileClientId, which broke desktop/loopback logins).
          // When unknown (tokens stored before clientId was persisted), omit it
          // entirely — HA only enforces the match when client_id is present.
          if (token.clientId != null) 'client_id': token.clientId!,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final expiresIn = (json['expires_in'] as num).toInt();
        final newToken = token.copyWith(
          accessToken: json['access_token'] as String,
          refreshToken: json['refresh_token'] as String? ?? token.refreshToken,
          tokenExpiry:
              DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn,
        );
        await _storage.write(newToken);
        _token = newToken;
        _refreshCompleter!.complete();
      } else {
        await _storage.delete();
        _token = null;
        final error = Exception('Token refresh failed: ${response.statusCode}');
        _refreshCompleter!.completeError(error);
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _refreshCompleter?.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final token = _token;
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${token.instanceUrl}/auth/revoke'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'token': token.refreshToken, 'action': 'revoke'},
        );
      } catch (_) {
        // Revocation failure must not block local credential removal.
      }
    }
    await _storage.delete();
    _token = null;
    _setState(AuthState.unauthenticated);
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
