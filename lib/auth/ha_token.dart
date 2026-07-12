class HaToken {
  final String accessToken;
  final String refreshToken;
  final int tokenExpiry; // Unix seconds since epoch
  final String instanceUrl;

  /// The OAuth `client_id` this token was issued to. Home Assistant binds a
  /// refresh token to its issuing client_id and rejects a refresh that presents
  /// a different one, so it must be replayed on refresh. Null for tokens stored
  /// before this field existed (refresh then omits client_id).
  final String? clientId;

  const HaToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
    required this.instanceUrl,
    this.clientId,
  });

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= tokenExpiry;
  }

  bool get isNearExpiry {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= tokenExpiry - 60;
  }

  factory HaToken.fromTokenResponse(
    Map<String, dynamic> json,
    String instanceUrl, {
    String? clientId,
  }) {
    final expiresIn = (json['expires_in'] as num).toInt();
    final tokenExpiry =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
    return HaToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenExpiry: tokenExpiry,
      instanceUrl: instanceUrl,
      clientId: clientId,
    );
  }

  HaToken copyWith({
    String? accessToken,
    String? refreshToken,
    int? tokenExpiry,
    String? instanceUrl,
    String? clientId,
  }) {
    return HaToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      instanceUrl: instanceUrl ?? this.instanceUrl,
      clientId: clientId ?? this.clientId,
    );
  }
}
