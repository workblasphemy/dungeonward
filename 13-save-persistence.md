# DUNGEONWARD — Feature 13: Save & Persistence

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M3–M7  
> **Prerequisites/integration:** F04, F05, F06, F09, F10  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-05, ARCH-06, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-01 — Four core attributes:** Strength, Dexterity, Vitality, Magic are the four core character attributes. No fifth core attribute (including Endurance) in v0.1. **Integration:** F05 stat schema, F02 damage formulas, F06 equipment modifiers; exact derived-stat coefficients remain OPEN.
- **GAME-02 — Death and recovery:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items. **Integration:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.
- **GAME-05 — Persistent couch profiles:** Couch co-op uses separate local owner profiles; guest characters persist across sessions instead of being temporary. **Integration:** F05 local profile registry and character UUIDs; F13 profile-isolated save directories. Guest export, migration, profile deletion, and account linking remain OPEN.
- **GAME-08 — Slot-based grid inventory:** Use a slot-based grid inventory, not a weight-based or category-only inventory as the default v0.1 model. **Integration:** F06 grid-slot transaction schema and F10 controller-first grid UI. Dimensions, stack limits, equipment slots, and overflow policy remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Reliably persist independent character progress and recover from interrupted writes, disconnects, incompatible versions, and stale network snapshots.

## 2. Locked requirements

1. Each character independently persists identity, attributes, XP, health/mana, inventory, equipment, gold, and progression.
2. On entering town: immediate per-character save.
3. While in town: save dirty state every 30 seconds and debounce changes by approximately 2 seconds.
4. On leaving town or normal shutdown: flush pending writes where possible.
5. Write to `user://` with explicit versioned schema, validated data, atomic replacement where supported, and known-good backup.
6. Per-character save queues are serialized and monotonic; stale revisions never overwrite newer state.
7. Owning device stores its character save; host validates gameplay changes and supplies revisioned snapshots.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Cloud sync and cross-device account transfer
- Manual save/quick save anywhere
- Dungeon-session restoration
- Save encryption or signed server attestation
- Guest-profile export/import UI

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `CharacterSaveEnvelope` | schema_version, character_id, owner_profile_id, revision, timestamp, checksum |
| `CharacterSavePayload` | stats, level/XP, HP/mana, item instances, equipment, gold, progression |
| `SaveRequest` | character_id, reason, authoritative_revision, snapshot |
| `SaveResult` | character_id, revision, success/error code, backup status |
| `MigrationStep` | from_version, to_version, transform function |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `CharacterSaveRepository` resolves profile-isolated paths and loads/writes validated DTOs.
- `SaveScheduler` tracks town presence, dirty flags, immediate entry saves, 2-second debounce, and 30-second dirty interval per character.
- `SaveWriteQueue` serializes writes by character ID and coalesces superseded revisions.
- `SaveMigrator` upgrades supported older schemas without mutating originals before backup.
- `SaveRecoveryService` checks checksum/schema, attempts backup restore, and reports errors to F10.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `mark_character_dirty(character_id, revision)` → schedule if in town.
- `on_town_enter(character_id)` → immediate save request.
- `on_town_exit(character_id)` → bounded flush request.
- `submit_authoritative_snapshot(character_id, revision, payload)` → validate ownership and monotonicity.
- `save_completed(character_id, revision)` / `save_failed(character_id, reason)` → UI and F04 ack.

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

- Two players on same PC save simultaneously: separate queues and paths.
- Newer revision arrives while old write runs: finish safely, then write latest; never regress.
- Power loss during replacement: recover from backup/temp state on next load.
- Disk full or permission denied: retain dirty data, show error, avoid false success.
- Host crashes after loot but before owner ack: preserve last confirmed save; reconcile explicitly.
- Corrupt/malformed save or unknown schema: reject and offer recovery; never silently erase.

## 11. Development work packages

- [ ] **SV-01:** Define versioned save DTO and per-profile paths.
- [ ] **SV-02:** Implement atomic repository, backups, and migrations.
- [ ] **SV-03:** Implement per-character dirty scheduler and town triggers.
- [ ] **SV-04:** Integrate host snapshot revisions and acknowledgements.
- [ ] **SV-05:** Fault-injection, multi-character, and migration regression.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Round-trip save/load reproduces all required fields and item instance IDs.
- [ ] Town entry, 2-second debounce, and 30-second dirty interval fire independently.
- [ ] Four simultaneous saves never mix character data.
- [ ] Interrupted write restores valid primary/backup and reports status.
- [ ] Stale revisions are rejected; migration tests cover every supported schema.
- [ ] Disconnect during save does not claim success without an ack.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] Four independent characters survive restart with full required progression.
- [ ] Town autosave timing and exit flush work in solo/local/hybrid.
- [ ] Atomic writes, backups, validation, and migrations are tested.
- [ ] All save failures are visible and retryable without silent data loss.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F04, F05, F06, F09, F10. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **SV-01 — Define versioned save DTO and per-profile paths**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
