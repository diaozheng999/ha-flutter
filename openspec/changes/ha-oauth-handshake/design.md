## Context

Home Assistant implements OAuth 2.0 via **IndieAuth** ([W3C TR/indieauth](https://www.w3.org/TR/indieauth/)) — a profile of OAuth 2.0 where the `client_id` is a URL that identifies the app, with no pre-registration against the HA instance required. The app currently has no auth layer. This design covers the end-to-end flow: presenting the HA login UI, capturing the authorization code, exchanging it for tokens, and persisting them securely.

Key spec constraints relevant to this implementation:
- `client_id` MUST be an `http`/`https` URL with a path component; loopback hostnames (`127.0.0.1`, `[::1]`) are explicitly permitted (§3.2)
- The authorization endpoint SHOULD verify `redirect_uri` against the client's published list **only when** the scheme, host, or port differ from `client_id` (§4.2.2) — if they match, no published list is needed
- HA's token exchange does NOT require a `me` parameter despite the IndieAuth spec — verified against the live instance and HA auth API docs
- IndieAuth does not define token refresh; HA's refresh token support is a proprietary extension, confirmed by the HA auth API (`expires_in` is typically 1800 s)
- HA exposes a revocation endpoint at `/auth/revoke` (RFC 7009-style); `client_id` is not required for revocation

Target platforms are Android and Windows; iOS/macOS are deferred.

## Goals / Non-Goals

**Goals:**
- Implement the OAuth 2.0 authorization code grant against `http://homeassistant.local:8123`
- Persist the access token and refresh token using platform keystore APIs
- Expose an `AuthService` that the rest of the app can query for auth state and bearer tokens
- Handle silent token refresh before expiry

**Non-Goals:**
- Instance discovery / mDNS browsing (the endpoint is hard-coded for now)
- Support for multiple HA instances
- Biometric lock on top of the stored token
- HTTPS / self-signed certificate handling (deferred; `homeassistant.local` is HTTP on LAN)

## Decisions

### 1. Platform-adaptive OAuth browser

**Decision:** Use the **system browser** on desktop (Windows, macOS) and an **embedded WebView** on mobile (Android, iOS).

**Rationale:** On desktop, the system browser is already running, gives the user a familiar trusted environment, and avoids embedding a full browser engine in the app. On mobile, the system browser flow requires deep-link registration or a loopback server, whereas `webview_flutter` lets us intercept the redirect directly inside the app without any OS plumbing. The two platforms therefore have different optimal paths; using one approach for both would mean accepting the downsides of each on the wrong target.

### 2. Redirect URI and code capture strategy — differs by platform

**Mobile (WebView):** `client_id` = `https://haflutter.app/`, `redirect_uri` = `https://haflutter.app/auth/callback`. Scheme, host, and port all match — HA does not need to look up published redirect URIs (§4.2.2). The WebView's `NavigationDelegate.onNavigationRequest` fires before any network request; we extract `code` from the URL and close the WebView. The URL never needs to resolve.

**Desktop (system browser):** `client_id` = `http://127.0.0.1:<port>/`, `redirect_uri` = `http://127.0.0.1:<port>/callback`. Same ephemeral port for both — scheme, host, and port match, so again no published redirect URI list is needed. The app spins up a temporary local HTTP server before opening the browser; the browser hits the loopback, the server captures `code`, returns a "you can close this tab" page, and shuts down. Loopback hostnames are explicitly permitted as `client_id` by IndieAuth §3.2.

**Alternative considered for desktop:** OS URL scheme registration (Windows registry / macOS plist) — rejected; requires install-time setup, is fragile across OS versions, and forces a non-loopback redirect that breaks the scheme/host/port match.

### 3. `http` package over `dio` for token exchange

**Decision:** Use the `http` package for the single POST to `/auth/token`.

**Rationale:** The token endpoint is one call with a simple form-encoded body. `dio`'s interceptors and retry logic add value when many API calls are made, but that belongs to the future HA API client layer, not this auth bootstrap. Adding `dio` here would be premature.

### 4. `flutter_secure_storage` for credential persistence

**Decision:** Use `flutter_secure_storage` to read/write tokens.

**Rationale:** It wraps Android Keystore (Android) and Windows Credential Manager (Windows) behind a uniform interface. No manual platform-channel code needed. iOS/macOS Keychain is already supported by the same package when those platforms are enabled.

**Stored keys:**
| Key | Value | Source |
|-----|-------|--------|
| `ha_access_token` | Bearer token string | HA token response |
| `ha_instance_url` | `http://homeassistant.local:8123` | Configured at login |
| `ha_refresh_token` | Refresh token string | HA token response |
| `ha_token_expiry` | Unix timestamp (seconds since epoch), stored as decimal string; computed as `now + expires_in` | HA token response (`expires_in`) |

### 5. `AuthService` as a `ChangeNotifier` singleton

**Decision:** Expose auth state through a `ChangeNotifier`-based `AuthService` registered via a simple service locator or `Provider`.

**Rationale:** State management is TBD for the project. `ChangeNotifier` is Flutter-native, requires no additional package, and can be wrapped by any future state management solution (Riverpod, Bloc, etc.) without changing the `AuthService` API.

**Auth states:** `unauthenticated` | `authenticating` | `authenticated` | `error`

### 6. IndieAuth `client_id` — derived from the redirect URI, differs by platform

**Decision:** Set `client_id` to the origin of the `redirect_uri` for each platform:

| Platform | `client_id` | `redirect_uri` |
|---|---|---|
| Mobile (WebView) | `https://haflutter.app/` | `https://haflutter.app/auth/callback` |
| Desktop (loopback) | `http://127.0.0.1:<port>/` | `http://127.0.0.1:<port>/callback` |

The loopback port is the same ephemeral port chosen when the temporary HTTP server is started, so `client_id` and `redirect_uri` always share the same origin within a single auth session.

**Rationale:** IndieAuth §4.2.2 requires extra verification only when `redirect_uri` differs in scheme, host, or port from `client_id`. By deriving `client_id` from the same origin as `redirect_uri` on each platform, we stay within the same-origin case and HA never needs to fetch a published redirect URI list. IndieAuth §3.2 explicitly permits loopback hostnames, making the desktop pairing spec-compliant without any special dispensation.

## Risks / Trade-offs

- **mDNS on Windows** → Windows does not enable mDNS (`.local` resolution) by default on all configurations. Mitigation: document the requirement; fall back to IP entry in a future discovery feature.
- **HTTP (not HTTPS) on LAN** → Tokens transmitted over plain HTTP are visible on the network. Mitigation: acceptable for the initial implementation on a trusted LAN; note in docs that HTTPS requires additional certificate-pinning work.
- **Token refresh race** → Multiple concurrent API calls could all detect expiry and each attempt a refresh. Mitigation: guard refresh with a mutex; only one call performs the refresh, others await the result.
- **Refresh token revocation** → If the user revokes the token in HA's UI, the next refresh will fail. Mitigation: treat a 401 from the refresh endpoint as a trigger to clear stored tokens and return to the login screen.
- **Token refresh is HA-proprietary** → IndieAuth does not define token refresh; HA's refresh token behaviour is undocumented and could change across HA versions. Mitigation: isolate refresh logic in `AuthService` so it can be updated without touching the rest of the auth flow.

## Open Questions

- Should the instance URL be user-configurable at login time (text field above the WebView), or stay hard-coded to `homeassistant.local` until a discovery feature is built?
