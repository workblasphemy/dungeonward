# DUNGEONWARD — Feature 01: Core Gameplay

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`../MASTER_BLUEPRINT.md`](../MASTER_BLUEPRINT.md) v0.2  
> **Milestones:** M3–M7  
> **Prerequisites/integration:** F04, F05, F09, F10, F13  
> **Engine:** Godot 4.x / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-01, ARCH-02, ARCH-03, ARCH-07, ARCH-08 **ACCEPTED** (2026-10-26). See [`../docs/adr/ADR-0001-foundational-architecture.md`](../docs/adr/ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`../docs/adr/ADR-0002-gameplay-design-v0.1.md`](../docs/adr/ADR-0002-gameplay-design-v0.1.md).

- **GAME-02 — Death and recovery:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items. **Integration:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.
- **GAME-04 — Party-majority dungeon transitions:** The party advances dungeon floors together after a majority vote of eligible active party members. **Integration:** F01/F03/F04 implement host-owned vote and synchronized transition barrier. Majority means strictly more than half of eligible voters. Eligible roster, vote timeout, ties, abstentions, and disconnected voters need explicit policies before coding.
- **GAME-06 — Simple v0.1 combat:** v0.1 includes basic attacks, spells, jumping, and a simple dodge. Complex parries, stamina-gated basic attacks, and advanced combo systems are not part of the required v0.1 combat scope. **Integration:** F02 actions and F14 default mappings; exact dodge cooldown/invulnerability, spell costs, and weapon timing remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Coordinate the town → dungeon → combat/exploration → rewards → return-to-town loop without duplicating responsibilities owned by specialist systems.

## 2. Locked requirements

1. First-person 3D classless dungeon-crawling hack-and-slash; combat remains simple and responsive.
2. One shared authoritative world session for 1–4 characters across local, online, or hybrid configurations.
3. Town is the primary safe hub; entering town initiates each arriving character's save.
4. Exploration, interaction, rewards, and level progression work in both solo and cooperative sessions.
5. World transitions use F04 readiness barriers and F03 floor descriptors; no gameplay actor spawns before F05 character approval.
6. Core flow never directly edits inventory, character saves, or combat damage; delegate to owning services.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Exact death gold penalty, respawn point, and invulnerability duration
- Return-to-town method (portal, stair, waypoint)
- Majority-vote eligibility, timeout, tie/abstention, and disconnect rules
- Optional quest objective tracking
- Respawn checkpoint behavior

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `RunContext` | run_id, seed, depth, difficulty_profile_id, party roster, world revision |
| `PlayerWorldState` | session_player_id, region_id, location, alive/downed status, interaction lock |
| `InteractableDefinition` | id, prompt, range, requirements, action_type |
| `WorldTransitionRequest` | transition_id, origin, destination, requesting players, policy |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `GameFlowCoordinator` finite state machine: TITLE → LOBBY → TOWN → LOADING → DUNGEON → RETURNING → TOWN.
- `WorldInteractionService` evaluates nearby interactables using host-side range and availability checks.
- `TransitionService` requests F04 world barriers; no direct scene changes from a player's button press.
- `RunStateService` holds dungeon depth, seed, run revision, and shared session flags.
- `PlayerLocationTracker` tracks per-character town/dungeon presence even when the v0.1 dungeon floor is shared.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `request_interact(session_player_id, target_id, action_id)` → host validation → result/event.
- `request_world_transition(session_player_id, destination)` → policy check → F04 barrier.
- `player_entered_town(session_player_id)` → F09 safe-zone verification → F13 immediate save.
- `run_started(run_context)`, `floor_completed(run_id, depth)`, `run_ended(reason)` signals.
- F03 returns a validated floor descriptor; F07 populates encounters; F08 grants rewards only through host-approved transactions.

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

- Two players interact with the same single-use door/chest simultaneously: process once with stable transaction ID.
- One player returns to town while another remains in dungeon: track locations independently; final transition policy is OPEN.
- Late join during floor load: defer actor activation until baseline synchronization completes.
- Player disconnects during transition: remove their readiness requirement safely; preserve confirmed character data.
- Interaction attempts against despawned or distant targets: reject without state mutation.

## 11. Development work packages

- [ ] **CG-01:** Implement game-flow states and world context DTOs.
- [ ] **CG-02:** Implement interaction detection and host validation.
- [ ] **CG-03:** Implement transition orchestration and player location tracking.
- [ ] **CG-04:** Connect town/dungeon/reward/progression services.
- [ ] **CG-05:** Run vertical-slice regression and failure tests.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Town → dungeon → town loop runs with one player and again with 2+2 hybrid players.
- [ ] Each player's town entry emits exactly one immediate save trigger; no duplicate triggers on overlapping zones.
- [ ] Stale transition acknowledgements do not activate wrong scenes.
- [ ] Shared interactables cannot grant duplicate rewards under simultaneous use.
- [ ] Existing players continue gameplay during local join and menu navigation.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Playable graybox loop with town, one floor, encounters, loot, return, and save.
- [ ] No unauthorized world transitions or duplicate interactions.
- [ ] All state changes are routed to owning feature services.
- [ ] Loop passes solo, four-local, four-online, and 2+2 hybrid smoke tests.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F04, F05, F09, F10, F13. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **CG-01 — Implement game-flow states and world context DTOs**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
