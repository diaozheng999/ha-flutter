## 1. Dependencies & Platform Setup

- [ ] 1.1 Add `flutter_secure_storage`, `webview_flutter`, `http`, and `url_launcher` to `pubspec.yaml`
- [ ] 1.2 Add `INTERNET` permission to `android/app/src/main/AndroidManifest.xml`
- [ ] 1.3 Configure `flutter_secure_storage` Windows support: add `LOCAL_MACHINE` key access in `windows/runner/main.cpp` per package docs
- [ ] 1.4 Run `flutter pub get` and verify `flutter doctor` shows no new issues

## 2. Token Model

- [ ] 2.1 Create `lib/auth/ha_token.dart` — `HaToken` class with fields: `accessToken`, `refreshToken`, `tokenExpiry` (int, Unix seconds), `instanceUrl`
- [ ] 2.2 Add `isExpired` and `isNearExpiry` (within 60 s) getters on `HaToken`
- [ ] 2.3 Add `HaToken.fromTokenResponse(Map<String, dynamic> json, String instanceUrl)` factory that computes `tokenExpiry` as `DateTime.now().millisecondsSinceEpoch ~/ 1000 + expires_in`

## 3. Token Storage

- [ ] 3.1 Create `lib/auth/ha_token_storage.dart` — `HaTokenStorage` class wrapping `FlutterSecureStorage`
- [ ] 3.2 Implement `write(HaToken token)` — writes all four keys (`ha_access_token`, `ha_refresh_token`, `ha_token_expiry`, `ha_instance_url`)
- [ ] 3.3 Implement `read()` — reads all four keys and returns `HaToken?` (null if `ha_access_token` is absent)
- [ ] 3.4 Implement `delete()` — deletes all four keys
- [ ] 3.5 Verify storage round-trip manually: write → read → delete → read returns null

## 4. Auth Service Scaffold

- [ ] 4.1 Create `lib/auth/ha_auth_service.dart` — `HaAuthService extends ChangeNotifier` with state enum `AuthState { unauthenticated, authenticating, authenticated, error }`
- [ ] 4.2 Inject `HaTokenStorage` into `HaAuthService`; expose current `AuthState` and `HaToken?`
- [ ] 4.3 Implement `initialize()` — reads stored token, transitions to `authenticated` if valid, `unauthenticated` otherwise
- [ ] 4.4 Register `HaAuthService` in the widget tree via `ChangeNotifierProvider` (or chosen service locator)

## 5. Authorization URL Construction

- [ ] 5.1 Create `lib/auth/ha_oauth_params.dart` — helper that generates a cryptographically random `state` string (`dart:math` `Random.secure`)
- [ ] 5.2 Implement `buildAuthorizationUrl({required String instanceUrl, required String clientId, required String redirectUri, required String state})` — returns the full `/auth/authorize` URL with query params
- [ ] 5.3 Add platform constant for mobile: `clientId = 'https://haflutter.app/'`, `redirectUri = 'https://haflutter.app/auth/callback'`

## 6. Mobile OAuth (WebView)

- [ ] 6.1 Create `lib/auth/widgets/ha_login_webview.dart` — `HaLoginWebView` stateful widget wrapping `WebViewWidget`
- [ ] 6.2 Set `NavigationDelegate.onNavigationRequest` to intercept any URL starting with `https://haflutter.app/auth/callback`
- [ ] 6.3 On intercept: parse `code` and `state` from the URL, call `HaAuthService.handleCallback(code, state)`, and pop the WebView
- [ ] 6.4 On intercept: return `NavigationDecision.prevent` to stop the WebView loading the redirect URL
- [ ] 6.5 Create `lib/auth/screens/login_screen.dart` — wraps `HaLoginWebView`, shown when `AuthState` is `unauthenticated` on Android

## 7. Desktop OAuth (Loopback Server)

- [ ] 7.1 Create `lib/auth/ha_loopback_server.dart` — binds an `HttpServer` to `127.0.0.1` on a random port, exposes `port`, `clientId`, `redirectUri`
- [ ] 7.2 Implement `waitForCode()` — awaits a single GET to `/callback`, extracts `code` and `state`, returns a `Future<({String code, String state})>`
- [ ] 7.3 After `waitForCode()` resolves: respond with HTTP 200 "Authentication complete — you can close this tab" and shut the server down
- [ ] 7.4 In `HaAuthService.startLogin()` on desktop: start loopback server, build authorization URL using `http://127.0.0.1:{port}/` as both `clientId` root and `redirectUri` base, open browser via `url_launcher`
- [ ] 7.5 Create login entry point on Windows that calls `startLogin()` (e.g., a button on a minimal login screen)

## 8. Token Exchange

- [ ] 8.1 Implement `HaAuthService.handleCallback(String code, String state)` — verifies `state` matches session state, aborts with `AuthState.error` on mismatch
- [ ] 8.2 On valid state: POST to `{instanceUrl}/auth/token` with `grant_type=authorization_code`, `code`, `client_id`, `redirect_uri` (form-encoded via `http` package)
- [ ] 8.3 On HTTP 200: parse response JSON, construct `HaToken` via `fromTokenResponse`, write to `HaTokenStorage`, transition to `authenticated`
- [ ] 8.4 On non-200: transition to `AuthState.error` and surface the HTTP status

## 9. Token Refresh

- [ ] 9.1 Implement `HaAuthService.getAccessToken()` — returns the current access token, triggering refresh first if `isNearExpiry`
- [ ] 9.2 Guard refresh with a `Mutex` (or `Completer`-based equivalent) so concurrent callers await a single in-flight refresh
- [ ] 9.3 Refresh POST: `{instanceUrl}/auth/token` with `grant_type=refresh_token`, `refresh_token`, `client_id`
- [ ] 9.4 On refresh HTTP 400/401: call `HaTokenStorage.delete()` and transition to `unauthenticated`
- [ ] 9.5 On successful refresh: update stored token with new `access_token` and recomputed `tokenExpiry`

## 10. Logout & Revocation

- [ ] 10.1 Implement `HaAuthService.logout()` — POST to `{instanceUrl}/auth/revoke` with `token={refreshToken}&action=revoke`
- [ ] 10.2 Call `HaTokenStorage.delete()` after revocation regardless of the revocation response status
- [ ] 10.3 Transition auth state to `unauthenticated` after deletion
- [ ] 10.4 Expose a logout button in the app UI (location TBD — placeholder is acceptable for this change)

## 11. App Integration

- [ ] 11.1 Call `HaAuthService.initialize()` in `main()` before `runApp`, or during app startup in an `initState`
- [ ] 11.2 Add a root router/guard that redirects to the login screen when `AuthState` is `unauthenticated` and to the home screen when `authenticated`
- [ ] 11.3 Verify on Android: cold launch → login screen → complete OAuth → home screen → relaunch → goes straight to home screen
- [ ] 11.4 Verify on Windows: cold launch → login screen → complete OAuth via browser → home screen → relaunch → goes straight to home screen
- [ ] 11.5 Verify logout: tap logout → revocation fires → local credentials cleared → login screen shown
