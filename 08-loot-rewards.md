# DUNGEONWARD — Feature 08: Loot & Reward System

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M6–M7  
> **Prerequisites/integration:** F02, F04, F05, F06, F07, F12, F13  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-01, ARCH-05, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-03 — Personal instanced multiplayer loot:** Each eligible player receives personal instanced loot; there is no competition to pick up another player's drops. **Integration:** F08 reward authority generates player-scoped grants/visibility; F06 atomic inventory transactions. Eligibility, reward quantity, and optional trading remain OPEN.
- **GAME-07 — Difficulty and rewards:** Offer four difficulty presets, bounded custom sliders, and modest capped reward bonuses tied to approved difficulty settings. **Integration:** F12 versioned profile and caps, F08 reward multiplier integration. Preset names, exact caps and reward curve remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Create satisfying randomized rewards while maintaining reproducible rolls, fair ownership rules, and item-transaction integrity.

## 2. Locked requirements

1. Host alone rolls drops, awards gold/XP, and authorizes world pickup.
2. Loot definitions are data-driven with weighted tables, rarity tiers, and optional affix pools.
3. Unique item instance IDs are assigned once and persisted via F06/F13.
4. Reward results respond to enemy tier, dungeon depth, and approved difficulty modifiers.
5. Every reward grant is idempotent and logged by source event/transaction ID.
6. Default multiplayer loot ownership is **personal instanced loot**, approved in GAME-03; eligibility and trading details remain OPEN.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Exact rarity tier names/colors and probabilities
- Personal-loot eligibility, per-player roll quantity, and instanced chest behavior (personal instancing approved)
- Trading and binding rules
- Pity systems, treasure rooms, set items
- Difficulty reward multipliers

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `LootTableDefinition` | table_id, weighted entries, eligibility, roll count |
| `RarityProfile` | rarity_id, weight, affix budget, UI style |
| `AffixDefinition` | affix_id, eligible item tags, stat modifiers, ranges |
| `LootRollContext` | run seed, enemy ID, event ID, depth, difficulty snapshot |
| `WorldLootInstance` | world_loot_id, item_instance_id, ownership policy, claimed revision |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `LootRoller` is a pure seeded weighted sampler with validated table weights.
- `RewardAuthority` translates enemy/chest/quest events into reward transactions.
- `WorldLootService` owns spawned pickups, visibility, ownership, and single-claim state.
- `AffixGenerator` applies eligible modifiers to item instances with bounded rolls.
- F06 performs the atomic grant; F13 persists resulting character revision.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `roll_loot(table_id, context)` → immutable reward proposal.
- `spawn_world_loot(source_event_id, reward_proposal)` → world loot IDs.
- `request_pickup(session_player_id, world_loot_id, transaction_id)` → host grant/reject.
- `grant_xp_gold(session_player_id, source_event_id, amounts)` → F05/F06 once.
- F12 supplies validated reward scaling; no client can choose roll seeds or results.

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

- Two players pick up same shared item: one successful authoritative claim.
- Full inventory: retain pickup in world or approved overflow; no silent loss.
- Late join: receive claimed/unclaimed world loot baseline.
- Network retry after successful pickup: return same transaction result, never reroll.
- Malformed zero/negative loot weights: reject at content validation.

## 11. Development work packages

- [ ] **LT-01:** Define loot/rarity/affix schemas and validator.
- [ ] **LT-02:** Implement seeded rolls and reward authority.
- [ ] **LT-03:** Implement world loot ownership and pickup.
- [ ] **LT-04:** Integrate inventory, XP, difficulty, UI, and persistence.
- [ ] **LT-05:** Run statistical and concurrency regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Fixed seed and context reproduce exact loot roll.
- [ ] Loot tables produce only eligible item definitions and affixes.
- [ ] Duplicate source events do not award twice.
- [ ] Simultaneous pickup race yields at most one item grant.
- [ ] Four-player save/reload preserves unique rolled item stats.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Enemy kills and chests produce reproducible gold/items.
- [ ] Rarity and affix generation use editable resources.
- [ ] Multiplayer ownership policy is documented and enforced.
- [ ] No known duplication from retries, disconnects, or late joins.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F02, F04, F05, F06, F07, F12, F13. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **LT-01 — Define loot/rarity/affix schemas and validator**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
