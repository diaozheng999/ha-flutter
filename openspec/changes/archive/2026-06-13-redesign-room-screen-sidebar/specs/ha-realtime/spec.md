# HA Realtime — Delta

## MODIFIED Requirements

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
