# DUNGEONWARD — Feature 12: Difficulty & Scaling

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M5–M7  
> **Prerequisites/integration:** F03, F04, F05, F07, F08  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-01, ARCH-02, ARCH-07 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-07 — Difficulty and rewards:** Offer four difficulty presets, bounded custom sliders, and modest capped reward bonuses tied to approved difficulty settings. **Integration:** F12 versioned profile and caps, F08 reward multiplier integration. Preset names, exact caps and reward curve remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Make challenge configurable and predictable across dungeon depth and party size, affecting encounter behavior and composition—not merely enemy HP.

## 2. Locked requirements

1. Host chooses authoritative difficulty profile for the shared run.
2. Provide **four** named presets and bounded custom sliders for enemy health, damage, density, aggression, elite frequency, and **modest capped reward bonuses**.
3. Party-size scaling is independent of difficulty preset and dungeon-depth scaling.
4. Scaling modifies encounter budgets/spawns as well as enemy statistics.
5. All peers receive a versioned difficulty snapshot; clients cannot independently change combat difficulty.
6. Avoid silently changing already-spawned enemies when party size changes unless explicitly approved.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Four preset names (Story/Casual naming remains OPEN)
- Exact multiplier values and caps
- Friendly fire, permadeath, healing and stamina modifiers
- Dynamic adaptive difficulty
- Exact modest reward multiplier formula and cap (capped bonuses approved)

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `DifficultyProfile` | id, preset label, HP/damage/density/aggression/elite/reward multipliers |
| `DifficultyOverride` | field→bounded value, schema version |
| `PartyScalingProfile` | count→HP/count/elite factors |
| `DepthScalingProfile` | depth curve parameters and caps |
| `RunDifficultySnapshot` | profile, overrides, party count, depth, revision, effective values |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `DifficultyResolver` combines base enemy stats × preset × depth × party factors in a documented order.
- `EncounterBudgetResolver` computes spawn count/type budgets with deterministic caps.
- `DifficultyValidator` clamps custom sliders and rejects invalid/negative/NaN values.
- `RunDifficultyAuthority` locks or revises the run profile under explicit host rules.
- `DifficultyPreviewPresenter` displays resulting values and reward policy in F10.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `resolve_enemy_stats(enemy_definition, depth, active_party_size, run_profile)` → scaled stats.
- `resolve_encounter_budget(room, depth, party_size, run_profile)` → spawn plan constraints.
- `request_difficulty_change(host_session_player_id, overrides)` → host-approved revision.
- `active_party_size_changed(count, revision)` from F04 updates future encounter generation.
- `get_reward_multiplier(context)` → F08, only if reward scaling approved.

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

- A fourth player joins mid-fight: existing enemies retain current HP; future spawns use updated party size.
- Custom sliders exceed limits: clamp and show final applied values.
- Difficulty changes during dungeon run: reject or defer to next floor (policy OPEN).
- Extreme density exceeds navigation/performance cap: enforce hard spawn budget.
- Party size zero during disconnect transition: no divide-by-zero; suspend spawns.

## 11. Development work packages

- [ ] **DF-01:** Define profiles, modifier ranges, and composition order.
- [ ] **DF-02:** Implement pure stat and encounter resolvers.
- [ ] **DF-03:** Integrate host configuration and party-size updates.
- [ ] **DF-04:** Implement controller-first difficulty UI.
- [ ] **DF-05:** Run balancing and edge-case regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Difficulty and party-size multipliers compose in documented order.
- [ ] Preset + custom override serialization is deterministic.
- [ ] Changing party size updates future encounter budgets, not existing enemy health.
- [ ] No negative HP, spawn counts, or unbounded enemy density.
- [ ] Host difficulty revision matches all connected peers.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] At least four presets plus bounded custom sliders work.
- [ ] Enemy HP/damage AND encounter count/composition respond to settings.
- [ ] Party/depth scaling and reward policy are visible and tested.
- [ ] 2+2 hybrid changes do not cause inconsistent difficulty.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F03, F04, F05, F07, F08. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **DF-01 — Define profiles, modifier ranges, and composition order**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
