# DUNGEONWARD — Feature 05: Character System

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M1–M3, M7  
> **Prerequisites/integration:** F04, F10, F13, F14  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-02, ARCH-03, ARCH-05, ARCH-06, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-01 — Four core attributes:** Strength, Dexterity, Vitality, Magic are the four core character attributes. No fifth core attribute (including Endurance) in v0.1. **Integration:** F05 stat schema, F02 damage formulas, F06 equipment modifiers; exact derived-stat coefficients remain OPEN.
- **GAME-02 — Death and recovery:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items. **Integration:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.
- **GAME-05 — Persistent couch profiles:** Couch co-op uses separate local owner profiles; guest characters persist across sessions instead of being temporary. **Integration:** F05 local profile registry and character UUIDs; F13 profile-isolated save directories. Guest export, migration, profile deletion, and account linking remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Create, select, identify, spawn, and progress classless persistent characters while enforcing one active use per character.

## 2. Locked requirements

1. Every player must select or create a character before entering the world.
2. Each character has a stable UUID, owner profile, name/appearance choices, level, XP, attributes, health/mana, and progression.
3. Characters remain portable across solo, couch, online, and hybrid modes, subject to ownership/compatibility policy.
4. No character may occupy two active or reserved multiplayer slots simultaneously.
5. Classless progression; weapon and spell access are not permanently restricted by class selection.
6. F13 persists independent character records; host validates in-session progression and spawn state.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Exact formulas for approved Strength/Dexterity/Vitality/Magic attributes (no fifth core stat)
- Respec costs and rules
- Appearance customization depth
- Level cap, XP curve, attribute points per level
- Character deletion/recovery policy

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `CharacterProfile` | character_id, owner_profile_id, name, cosmetic_ids, creation_version |
| `CharacterProgression` | level, xp, unspent_points, attribute allocations, unlocks |
| `EffectiveStats` | base attributes, equipment modifiers, temporary modifiers, derived health/mana |
| `CharacterSelectionRequest` | reservation_token, character_id, schema_version, save_revision |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `CharacterRepository` lists/creates local profiles without touching world scenes.
- `CharacterCreationService` validates names, cosmetic IDs, starting allocations, and UUIDs.
- `CharacterProgressionService` computes XP thresholds and applies level-ups on host.
- `StatCalculator` is a pure function with ordered modifier phases.
- `CharacterJoinService` (F04 integration) validates selection and gates actor spawn.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `create_character(owner_profile_id, draft)` → validated `CharacterProfile`.
- `select_character(local_slot_id, character_id)` → F04 reservation approval → spawn request.
- `grant_xp(session_player_id, amount, event_id)` → host validates and applies once.
- `compute_effective_stats(character, equipment, buffs)` → immutable snapshot.
- `character_changed(character_id, revision)` → F13 dirty-save scheduling.

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

- A player selects a character already active on another local controller: reject with a clear prompt.
- Save schema incompatible: show recovery/migration UI before spawn.
- Disconnect during character selection: expire reservation without creating ghost actor.
- Two simultaneous XP events: unique event IDs and monotonic progression revision.
- Invalid character name or missing cosmetic asset: sanitize/fallback without corrupting save.

## 11. Development work packages

- [ ] **CH-01:** Define character schema and ownership IDs.
- [ ] **CH-02:** Implement creation/selection and validation.
- [ ] **CH-03:** Implement stats, XP, and progression.
- [ ] **CH-04:** Integrate multiplayer spawn gate and persistence.
- [ ] **CH-05:** Test four-profile and migration edge cases.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Character creation produces unique stable IDs and valid starting state.
- [ ] A selected character cannot be selected again in the same session.
- [ ] Progression formula and attribute derivation are deterministic.
- [ ] Character profiles load independently for four couch players.
- [ ] Character selection always precedes spawn in local, online, and hybrid flows.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Character creator/selector works with gamepad and keyboard/mouse.
- [ ] Four unique characters can join and progress independently.
- [ ] Classless stats/XP are data-driven and save-compatible.
- [ ] Duplicate character activation is impossible within session rules.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F04, F10, F13, F14. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **CH-01 — Define character schema and ownership IDs**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
