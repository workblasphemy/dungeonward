# DUNGEONWARD — Feature 03: Procedural Dungeon Generation

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M5–M7  
> **Prerequisites/integration:** F01, F04, F07, F09, F12  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-01, ARCH-07, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-04 — Party-majority dungeon transitions:** The party advances dungeon floors together after a majority vote of eligible active party members. **Integration:** F01/F03/F04 implement host-owned vote and synchronized transition barrier. Majority means strictly more than half of eligible voters. Eligible roster, vote timeout, ties, abstentions, and disconnected voters need explicit policies before coding.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Generate reproducible, connected, traversable dungeon floors from reusable low-poly room modules, with host-owned mutable state.

## 2. Locked requirements

1. Seeded procedural floor layouts with generator version and profile identity.
2. Host determines canonical layout; clients receive descriptor and mutable state, not just a seed.
3. Every generated floor has a valid entrance, exit/stairs, traversable connectivity, and safe spawn positions.
4. Use modular authored rooms/corridors with compatible door sockets and biome tags.
5. Enemy and loot placements are driven by validated encounter/loot budgets.
6. Vertical slice targets one stone dungeon biome and approximately 6–10 rooms per floor.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Multi-level rooms, puzzles, traps, secret rooms, biome transitions
- Branch density and dead-end rewards
- Procedural lighting variations
- Room-specific scripted events

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `DungeonGenerationProfile` | generator_version, biome, room_count, branch budget, encounter budget |
| `RoomDefinition` | scene_id, footprint, socket transforms/types, tags, weight, bounds |
| `FloorDescriptor` | seed, version, graph nodes/edges, transforms, exit node, layout hash |
| `FloorMutableState` | opened containers, doors, defeated enemies, collected pickups, revision |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `DungeonGraphBuilder` creates abstract room topology from a seeded RNG.
- `RoomPlacementSolver` matches compatible sockets and rejects geometry overlaps.
- `DungeonValidator` checks graph connectivity, spawn/exit reachability, socket alignment, and collision/navmesh readiness.
- `DungeonInstantiator` loads room scenes from approved IDs; never arbitrary client paths.
- `FloorStateAuthority` owns mutable objects; F04 distributes baseline and durable events.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `generate_floor(seed, depth, profile_id, generator_version)` → `FloorDescriptor | Error`.
- `validate_floor(descriptor)` → diagnostics; invalid results retry deterministically with bounded attempts.
- `floor_ready(descriptor, mutable_state)` signals F04 barrier.
- `get_spawn_markers(tags, count)` feeds F07/F08 placement; F12 supplies encounter budgets.

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

- No valid exit path: reject seed candidate and retry with recorded attempt index.
- Room overlap or incompatible sockets: reject placement; never create inaccessible content.
- A client has different generator version: reject/upgrade instead of rendering mismatched layout.
- Late join after chest opens: apply mutable state baseline before activation.
- Party transition occurs during enemy death/pickup: snapshot transaction revision first.

## 11. Development work packages

- [ ] **DG-01:** Define room sockets, profiles, and graph DTOs.
- [ ] **DG-02:** Implement seeded graph and placement solver.
- [ ] **DG-03:** Implement connectivity/geometry validators.
- [ ] **DG-04:** Instantiate rooms and host mutable state.
- [ ] **DG-05:** Integrate enemies, difficulty, networking, and seed regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Generate and validate at least 1,000 fixed seeds per profile in headless tests.
- [ ] Same seed/profile/version yields identical logical graph/hash.
- [ ] Entrance connects to exit and all required rooms; no overlapping bounds.
- [ ] Mutable state survives late join and return transitions.
- [ ] Four-player spawn positions are collision-safe and navigable.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] One biome with reusable rooms generates reliable 6–10-room floors.
- [ ] Seed regression corpus and failure diagnostics are committed.
- [ ] Host and clients share consistent layout and mutable state.
- [ ] No known unreachable mandatory room or invalid exit.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F01, F04, F07, F09, F12. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **DG-01 — Define room sockets, profiles, and graph DTOs**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
