import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ha_flutter/auth/ha_token.dart';

/// Token storage abstraction used by the auth service.
abstract class TokenStorage {
  Future<void> write(HaToken token);
  Future<HaToken?> read();
  Future<void> delete();
}

/// Default token storage for this app.
///
/// On macOS, use an in-memory fallback to avoid keychain entitlement and
/// signing issues during temporary development/testing.
TokenStorage createDefaultTokenStorage() {
  if (Platform.isMacOS) {
    return InMemoryTokenStorage();
  }
  return HaTokenStorage();
}

class HaTokenStorage implements TokenStorage {
  static const _keyAccessToken = 'ha_access_token';
  static const _keyRefreshToken = 'ha_refresh_token';
  static const _keyTokenExpiry = 'ha_token_expiry';
  static const _keyInstanceUrl = 'ha_instance_url';

  final FlutterSecureStorage _storage;

  HaTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> write(HaToken token) async {
    await _storage.write(key: _keyAccessToken, value: token.accessToken);
    await _storage.write(key: _keyRefreshToken, value: token.refreshToken);
    await _storage.write(
      key: _keyTokenExpiry,
      value: token.tokenExpiry.toString(),
    );
    await _storage.write(key: _keyInstanceUrl, value: token.instanceUrl);
  }

  @override
  Future<HaToken?> read() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    if (accessToken == null) return null;
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    final tokenExpiryStr = await _storage.read(key: _keyTokenExpiry);
    final instanceUrl = await _storage.read(key: _keyInstanceUrl);
    if (refreshToken == null || tokenExpiryStr == null || instanceUrl == null) {
      return null;
    }
    return HaToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiry: int.parse(tokenExpiryStr),
      instanceUrl: instanceUrl,
    );
  }

  @override
  Future<void> delete() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTokenExpiry);
    await _storage.delete(key: _keyInstanceUrl);
  }
}

/// WARNING: This in-memory token storage is temporary for macOS only.
///
/// It does not persist tokens across app restarts, and users will need to
/// re-authenticate when the app closes and reopens.
class InMemoryTokenStorage implements TokenStorage {
  HaToken? _token;

  @override
  Future<void> write(HaToken token) async {
    _token = token;
  }

  @override
  Future<HaToken?> read() async => _token;

  @override
  Future<void> delete() async {
    _token = null;
  }
}
