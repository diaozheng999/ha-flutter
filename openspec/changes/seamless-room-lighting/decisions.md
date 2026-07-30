# Decision Log: Seamless Room Lighting

## Context

- Goal, in priority order: **coherence first, then speed, then expression**,
  presented as a simple surface that allows deeper drilling. The three are not
  in contention — progressive disclosure keeps the simple case simple.
- The change spans both presentation and the data/model layer: resolving a
  room's fixtures into lighting-role layers is not derivable from the current
  area-driven `RoomConfig` alone.
- Findings below were verified against the live HA instance (`2026.7.2`, 29
  lights across 6 areas) during exploration on 2026-07-12. Entity ids cited are
  real and should be re-checked before they harden into spec scenarios.

### D1 - Model lighting as role layers, not a flat group + list (2026-07-12)

- **Decision:** Organise each room's lights into overhead / task / ambient
  **layers**, each a single control unit acting on its members together.
- **Why:** The user thinks and acts in lighting design terms (overhead / task /
  ambient with gradual individual falloff), which the current flat "group toggle
  + individual tiles" layout cannot express.
- **Alternatives considered:** Keeping the flat group-plus-tiles layout was
  rejected — it has no concept of role and forces per-fixture fiddling. One
  mega-group per room was rejected — it hides the layer intent.
- **Status:** Decided
- **Handoff note:** Layers are the L1 surface. Role does not exist anywhere in
  HA today (see D6); this is the one genuinely new piece of data.

### D2 - Progressive disclosure, four levels (2026-07-12)

- **Decision:** L0 = scene chips + smart master + adaptive toggle; L1 = layers;
  L2 = individual members; L3 = colour + effects. Each level is optional and
  reached by drilling in.
- **Why:** Satisfies "simple interface, deeper drilling later" and the
  coherence > speed > expression ordering without the levels competing.
- **Alternatives considered:** Showing group sliders + per-tile sliders + chips
  all at once (today's behaviour) was rejected as a tall, redundant stack for a
  usually one-tap intent.
- **Status:** Decided
- **Handoff note:** The smart master + scene chips replace the always-visible
  group sliders at the top level; dials live one drill down.

### D3 - Groups are self-describing control units (2026-07-12)

- **Decision:** Where a HA light group (`platform: "group"`) represents a layer,
  use it directly as the control unit — read members from its `entity_id`
  attribute and rely on HA's unioned `supported_color_modes` / `effect_list`.
- **Why:** Verified: `light.entry_lights` reports `["color_temp","rgb","xy"]`,
  the union of a Yeelight (rgb) and a Hue (xy); groups expose members and
  aggregate state for free. No client-side capability math needed for groups.
- **Alternatives considered:** Client-side aggregation over labelled individuals
  (option B from exploration) was not rejected outright but is unnecessary when a
  group entity already exists; it remains the fallback for ungrouped fixtures.
- **Status:** Decided
- **Handoff note:** Groups are messy in practice (D7, D8) — self-describing does
  not mean cleanly partitioned.

### D4 - Template lights are opaque, possibly stepped, leaves (2026-07-12)

- **Decision:** Detect template lights (`platform: "template"`) and render a
  capability-typed control for whatever modes they advertise, but do **not**
  attempt to expand them into members, and tolerate quantised/discrete ranges.
- **Why:** Verified: `light.bedroom_light` / `light.study_light` are template
  lights advertising only `["color_temp"]` with **no** `entity_id` attribute;
  their alias documents 7 discrete brightness levels and 3 fixed colour temps
  (2700/4000/6500K). Backing entities live in arbitrary Jinja and are not
  registry-enumerable.
- **Alternatives considered:** Parsing template config to find members was
  rejected as unreliable (YAML templates expose nothing; even UI helpers only
  expose partial config).
- **Status:** Decided
- **Handoff note:** The capability-typed primitive must handle "color_temp but
  discrete" — a stepped control, not a continuous slider, for these.

### D5 - Ungrouped fixtures get an "Other" bucket (2026-07-12)

- **Decision:** Room lights belonging to no layer render in an explicit
  "Other / ungrouped" bucket so no fixture is unreachable.
- **Why:** Verified: `light.living_room_donut`, `light.master_toilet_bulb_1`,
  and the standalone Shelly `walkway_spotlight` are in no group. The user
  confirmed ungrouped lights are expected.
- **Status:** Decided
- **Handoff note:** The bucket uses the same capability-typed leaves as layer
  members; it is a fallback container, not a fourth role.

### D6 - Role assignment mechanism: HA labels (leaning, not final) (2026-07-12)

- **Decision (provisional):** Assign lighting role via HA **labels**
  (`role:overhead` / `role:task` / `role:ambient`) on the canonical control unit.
- **Why:** Role is encoded nowhere in HA today, so it must be introduced.
  Labels are native, editable in HA, and multi-valued, so they coexist with the
  existing `matterbridge` labels already on many entities.
- **Alternatives considered:** Naming convention (fragile, collides with
  friendly-name freedom); Flutter-side `room_overrides` config (not editable
  without a code change, app-only).
- **Status:** Open — confirm before specs.
- **Handoff note:** If labels are chosen, the app must read entity labels
  (`ha_get_entity` returns them) as part of room resolution.

### D7 - Room resolution must tolerate area-less groups; fix area_id in HA (2026-07-12)

- **Decision:** Room → fixture resolution must not depend solely on
  `area_id`, because many group entities have `area_id: null`. Recommend fixing
  the missing `area_id`s in HA as a prerequisite; the app degrades gracefully
  (e.g. derive a group's room from its members' area) until then.
- **Why:** Verified: `light.kitchen_spotlights`, `dining_table_lights`,
  `entry_lights`, `pantry_lights` all have `area_id: null`, so the current
  area-driven room model skips them entirely. The user confirmed this is
  **unintentional** — a data-hygiene gap, not a design constraint.
- **Status:** Decided (approach); HA-side fix recommended separately.
- **Handoff note:** Member-derived room inference is the interim fallback; once
  `area_id`s are set, direct area mapping is authoritative.

### D8 - De-tangle nested / overlapping groups to one canonical unit (2026-07-12)

- **Decision:** Pick exactly one canonical control unit per (room, role) so a
  bulb is not controlled from two places; do not double-count members.
- **Why:** Verified overlap and nesting: `light.kitchen_lights` ⊃
  `light.kitchen_spotlights` (differs only by the ceiling); the Yeelight
  `light.yeelink_...312630637` is a member of both `entry_lights` and
  `dining_table_lights`.
- **Status:** Open — the resolution policy (hide covered sub-groups vs surface
  both; how to break overlap ties) is undecided.
- **Handoff note:** This is the thorniest data-layer decision; a spec needs a
  deterministic rule, likely informed by which unit carries a role label (D6).

### D9 - Smart master: off = all room lighting, on = comfort-or-turn-on (2026-07-12)

- **Decision:** Master Off turns off all of the room's lighting, computed from
  the room's resolved fixtures — **not** `scene.all_off`. Master On recalls the
  room's comfort scene if one exists, else performs a plain turn-on.
- **Why:** The user wants the highest-frequency tap to be an intent, not a dumb
  switch. Verified `scene.all_off` is unsuitable to reuse: it is hand-curated,
  already incomplete (omits bedroom/study/pantry lights), and over-scoped (pins
  `number.*` countdowns and `select.*` config entities that will drift).
- **Alternatives considered:** Reusing `scene.all_off` (rejected: brittle,
  captures non-light config); On = plain turn-on only (kept as the fallback, but
  comfort recall is the target end state per D12).
- **Status:** Decided
- **Handoff note:** HA scenes have no "active" state, so the master cannot
  truthfully show "Comfort active"; status should read plainly (e.g. "N on").

### D10 - Per-room scene chips via member-overlap association (2026-07-12)

- **Decision:** Surface, as L0 chips, the scenes that affect this room's lights,
  associating a scene to a room by overlap between the scene's `entity_id`
  members and the room's fixtures.
- **Why:** Scenes are the user's primary lighting interaction but are only
  surfaced globally today. Verified association is derivable: `scene.living_room`
  ("Daylight") sets exactly the two living-room Hue bulbs, and scenes carry no
  `area_id`, so overlap is the available signal.
- **Alternatives considered:** Requiring scenes to be area-assigned (scenes are
  not reliably area-bound); a naming convention (fragile).
- **Status:** Decided
- **Handoff note:** Only one real room lighting scene exists today
  (`scene.living_room`); the fan-speed scenes must be excluded (they set fans,
  not lights) — filter by whether members are lighting fixtures.

### D11 - Colour + effects are in scope, capability-gated (2026-07-12)

- **Decision:** Add colour picking and effect selection at L3, shown only on
  fixtures/layers that advertise the capability (`hs`/`rgb`/`rgbw`/`xy`,
  `effect_list`).
- **Why:** The user confirmed the current colour omission is an omission, not a
  deliberate cut, and occasionally wants ambiance/effects on capable bulbs.
- **Status:** Decided
- **Handoff note:** Effects are plentiful in the fleet (e.g. `entry_lights`
  exposes ~20 Hue effects); effect lists vary per fixture and per group union.

### D12 - Comfort scenes: authored per room, deferred to the final phase (2026-07-12)

- **Decision:** Comfort scenes are option (a) — **authored per room** — and this
  is the **last** phase. Until then, master On uses the plain-turn-on fallback
  (D9). Authoring is hand-configured room by room by the user.
- **Why:** The user chose authored comfort scenes but wants them last, because
  they require manual per-room configuration. Verified they do not exist today:
  only living room has any lighting scene, and it is not a comfort scene.
- **Alternatives considered:** (b) capture-current-state as comfort and (c)
  ship turn-on-only were both discussed; (c) is retained only as the interim
  fallback, not the end state.
- **Status:** Decided
- **Handoff note:** No earlier phase may depend on comfort scenes existing.

### D13 - Switch-controlled lighting: flagged, scope undecided (2026-07-12)

- **Decision (pending):** Whether `switch.*` entities that control lights are
  treated as lighting fixtures is undecided.
- **Why:** Verified the user already treats them as lights: `scene.all_off`
  turns off `switch.entry_switch_l1/l2` and `switch.0xa4c1388aecbb45dd_l1..l4`.
  The app's model is `light.*`-only, so switch-controlled lighting is currently
  invisible to it.
- **Status:** Open — likely a scope-cut for the first change, revisit for the
  "all room lighting" off computation (D9).
- **Handoff note:** If included, room off (D9) and the ungrouped bucket (D5)
  must extend beyond the `light` domain.

### D14 - Role assignment via HA labels (resolves D6) (2026-07-12)

- **Decision:** Role is assigned by HA **labels** on the canonical control unit,
  using a `role:<name>` convention. Confirmed choice; D6 is now closed.
- **Why:** Native to HA, editable from its UI, and multi-valued so it coexists
  with the existing `matterbridge` labels. The app reads `labels` via
  `ha_get_entity` during room resolution.
- **Alternatives considered:** Naming convention (fragile, breaks on rename);
  Flutter-side `room_overrides` (not editable without a code change, invisible
  to HA). Both rejected.
- **Status:** Decided (supersedes D6 "Open").
- **Handoff note:** Because the taxonomy is configurable (D17), the label
  namespace is open — any `role:<name>` is valid; ordering/display is config
  (D17). The label reader must be added to the data layer.

### D15 - Role-labelled entity is the canonical control unit (resolves D8) (2026-07-12)

- **Decision:** The entity carrying a `role:<name>` label **is** the canonical
  control unit for that layer. Its members (if it is a group) render as its
  drill-down. Overlapping/nested groups that are not role-labelled do not render
  as layers; their members reach the user only via a labelled ancestor or the
  ungrouped bucket (D5). One label per (room, role) is the invariant.
- **Why:** Overlap and nesting (kitchen_lights ⊃ kitchen_spotlights; a bulb in
  both entry_lights and dining_table_lights) make automatic canonicalisation
  ambiguous. Anchoring on the human-applied role label makes the choice explicit
  and deterministic, and reuses D14's mechanism instead of inventing a tie-break.
- **Alternatives considered:** Surface both parent and sub-group (rejected —
  re-introduces double control/double count); flatten to individuals grouped by
  label (rejected — discards HA's free capability-union and aggregate state).
- **Status:** Decided (supersedes D8 "Open").
- **Handoff note:** Validation concern: two entities labelled the same role in
  one room, or a bulb reachable from two labelled units. The resolver needs a
  defined behaviour (warn + pick first? surface a config warning?) — see design
  Open Questions.

### D16 - Switch-controlled lighting is in scope (resolves D13) (2026-07-12)

- **Decision:** Fixtures controlled via `switch.*` are treated as lighting from
  the first change. The lighting-fixture abstraction spans `light.*` and
  `switch.*`; a switch is an on/off-only fixture (the bottom rung of the
  capability ladder).
- **Why:** The user already treats them as lights (`scene.all_off` toggles
  `switch.entry_switch_*` and `switch.0xa4c1388aecbb45dd_l*`). Excluding them
  would make room-off (D9) silently incomplete and leave real lights unreachable.
- **Alternatives considered:** Light-domain-only first change (rejected — the
  user's own "all off" proves switches are lighting; deferring guarantees a
  wrong room-off).
- **Status:** Decided (supersedes D13 "Open").
- **Handoff note:** Room-off (D9), the ungrouped bucket (D5), and role labelling
  (D14) all extend to `switch.*`. A switch has no brightness/colour — the
  capability-typed primitive (D4/D11) already degrades to on/off at the bottom
  rung, so a switch is just the minimal case. Distinguish light-controlling
  switches from other switches — likely by the presence of a `role:<name>` label
  (a switch is lighting iff it is role-labelled), avoiding a domain-wide sweep.

### D17 - Role taxonomy is configurable, not a fixed three (2026-07-12)

- **Decision:** The set of role layers is configurable rather than a hard-coded
  overhead/task/ambient. Layers are dynamic per room, ordered by config; the
  layout renders a variable number of layers.
- **Why:** The user chose flexibility; rooms differ and the label namespace (D14)
  is already open-ended.
- **Alternatives considered:** Fixed overhead/task/ambient (rejected — simpler
  but the user wants an open set; a fixed enum would fight the open label space).
- **Status:** Decided.
- **Handoff note:** Needs a small config surface: the ordered list of roles and
  their display (name/icon). Unknown/unlabelled roles fall back to the ungrouped
  bucket (D5). The room layout (L1) must not assume a fixed layer count.

### D18 - Default role taxonomy is overhead / task / ambient (2026-07-12)

- **Decision:** The configurable taxonomy (D17) ships with a **default ordered
  list of `overhead`, `task`, `ambient`**, in that order. A room with no override
  uses these three; a room may override the set/order via config.
- **Why:** Matches how the user described the space and gives a predictable,
  non-empty layout out of the box, without forcing everything into the ungrouped
  bucket until labels are applied. Keeps the common case zero-config while
  preserving D17's flexibility.
- **Alternatives considered:** Default-empty (everything ungrouped until labelled)
  was rejected — it makes an unconfigured room look broken and hides the intended
  layer model on first run.
- **Status:** Decided (resolves the "default role taxonomy" open question in
  design.md).
- **Handoff note:** Labels still drive membership (D14/D15); the default only
  fixes which role *layers* render and their order. A default-role layer with no
  labelled fixtures renders empty/absent rather than as an error. `role:<name>`
  labels outside the default three are honoured (D17) and appended after them
  unless the room overrides ordering.

### D19 - Stepped colour temperature is app-configured, not detected (2026-07-12)

- **Decision:** Discrete/quantised colour-temperature ranges are declared in
  `lib/config/lighting_config.dart` (`steppedColorTempKelvins`, keyed by entity
  id) rather than detected from HA. `LightCapabilities.fromState` accepts the
  step list as a parameter and exposes `isSteppedColorTemp`.
- **Why:** Discovered while implementing task 1.4: HA advertises
  `min_color_temp_kelvin` / `max_color_temp_kelvin` as a **continuous** range even
  when the device accepts only a few values. There is no attribute meaning "my
  range is discrete", so the spec's stepped-colour-temp scenario cannot be
  satisfied by detection alone. The knowledge for `light.bedroom_light` /
  `light.study_light` came from the user's own entity aliases (7 brightness
  levels, 3 temperatures at 2700/4000/6500 K), i.e. human knowledge, not HA data.
- **Alternatives considered:** Inferring discreteness from a narrow min/max span
  (rejected — unreliable, and these lights report a normal wide span); probing by
  writing values and reading back (rejected — mutates the user's lights); giving
  up on stepped support (rejected — D4 and the spec require it).
- **Status:** Implemented
- **Handoff note:** Adding a stepped fixture is a one-line config edit. If HA ever
  exposes discrete ranges natively, `fromState` is the single place to change.

### D20 - Role/platform read from the entity registry; WS label availability is a verification item (2026-07-12)

- **Decision:** `EntityRegistryEntry` gained `labels` and `platform`, both parsed
  defensively (missing → empty list / null). `isGroupPlatform` and
  `isTemplatePlatform` derive from `platform`, giving registry-time group/template
  detection before any state has loaded.
- **Why:** Role resolution (D14) needs labels, and knowing group-vs-template at
  registry time avoids ordering dependencies on state arrival. Parsing defensively
  means a registry response without `labels` degrades to "no layers" rather than
  crashing.
- **Verification item (not yet confirmed):** whether HA's WebSocket
  `config/entity_registry/list` includes `labels` and `platform` in **this**
  instance's response. `ha_get_entity` (a different code path) does return both.
  If the WS list omits them, layers will silently resolve empty and the
  implicit-layer fallback (task 2.7) will keep the screen working — but the
  feature will not populate until the fetch is switched to a per-entity or
  display-oriented registry call.
- **Status:** Implemented (parsing); WS field availability to be verified in
  task 8.
- **Handoff note:** Verify by logging one parsed entry's `labels`/`platform` when
  running against live HA; this is the single riskiest unverified assumption in
  the change.

### D21 - Resolver rules for duplicate roles, shared members, and redundant groups (resolves the design's mislabelling Open Question) (2026-07-12)

- **Decision:** Three deterministic rules, each emitting a `kDebugMode` warning
  rather than failing or silently guessing:
  1. **Two entities labelled the same role in one room** — prefer a group over a
     leaf (a group commands more), then the larger group, then the lowest entity
     id for run-to-run stability.
  2. **A member reachable from two role-labelled units** — the layer earlier in
     the configured role order claims it; later layers omit it. A fixture is
     therefore never controlled from two layers.
  3. **An unlabelled group overlapping a role layer** — suppressed entirely
     (commanding it would reach fixtures a layer already owns), and its
     *uncovered* members are promoted into the ungrouped bucket so nothing
     becomes unreachable. An unlabelled group with no overlap is kept whole,
     since it is still a useful single unit.
- **Why:** Task 2.6 and the design Open Question required a deterministic rule.
  Rule 3 is the one the spec scenario implies but does not spell out: suppressing
  `light.kitchen_lights` as a *layer* is not enough — leaving it in the ungrouped
  bucket would re-create the double-control problem it was suppressed to avoid,
  while dropping it outright would strand `light.kitchen_ceiling_light`.
- **Alternatives considered:** Failing loudly on ambiguity (rejected — a
  mislabel in HA should not break the room screen); surfacing a user-visible
  config warning (deferred — debug logging first, promote later if mislabels turn
  out to be common); keeping overlapping unlabelled groups (rejected — double
  control).
- **Status:** Implemented, covered by `test/lighting_resolver_test.dart`
  (20 tests, all passing).
- **Handoff note:** The rules live in `lib/ha/lighting_resolver.dart`
  (`_pickCanonicalUnit`, the `claimed` set, and the ungrouped-bucket pass). If a
  user-visible warning is wanted later, the three `debugPrint` sites are the
  hooks.

### D22 - Lighting states are fetched before room resolution (2026-07-12)

- **Decision:** `roomConfigsProvider` now REST-fetches the states of all lighting
  candidates (all `light.*` plus role-labelled `switch.*`) **before** building
  rooms, and the room-emptiness check runs after lighting resolution so a room
  whose only lighting is a rescued area-less group still exists.
- **Why:** Group membership lives in the `entity_id` **state** attribute, and
  area-less groups are attributed to a room via their members — so resolution
  needs state. The provider's existing bootstrap ran *after* rooms were built and
  derived its id list *from* those rooms, a chicken-and-egg the new pass breaks.
  Bounded cost: one extra REST call over ~29 entities.
- **Alternatives considered:** Resolving lighting lazily in a separate provider
  after state arrives (rejected — layers would pop in after first paint and the
  area-less rescue could not influence which rooms exist); subscribing before
  resolving (rejected — slower and racier than one bounded REST fetch).
- **Status:** Implemented
- **Handoff note:** The fetch is best-effort; on failure groups resolve as leaves
  and the implicit-layer fallback keeps the section usable. Layer/member ids are
  added to the WS subscription list so members stay live once drilled into.

### D23 - Colour/effects built in phase 1 code, and the superseded light widgets retired (2026-07-12)

- **Decision:** `LightColorPicker` and `LightEffectSelector` (planned as phase 3,
  group 6) were written during phase 1 because `CapabilityLightControl`
  references them directly. `LightTile` and `LightToggleWidget` are deleted, their
  role taken over by `CapabilityLightControl`; `test/light_tile_test.dart` is
  removed and `control_scheme_render_test.dart`'s light-group case now exercises
  the new primitive.
- **Why:** Phases order *shipping*, not code — leaving the primitive referencing
  non-existent widgets would not compile. After the section rewrite both old
  widgets had zero production call sites, so keeping them would be dead code of
  exactly the kind the previous change's cleanup removed. Their behaviours
  (tap-toggle, drag-to-zero → `turn_off`, unavailable dimming) are covered by the
  new `test/capability_light_control_test.dart` before deletion, so coverage did
  not regress.
- **Alternatives considered:** Stubbing colour/effects until phase 3 (rejected —
  pointless churn); keeping the old widgets around (rejected — dead code, and two
  competing light controls is the incoherence this change exists to remove).
- **Status:** Implemented. Colour is sent as `hs_color`, which HA converts to each
  light's native mode (xy for Hue, rgb for Yeelight), so one picker serves the
  whole fleet.
- **Handoff note:** Groups 3, 4, 5, 6 are complete; the expression rungs are
  live behind a "Colour & effects" disclosure rather than waiting for phase 3.

### D24 - Master off commands top-level units, not every fixture (2026-07-12)

- **Decision:** The master "off" action calls `turn_off` on
  `RoomLighting.controlUnitIds` (layer units + ungrouped fixtures) rather than
  literally iterating `allFixtureIds`.
- **Why:** Turning off a group turns off its members, so commanding units covers
  every fixture transitively while avoiding a burst of redundant service calls
  (and the state churn/flicker they cause). This satisfies the spec's intent —
  all of the room's lighting goes off, and `scene.all_off` is not reused — via
  the smaller call set. Recorded because it deviates from a literal reading of the
  spec scenario's "each resolved lighting fixture".
- **Alternatives considered:** Calling `turn_off` on every fixture id (rejected —
  duplicate calls per group member); a single `homeassistant.turn_off` with all
  ids (rejected — loses the per-domain routing the service facade provides).
- **Status:** Implemented
- **Handoff note:** `controlUnitIds` is exhaustive by construction: every member
  belongs to a layer whose unit is included, and unlabelled leaves are in the
  ungrouped bucket. If layer nesting ever deepens, re-check that invariant.

### D25 - Comfort scene resolved by naming convention (resolves task 7.1) (2026-07-12)

- **Decision:** The comfort scene is `scene.<area_id>_comfort`, resolved by
  `comfortSceneProvider`. Absent scene → null → master "on" falls back to a plain
  turn-on.
- **Why:** Task 7.1 offered naming convention vs a scene label. The convention
  needs no extra HA metadata and is self-documenting, and because resolution is
  null-safe the feature simply starts working for a room the moment its scene is
  authored — no code change, matching the user's "hand configure this room by
  room" intent. Scene labels would need a second label-registry read for scenes,
  which the app does not currently fetch.
- **Alternatives considered:** A `comfort` label on the scene (rejected for now —
  more moving parts, no benefit while one scene per room is the model); a
  `RoomOverride` field (rejected — a code edit per room).
- **Status:** Implemented (resolution + fallback). Task 7.3 — actually authoring
  the scenes in HA — remains the user's manual step.
- **Handoff note:** Rooms are keyed by HA `area_id`, so the expected ids are
  `scene.living_room_comfort`, `scene.kitchen_comfort`, `scene.bedroom_comfort`,
  `scene.study_comfort`, `scene.entrance_comfort`, `scene.pantry_comfort`.
