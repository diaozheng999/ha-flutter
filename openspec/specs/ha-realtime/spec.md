# HA Realtime

## Purpose

Defines the Home Assistant WebSocket real-time data layer: connection lifecycle, entity subscription, state mapping to Riverpod, service call API, reconnection, stale state handling, and initial REST bootstrap.

## Requirements

### Requirement: WebSocket connection lifecycle
The app SHALL establish a WebSocket connection to the HA instance using the `web_socket_channel` package immediately after the access token is retrieved from secure storage. The connection URL SHALL be `ws(s)://<ha_host>/api/websocket`. On connect, the app SHALL complete the HA WebSocket authentication handshake by sending `{"type": "auth", "access_token": "<token>"}` in response to the `auth_required` message. The app SHALL NOT store the token in memory longer than the lifetime of the connection attempt.

#### Scenario: Successful authentication handshake
- **WHEN** the WebSocket connects and HA sends `{"type": "auth_required"}`
- **THEN** the app SHALL respond with the auth message and, upon receiving `{"type": "auth_ok"}`, transition to the `connected` state

#### Scenario: Authentication failure
- **WHEN** HA responds with `{"type": "auth_invalid"}`
- **THEN** the app SHALL close the WebSocket, clear the stored token, and navigate to the authentication screen

---

### Requirement: Entity allowlist subscription
After successful authentication, the app SHALL call `subscribe_entities` with the explicit base allowlist of entity IDs defined in `HaEntities`. The base allowlist SHALL be a compile-time constant. The app SHALL NOT subscribe to `state_changed` for the full entity registry. After alert-sensor autodiscovery completes (per `room-status-alerts`), the app SHALL extend the subscription with the discovered alert entity ids and any entities referenced by configured alert rules; this extension SHALL be bounded to device-class-filtered alert sensors and SHALL be re-applied automatically on reconnection. If `subscribe_entities` returns an error (HA < 2022.9), the app SHALL fall back to `subscribe_events` for `state_changed` and apply a client-side filter covering both the base allowlist and the discovered extension.

#### Scenario: Subscription sends allowlist
- **WHEN** the WebSocket authenticates successfully
- **THEN** the app SHALL send a `subscribe_entities` message containing the base allowlist entity IDs

#### Scenario: Discovered alert entities extend the subscription
- **GIVEN** registry autodiscovery has identified alert sensors for the rooms
- **WHEN** discovery completes
- **THEN** the app SHALL subscribe to those entity ids in addition to the base allowlist, and their states SHALL flow through `entityStateProvider` like any other entity

#### Scenario: Extension survives reconnect
- **GIVEN** the subscription was extended with discovered alert entities
- **WHEN** the WebSocket reconnects and re-authenticates
- **THEN** both the base allowlist and the discovered extension SHALL be re-subscribed without re-running user-visible loading states

#### Scenario: Fallback to subscribe_events on older HA
- **WHEN** `subscribe_entities` returns an error result
- **THEN** the app SHALL subscribe to `state_changed` events and filter incoming events to the base allowlist plus discovered alert entities before updating state

---

### Requirement: Entity state mapping to Riverpod
The app SHALL expose entity state via a `entityStateProvider(String entityId)` Riverpod `StreamProvider<EntityState>`. `EntityState` SHALL be a typed Dart class carrying: `entityId`, `state` (string), `attributes` (Map), and `lastUpdated` (DateTime). All widget reads of entity state SHALL use this provider family. Direct access to the raw WebSocket stream from widgets is prohibited.

#### Scenario: Provider delivers state on first subscription
- **WHEN** a widget subscribes to `entityStateProvider('light.living_room_lights')` after the WebSocket is connected
- **THEN** the provider SHALL synchronously deliver the last-known `EntityState` from the repository cache, then deliver updates as WebSocket events arrive

#### Scenario: Provider delivers loading state before connection
- **WHEN** a widget subscribes to an entity provider before the WebSocket has authenticated
- **THEN** the provider SHALL be in `AsyncValue.loading()` state

---

### Requirement: Service call API
The app SHALL expose a `callService({required String domain, required String service, required Map<String, dynamic> data})` method on a `HaWebSocketService` singleton accessible via Riverpod. Service calls SHALL be sent as HA WebSocket `call_service` messages with an auto-incremented `id`. The result (`result_ok` / `result_error`) SHALL be awaited and surfaced to the caller as a `Future<void>` that throws on error.

#### Scenario: Successful service call
- **WHEN** a widget calls `callService(domain: 'light', service: 'turn_on', data: {'entity_id': 'light.bedroom_light', 'brightness_pct': 80})`
- **THEN** the app SHALL send the corresponding WebSocket message and the future SHALL complete without error

#### Scenario: Service call error shown to user
- **WHEN** a service call returns `result_error` from HA
- **THEN** the future SHALL throw and the calling widget SHALL display a `SnackBar` with a brief error description

---

### Requirement: Reconnection with exponential backoff
When the WebSocket disconnects for any reason other than explicit app close, the app SHALL attempt to reconnect using exponential backoff: 1 s → 2 s → 4 s → … capped at 60 s. The app SHALL surface a non-blocking "Reconnecting…" status chip in the AppBar during any disconnected period. On successful reconnection, all entity subscriptions SHALL be re-established automatically.

#### Scenario: Reconnect chip appears on disconnect
- **WHEN** the WebSocket connection drops unexpectedly
- **THEN** within 200 ms the AppBar SHALL display a "Reconnecting…" amber chip

#### Scenario: Reconnect chip disappears on reconnect
- **WHEN** the WebSocket reconnects and re-authenticates successfully
- **THEN** the "Reconnecting…" chip SHALL animate out and entity states SHALL resume updating

---

### Requirement: Stale state indicator
While disconnected, the app SHALL continue to display the last-known entity state for all subscribed entities. Stale values SHALL not be visually distinguished from live values (to avoid a sea of indicators), except for interactive controls: any control widget with a pending service call that has not been confirmed SHALL show a spinner overlay until either confirmation arrives or the call times out after 5 s.

#### Scenario: Stale state displayed during disconnect
- **WHEN** the WebSocket is disconnected
- **THEN** room cards, device control cards, and environment readings SHALL continue to display the last-received values

#### Scenario: Pending service call shows spinner
- **WHEN** a service call is sent and no confirmation has been received within 500 ms (e.g., due to disconnect)
- **THEN** the triggering control widget SHALL display a spinner overlay until the call completes or times out

---

### Requirement: Initial state bootstrap via REST
Before the WebSocket subscription delivers its first diff, the app SHALL fetch the current state of all allowlisted entities via the HA REST API (`GET /api/states`) and populate the `EntityStateRepository` cache. This ensures the home screen renders with real data immediately rather than showing loading placeholders. The REST call SHALL use the same stored Bearer token.

#### Scenario: Home screen renders with data on first launch
- **WHEN** the app opens and the REST bootstrap completes before the WebSocket first diff
- **THEN** all home screen entity-dependent widgets SHALL render with real values and no loading spinner

#### Scenario: WebSocket diff updates bootstrap values
- **WHEN** a WebSocket entity diff arrives for an entity whose state was already populated by the REST bootstrap
- **THEN** the newer WebSocket value SHALL replace the bootstrap value in the repository
