class HaToken {
  final String accessToken;
  final String refreshToken;
  final int tokenExpiry; // Unix seconds since epoch
  final String instanceUrl;

  const HaToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
    required this.instanceUrl,
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
    String instanceUrl,
  ) {
    final expiresIn = (json['expires_in'] as num).toInt();
    final tokenExpiry =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
    return HaToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenExpiry: tokenExpiry,
      instanceUrl: instanceUrl,
    );
  }

  HaToken copyWith({
    String? accessToken,
    String? refreshToken,
    int? tokenExpiry,
    String? instanceUrl,
  }) {
    return HaToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      instanceUrl: instanceUrl ?? this.instanceUrl,
    );
  }
}
