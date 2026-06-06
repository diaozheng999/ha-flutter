import 'dart:math';

const haInstanceUrl = 'http://homeassistant.local:8123';
const _mobileClientId = 'https://haflutter.app/';
const _mobileRedirectUri = 'https://haflutter.app/auth/callback';

String get mobileClientId => _mobileClientId;
String get mobileRedirectUri => _mobileRedirectUri;

String generateState() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

Uri buildAuthorizationUrl({
  required String instanceUrl,
  required String clientId,
  required String redirectUri,
  required String state,
}) {
  return Uri.parse('$instanceUrl/auth/authorize').replace(
    queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'state': state,
      'response_type': 'code',
    },
  );
}
