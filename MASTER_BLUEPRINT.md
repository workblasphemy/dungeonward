# DUNGEONWARD — Master Development Blueprint

> Status: Preproduction specification v0.5 — architecture/gameplay approved; foundation implementation specification added  
> Engine: Godot 4.7.2 (GDScript; selected target, binaries to be verified)  
> Target: Windows and Linux functional by M3; gamepad-first, keyboard/mouse compatible  
> Genre: Stylized low-poly first-person, classless dungeon-crawling action RPG  
> Players: 1–4 per lobby, local split-screen, online, or hybrid  
> Source of truth: This document governs cross-feature architecture. Individual feature specifications elaborate without overriding it.

## Foundation implementation plan

The project owner selected **Godot 4.7.2**, **GitHub** source control, and **Windows + Linux** as required functional platforms by the end of **M3**. Development and testing span the owner's Windows PC and DeepSeek's Linux workspace; DeepSeek may also run local PC tests where explicitly permitted. Test execution must produce verifiable logs and version/OS/commit metadata; no test is considered passed solely on an agent's assertion.

**Implementation source:** [`FOUNDATION_IMPLEMENTATION_SPEC.md`](FOUNDATION_IMPLEMENTATION_SPEC.md) defines M0–M3 DTOs, lobby reservations, RPC validation, session/device lifecycles, test strategy, and platform acceptance. Its proposed defaults are implementation details, **not** additional gameplay approvals. GitHub repository URL and availability of the exact engine build remain to be verified.

## Architecture approval record

**ACCEPTED (2026-10-26):** ARCH-01 through ARCH-08, documented in [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). These contracts govern F01–F14. Eight gameplay choices are also **ACCEPTED** under [ADR-0002](ADR-0002-gameplay-design-v0.1.md); only decisions not explicitly approved remain **OPEN**.

| ID | Accepted contract |
|---|---|
| ARCH-01 | Host-authoritative ENet |
| ARCH-02 | Four character slots |
| ARCH-03 | Mandatory character selection |
| ARCH-04 | Independent input and UI |
| ARCH-05 | Persistent character ownership |
| ARCH-06 | Town-based autosaving |
| ARCH-07 | Shared dungeon simulation |
| ARCH-08 | Modular Godot architecture |

## Approved gameplay decisions (ADR-0002)

**ACCEPTED (2026-10-26):**

| ID | Approved v0.1 design |
|---|---|
| GAME-01 | Strength, Dexterity, Vitality, Magic are the four core character attributes. No fifth core attribute (including Endurance) in v0.1. |
| GAME-02 | On death, the character respawns with a modest gold penalty and retains all equipped and carried items. |
| GAME-03 | Each eligible player receives personal instanced loot; there is no competition to pick up another player's drops. |
| GAME-04 | The party advances dungeon floors together after a majority vote of eligible active party members. |
| GAME-05 | Couch co-op uses separate local owner profiles; guest characters persist across sessions instead of being temporary. |
| GAME-06 | v0.1 includes basic attacks, spells, jumping, and a simple dodge. Complex parries, stamina-gated basic attacks, and advanced combo systems are not part of the required v0.1 combat scope. |
| GAME-07 | Offer four difficulty presets, bounded custom sliders, and modest capped reward bonuses tied to approved difficulty settings. |
| GAME-08 | Use a slot-based grid inventory, not a weight-based or category-only inventory as the default v0.1 model. |

**Boundaries:** Approval does not set numeric formulas, gold-loss rates, voting timeout/eligibility, loot eligibility/trading, inventory dimensions, or reward caps. Those remain OPEN until separately specified.

## 1. Product vision

Create an original fantasy dungeon crawler inspired by the rewarding town–dungeon–loot–upgrade loop of WildTangent's FATE. Combat is straightforward, fast, and satisfying rather than a mandatory stamina/parry-heavy Souls-like system. Dungeons are seeded and procedural; equipment and character growth provide long-term replayability. The game must remain enjoyable alone and with any combination of up to four local and remote players.

**Originality boundary:** Create original names, worldbuilding, art, music, interface assets, and content. Reference FATE's broad design ideas rather than copying protected assets or expression.

### Non-negotiable requirements

1. First-person 3D action gameplay, stylized low-poly visuals.
2. Classless character progression and varied equipment/loot.
3. Procedurally generated dungeon floors with reliable traversal and escalating depth.
4. Up to **four player characters total** in one lobby, across local, online, or hybrid arrangements.
5. Local players join seamlessly during play: unassigned controller presses **Start twice**, then selects or creates a character; no character spawns before selection/creation succeeds.
6. Controller-first controls and **fully gamepad-navigable** menus, character creator, inventory, vendors, and settings; keyboard/mouse also supported.
7. Host-configurable difficulty presets and granular modifiers that affect enemy base statistics **and encounter generation**, with independent party-size scaling.
8. Every character's health, stats, inventory, equipment, gold, and progression autosave on entering town and while in town, independently of other players.
9. Data-driven, modular systems, with tests and documented interfaces.

## 2. Experience pillars

- **A compelling loop:** prepare in town → descend → explore/fight → earn loot and XP → return → save and upgrade → repeat.
- **Easy to play together:** couch drop-in/out, online join, and hybrid sessions are first-class, not later patches.
- **Readable action:** distinct weapon feedback, clear enemy tells, accessible UI at quarter-screen size.
- **Endless variation, controlled fairness:** procedural layouts and encounters must be completable and reproducible.
- **Reliable ownership:** persistent characters and items must survive routine restarts, disconnects, and version changes.

## 3. Approved scope versus proposals

**Approved:** simple hack-and-slash; seeded procedural floors; classless progression; multiplayer modes; two-press Start joining; character selection requirement; town autosave; difficulty customization; full controller support.

**Approved gameplay scope (ADR-0002):** four attributes (Strength, Dexterity, Vitality, Magic); death respawn with modest gold penalty and all equipment retained; personal instanced loot; party-majority floor transitions; persistent local guest profiles; basic attacks/spells/jump/simple dodge; four difficulty presets plus bounded custom sliders and capped modest reward bonuses; slot-based grid inventory.

**Still proposed / OPEN:** exact attribute formulas; gold penalty amount and respawn location; loot eligibility/trading; voting eligibility/timing/ties; guest export; spell/dodge tuning; difficulty names/numeric bounds; grid dimensions/stacking; blocking/parrying and stamina systems; crafting; pets; quests; biome count; public matchmaking; voice chat; cloud sync; cross-platform release; dedicated servers; simultaneous different dungeon floors; permanent death. Concept sheets remain non-binding visual references.

**Approved v0.1 architecture:** one shared active dungeon floor per party; direct-IP/LAN ENet peer-hosted sessions; host-authoritative world simulation. **Still working gameplay defaults:** one stone dungeon biome; individual character progression; no required stamina for basic attacks; four approved core attributes (Strength, Dexterity, Vitality, Magic); no cloud service dependency.

## 4. System catalog and planned feature documents

| ID | Feature | Planned file | Core responsibility |
|---|---|---|---|
| F01 | Core Gameplay | `01-core-gameplay.md` | Game loop, interaction, transitions |
| F02 | Combat System | `02-combat.md` | Attacks, damage, hit feedback, abilities |
| F03 | Procedural Dungeon Generation | `03-dungeon-generation.md` | Layouts, rooms, connectivity, floor state |
| F04 | Multiplayer System | `04-multiplayer.md` | Lobbies, authority, hybrid sessions, joins |
| F05 | Character System | `05-character-system.md` | Creation, stats, levels, identity |
| F06 | Inventory & Equipment | `06-inventory-equipment.md` | Inventory, slots, item operations |
| F07 | Enemy System & AI | `07-enemy-ai.md` | Enemy behaviors, spawn integration |
| F08 | Loot & Reward System | `08-loot-rewards.md` | Drops, rarities, affixes, rewards |
| F09 | Town & Hub System | `09-town-hub.md` | Safe hub, services, save boundaries |
| F10 | UI & Menu System | `10-ui-menus.md` | HUD, navigation, menus, split-screen UI |
| F11 | Audio, Visuals & Immersion | `11-audio-visuals.md` | Style, audio, VFX, performance |
| F12 | Difficulty & Scaling | `12-difficulty-scaling.md` | Presets, modifiers, encounter budgets |
| F13 | Save & Persistence | `13-save-persistence.md` | Character saves, migration, recovery |
| F14 | Controller & Input | `14-controller-input.md` | Device routing, remapping, join gesture |

Feature documents should follow: **Purpose → Locked requirements → Out-of-scope → Data/resources → Scenes/services → API/contracts → Network authority → Persistence → UI/input → Edge cases → Tests → Acceptance criteria → Dependencies**.

## 5. Architecture principles

1. **Peer is not player.** One network connection can own 1–4 local character slots; lobby maximum is four characters, not four peers.
2. **Player identity is layered.** `peer_id` (connection), `local_slot_id` (input/view on that machine), `session_player_id` (unique in lobby), `character_id` (persistent owner-specific character) are distinct.
3. **Server/host authoritative gameplay.** The host decides enemy AI, damage, spawn results, world item pickup, currency changes, and dungeon state. Clients submit intent, not authoritative outcomes.
4. **Presentation is local.** Split-screen viewports, HUDs, and controller prompts belong to local player slots, not replicated game state.
5. **Resources describe content.** Godot custom `Resource` types define weapons, enemies, items, loot tables, rooms, spells, and difficulty profiles; scenes implement visuals and behaviors.
6. **Composition over inheritance.** Actors use reusable health, stats, hurtbox, combat, inventory, and interaction components.
7. **Deterministic generation.** Seed + generator version + profile yield a reproducible logical layout. The host remains authoritative over mutable floor state.
8. **Save schemas are versioned.** Never serialize live scene trees as the primary save format. Use explicit validated data transfer objects and migrations.
9. **Avoid global-state sprawl.** Autoloads handle stable services; scene-owned controllers manage local world and UI lifecycles.
10. **All critical operations are testable.** Core logic is separable from rendering and input hardware.

## 6. Proposed repository layout

```text
res://
  core/                  # events, IDs, registry, common utilities
  data/                  # custom Resources and content registries
  actors/
    player/              # player actor and reusable components
    enemies/
    components/
  combat/
  characters/
  inventory/
  loot/
  dungeon/
    generation/          # pure layout algorithm and validators
    rooms/               # modular room scenes
    runtime/             # floor instantiation and mutable state
  multiplayer/
    lobby/               # slots, peers, ready state
    transport/           # ENet adapter, RPC contracts
    replication/
  local_play/
    input/               # device assignment, action routing
    viewports/           # SubViewport layout and HUD ownership
  difficulty/
  persistence/
  town/
  ui/
  audio_visual/
  tests/
  main.tscn
```

`user://characters/`, `user://settings/`, and `user://sessions/` hold writable runtime data. Content definitions live in `res://`.

## 7. Essential data contracts

### PlayerSlot

```text
session_player_id: UUID
peer_id: integer
local_slot_id: integer
character_id: UUID or null
join_state: UNASSIGNED | CONFIRMING | SELECTING | READY | SPAWNED | DISCONNECTED
input_device_id: integer (local only)
```

**Rules:** reserve a slot during character selection; a slot cannot spawn with a null character; the same character cannot be active in two lobby slots; release abandoned pending slots after an explicit timeout policy; never trust a client-provided character identifier without ownership checks.

### CharacterSave (versioned)

```text
schema_version, character_id, owner_id, display_name, appearance
level, experience, base_attributes, unspent_points
current_health, current_mana, derived_stat_inputs
inventory_items[], equipment_slots{}, gold, stash_ref
quest_flags{}, unlocks{}, last_safe_town_location
revision, saved_at, integrity_metadata
```

Item instances need stable unique IDs and base-definition IDs, quantity, affix rolls, and mutable durability where applicable. Save computed values only when necessary; recompute derived stats consistently.

### DifficultyProfile

```text
profile_id, preset_name, enemy_health_multiplier, enemy_damage_multiplier
spawn_density_multiplier, elite_chance, encounter_budget_multiplier
loot_quantity_multiplier, optional_aggression_parameters
party_scaling_profile_id, profile_revision
```

The host freezes the active run's effective difficulty snapshot on dungeon entry by default. Difficulty changes in the lobby affect the next run, not silently alter living enemies.

### DungeonRun

```text
run_id, seed, generator_version, biome_id, floor_index
layout_descriptor, difficulty_snapshot, active_party_snapshot
mutable_world_state, opened_chests, defeated_bosses, loot_claims
```

Seed alone is insufficient for recovery when doors, loot, enemies, and objectives have changed.

## 8. Multiplayer and split-screen design

### Local join sequence

1. Unassigned gamepad presses Start → display per-device join prompt; do not steal active player focus.
2. Same device presses Start again → reserve one of four lobby character slots.
3. Open controller-operated character select/create flow in a local overlay.
4. Validate character ownership, unique selection, and save compatibility.
5. Host approves spawn in a safe location; allocate camera/HUD and transition split-screen smoothly.
6. Reassign controller ownership and remove pending UI; gameplay begins.

If the lobby is full, show a clear message and do not allocate a viewport. Disconnecting a controller must not delete the character. Remote peers can have multiple local slots and follow the same character gating.

### Replication rules

- Clients send timestamped/sequenced player **input commands** associated with an authorized session player ID.
- Host validates and applies actions; sends snapshots and discrete events to clients.
- Use interpolation for remote actors; consider client-side prediction/reconciliation for local movement after basic correctness is proven.
- Host is authoritative for inventory mutations and loot pickup; transactions use unique IDs to prevent double claims.
- Scene transitions use readiness acknowledgements so clients do not act in partially loaded floors.
- Host migration is **not** a v0.1 requirement; communicate clearly if host departure ends the session.

### Testing matrix

- 1 local; 2, 3, 4 local on one PC.
- 1+1, 2+1, 2+2, 3+1 across machines; 4 online on four machines.
- Joining mid-dungeon, pending-character cancellation, full lobby, duplicate character, reconnect, controller unplug, host disconnect, packet delay/loss, simultaneous item pickup.

## 9. Dungeon generation and encounter composition

**Layout pipeline:** select biome → seeded room graph → place non-overlapping room footprints → connect graph (spanning network + optional loops) → validate start-to-exit and required objective reachability → instantiate modular 3D room scenes → bake/load navigation → assign encounters, treasure, traps, secrets → publish authoritative floor state.

Keep the logical room graph separate from the scene instantiation. Test hundreds of seeds in headless mode. Room connection metadata must define doorway position/orientation, footprint, floor height, and allowed neighboring modules. Initial release should avoid complex vertical room connectivity until basic horizontal layouts are reliable.

**Difficulty and party scaling:** calculate encounter budget from dungeon depth, difficulty profile, and active party size; allocate budget among enemy types, groups, and elites. Scale health/damage separately from encounter density. Use spawn caps and safe-spawn distances. Changing party size affects future spawns by default, not existing enemy HP. All numbers are tunable; do not treat concept-art figures as balance specifications.

## 10. Combat and progression

- First-person melee with responsive attack timing, hit windows, reach, knockback/stagger where appropriate, and strong audiovisual feedback.
- Weapon definition specifies attack cadence, range, damage distribution, animation/audio/VFX references, and stat requirements.
- Host resolves hits and damage; clients display predicted local swing visuals, then reconcile authoritative results.
- Enemy AI uses reusable states (idle/patrol, detect, chase, attack, recover, retreat as applicable), with data-driven enemy definitions.
- Classless XP/level system; base attributes, requirements, and derived stat formulas live in one documented stat calculator.
- Equipment and loot use immutable definitions + mutable per-instance rolls; character inventory transactions are atomic at the gameplay level.

## 11. Town autosave policy — mandatory

**Town is the primary safe persistence zone.** For each character individually:

- On entering town: queue an immediate save of validated current health, stats, inventory, equipment, currency, and progression.
- While in town: autosave changed character data every **30 seconds** as an initial configurable default.
- On persistent changes while in town: debounce save for approximately **2 seconds** to coalesce rapid operations.
- On leaving town or normal exit: flush outstanding changes and confirm completion where possible.
- Per-character writes are serialized; write to a temporary file, verify it, then atomically replace the primary save when supported, retaining a known-good backup.
- Every save carries schema version and monotonically increasing revision; reject stale overwrites and detect malformed records.
- Multiplayer character ownership: each owner's device stores its character save in the initial peer-hosted model, while host validates authoritative changes. Define signed/validated snapshots and acknowledgement/retry semantics before implementation; do **not** claim this provides cheat-proof persistence.
- Dungeon session recovery, cloud backup, and manual/quick saves are **separate proposals**, not substitutes for required town autosaves.

**Edge cases:** host/client disconnect during town save; item transfer while a save is queued; simultaneous town entry; full disk; corrupt save; rollback from backup; repeated join/leave; player in town while others remain in dungeon. Independent per-player location tracking is required even if the first prototype enforces a shared active dungeon floor.

## 12. Controller and accessibility requirements

- Assign input devices to local slots, not to network peers.
- Detect Start on **unassigned** devices even when another player's menu is open.
- Per-player remapping, stick dead zones, look sensitivity, invert Y, hold/toggle actions, vibration level, and prompt glyph family.
- Keyboard/mouse is supported as one local player's input device; multiple simultaneous keyboard/mouse players are not an initial requirement.
- Menus must have explicit focus ownership per local player. Never allow one player's menu to pause the entire online session inadvertently.
- Four-way split-screen must remain legible; include UI scaling, reduced HUD density, and independent overlays.
- Provide accessible color-independent status cues, subtitle options, and adjustable screen shake.

## 13. Performance and quality targets

Targets are provisional and must be validated on agreed minimum PC hardware. Measure 1, 2, and 4 local viewports plus network clients. Track frame time, draw calls, GPU time, navigation costs, enemy counts, replication bandwidth, input latency, and save latency. Favor low-poly geometry, shared materials, LOD/culling, restrained dynamic lighting, and bounded particle counts. No unsupported FPS promises until profiling.

Automated tests: pure stat/damage formulas; loot roll reproducibility; item transactions; difficulty scaling; dungeon connectivity across many seeds; save serialize/deserialize/migration; player-slot state machine. Manual/automated integration tests: multi-instance ENet session, join/leave, controller routing, scene transitions, and split-screen performance.

## 14. Milestones and gates

| Milestone | Deliverable | Exit gate |
|---|---|---|
| M0 — Repo & contracts | Godot skeleton, CI/test runner, IDs/resources, architecture decision records | Project opens, tests run, conventions documented |
| M1 — Local multiplayer proof | Four independent controller players, Start×2 join, character gate, dynamic viewports | Four local players can join/leave without control crossover |
| M2 — Hybrid networking proof | Host/join ENet, local-slot-to-peer mapping, authoritative movement | 2+2 hybrid and four online sessions work in test scene |
| M3 — Persistence proof | Character creation, versioned saves, town zone and autosave | All four players can save/reload independently, including failure recovery |
| M4 — Combat & AI | Two weapons, basic enemy, host damage resolution | Correct combat under simulated latency and 4-player load |
| M5 — Dungeon | One biome, seeded 6–10-room floor, stairs, encounters | Connectivity tests pass; all peers see same floor/state |
| M6 — Loot, UI & scaling | Inventory/equipment, drops, difficulty profiles, split HUD | No duplicate item pickups; controller-only playthrough |
| M7 — v0.1 vertical slice | Town → dungeon → combat → loot → level → town → autosave | Repeatable full loop in solo/local/online/hybrid |
| M8 — Content alpha | More weapons, monsters, rooms, quests, biomes as approved | Content can be added through data/resources without core rewrites |

**Vertical slice minimum:** small town, one dungeon biome, three enemies, three starter weapons, basic armor/potions/gold, inventory/equipment, XP/attributes, difficulty presets, seeded floor, multiplayer and reliable town autosave. This is a target scope, not a claim of implementation.

### 14.1. Explicit development order — all 14 feature specifications

**This is the recommended order to write, review, and implement feature specifications**, based on technical dependencies and early risk reduction. Feature IDs remain fixed for cross-references; the order below is not the numeric feature order. Cross-cutting features begin with minimum viable contracts and are expanded at their assigned stage. Work may overlap only when interfaces and ownership rules are already agreed.

| Order | Feature | Specification | Why at this stage | Primary milestone(s) |
|---|---|---|---|---|
| 1 | **F04 — Multiplayer System** | `04-multiplayer.md` | Define peers vs players, lobby slots, host authority, session identity, joining, and replication contracts first. | M0–M2 |
| 2 | **F14 — Controller & Input** | `14-controller-input.md` | Implement controller ownership, Start-twice joining, local input routing, and independent player controls. | M1–M2 |
| 3 | **F05 — Character System** | `05-character-system.md` | Establish required character creation/selection, character IDs, attributes, and per-player spawn gates. | M1–M3 |
| 4 | **F13 — Save & Persistence** | `13-save-persistence.md` | Validate per-character ownership, serialization, autosave/recovery, and online save acknowledgements before valuable loot exists. | M3 |
| 5 | **F10 — UI & Menu System** | `10-ui-menus.md` | Build controller-first lobby, character, HUD, and split-screen UI primitives needed by subsequent systems. | M1–M3, M6 |
| 6 | **F01 — Core Gameplay** | `01-core-gameplay.md` | Define the playable world loop, interactions, town/dungeon transitions, and per-player state flow. | M3–M7 |
| 7 | **F02 — Combat System** | `02-combat.md` | Implement authoritative attacks, hit/damage contracts, weapon timing, and feedback before enemy content. | M4 |
| 8 | **F07 — Enemy System & AI** | `07-enemy-ai.md` | Add reusable enemies and AI that consume combat contracts and support host-owned simulation. | M4–M5 |
| 9 | **F03 — Procedural Dungeon Generation** | `03-dungeon-generation.md` | Generate seeded, validated shared floors and integrate enemy spawn locations. | M5 |
| 10 | **F12 — Difficulty & Scaling** | `12-difficulty-scaling.md` | Apply presets, party-size factors, and encounter budgets to established enemies and dungeon generation. | M5–M6 |
| 11 | **F06 — Inventory & Equipment** | `06-inventory-equipment.md` | Add validated item ownership, equipment, and transactions on top of established character/save contracts. | M6 |
| 12 | **F08 — Loot & Reward System** | `08-loot-rewards.md` | Add drops, rarities, affixes, and rewards using the authoritative inventory and encounter systems. | M6 |
| 13 | **F09 — Town & Hub System** | `09-town-hub.md` | Integrate merchants, storage, safe-zone transitions, and the already-tested town autosave trigger. | M3, M7 |
| 14 | **F11 — Audio, Visuals & Immersion** | `11-audio-visuals.md` | Polish presentation and performance after the full loop is demonstrable; basic placeholder feedback exists earlier. | M4–M8 |

**Important sequencing notes:**

- M0 must define shared interfaces for **all** features, even if their full implementation occurs later.
- The **town autosave trigger is prototyped at M3** with a minimal town test zone; F09's later position refers to the *full* town/hub feature, not delaying required persistence.
- F10's early position covers foundational menus and split-screen layout; inventory-specific UI is finished alongside F06.
- F11's late position covers full polish; basic animation, audio feedback, and profiling begin with the first controller/combat prototypes.
- F12 can define its data schema early, but final enemy/encounter tuning follows F07 and F03.
- **Dependency gate:** do not start a downstream feature's full implementation until its upstream contracts and acceptance tests are stable; update this sequence through an architecture decision record if new findings justify a change.

## 15. Development workflow

- Git repository from day one; protect stable main; feature branches and reviewed pull requests.
- Every code change links to a feature spec and acceptance criterion.
- Add automated tests for every pure-data subsystem before expanding content.
- Keep implementation specifications at the repository root. Concept art never overrides requirements.
- Document important decisions in a repository-root `ADR-NNNN-title.md` (see `ADR-0001-foundational-architecture.md` and `ADR-0002-gameplay-design-v0.1.md`) with context, decision, and consequences.
- Require test evidence and multiplayer regression checks before merging network, inventory, or persistence changes.
- Separate MVP-critical work from stretch goals; do not let cloud saves, public matchmaking, or complex crafting delay the vertical slice.

## 16. Key risks and mitigations

| Risk | Mitigation |
|---|---|
| Four simultaneous first-person cameras are GPU-heavy | Prototype early, profile per viewport, configurable lighting and VFX |
| One peer controls multiple local players | Explicit identity mapping and input router; test hybrid first |
| Inventory duplication/desync | Host-validated atomic transactions, item IDs, revision tracking |
| Character loss on crash/disconnect | Town autosaves, backups, per-character queues, recovery tests |
| Procedural floors produce unreachable rooms | Pure graph validation and seeded regression corpus |
| Host departure disrupts game | v0.1 clear end-of-session policy; preserve confirmed saves |
| Feature creep from concept art | Approved/proposed classification and milestone gates |
| Tiny split-screen menus | Per-viewport UI scaling and controller focus tests |

## 17. Decisions to finalize before detailed feature implementation

Eight high-level gameplay decisions are **ACCEPTED** in [ADR-0002](ADR-0002-gameplay-design-v0.1.md). Remaining implementation-level decisions:

1. Exact derived-stat formulas, XP progression, attribute points, and respec policy (four core attributes are locked).
2. Death penalty amount/cap, respawn location, and any temporary protection (keep equipment and respawn are locked).
3. Personal-loot eligibility, per-player roll count, trade/gift policy, and shared quest reward behavior (personal instancing is locked).
4. Floor vote eligibility, duration, ties/abstentions, disconnects, and handling of 1-player parties (majority and shared transition are locked).
5. Persistent guest-profile export/import, storage quotas, and deletion/recovery rules (profile persistence is locked).
6. Dodge timing, spell costs, and ranged weapon action details (simple baseline actions are locked).
7. Difficulty preset names, slider bounds, reward cap/multiplier formula, and exploit protections (four presets/custom/capped bonuses are locked).
8. Grid dimensions, item footprint, stacking, sorting, and overflow rules (slot grid is locked).
9. Network reconnect grace periods, late-join safe spawn, and public-internet security policy.
10. Minimum four-camera performance target and supported hardware.

Resolve these before implementing the corresponding feature behavior, not before M0 identity and lobby contracts.

## 18. Definition of ready and definition of done

**Ready:** feature has approved behavior, data ownership, network authority, save implications, UI/input behavior, dependencies, and acceptance tests.  
**Done:** implemented in Godot, code-reviewed, automated tests passing where applicable, controller navigable, verified in solo and relevant co-op combinations, no known progression-blocking bug, docs updated, and milestone demo reproducible.

---

### Document maintenance

Version each spec. Changes to shared contracts must update this blueprint, affected feature specs, and architecture decision records together. Proposed content remains explicitly non-binding until approved. The 14 feature specifications are present. The next implementation deliverable is MP-01 (identity, lobby contracts, and headless tests). The eight architecture contracts are recorded in ADR-0001 and eight gameplay choices in ADR-0002. Unspecified tuning and adjacent choices remain open.
