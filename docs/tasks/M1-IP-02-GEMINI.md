# M1 IP-02 — Gemini bounded implementation assignment

**Status:** Assigned for drafting; NOT implemented or tested.
**Owner:** Gemini. **Reviewer/integrator:** Codex. **Independent tester:** DeepSeek.
**Branch:** `feature/m0-foundation`; do not merge main. Do not push independently without approved handoff workflow.

## Scope (one file group only)
Draft `game/core/input/join_gesture.gd` as a pure Godot 4.7.2 `RefCounted` class. No autoload, scene, RPC, UI or networking.

### Approved behavior
- State per transient nonnegative device ID: `UNASSIGNED`, `CONFIRMING`, `SELECTING`, `ASSIGNED`. An internal `RESERVING` state is permitted for in-flight host request; avoid duplicate requests.
- `start_pressed(device_id: int, now_ms: int, confirmation_window_ms: int, assigned: bool) -> Dictionary` or an equivalent explicit, typed API. Never hardcode the confirmation window; caller injects positive duration.
- First Start on unassigned device: show prompt / transition to CONFIRMING, no reservation.
- Second Start on **same** device within deadline: produce a single `REQUEST_RESERVATION` intent (not a direct registry call).
- Independent devices can confirm simultaneously. Start on assigned device returns `OPEN_MENU` intent, never a join.
- Expiry and cancel restore UNASSIGNED. Duplicate Start while reservation pending must not issue another request.
- `reservation_result(device_id, success)` transitions to SELECTING only after host success; failed result returns to UNASSIGNED or retryable state with clear error.
- `mark_assigned(device_id)` only after explicit approved device-slot binding; `disconnect(device_id)` never silently reassigns a saved character.
- Validate invalid IDs, timestamps and window. Return explicit `ok`, `error_code`, `intent` and `state`; do not put tokens, character IDs, peer IDs or network identity in gesture state.
- No implicit spawn or auto-start of world.

## Interface boundary
The local adapter consumes `REQUEST_RESERVATION`, chooses a free local slot, then calls the existing trusted host `M0RequestAuthorizer.request_slot(sender_peer_id, {"request_id": ..., "local_slot_id": ..., "protocol_version": 1}, now_ms)`. Host assigns session_player_id and reservation_token; gesture must never generate these. `DeviceRegistry.bind_device` happens only after approved assignment. Keep peer ID separate from device ID.

## Required deliverable
One GDScript file plus short interface description and edge-case list. Avoid changing `device_registry.gd`, `lobby_registry.gd`, `m0_request_authorizer.gd`, `project.godot` or tests. Explicitly state tests NOT RUN unless actually executed. No unapproved numeric defaults.

## Acceptance criteria
First press no reservation; same-device second press exactly one intent; other device cannot confirm it; timeout/cancel; simultaneous devices; assigned device opens menu; pending duplicate suppressed; failed reservation recovery; no character spawn; Godot parser-safe method names (avoid native `Object` collisions).
