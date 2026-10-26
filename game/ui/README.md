# Local presentation

Reserved for reusable UI scenes and per-local-player controllers. The current
status label lives in `game/main.tscn`; no lobby or HUD is implemented.

Proposed convention: UI consumes explicit view data and emits typed intent to an
injected controller. It cannot directly mutate authoritative world or save state.
Keep player focus, viewport and device assignment local and isolated. Reuse theme
Resources and small scenes instead of copying HUD logic into gameplay services.
Controller navigation and screenshots become acceptance checks when UI is added.
