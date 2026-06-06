## Why

The app has no authentication layer, making it unable to connect to a real Home Assistant instance. Implementing the HA OAuth 2.0 authorization code flow — the only officially supported login method — is the prerequisite for every feature that touches live HA data.

## What Changes

- Add an OAuth 2.0 authorization code flow against `http://homeassistant.local:8123` (standard mDNS endpoint)
- Present a WebView-based login screen so the user authenticates through HA's own UI without the app ever handling credentials directly
- Exchange the authorization code for an access token + long-lived refresh token via the HA token endpoint
- Persist tokens securely using platform keystore APIs (Android Keystore on Android, Windows Credential Manager on Windows)
- Expose a simple auth state to the rest of the app (authenticated vs. unauthenticated)

## Capabilities

### New Capabilities

- `ha-oauth-flow`: Full OAuth 2.0 authorization code grant against the HA instance — authorization URL construction, WebView presentation, redirect interception, code-for-token exchange, and token refresh
- `ha-token-storage`: Secure read/write/delete of HA credentials (access token, refresh token, token expiry, instance URL) using platform keystore APIs via `flutter_secure_storage`

### Modified Capabilities

*(none — this is a greenfield addition)*

## Impact

- **New dependencies**: `flutter_secure_storage` (keystore wrapper), `webview_flutter` (OAuth WebView), `http` or `dio` (token endpoint calls)
- **New files**: auth service / repository, token model, login screen, WebView widget
- **Platform configuration**: Android `AndroidManifest.xml` needs an intent filter for the OAuth redirect URI; Windows may need registry entries for a custom URI scheme
- **Deferred platforms**: iOS/macOS keychain integration can be added when Xcode is available — `flutter_secure_storage` already supports it
- **No existing code paths affected** — auth is additive at this stage
