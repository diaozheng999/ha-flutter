## 1. Dependencies & Platform Setup

- [x] 1.1 Add `flutter_secure_storage`, `webview_flutter`, `http`, and `url_launcher` to `pubspec.yaml`
- [x] 1.2 Add `INTERNET` permission to `android/app/src/main/AndroidManifest.xml`
- [x] 1.3 Configure `flutter_secure_storage` Windows support: add `LOCAL_MACHINE` key access in `windows/runner/main.cpp` per package docs
- [x] 1.4 Run `flutter pub get` and verify `flutter doctor` shows no new issues

## 2. Token Model

- [x] 2.1 Create `lib/auth/ha_token.dart` — `HaToken` class with fields: `accessToken`, `refreshToken`, `tokenExpiry` (int, Unix seconds), `instanceUrl`
- [x] 2.2 Add `isExpired` and `isNearExpiry` (within 60 s) getters on `HaToken`
- [x] 2.3 Add `HaToken.fromTokenResponse(Map<String, dynamic> json, String instanceUrl)` factory that computes `tokenExpiry` as `DateTime.now().millisecondsSinceEpoch ~/ 1000 + expires_in`

## 3. Token Storage

- [x] 3.1 Create `lib/auth/ha_token_storage.dart` — `HaTokenStorage` class wrapping `FlutterSecureStorage`
- [x] 3.2 Implement `write(HaToken token)` — writes all four keys (`ha_access_token`, `ha_refresh_token`, `ha_token_expiry`, `ha_instance_url`)
- [x] 3.3 Implement `read()` — reads all four keys and returns `HaToken?` (null if `ha_access_token` is absent)
- [x] 3.4 Implement `delete()` — deletes all four keys

## 4. Auth Service Scaffold

- [x] 4.1 Create `lib/auth/ha_auth_service.dart` — `HaAuthService extends ChangeNotifier` with state enum `AuthState { unauthenticated, authenticating, authenticated, error }`
- [x] 4.2 Inject `HaTokenStorage` into `HaAuthService`; expose current `AuthState` and `HaToken?`
- [x] 4.3 Implement `initialize()` — reads stored token, transitions to `authenticated` if valid, `unauthenticated` otherwise
- [x] 4.4 Register `HaAuthService` in the widget tree via `ChangeNotifierProvider` (or chosen service locator)

## 5. Authorization URL Construction

- [x] 5.1 Create `lib/auth/ha_oauth_params.dart` — helper that generates a cryptographically random `state` string (`dart:math` `Random.secure`)
- [x] 5.2 Implement `buildAuthorizationUrl({required String instanceUrl, required String clientId, required String redirectUri, required String state})` — returns the full `/auth/authorize` URL with query params
- [x] 5.3 Add platform constant for mobile: `clientId = 'https://haflutter.app/'`, `redirectUri = 'https://haflutter.app/auth/callback'`

## 6. Mobile OAuth (WebView)

- [x] 6.1 Create `lib/auth/widgets/ha_login_webview.dart` — `HaLoginWebView` stateful widget wrapping `WebViewWidget`
- [x] 6.2 Set `NavigationDelegate.onNavigationRequest` to intercept any URL starting with `https://haflutter.app/auth/callback`
- [x] 6.3 On intercept: parse `code` and `state` from the URL, call `HaAuthService.handleCallback(code, state)`, and pop the WebView
- [x] 6.4 On intercept: return `NavigationDecision.prevent` to stop the WebView loading the redirect URL
- [x] 6.5 Create `lib/auth/screens/login_screen.dart` — wraps `HaLoginWebView`, shown when `AuthState` is `unauthenticated` on Android

## 7. Desktop OAuth (Loopback Server)

- [x] 7.1 Create `lib/auth/ha_loopback_server.dart` — binds an `HttpServer` to `127.0.0.1` on a random port, exposes `port`, `clientId`, `redirectUri`
- [x] 7.2 Implement `waitForCode()` — awaits a single GET to `/callback`, extracts `code` and `state`, returns a `Future<({String code, String state})>`
- [x] 7.3 After `waitForCode()` resolves: respond with HTTP 200 "Authentication complete — you can close this tab" and shut the server down
- [x] 7.4 In `HaAuthService.startLogin()` on desktop: start loopback server, build authorization URL using `http://127.0.0.1:{port}/` as both `clientId` root and `redirectUri` base, open browser via `url_launcher`
- [x] 7.5 Create login entry point on Windows that calls `startLogin()` (e.g., a button on a minimal login screen)

## 8. Token Exchange

- [x] 8.1 Implement `HaAuthService.handleCallback(String code, String state)` — verifies `state` matches session state, aborts with `AuthState.error` on mismatch
- [x] 8.2 On valid state: POST to `{instanceUrl}/auth/token` with `grant_type=authorization_code`, `code`, `client_id`, `redirect_uri` (form-encoded via `http` package)
- [x] 8.3 On HTTP 200: parse response JSON, construct `HaToken` via `fromTokenResponse`, write to `HaTokenStorage`, transition to `authenticated`
- [x] 8.4 On non-200: transition to `AuthState.error` and surface the HTTP status

## 9. Token Refresh

- [x] 9.1 Implement `HaAuthService.getAccessToken()` — returns the current access token, triggering refresh first if `isNearExpiry`
- [x] 9.2 Guard refresh with a `Mutex` (or `Completer`-based equivalent) so concurrent callers await a single in-flight refresh
- [x] 9.3 Refresh POST: `{instanceUrl}/auth/token` with `grant_type=refresh_token`, `refresh_token`, `client_id`
- [x] 9.4 On refresh HTTP 400/401: call `HaTokenStorage.delete()` and transition to `unauthenticated`
- [x] 9.5 On successful refresh: update stored token with new `access_token` and recomputed `tokenExpiry`

## 10. Logout & Revocation

- [x] 10.1 Implement `HaAuthService.logout()` — POST to `{instanceUrl}/auth/revoke` with `token={refreshToken}&action=revoke`
- [x] 10.2 Call `HaTokenStorage.delete()` after revocation regardless of the revocation response status
- [x] 10.3 Transition auth state to `unauthenticated` after deletion
- [x] 10.4 Expose a logout button in the app UI (location TBD — placeholder is acceptable for this change)

## 11. App Integration

- [x] 11.1 Call `HaAuthService.initialize()` in `main()` before `runApp`, or during app startup in an `initState`
- [x] 11.2 Add a root router/guard that redirects to the login screen when `AuthState` is `unauthenticated` and to the home screen when `authenticated`
