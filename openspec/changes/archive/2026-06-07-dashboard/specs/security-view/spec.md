## ADDED Requirements

### Requirement: Security screen layout
The app SHALL provide a `SecurityScreen` as the third bottom-navigation destination (icon: `Icons.security_outlined`). The screen SHALL contain: an alarm status section at the top, a camera feeds section (doorbell, then living room), and a Frigate event thumbnails section below the feeds.

#### Scenario: Security tab navigates to security screen
- **WHEN** the user taps the Security tab in the bottom navigation bar
- **THEN** `SecurityScreen` SHALL render with all sections visible

---

### Requirement: Alarm status and control
The security screen SHALL display the state of `alarm_control_panel.doorbell_security_system` as a prominent status chip (Disarmed / Armed Home / Armed Away / Triggered). The chip colour SHALL be: green for `disarmed`, amber for `armed_home`, red for `armed_away` or `triggered`. No arm/disarm action buttons SHALL be provided in v1 — the chip is display-only.

#### Scenario: Disarmed state renders green
- **WHEN** `alarm_control_panel.doorbell_security_system` state is `disarmed`
- **THEN** the alarm chip SHALL display "Disarmed" in green

#### Scenario: Triggered state renders red
- **WHEN** the alarm state is `triggered`
- **THEN** the alarm chip SHALL display "Triggered" in red with a pulsing animation

---

### Requirement: Doorbell camera feed
The security screen SHALL display a live camera feed for `camera.doorbell_2` using HA's `/api/camera_proxy_stream/{entity_id}` MJPEG endpoint, authenticated with the stored Bearer token. The feed SHALL pause (switch to a still-image refresh at 2 s interval) when the Security tab is not the active screen, to conserve battery.

#### Scenario: Doorbell feed renders live when Security tab is active
- **WHEN** the Security tab is the active bottom-navigation destination
- **THEN** the doorbell MJPEG stream SHALL be connected and rendering frames

#### Scenario: Doorbell feed pauses when tab is inactive
- **WHEN** the user navigates away from the Security tab
- **THEN** the MJPEG stream SHALL disconnect and the widget SHALL switch to still-image refresh mode

---

### Requirement: Living Room camera feed with PTZ controls
The security screen SHALL display a live feed for `camera.living_room` below the doorbell feed. Beneath the feed SHALL be a PTZ control cluster: four directional buttons (pan left/right, tilt up/down) that call `button.press` on the corresponding button entities (`button.living_room_camera_pan_left`, `button.living_room_camera_pan_right`, `button.living_room_camera_tilt_up`, `button.living_room_camera_tilt_down`), and two sliders for pan degree (`number.living_room_camera_pan_degrees`, range 1–90) and tilt degree (`number.living_room_camera_tilt_degrees`, range 1–45). The same pause-on-inactive rule SHALL apply as for the doorbell feed.

#### Scenario: Pan right button calls service
- **WHEN** the user taps the pan-right directional button
- **THEN** the app SHALL call `button.press` with `entity_id: button.living_room_camera_pan_right`

#### Scenario: Pan degree slider sets value
- **WHEN** the user moves the pan degree slider to 45
- **THEN** the app SHALL call `number.set_value` with `entity_id: number.living_room_camera_pan_degrees` and `value: 45`

---

### Requirement: Frigate event thumbnails
The security screen SHALL display a horizontally scrolling row of recent Frigate event thumbnails for the doorbell camera. Each thumbnail SHALL be a still image loaded from HA's `/api/camera_proxy/{entity_id}` for the Frigate snapshot entities (`image.doorbell_frigate_person`, `image.doorbell_frigate_backpack`). Tapping a thumbnail SHALL display the full image in a modal overlay. The row SHALL refresh its images every 30 seconds via a timer.

#### Scenario: Thumbnail row renders Frigate snapshots
- **WHEN** the security screen is displayed
- **THEN** the thumbnail row SHALL show the most recent Person and Backpack snapshot images from the doorbell

#### Scenario: Thumbnail tap shows full image
- **WHEN** the user taps a Frigate snapshot thumbnail
- **THEN** a modal overlay SHALL display the full-resolution image with a close button
