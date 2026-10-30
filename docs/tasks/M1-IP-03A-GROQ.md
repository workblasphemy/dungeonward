# M1-IP-03A — Groq: independent routing regression tests

**Status:** delegated draft, not executed. **Engine:** Godot 4.7.2. **Read:** 00_SHARED_RULES.md, 06_GROQ.md, 14-controller-input.md sections 1–7, game/core/input/device_registry.gd, docs/tasks/M1-IP-03A-GEMINI.md, tests/run_all.gd check() pattern.

Draft `tests/unit/test_local_input_router.gd` with static `run(check: Callable, router_script: Script, registry_script: Script) -> void` so Codex can integrate into `tests/run_all.gd`. Tests must be independently derived from the brief, not merely mirror implementation.

Required cases: two devices bound to distinct slots; interleaved action sequences stay isolated; unknown and disconnected devices rejected; reconnect retains original slot; duplicate and stale per-device sequence rejected; invalid negative IDs and sequences rejected; unknown/empty action rejected; rejected input must not advance sequence watermark; disconnect cannot silently reassign; slot capacity and ownership remain DeviceRegistry's job; explicit sequence reset is required for a new device stream; action allowlist prevents arbitrary gameplay commands; no scene or RPC.

Use a fixture action allowlist (e.g. `["fixture_jump", "fixture_menu"]`) **only for tests**, not an approved default mapping. Return complete GDScript and exact test claims, or `not run`. No push; Codex reviews, reconciles APIs and runs CI before DeepSeek.
