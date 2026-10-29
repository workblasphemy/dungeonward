# DUNGEONWARD — Feature 06: Inventory & Equipment

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M6–M7  
> **Prerequisites/integration:** F04, F05, F08, F10, F13  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-01, ARCH-05, ARCH-06, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-02 — Death and recovery:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items. **Integration:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.
- **GAME-03 — Personal instanced multiplayer loot:** Each eligible player receives personal instanced loot; there is no competition to pick up another player's drops. **Integration:** F08 reward authority generates player-scoped grants/visibility; F06 atomic inventory transactions. Eligibility, reward quantity, and optional trading remain OPEN.
- **GAME-08 — Slot-based grid inventory:** Use a slot-based grid inventory, not a weight-based or category-only inventory as the default v0.1 model. **Integration:** F06 grid-slot transaction schema and F10 controller-first grid UI. Dimensions, stack limits, equipment slots, and overflow policy remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Manage unique item instances in an approved slot-based grid, equipment slots, consumables, and host-validated transactions with controller-friendly presentation.

## 2. Locked requirements

1. Each character owns an independent inventory and equipment state.
2. Item instances have unique IDs; item definitions are immutable resources.
3. Equip, unequip, move, split, consume, drop, sell, and purchase are authoritative transactions.
4. Equipment modifies character effective stats through F05; combat reads equipped action definitions.
5. No item duplication from repeated requests, disconnects, or simultaneous pickup attempts.
6. Inventory and equipment changes mark the owning character dirty for F13 town autosaving.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Grid dimensions, item footprints, and controller grid-navigation behavior (grid layout approved)
- Inventory size/weight restrictions
- Stack limits and item durability
- Shared storage, trading, crafting, sorting
- Equipment slot taxonomy beyond weapon/armor/accessory

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `ItemDefinition` | definition_id, display name, type, equip slot, icon, base stats, tags |
| `ItemInstance` | instance_id, definition_id, rolled affixes, quantity, revision |
| `InventoryState` | character_id, slots, item IDs, currency, revision |
| `EquipmentState` | character_id, slot→item instance ID |
| `InventoryTransaction` | transaction_id, actor, operation, source/destination, expected revision |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `InventoryAuthority` validates all mutations on the host.
- `InventoryTransactionProcessor` applies operations atomically and idempotently.
- `EquipmentService` enforces slot compatibility and stat recalculation.
- `ItemRegistry` resolves approved definition IDs; no arbitrary resource loading from client payloads.
- `InventoryPresenter` (F10) is a per-local-player view of authoritative state.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `request_inventory_operation(session_player_id, operation, expected_revision, transaction_id)` → result.
- `request_equip(session_player_id, item_instance_id, equipment_slot)` → validated transaction.
- `inventory_changed(character_id, revision, delta)` → F10 UI and F13 dirty flag.
- `get_equipped_action_set(character_id)` → F02; `get_stat_modifiers(character_id)` → F05.
- F08 submits authoritative pickup/grant operations through the same transaction engine.

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

- Two pickup requests target same world item: only one grant succeeds.
- Client repeats purchase after timeout: transaction ID prevents double charge.
- Full inventory: reject or use approved overflow policy; never silently delete items.
- Unequipping when inventory full: atomic swap or explicit rejection.
- Disconnect mid-trade (if trading approved): rollback or durable commit with transaction log.

## 11. Development work packages

- [ ] **IN-01:** Define item definitions, instances, and inventory schemas.
- [ ] **IN-02:** Implement atomic transaction processor.
- [ ] **IN-03:** Implement equipment/stat integration.
- [ ] **IN-04:** Implement controller-first inventory UI.
- [ ] **IN-05:** Integrate loot, merchants, saves, and concurrency tests.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Equip/unequip round trip preserves item IDs and stats.
- [ ] Duplicate transaction IDs are applied at most once.
- [ ] Concurrent pickup attempts never duplicate an instance.
- [ ] Inventory revision mismatch is rejected and refreshed.
- [ ] Four players can browse inventories independently without global pause.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Starter weapons, armor, potions, and gold function end-to-end.
- [ ] Host enforces all item operations and emits revisioned deltas.
- [ ] Inventory survives save/reload with unique item IDs intact.
- [ ] Gamepad UI remains readable in four-way split-screen.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F04, F05, F08, F10, F13. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **IN-01 — Define item definitions, instances, and inventory schemas**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
