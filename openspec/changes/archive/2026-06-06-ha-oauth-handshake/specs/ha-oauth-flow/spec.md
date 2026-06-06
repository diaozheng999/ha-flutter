## ADDED Requirements

### Requirement: Authorization URL construction
The system SHALL construct a valid IndieAuth authorization URL targeting `{instance_url}/auth/authorize` with the following query parameters: `client_id` (platform-derived origin URL), `redirect_uri` (platform-derived callback URL), `state` (cryptographically random value generated per session), and `response_type=code`.

#### Scenario: Mobile authorization URL
- **WHEN** the login flow is initiated on a mobile platform
- **THEN** the authorization URL uses `client_id=https://haflutter.app/` and `redirect_uri=https://haflutter.app/auth/callback`

#### Scenario: Desktop authorization URL
- **WHEN** the login flow is initiated on a desktop platform
- **THEN** the system binds an ephemeral local port, and the authorization URL uses `client_id=http://127.0.0.1:{port}/` and `redirect_uri=http://127.0.0.1:{port}/callback` with the same port value in both

#### Scenario: State parameter uniqueness
- **WHEN** two separate login sessions are initiated
- **THEN** each generates a distinct `state` value

---

### Requirement: Platform-adaptive OAuth browser
The system SHALL open the authorization URL in an embedded WebView on mobile platforms and in the OS default browser on desktop platforms.

#### Scenario: Mobile browser presentation
- **WHEN** the login flow is initiated on Android
- **THEN** an embedded `webview_flutter` WebView opens and loads the authorization URL

#### Scenario: Desktop browser launch
- **WHEN** the login flow is initiated on Windows
- **THEN** the OS default browser opens with the authorization URL and the app simultaneously starts a loopback HTTP server on the chosen ephemeral port

---

### Requirement: Redirect capture on mobile
The system SHALL intercept the WebView navigation to the `redirect_uri` before it resolves over the network, extract the `code` and `state` query parameters, and dismiss the WebView.

#### Scenario: Successful redirect interception
- **WHEN** the HA authorization endpoint redirects the WebView to `https://haflutter.app/auth/callback?code=X&state=Y`
- **THEN** the WebView navigation is cancelled, the WebView is closed, and the code `X` and state `Y` are passed to the token exchange step

#### Scenario: Redirect to wrong URL ignored
- **WHEN** the WebView navigates to any URL that does not begin with `https://haflutter.app/auth/callback`
- **THEN** the navigation proceeds normally and no code extraction is attempted

---

### Requirement: Redirect capture on desktop
The system SHALL run a temporary local HTTP server that listens for a single GET request to `/callback`, captures the `code` and `state` query parameters from that request, responds with a success page instructing the user to return to the app, then shuts the server down.

#### Scenario: Successful loopback capture
- **WHEN** the browser is redirected to `http://127.0.0.1:{port}/callback?code=X&state=Y`
- **THEN** the server captures code `X` and state `Y`, returns an HTTP 200 response with a human-readable "Authentication complete" message, and terminates

#### Scenario: Server shuts down after capture
- **WHEN** the callback request has been handled
- **THEN** the loopback server stops accepting connections regardless of whether the token exchange succeeds

---

### Requirement: State verification
The system SHALL verify that the `state` value returned in the redirect matches the `state` value generated for the current session before proceeding with token exchange.

#### Scenario: Valid state
- **WHEN** the redirect `state` matches the session-generated `state`
- **THEN** the flow proceeds to token exchange

#### Scenario: State mismatch
- **WHEN** the redirect `state` does not match the session-generated `state`
- **THEN** the flow is aborted, any partially captured code is discarded, and the auth state transitions to `error`

---

### Requirement: Authorization code exchange
The system SHALL exchange the authorization code for tokens by POSTing to `{instance_url}/auth/token` with an `application/x-www-form-urlencoded` body containing `grant_type=authorization_code`, `code`, `client_id`, and `redirect_uri`.

#### Scenario: Successful token exchange
- **WHEN** the token endpoint returns HTTP 200 with a JSON body containing `access_token`, `token_type=Bearer`, `expires_in`, and `refresh_token`
- **THEN** the access token, refresh token, and computed expiry (`current_unix_time + expires_in`) are passed to token storage and the auth state transitions to `authenticated`

#### Scenario: Token exchange failure
- **WHEN** the token endpoint returns a non-200 response
- **THEN** no credentials are stored and the auth state transitions to `error` with the HTTP status code available for display

---

### Requirement: Silent token refresh
The system SHALL refresh the access token using HA's proprietary refresh mechanism before the token expires, without requiring user interaction.

#### Scenario: Proactive refresh
- **WHEN** a caller requests the current bearer token and the stored expiry is within 60 seconds of the current time
- **THEN** the system POSTs to `{instance_url}/auth/token` with `grant_type=refresh_token`, `refresh_token`, and `client_id` before returning the new access token

#### Scenario: Concurrent refresh guarded
- **WHEN** multiple callers simultaneously detect that the token requires refresh
- **THEN** only one refresh request is sent; all other callers await its result

#### Scenario: Refresh failure clears credentials
- **WHEN** the refresh endpoint returns HTTP 400 or 401
- **THEN** all stored credentials are deleted and the auth state transitions to `unauthenticated`

---

### Requirement: Auth state
The system SHALL maintain and expose an observable auth state with four values: `unauthenticated`, `authenticating`, `authenticated`, and `error`.

#### Scenario: Initial state
- **WHEN** the app starts and no stored credentials exist
- **THEN** the auth state is `unauthenticated`

#### Scenario: Restored session
- **WHEN** the app starts and valid stored credentials exist
- **THEN** the auth state transitions directly to `authenticated` without repeating the login flow

#### Scenario: Login in progress
- **WHEN** the authorization URL has been opened and the redirect has not yet been captured
- **THEN** the auth state is `authenticating`

---

### Requirement: Logout
The system SHALL revoke the stored refresh token by POSTing to `{instance_url}/auth/revoke` with `token={refresh_token}&action=revoke` (`client_id` is not required), then delete all stored credentials and transition auth state to `unauthenticated`.

#### Scenario: Logout revokes and clears
- **WHEN** the user initiates logout
- **THEN** a revocation request is sent to `/auth/revoke` with the stored refresh token, all credential keys are deleted from secure storage, and auth state becomes `unauthenticated`

#### Scenario: Logout clears even if revocation fails
- **WHEN** the revocation request returns a non-200 response or the network is unavailable
- **THEN** stored credentials are deleted anyway and auth state becomes `unauthenticated`
