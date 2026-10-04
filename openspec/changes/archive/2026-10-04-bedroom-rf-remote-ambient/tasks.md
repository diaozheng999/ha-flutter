## 1. Resolve installed configuration

- [x] 1.1 Read decisions.md and re-read the bedroom event entity, ambient group/member capabilities, helper-correction automation and wall-light automation using the retained HA access path; record IDs and current hashes.
- [x] 1.2 Search ambient/group-member consumers and inspect the installed Adaptive Lighting profile's membership, expansion, takeover/reset settings and service schema; resolve ambient-only manual-control targets.

## 2. Prepare and verify the automation

- [x] 2.1 Add reviewable automation JSON under home_assistant/ with a bounded queue, per-occurrence event snapshots, the established freshness guard and the exact six-command unmarked allowlist.
- [x] 2.2 Implement ambient OFF and 2700/4000/6500 K turn-on actions, preserving ambient brightness and using no Mistral, Broadlink, spotlight, relay or wall-automation target.
- [x] 2.3 Implement +/-10-percentage-point brightness from a guarded ambient state snapshot while on, byte-aware rounding and 1–100% clamping; use ordered native group calls without added confirmation waits (D15).
- [x] 2.4 Add ambient-only Adaptive Lighting takeover before eligible manual on/temperature/brightness actions while retaining the installed reset policy and behavior when adaptation is disabled.
- [x] 2.5 Add and run meaningful event/action checks for all mappings, excluded sources/rooms/fan commands, fresh versus restored events, parent versus nested guard semantics, off/unavailable/non-numeric guards, endpoint clamps, successive responsive occurrences and scoped manual targets.
- [x] 2.6 Validate the simplified automation through supported HA tooling and preserve a private local rollback record without committing access data or raw backups.

## 3. Deploy and record scoped acceptance

- [x] 3.1 Update the existing added automation through HA's configuration API, record its returned ID/hash, and verify enabled state and exact configuration by readback; confirm existing correction/wall configurations remain unchanged.
- [x] 3.2 Close scoped ambient mapping, manual takeover and spotlight-isolation acceptance by the user's explicit "it's fine" direction (D18); retain recorded traces/state and unmeasured physical timing without claiming a new six-button sweep.
- [x] 3.3 Verify excluded traffic, repeated responsive brightness occurrences and the applicable adaptation-reset path through meaningful automated or actual existing evidence; do not manufacture events on the live receiver entity or initiate unrequested Broadlink sends.
- [x] 3.4 Record deployment, rollback steps and acceptance status in decisions.md; distinguish verified behavior, explicit user acceptance and unobserved physical outcomes, then run strict OpenSpec validation.
