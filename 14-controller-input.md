# DUNGEONWARD — Feature 14: Controller & Input

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M1–M2, M6  
> **Prerequisites/integration:** F04, F05, F10  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-02, ARCH-03, ARCH-04, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-04 — Party-majority dungeon transitions:** The party advances dungeon floors together after a majority vote of eligible active party members. **Integration:** F01/F03/F04 implement host-owned vote and synchronized transition barrier. Majority means strictly more than half of eligible voters. Eligible roster, vote timeout, ties, abstentions, and disconnected voters need explicit policies before coding.
- **GAME-06 — Simple v0.1 combat:** v0.1 includes basic attacks, spells, jumping, and a simple dodge. Complex parries, stamina-gated basic attacks, and advanced combo systems are not part of the required v0.1 combat scope. **Integration:** F02 actions and F14 default mappings; exact dodge cooldown/invulnerability, spell costs, and weapon timing remain OPEN.
- **GAME-08 — Slot-based grid inventory:** Use a slot-based grid inventory, not a weight-based or category-only inventory as the default v0.1 model. **Integration:** F06 grid-slot transaction schema and F10 controller-first grid UI. Dimensions, stack limits, equipment slots, and overflow policy remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Provide controller-first, independently routed input for up to four local players, with seamless Start×2 joining, remapping, and accessibility.

## 2. Locked requirements

1. Support Xbox, PlayStation, and generic compatible gamepads; keyboard/mouse supports at least one local player.
2. Up to four controllers on one PC, each bound to one local slot and never to a network peer identity.
3. Unassigned controller Start #1 opens confirmation; Start #2 on same device requests slot/character selection.
4. Every gameplay/menu action is routed to the owning local player; menus do not steal another player's focus.
5. Hotplug/disconnect/reconnect must not silently reassign a character or spawn a new one.
6. Expose per-player remapping, dead zones, sensitivity, invert Y, hold/toggle options, and vibration settings.
7. Dynamic button glyphs and fully gamepad-navigable UI are required.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Final default mapping, simple dodge button, and bumper/hotbar behavior
- Gyro aiming
- Adaptive triggers
- Per-player keyboard/mouse alongside multiple gamepads
- Input macros and platform-specific glyph detection

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `DeviceAssignment` | local_device_id, local_slot_id, session_player_id, connected flag |
| `InputBindingProfile` | action→physical input map, controller family, revision |
| `InputAccessibilitySettings` | dead zones, look curve, invert Y, hold/toggle, rumble strength |
| `LocalInputCommand` | local_slot_id, move/look axes, pressed/held bitfields, sequence |
| `JoinGestureState` | device ID, UNASSIGNED/CONFIRMING/SELECTING/ASSIGNED, timeout |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `DeviceAssignmentService` observes Godot joypad connection changes and maintains local-only ownership.
- `UnassignedDeviceListener` detects Start independently of focused menus.
- `LocalJoinStateMachine` performs Start×2 and calls F04 slot reservation; F05 controls character choice.
- `PerPlayerInputRouter` converts device events to normalized commands and dispatches by local slot.
- `InputRemapService` validates conflicts, persists settings, and updates F10 glyph prompts.
- `HapticsBridge` applies F11 feedback to assigned gamepad only.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `unassigned_start_pressed(device_id)` → join confirmation UI.
- `join_confirmed(device_id)` → F04 `reserve_slot` → F05 select/create.
- `bind_device(device_id, local_slot_id)` only after approved assignment.
- `get_input_command(local_slot_id, tick)` → F04 authority path.
- `device_disconnected(local_slot_id)` → F04 slot retained/rebind policy; F10 overlay.
- `glyph_family_changed(local_slot_id, family)` → per-player UI prompts.

All gameplay-affecting requests return explicit success/error codes, carry stable actor/player identity and revisions where applicable, and are idempotent when retried.

## 7. Network authority and local presentation

**Authority baseline:** F04's host owns shared gameplay state and consequential transactions. Clients send input or requests, never final combat/item/currency outcomes. One network peer may represent multiple local player slots; resolve `session_player_id` through the registry and validate the actual sender. Local controllers, cameras, viewports, menu focus, and glyphs are not replicated.

**Replication baseline:** Use reliable revisioned events for durable changes and bounded snapshots for transient presentation. Late joiners receive an authoritative baseline before actor activation. Avoid applying duplicate event IDs. Purely cosmetic UI/audio may be predicted locally but cannot modify authoritative state.

## 8. Persistence and recovery

F13 owns save formats, write queues, backup, migration, and per-character revision checks. Any persistent character mutation marks that **specific character** dirty. On entering town, request an immediate save; while in town, save dirty state every **30 seconds** and debounce changes by about **2 seconds**. Flush on town exit/normal shutdown where possible. Each owning device stores its character profile using host-validated in-session state. Never let stale snapshots overwrite newer confirmed saves.

For world/run state, distinguish optional dungeon-session recovery from mandatory character town autosaves. Log and surface failed writes rather than claiming success.

## 9. Controller-first UI and accessibility

All player-facing operations must be possible with an assigned gamepad, including four-way split-screen. Each local player has independent UI focus. Respect F14 remapping, dead zones, glyph families, and device reassignment; one player's menu cannot pause the active multiplayer world. Use scalable fonts, readable iconography, and color-independent status cues.

## 10. Edge cases and failure handling

- Two unassigned controllers press Start simultaneously: separate confirmation states and capacity-safe reservations.
- A controller is unplugged during character selection: retain/release reservation per explicit timeout.
- Assigned controller presses Start: opens its menu, not a new join.
- Keyboard/mouse and controller inputs must not both control one slot unless explicitly configured.
- Four-player split-screen menu focus must remain isolated when two users press confirm simultaneously.
- Controller reconnect with different OS device ID requires explicit safe rebind policy.

## 11. Development work packages

- [ ] **IP-01:** Define device/slot registry and normalized input actions.
- [ ] **IP-02:** Implement unassigned Start×2 join state machine.
- [ ] **IP-03:** Implement per-player input routing and gamepad-first UI focus.
- [ ] **IP-04:** Implement remapping, settings, glyphs, and haptics.
- [ ] **IP-05:** Run four-device/hybrid/hotplug accessibility regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Four gamepads move four distinct characters without input crossover.
- [ ] Start×2 on same unassigned controller opens character selection; one press never spawns.
- [ ] Start on assigned controller does not create a fifth player.
- [ ] 2+2 hybrid input maps correctly through peer-to-multiple-slot registry.
- [ ] Each player can independently remap and navigate menus while others play.
- [ ] Hotplug/reconnect does not corrupt slot ownership or character saves.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Four local controllers work concurrently in live gameplay and UI.
- [ ] Join gesture and character gate integrate correctly with F04/F05.
- [ ] Remapping, dead zones, glyphs, and reconnect behavior are functional.
- [ ] Controller-only town → dungeon → town loop passes in 4-way split-screen.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F04, F05, F10. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **IP-01 — Define device/slot registry and normalized input actions**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
