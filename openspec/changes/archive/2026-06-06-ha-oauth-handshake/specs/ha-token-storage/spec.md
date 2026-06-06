## ADDED Requirements

### Requirement: Secure credential write
The system SHALL write credential values to the platform keystore using `flutter_secure_storage`, which maps to Android Keystore on Android and Windows Credential Manager on Windows.

#### Scenario: Write on successful token exchange
- **WHEN** the token exchange completes successfully
- **THEN** `ha_access_token`, `ha_instance_url`, `ha_refresh_token`, and `ha_token_expiry` (computed as `current_unix_time + expires_in`) are all written to secure storage before the auth state transitions to `authenticated`

#### Scenario: Write is atomic per key
- **WHEN** a credential value is written
- **THEN** reading the same key immediately after returns the written value

---

### Requirement: Secure credential read
The system SHALL read credential values from the platform keystore. Reading a key that has not been written SHALL return null.

#### Scenario: Read existing credential
- **WHEN** a key has been previously written
- **THEN** reading that key returns the stored value

#### Scenario: Read absent credential
- **WHEN** a key has never been written or has been deleted
- **THEN** reading that key returns null

---

### Requirement: Credential deletion
The system SHALL delete all stored credential keys atomically when logout or an unrecoverable auth failure occurs.

#### Scenario: Logout deletes all keys
- **WHEN** logout is requested
- **THEN** `ha_access_token`, `ha_instance_url`, `ha_refresh_token`, and `ha_token_expiry` are all deleted from secure storage

#### Scenario: Post-deletion reads return null
- **WHEN** credentials have been deleted
- **THEN** reading any of the credential keys returns null

---

### Requirement: Token expiry check
The system SHALL compare the stored `ha_token_expiry` Unix timestamp (seconds since epoch, stored as a decimal string) against the current UTC Unix time to determine whether the access token requires refresh before use.

#### Scenario: Token is current
- **WHEN** the current Unix time is more than 60 seconds before `ha_token_expiry`
- **THEN** the stored access token is returned directly without triggering a refresh

#### Scenario: Token is near expiry
- **WHEN** the current Unix time is within 60 seconds of or past `ha_token_expiry`
- **THEN** a token refresh is triggered before the access token is returned to the caller

#### Scenario: No expiry stored
- **WHEN** `ha_token_expiry` is null (HA did not return `expires_in`)
- **THEN** the stored access token is returned as-is and no refresh is triggered

---

### Requirement: Credential key schema
The system SHALL use the following fixed key names in secure storage.

| Key | Type | Description |
|-----|------|-------------|
| `ha_access_token` | String | Bearer token for HA API requests |
| `ha_instance_url` | String | HA instance base URL (e.g. `http://homeassistant.local:8123`) |
| `ha_refresh_token` | String | HA refresh token for obtaining new access tokens |
| `ha_token_expiry` | String | Unix timestamp (seconds since epoch) of access token expiry, stored as a decimal string; computed as `current_unix_time + expires_in` from the token response |

#### Scenario: Key names are stable
- **WHEN** credentials are written during one app session
- **THEN** those credentials are retrievable using the same key names in a subsequent app session
