# DUNGEONWARD — Feature 09: Town & Hub System

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M3 (minimal save zone), M7 (full hub)  
> **Prerequisites/integration:** F01, F04, F05, F06, F08, F10, F13  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-05, ARCH-06, ARCH-07 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-02 — Death and recovery:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items. **Integration:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.
- **GAME-04 — Party-majority dungeon transitions:** The party advances dungeon floors together after a majority vote of eligible active party members. **Integration:** F01/F03/F04 implement host-owned vote and synchronized transition barrier. Majority means strictly more than half of eligible voters. Eligible roster, vote timeout, ties, abstentions, and disconnected voters need explicit policies before coding.
- **GAME-05 — Persistent couch profiles:** Couch co-op uses separate local owner profiles; guest characters persist across sessions instead of being temporary. **Integration:** F05 local profile registry and character UUIDs; F13 profile-isolated save directories. Guest export, migration, profile deletion, and account linking remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Provide the safe preparation hub for character progression, merchants, dungeon access, and mandatory independent town autosaves.

## 2. Locked requirements

1. Town is the primary safe zone and the anchor of the prepare → descend → return loop.
2. Every character entering town triggers their own immediate save request.
3. While an individual character remains in town, dirty state autosaves every 30 seconds and debounces changes by ~2 seconds.
4. Town location is tracked per player; never assume all four players enter/leave together.
5. Merchants and services use host-validated inventory/currency transactions.
6. Controller-only navigation works for vendors, dialogue, dungeon entrance, and character services.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Full town layout and named NPCs
- Storage chest, crafting, quests, training
- Town upgrades and housing
- Return portals and floor-vote rules
- Town-specific ambience and day/night

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `TownRegionDefinition` | region_id, safe-zone bounds, spawn markers, service IDs |
| `TownServiceDefinition` | service_id, type, NPC ID, inventory/prices, access rules |
| `MerchantStock` | item definition IDs, prices, stock revision |
| `PlayerTownPresence` | character ID, entered timestamp, dirty flag, save schedule |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `TownRegionTracker` authoritatively determines enter/exit events for each actor.
- `TownServiceRegistry` binds interactables to vendor/character/dungeon services.
- `MerchantAuthority` validates purchases and sales using F06 transactions.
- `TownSpawnCoordinator` chooses safe per-player spawn markers.
- `TownSaveBridge` emits F13 triggers; F13 owns timers, writes, backups, and recovery.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `player_entered_town(session_player_id, region_id)` → F13 immediate save.
- `player_left_town(session_player_id, region_id)` → F13 flush request.
- `request_merchant_purchase(player_id, stock_id, item_id, transaction_id)` → atomic F06 mutation.
- `request_enter_dungeon(player_id, entrance_id)` → F01 transition policy/F04 barrier.
- `town_service_opened(player_id, service_id)` → F10 local viewport menu.

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

- Two players enter town in the same tick: two independent save queues.
- One player is in town while others fight: save schedule applies only to town player.
- Save write fails on entry: surface error and retain dirty data for retry.
- Merchant stock is exhausted by simultaneous requests: at most one sale.
- A player leaves town while a save is pending: flush or clearly report failure.

## 11. Development work packages

- [ ] **TW-01:** Create minimal town save zone and per-player tracking (M3).
- [ ] **TW-02:** Create modular town scene and safe spawn points.
- [ ] **TW-03:** Implement merchant service and transaction integration.
- [ ] **TW-04:** Integrate dungeon transitions and controller UI.
- [ ] **TW-05:** Validate save concurrency and full loop.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Town entry emits one immediate save per character.
- [ ] 30-second dirty interval and 2-second debounce work independently.
- [ ] Merchants cannot duplicate items or create negative currency.
- [ ] A vendor menu does not pause other local players.
- [ ] 2+2 hybrid group can split town/dungeon presence tracking without overwriting saves.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Minimal town region exists by M3 for persistence tests.
- [ ] M7 hub contains dungeon entrance, merchant, and safe return point.
- [ ] All four players can independently access town services and save.
- [ ] Save boundaries and merchant transactions pass failure tests.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F01, F04, F05, F06, F08, F10, F13. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **TW-01 — Create minimal town save zone and per-player tracking (M3)**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
