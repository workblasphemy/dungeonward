# DUNGEONWARD — Feature 07: Enemy System & AI

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`../MASTER_BLUEPRINT.md`](../MASTER_BLUEPRINT.md) v0.2  
> **Milestones:** M4–M5, M7  
> **Prerequisites/integration:** F02, F03, F04, F11, F12  
> **Engine:** Godot 4.x / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-01, ARCH-07, ARCH-08 **ACCEPTED** (2026-10-26). See [`../docs/adr/ADR-0001-foundational-architecture.md`](../docs/adr/ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`../docs/adr/ADR-0002-gameplay-design-v0.1.md`](../docs/adr/ADR-0002-gameplay-design-v0.1.md).

- **GAME-06 — Simple v0.1 combat:** v0.1 includes basic attacks, spells, jumping, and a simple dodge. Complex parries, stamina-gated basic attacks, and advanced combo systems are not part of the required v0.1 combat scope. **Integration:** F02 actions and F14 default mappings; exact dodge cooldown/invulnerability, spell costs, and weapon timing remain OPEN.
- **GAME-07 — Difficulty and rewards:** Offer four difficulty presets, bounded custom sliders, and modest capped reward bonuses tied to approved difficulty settings. **Integration:** F12 versioned profile and caps, F08 reward multiplier integration. Preset names, exact caps and reward curve remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Provide reusable host-simulated enemies with clear behaviors, combat tells, navigation, encounter roles, and data-driven variants.

## 2. Locked requirements

1. Enemy AI runs on the authoritative host only.
2. Enemies use reusable definitions, health/hurtbox/combat components, and explicit behavior states.
3. First vertical slice includes at least three enemy archetypes with distinct readable behavior.
4. Enemies use navigation and leash/reset rules to avoid permanently trapping or losing the player.
5. Encounter composition responds to dungeon depth, difficulty, and party-size scaling.
6. Clients receive replicated transforms, animation state, combat events, and death outcomes.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Elite affixes, boss phases, summoning, status effects
- Advanced coordinated squad tactics
- Respawn timers
- Aggro persistence across floors
- Enemy friendly fire

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `EnemyDefinition` | enemy_id, scene_id, level band, base stats, movement, attack set, tags |
| `EnemyBehaviorProfile` | detection range, attack range, cooldowns, retreat/leash thresholds |
| `EnemySpawnRequest` | spawn_marker_id, archetype_id, scaled stats, run revision |
| `EnemyRuntimeState` | actor ID, HP, state, target, position, AI tick, death revision |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `EnemySpawner` accepts host-approved encounter plans from F03/F12.
- `EnemyBrain` uses a small state machine: IDLE → ALERT → CHASE → ATTACK → RECOVER → CHASE/RETURN → DEAD.
- `TargetSelector` chooses valid player targets using distance, line of sight, threat rules.
- `NavigationAgent3D` handles path following; invalid path triggers bounded recovery.
- `EnemyReplicationPresenter` animates client ghosts without running authoritative AI.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `spawn_encounter(encounter_descriptor)` → host actor IDs.
- `select_target(enemy_id, visible_players)` → session player ID or none.
- `request_enemy_attack(enemy_id, attack_id)` → F02 authoritative resolver.
- `enemy_died(enemy_id, killer_credit, event_id)` → F08 reward request once.
- `party_size_changed(count, revision)` → F12 future encounter tuning.

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

- Target disconnects mid-chase: choose new valid target or return.
- Navigation path becomes invalid after door changes: recalculate or recover.
- Two lethal hits arrive same tick: one death and one loot event.
- Enemy despawns while a client interpolates: reliable despawn clears ghost.
- Four-player aggro should not target a character still selecting/spawning.

## 11. Development work packages

- [ ] **AI-01:** Define enemy resources and actor components.
- [ ] **AI-02:** Implement behavior state machine and targeting.
- [ ] **AI-03:** Integrate navigation, attacks, and death.
- [ ] **AI-04:** Integrate encounter spawns, scaling, and replication.
- [ ] **AI-05:** Profile 4-player enemy loads and regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] State transitions respect detection, chase, attack, and leash rules.
- [ ] Host-only AI does not duplicate enemy actions on clients.
- [ ] Enemy death generates one reward event.
- [ ] Enemy targets only approved active actors.
- [ ] Three enemy archetypes function under 2+2 hybrid play.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Three distinct enemies with clear tells and functional pathfinding.
- [ ] Data-only addition of a new enemy archetype is documented.
- [ ] Host authority and replication pass latency tests.
- [ ] Encounter density scales without breaking navigation/performance.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F02, F03, F04, F11, F12. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **AI-01 — Define enemy resources and actor components**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
