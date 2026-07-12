// HaToken carries the issuing client_id through parsing and updates, so a
// refresh can replay the exact client_id HA bound the refresh token to.

import 'package:flutter_test/flutter_test.dart';
import 'package:ha_flutter/auth/ha_token.dart';

void main() {
  group('HaToken client_id', () {
    test('fromTokenResponse records the issuing client_id', () {
      final token = HaToken.fromTokenResponse(
        const {
          'access_token': 'a',
          'refresh_token': 'r',
          'expires_in': 1800,
        },
        'http://homeassistant.local:8123',
        clientId: 'http://127.0.0.1:54321/',
      );
      expect(token.clientId, 'http://127.0.0.1:54321/');
      expect(token.accessToken, 'a');
      expect(token.refreshToken, 'r');
    });

    test('client_id is null when not supplied (legacy tokens)', () {
      final token = HaToken.fromTokenResponse(
        const {
          'access_token': 'a',
          'refresh_token': 'r',
          'expires_in': 1800,
        },
        'http://homeassistant.local:8123',
      );
      expect(token.clientId, isNull);
    });

    test('copyWith preserves client_id across a refresh update', () {
      final token = HaToken.fromTokenResponse(
        const {
          'access_token': 'old',
          'refresh_token': 'r',
          'expires_in': 1800,
        },
        'http://homeassistant.local:8123',
        clientId: 'http://127.0.0.1:54321/',
      );
      // Mirrors _doRefresh: new access/refresh/expiry, client_id untouched.
      final refreshed = token.copyWith(
        accessToken: 'new',
        tokenExpiry: token.tokenExpiry + 1800,
      );
      expect(refreshed.accessToken, 'new');
      expect(refreshed.clientId, 'http://127.0.0.1:54321/');
    });
  });
}
