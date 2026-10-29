# DUNGEONWARD — Feature 10: UI & Menu System

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M1–M3, M6–M7  
> **Prerequisites/integration:** F04, F05, F06, F13, F14  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-03, ARCH-04, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-04 — Party-majority dungeon transitions:** The party advances dungeon floors together after a majority vote of eligible active party members. **Integration:** F01/F03/F04 implement host-owned vote and synchronized transition barrier. Majority means strictly more than half of eligible voters. Eligible roster, vote timeout, ties, abstentions, and disconnected voters need explicit policies before coding.
- **GAME-07 — Difficulty and rewards:** Offer four difficulty presets, bounded custom sliders, and modest capped reward bonuses tied to approved difficulty settings. **Integration:** F12 versioned profile and caps, F08 reward multiplier integration. Preset names, exact caps and reward curve remain OPEN.
- **GAME-08 — Slot-based grid inventory:** Use a slot-based grid inventory, not a weight-based or category-only inventory as the default v0.1 model. **Integration:** F06 grid-slot transaction schema and F10 controller-first grid UI. Dimensions, stack limits, equipment slots, and overflow policy remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Deliver consistent, controller-first menus and HUDs that remain independent and readable in one-to-four local viewports.

## 2. Locked requirements

1. Every required interaction is operable without a mouse: title, lobby, character creation, inventory, equipment, vendors, settings, recovery.
2. Each local player owns an independent focus context, HUD, and menu stack.
3. Opening one player's menu does not steal another's controller or globally pause multiplayer.
4. UI adapts to 1/2/3/4 split-screen layouts and quarter-screen readability.
5. Prompts match assigned device/glyph family and update on rebind.
6. Connection errors, join capacity, save failures, and character compatibility are explicit and actionable.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Exact visual skin and animated ornamentation
- Radial vs list menus
- Two-player split orientation
- Advanced minimap and quest tracker
- Narrative dialogue styling

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `UIThemeDefinition` | font sizes, palette, spacing, icon set, nine-slice assets |
| `LocalUIContext` | local_slot_id, viewport_id, focus_owner, menu stack, input glyph family |
| `HUDViewModel` | health, mana, hotbar, XP, target, connection/save indicators |
| `MenuRoute` | screen ID, parameters, return focus, pause policy |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `ViewportUIManager` instantiates a HUD and overlay stack per local slot.
- `FocusRouter` consumes F14 actions only from the owning local device.
- `MenuNavigator` manages per-player navigation/back/confirm and modal behavior.
- `HUDPresenter` subscribes to state events; never writes authoritative gameplay state.
- `UIScalePolicy` selects density/font/layout based on viewport size and accessibility settings.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `open_menu(local_slot_id, route)` / `close_menu(local_slot_id)` with independent focus.
- `bind_hud(session_player_id, viewport_id)` on F04 spawn and slot mapping.
- `device_glyph_changed(local_slot_id, glyph_family)` from F14.
- `show_error(local_slot_id, code, details)` for join/save/transaction failures.
- `inventory_delta(character_id, revision)` updates only the owning player's UI.

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

- One player selects a character while three others fight: no focus theft.
- Controller disconnect while modal open: retain state and show rebind prompt.
- 3/4-way viewport shrinking: text remains legible without clipping.
- Duplicate RPC UI events: dedupe by revision/event ID.
- Save error occurs with inventory open: non-destructive alert with retry path.

## 11. Development work packages

- [ ] **UI-01:** Create theme, focus router, and per-slot UI contexts.
- [ ] **UI-02:** Implement lobby/character/Start×2 UI.
- [ ] **UI-03:** Implement HUD and dynamic split-screen layouts.
- [ ] **UI-04:** Implement inventory/vendor/settings screens.
- [ ] **UI-05:** Run accessibility, device, and quarter-screen regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Complete character creation and equipment flow with gamepad only.
- [ ] Four independent menus navigate concurrently without cross-control.
- [ ] Viewport resize/layout change preserves each player's focus and scroll position.
- [ ] All actionable controls are visible/readable in quarter-screen.
- [ ] Device prompt glyph updates correctly on controller/keyboard switch.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Lobby, character select, HUD, inventory, merchant, and settings are navigable with gamepad.
- [ ] Independent per-player focus and overlays pass 4-local tests.
- [ ] Error/recovery UI is functional, not decorative.
- [ ] UI is scalable and tested for keyboard/mouse as well.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F04, F05, F06, F13, F14. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **UI-01 — Create theme, focus router, and per-slot UI contexts**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
