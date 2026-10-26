# DUNGEONWARD — Feature 02: Combat System

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`../MASTER_BLUEPRINT.md`](../MASTER_BLUEPRINT.md) v0.2  
> **Milestones:** M4–M7  
> **Prerequisites/integration:** F04, F05, F06, F07, F10, F11, F12, F14  
> **Engine:** Godot 4.x / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-01, ARCH-08 **ACCEPTED** (2026-10-26). See [`../docs/adr/ADR-0001-foundational-architecture.md`](../docs/adr/ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`../docs/adr/ADR-0002-gameplay-design-v0.1.md`](../docs/adr/ADR-0002-gameplay-design-v0.1.md).

- **GAME-01 — Four core attributes:** Strength, Dexterity, Vitality, Magic are the four core character attributes. No fifth core attribute (including Endurance) in v0.1. **Integration:** F05 stat schema, F02 damage formulas, F06 equipment modifiers; exact derived-stat coefficients remain OPEN.
- **GAME-02 — Death and recovery:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items. **Integration:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.
- **GAME-06 — Simple v0.1 combat:** v0.1 includes basic attacks, spells, jumping, and a simple dodge. Complex parries, stamina-gated basic attacks, and advanced combo systems are not part of the required v0.1 combat scope. **Integration:** F02 actions and F14 default mappings; exact dodge cooldown/invulnerability, spell costs, and weapon timing remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Provide satisfying, readable first-person melee, ranged, and magic actions with host-authoritative damage and reusable weapon/ability definitions.

## 2. Locked requirements

1. Simple hack-and-slash baseline with basic attacks, spells, jumping, and a simple dodge; stamina-gated attacks, complex parries, and Souls-like combat are not required.
2. Host validates attack intent, cooldown, equipment, range, line of sight, hit, damage, and death.
3. Melee weapon swings have authored timings and collision windows; no client-reported hit outcomes.
4. Support extensible melee/ranged/spell action definitions, even if the vertical slice only includes a small set.
5. Readable enemy tells, hit confirmation, impact audio/VFX, and gamepad-friendly controls.
6. Character attributes, difficulty, equipment, and enemy resistances feed one documented damage pipeline.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Blocking, parry, stagger, status effects, critical-hit formula, and dodge tuning (simple dodge is approved)
- Friendly fire
- Mana and spell taxonomy
- Combo chains and charge attacks
- Dual wielding

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `AttackDefinition` | attack_id, windup, active, recovery, range, arc, damage tags, resource cost |
| `WeaponActionSet` | primary/secondary action references, animation timings |
| `DamageContext` | attacker, defender, attack_id, roll seed, attributes, difficulty snapshot |
| `HitResult` | event_id, damage, mitigation, critical flag, killed flag |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `CombatController` consumes player intents from F04 and resolves allowed actions.
- `AttackStateMachine` tracks idle/windup/active/recovery/cancel states using authoritative ticks.
- `HitQueryService` uses ray/shape casts or validated overlap during active frames.
- `DamageResolver` is a pure deterministic function given validated inputs and seeded rolls.
- `HealthComponent` and `HurtboxComponent` compose into players/enemies; F11 receives cosmetic events.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `submit_attack_intent(session_player_id, action_slot, input_sequence)` → accepted/rejected.
- `resolve_hit(attacker_actor_id, target_actor_id, attack_id, tick)` → `HitResult`.
- `damage_applied(event_id, target_id, hp_before, hp_after)` replicated once.
- F06 supplies equipped action set; F05 supplies effective attributes; F12 supplies modifiers; F07 reacts to hit/death events.

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

- Double attack input during cooldown is ignored or buffered according to explicit policy.
- Targets moving out of range before active frame are not hit.
- Duplicate network attack event cannot apply damage twice.
- Client prediction may play a swing but must reconcile rejected attacks without granting damage.
- Friendly players and pets are filtered according to approved faction policy.

## 11. Development work packages

- [ ] **CB-01:** Define attacks, damage DTOs, and formula tests.
- [ ] **CB-02:** Implement attack state machine and hit queries.
- [ ] **CB-03:** Integrate host-authoritative networking.
- [ ] **CB-04:** Connect equipment, stats, enemies, and feedback.
- [ ] **CB-05:** Balance and latency regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Identical damage contexts yield reproducible results with a fixed seed.
- [ ] Cooldown, attack range, and resource-cost checks reject invalid intents.
- [ ] Two players striking one enemy simultaneously produce one consistent death event.
- [ ] Host rejects forged client damage and forged target IDs.
- [ ] Basic melee remains responsive at simulated 150 ms latency.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] At least two melee weapons and one ranged/magic prototype share a data-driven pipeline.
- [ ] Host-owned health/death and replicated feedback work in hybrid sessions.
- [ ] Attack timing and hit queries are testable without animation assets.
- [ ] No double damage from duplicate events.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F04, F05, F06, F07, F10, F11, F12, F14. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **CB-01 — Define attacks, damage DTOs, and formula tests**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
