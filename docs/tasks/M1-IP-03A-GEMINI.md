# M1-IP-03A — Gemini: pure per-player input routing

**Status:** delegated draft, not executed. **Engine:** Godot 4.7.2. **Branch:** feature/m0-foundation.
**Read:** 00_SHARED_RULES.md, 02_GEMINI.md, ADR-0001 ARCH-02/03/04/08, ADR-0003, 14-controller-input.md sections 1–7, game/core/input/device_registry.gd, game/core/input/join_gesture.gd, this brief.

## Goal
Draft `game/core/input/local_input_router.gd` as a pure RefCounted routing component, no scenes/autoloads/transport. Input arrives from a trusted local adapter with `device_id`, `action`, `pressed` and monotonically increasing `sequence`; resolve local_slot_id from injected DeviceRegistry, never from an untrusted event field. No gameplay command DTO schema is locked yet: output only normalized local event dictionaries `{local_slot_id, device_id, action, pressed, sequence}`, not network RPC or combat commands.

## Contract
- Constructor `_init(device_registry: RefCounted)` injected dependency. Expose `route_action(device_id: int, action: String, pressed: bool, sequence: int) -> Dictionary`.
- Return `{ok: bool, error_code: String, event: Dictionary}` with empty event on rejection.
- Reject negative IDs/sequence, empty action, unknown/unbound or disconnected device, and stale or duplicate sequence **per device**; do not mutate sequence watermark on rejected input.
- Validate action against an **injected allowlist** supplied to constructor or explicit setter; do not invent final mappings or default combat actions. Reject unknown actions.
- Preserve separate sequence state for each device, and prevent input from one device being routed to another local slot. No global menu focus, no world pause, no slot mutation.
- Include `reset_device_sequence(device_id)` only as an explicit trusted lifecycle operation; ordinary disconnect does not free slot or transfer ownership.
- Provide narrow, documented interfaces. No hardcoded numeric tuning or device OS IDs.

## Return
Source file as complete GDScript; contract notes; assumptions; tests **not run** unless executed with exact provenance. Do not push; operator sends draft to Codex for review. Coordinate no shared file with Groq.
