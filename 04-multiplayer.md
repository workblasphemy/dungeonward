# DUNGEONWARD — Feature 04: Multiplayer System

> **Version:** 0.1 | **Status:** Development specification / not implemented
> **Authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5
> **Engine:** Godot 4.7.2, GDScript, ENet
> **Milestones:** M0–M2, integrated through M7
> **Next dependencies:** F14 Controller & Input; F05 Character; F13 Save & Persistence; F10 UI

> **Architecture approval:** ARCH-01, ARCH-02, ARCH-03, ARCH-04, ARCH-05, ARCH-06, ARCH-07, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-03 — Personal instanced multiplayer loot:** Each eligible player receives personal instanced loot; there is no competition to pick up another player's drops. **Integration:** F08 reward authority generates player-scoped grants/visibility; F06 atomic inventory transactions. Eligibility, reward quantity, and optional trading remain OPEN.
- **GAME-04 — Party-majority dungeon transitions:** The party advances dungeon floors together after a majority vote of eligible active party members. **Integration:** F01/F03/F04 implement host-owned vote and synchronized transition barrier. Majority means strictly more than half of eligible voters. Eligible roster, vote timeout, ties, abstentions, and disconnected voters need explicit policies before coding.
- **GAME-05 — Persistent couch profiles:** Couch co-op uses separate local owner profiles; guest characters persist across sessions instead of being temporary. **Integration:** F05 local profile registry and character UUIDs; F13 profile-isolated save directories. Guest export, migration, profile deletion, and account linking remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Deliver **1–4 player characters per lobby** in any combination of local couch split-screen, online, or hybrid multiplayer. A **network peer is not a player**: one connected PC may own multiple local player characters. The game must remain playable as solo, couch, online, or hybrid without separate gameplay implementations.

### Supported combinations

| Setup | Players per PC | Total |
|---|---|---:|
| Solo | 1 | 1 |
| Local couch | 2 / 3 / 4 | 2–4 |
| Online | 1+1 / 1+1+1 / 1+1+1+1 | 2–4 |
| Hybrid | 2+1 / 2+2 / 3+1 / 2+1+1 | 3–4 |

**Capacity is four active or reserved character slots, not four connections.**

## 2. Non-negotiable behavior

1. A player may join a running world without resetting the existing session.
2. An **unassigned controller presses Start once** to reveal a join prompt, then **Start a second time on that same controller** to request a player slot and open character selection/creation.
3. **No player actor spawns without an approved, unique selected or newly created character.**
4. Every local player owns independent input routing, camera, viewport, HUD, menu focus, and persistent character identity.
5. A remote PC may join with two or more local players using **one ENet peer connection**.
6. Host owns the authoritative world: player movement resolution, combat, enemies, loot claims, currency changes, dungeon run state, and encounter spawns.
7. Each character's save belongs to its owning device/profile. The host validates gameplay changes; F13 handles versioned, revision-aware local persistence.
8. One player's inventory/menu never globally pauses the world or steals another player's controls in multiplayer.
9. Controller disconnect is not character deletion; network peer disconnect is not the same as local player leave.
10. Host migration is **out of scope** for v0.1; host exit may terminate the session with a clear message.

## 3. Scope and exclusions

**First implementation:** offline/local sessions, ENet LAN/direct-IP host/join, lobby reservations, character approval, four-player split-screen, host-authoritative movement, hybrid peer/slot ownership, world-state snapshots, scene-transition barriers, disconnect handling, minimal reconnect, and test instrumentation.

**Not automatically included:** public matchmaking, NAT traversal/relay, cloud accounts, dedicated servers, voice chat, host migration, cross-platform console certification, cheat-proof local saves, or simultaneous independent dungeon floors.

Concept-sheet imagery is visual guidance, not authorization for extra mechanics.

## 4. Architecture and ownership

```text
GameRoot
├── SessionCoordinator              # host/join/close and session state
├── LobbyService                    # peers, 4-slot capacity, reservations
├── SessionPlayerRegistry           # peer ↔ local slot ↔ session player ↔ character
├── CharacterJoinService            # character selection approval and spawn gate
├── TransportAdapter
│   ├── OfflineLoopbackTransport    # same logical rules for solo/couch
│   └── ENetTransport               # peer-hosted network
├── WorldAuthority [HOST ONLY]      # movement, enemies, damage, loot, dungeon state
├── ReplicationService              # input, snapshots, reliable events
├── SceneTransitionCoordinator      # load/ready/baseline/activate handshake
└── LocalPlayCoordinator [EACH PC]  # local-only presentation and devices
    ├── DeviceAssignmentService     # F14
    ├── ViewportManager             # F10/F14
    └── LocalJoinUI                 # F05/F10
```

**Boundary:** session membership is not input-device ownership; world authority is not save-file ownership; viewports are local and must not be replicated.

### Proposed Godot directories

```text
res://multiplayer/
  session/{session_coordinator,session_state}.gd
  lobby/{lobby_service,player_slot,peer_record,slot_reservation}.gd
  identity/{session_player_registry,player_identity}.gd
  join/{character_join_service,join_state_machine}.gd
  transport/{transport_interface,enet_transport,offline_loopback_transport,protocol}.gd
  replication/{replication_service,input_command,actor_snapshot,world_event}.gd
  world/{world_authority,actor_spawn_service,scene_transition_coordinator}.gd
  debug/multiplayer_debug_overlay.tscn
  tests/
res://local_play/                  # local devices, cameras, HUDs, focus
```

Prefer composed session-owned services and a small autoload surface over a monolithic global NetworkManager.

## 5. Identity and player-slot contract

| Identifier | Meaning | Scope |
|---|---|---|
| `peer_id` | ENet connection endpoint | Ephemeral connection |
| `local_slot_id` | Player/input/viewport index on one PC | Local device/session |
| `session_player_id` | Unique player slot across the whole lobby | Session |
| `character_id` | Stable persistent character UUID | Across sessions |
| `owner_profile_id` | Local profile that owns the character save | Owning device |
| `actor_network_id` | Host-assigned replicated actor identity | Current world |
| `reservation_token` | Short-lived opaque join reservation | Pending join |

**Required invariants:**

- `(peer_id, local_slot_id)` uniquely identifies at most one occupied/reserved slot.
- Each `session_player_id` belongs to exactly one owning peer.
- Each `character_id` is active/reserved in at most one session slot.
- The host allocates `session_player_id`, `actor_network_id`, and reservations.
- A slot cannot become SPAWNED if `character_id` is empty, unapproved, or duplicate.
- Reservations count toward the four-player limit and expire safely.
- Remote `device_id` is never treated as authoritative; device IDs stay on the owning PC.
- Cleanup/release must be idempotent, including duplicate disconnect events.

### Example typed model (illustrative, not a wire schema)

```gdscript
class_name PlayerSlot
extends RefCounted

enum State { SELECTING, READY, SPAWNED, DISCONNECTED }

var session_player_id: String
var peer_id: int
var local_slot_id: int
var character_id: String = ""
var owner_profile_id: String = ""
var actor_network_id: int = -1
var state: State = State.SELECTING
var reservation_token: String = ""
var reservation_expires_at_ms: int = 0
```

The local `UNASSIGNED` and `CONFIRMING` controller states live in F14's local join state machine **before** any lobby reservation exists.

## 6. Session and joining state machines

### Session lifecycle

```text
IDLE → HOSTING / CONNECTING → LOBBY → WORLD_LOADING → PLAYING
                                     ↖ WORLD_TRANSITION ↗
Any active state → CLOSING → IDLE
Connection failure → ERROR → cleanup → IDLE
```

### Mandatory local Start×2 flow

```text
UNASSIGNED GAMEPAD
  Start #1 → CONFIRMING (local join prompt, no slot reserved)
  Start #2 → HOST SLOT REQUEST
    ├─ Full/rejected → clear message, remain unassigned
    └─ Reserved → SELECTING CHARACTER
         ├─ Cancel/timeout → release reservation
         ├─ Invalid/duplicate character → show error, stay selecting
         └─ Approved character → READY → synchronize world → SPAWNED
```

Both Start presses must originate from the same unassigned device. Start on an already assigned controller opens that player's menu. Existing players keep playing during selection. A joining player receives a viewport/HUD only when appropriate; **no playable actor** exists until the character gate succeeds.

### Remote/hybrid join flow

1. Establish ENet connection and validate compatible build/protocol versions.
2. Host registers one peer connection.
3. Each local player on that PC independently requests a session slot.
4. Host reserves slots (up to four total) and issues reservation tokens.
5. Each local player chooses/creates a character.
6. Host checks reservation ownership, duplicate character, and save compatibility.
7. Host registers session player identities, sends world baseline and spawn plan.
8. Client loads world and acknowledges readiness.
9. Host activates/spawns actors and broadcasts the updated lobby.

**Example:** PC A has two gamepads and PC B has two gamepads: two network peers, **four** session players.

## 7. Network transport and RPC security

- Start with `ENetMultiplayerPeer` and Godot's high-level multiplayer API.
- Implement an offline loopback adapter to exercise the same authority path in solo/local modes.
- Define protocol version, bounded payload schemas, error codes, and message rate limits.
- For every inbound player-specific RPC, read `multiplayer.get_remote_sender_id()` **inside the RPC handler**; resolve authorized `session_player_id` from the registry.
- Never trust a claimed sender ID, client position, damage value, gold amount, loot result, or arbitrary node/resource path.
- Reject NaN/Infinity, invalid enums, oversized payloads, out-of-range movement vectors, stale input sequences, and repeated consequential transactions.
- Use unique event/transaction IDs to prevent duplicate item pickups or replayed inventory mutations.
- Public internet hosting requires a separate connectivity/encryption/security review; LAN/direct-IP is the initial target.

### Logical messages

| Message | Direction | Delivery | Responsibility |
|---|---|---|---|
| `hello / welcome / reject` | Both | Reliable | Version/session handshake |
| `request_slot / slot_result` | Client↔host | Reliable | Four-player capacity and reservation |
| `select_character / character_result` | Client↔host | Reliable | Character approval |
| `release_slot` | Client→host | Reliable | Leave/cancel |
| `input_batch` | Client→host | Unreliable ordered | Sequenced player intents |
| `actor_snapshot` | Host→clients | Unreliable ordered | Frequent state replication |
| `world_event` | Host→clients | Reliable where durable | Spawn, death, loot, progression |
| `prepare_world / world_ready` | Both | Reliable | Transition barrier |
| `world_baseline / activate_world` | Host→clients | Reliable | Late join / scene activation |
| `save_snapshot / save_ack` | Host↔owner | Reliable | Revisioned persistence handoff |

Use separate channels for differently sized or differently prioritized unreliable-ordered traffic. Include application-level sequence IDs and reject stale snapshots/events.

### Input command contract

```text
session_player_id
sequence_number
client_tick
move_axis: Vector2
look_delta: Vector2
buttons_pressed: bitfield
buttons_held: bitfield
```

The host checks sender ownership and command validity, then simulates actions. Host-local players use the same simulation queue through a trusted local path, rather than spoofing a remote sender.

## 8. Simulation and replication

**Prototype tunables, not final guarantees:**

| Parameter | Initial target |
|---|---|
| Physics simulation | 60 Hz |
| Input send cadence | 20–30 Hz, batched |
| Actor snapshots | 10–20 Hz |
| Remote interpolation buffer | ~100 ms |
| Active/reserved player slots | 4 |

- Host computes movement, collision, AI, hits, pickups, and world state.
- Clients send intent and display authoritative snapshots.
- Start with authoritative correctness and remote interpolation; add local prediction/reconciliation only after hybrid tests pass.
- Reliable events carry stable IDs and are applied idempotently.
- Spawn/despawn and immutable dungeon descriptors are reliable; frequent transforms are disposable snapshots.
- Interest filtering and bandwidth optimization follow functional correctness.
- Host snapshots should include revision/tick metadata and actor ownership.
- A local four-player machine renders **four cameras**; benchmark viewport cost early.

## 9. Split-screen and independent UI

| Local characters on one PC | Default presentation |
|---:|---|
| 1 | Full screen |
| 2 | Two equal panes |
| 3 | Three-pane layout with readable HUD |
| 4 | Four quadrants |

- Only locally controlled characters receive viewports; remote characters appear as world actors.
- Each viewport owns one first-person camera and one player HUD.
- Each player can independently navigate inventory, settings, character menus, and character selection using their assigned input device.
- A local player's pause/menu does not pause online/hybrid world simulation.
- Viewport changes during join/leave must not reassign other players' devices.
- HUD legibility and controller navigation must be tested at quarter-screen size.
- Layout orientation and polish are **OPEN** design choices for F10/F14.

## 10. World loading, late join, and dungeon state

### Transition handshake

```text
HOST chooses destination and transition_id
  → Sends destination/seed/generator version/run descriptor
  → Peers load required scenes and reply world_ready(transition_id)
  → Host sends authoritative mutable world baseline
  → Peers acknowledge baseline revision
  → Host activates participants at a defined simulation tick
```

- Never send gameplay-node RPCs before the destination scene is instantiated on recipients.
- Timeout/disconnected peers must not permanently block surviving players.
- A late joiner receives a coherent baseline before becoming active.
- Host selects a safe spawn location, including for joins during dungeon play.
- F03 owns deterministic generation; F04 sends **seed + generator version + layout descriptor + mutable state**. Seed alone cannot reconstruct opened chests, dead enemies, or altered doors.
- F12 receives an authoritative active-party-size signal. By default, new party-size scaling applies to **future encounters**, not silent health changes to existing enemies; finalize in F12.

## 11. Disconnect, leave, and reconnect

| Situation | Expected behavior |
|---|---|
| Controller unplug | Stop commands; retain player/character slot for rebind grace period |
| Local player explicitly leaves | Flush save-safe state; despawn; release slot |
| Remote peer disconnects | Mark **all** its local player slots disconnected; apply timeout/reconnect policy |
| Join canceled during character select | Release reservation and duplicate-character lock |
| Lobby full | Reject fifth slot without affecting current party |
| Host leaves/crashes | End session cleanly where possible; preserve confirmed saves |
| Reconnect | Validate short-lived ticket, restore ownership, send fresh world baseline |

Do not use the old ENet `peer_id` as proof of reconnect identity; peer IDs can change. Reconnect tickets and local profiles are not robust online account authentication. Host migration is out of scope.

**OPEN:** exact disconnect grace period (prototype proposal: 60 seconds), rejoin spawn position, ownership transfer between PCs, whether disconnected actors become invulnerable or inactive.

## 12. Save & persistence integration (F13)

Character persistence is **per player**, including when multiple players share one PC.

- Each persistent character has a unique `character_id`, local owning profile, schema version, and monotonic save revision.
- The host authoritatively validates character-affecting gameplay and produces revisioned per-character snapshots.
- Each owner's device stores only its owned character data.
- **On entering town:** immediate save request.
- **While in town:** save dirty character state every **30 seconds**.
- **While in town after changes:** debounce saves by approximately **2 seconds**.
- **On town exit/normal shutdown:** flush pending writes where possible.
- Save writes are serialized per character, validated, and atomically replaced with backup/recovery support.
- A stale snapshot must never overwrite a newer confirmed revision.
- Disconnects and save-ack failures need explicit retry/recovery and user-visible failure status.

**Important limitation:** peer-hosted gameplay with client-owned local saves cannot be cheat-proof or guarantee zero progress loss after abrupt host failure. Do not describe local snapshot signatures as trusted server attestation.

## 13. Feature integration contracts

| Feature | Required interface |
|---|---|
| **F14 Input** | Emits local join gesture and per-local-slot commands; F04 returns session player ownership |
| **F05 Character** | Supplies select/create/validation; F04 enforces spawn gate and duplicate-character exclusion |
| **F13 Persistence** | Handles per-character save revisions and writes; F04 provides host-validated state |
| **F10 UI** | Lobby, join prompt, independent menus, split-screen viewports, error/reconnect overlays |
| **F01 Core** | World/session state transitions, interactions |
| **F02 Combat** | Host-authoritative attack intent, hit validation, and replicated outcomes |
| **F03 Dungeon** | Generator version, seed, layout descriptor, mutable run-state snapshot |
| **F06 Inventory** | Validated item/equipment transactions; sender authorization |
| **F07 Enemy AI** | Host-owned enemy simulation and replicated actor state |
| **F08 Loot** | Atomic pickup claims and item ownership |
| **F09 Town** | Per-player town entry/exit triggers; save-safe transition |
| **F11 Presentation** | Network events for sound/VFX; performance profiling |
| **F12 Difficulty** | Active party size and host-owned run difficulty snapshot |

### Proposed service APIs

```text
SessionCoordinator:
  start_offline_session(config) -> Result
  host_session(config) -> Result
  join_session(address, port) -> Result
  close_session(reason) -> void

LobbyService:
  reserve_slot(sender_peer_id, local_slot_id) -> ReservationResult
  approve_character(sender_peer_id, token, character_metadata) -> Result
  release_slot(session_player_id, reason) -> Result
  get_active_party_size() -> int

SessionPlayerRegistry:
  peer_owns_player(peer_id, session_player_id) -> bool
  resolve_player(peer_id, local_slot_id) -> session_player_id?
  players_for_peer(peer_id) -> Array

ReplicationService:
  enqueue_input(session_player_id, command) -> Result
  publish_actor_snapshot(snapshot) -> void
  publish_world_event(event) -> void
```

Suggested signals: `slot_reserved`, `character_approved`, `player_spawned`, `player_left`, `peer_disconnected`, `active_party_size_changed`, `world_transition_started`, `world_transition_completed`, `save_snapshot_ready`, `network_error`.

## 14. Implementation work packages

### MP-01 — Identity, lobby contracts, tests (M0)
- [ ] Implement ID types, DTOs, state enums, result codes, protocol version.
- [ ] Build peer/slot/character registry and four-slot reservation service.
- [ ] Reject duplicate characters, duplicate local slots, and fifth player.
- [ ] Add timeouts, cancellation, idempotent cleanup.
- [ ] Test pure logic without scenes or physical controllers.

**Exit:** four unique slots can be reserved/released and one peer can own multiple players.

### MP-02 — Local couch joining (M1)
- [ ] Integrate F14 Start×2 input.
- [ ] Add per-device join UI and F05 mandatory character selection.
- [ ] Spawn one approved actor per selected character.
- [ ] Create 1/2/3/4 local viewports and independent HUD/focus.
- [ ] Handle cancel, unplug/replug, join during gameplay.

**Exit:** four gamepads independently join an active local session without input crossover.

### MP-03 — Authoritative movement and replication (M1–M2)
- [ ] Host-owned actor IDs and movement simulation.
- [ ] Validated, sequenced input commands.
- [ ] Actor snapshots, interpolation, durable event IDs.
- [ ] Debug overlay for ownership, RTT, packet rate.

**Exit:** all players see coherent actor movement; spoofed inputs are rejected.

### MP-04 — ENet hybrid multiplayer (M2)
- [ ] Host/join, handshake, version checks, transport errors.
- [ ] Multiple player slots under one remote peer.
- [ ] Authoritative ownership validation on all RPCs.
- [ ] Test 2+2, 3+1, 2+1+1, and four-online configurations.

**Exit:** 2+2 hybrid session works across two PCs in a test scene.

### MP-05 — Late join and scene transitions (M2–M3)
- [ ] Transition IDs, load/ready barriers, baseline snapshots.
- [ ] Safe spawn, join during play, timeout recovery.
- [ ] Procedural dungeon descriptor and mutable state stubs.

**Exit:** late joiners do not spawn into unloaded or inconsistent worlds.

### MP-06 — Persistence and resilience (M3)
- [ ] Revisioned host-validated save snapshots and acknowledgements.
- [ ] Independent local/remote character autosaves on town entry and while in town.
- [ ] Peer disconnect, host exit, stale snapshot, save failure tests.
- [ ] Prototype reconnect tickets and slot recovery.

**Exit:** four characters can separately save, leave, and reload without cross-contamination.

### MP-07 — Performance and regression (M2–M7)
- [ ] Profile four local cameras plus remote peers.
- [ ] Simulate latency, jitter, loss, duplicates, and disconnects.
- [ ] Test simultaneous loot claims and repeated world transitions.
- [ ] Document performance results and remaining limitations.

**Exit:** reproducible town → dungeon → town multiplayer vertical slice passes.

## 15. Automated tests and integration matrix

| ID | Test | Pass condition |
|---|---|---|
| MP-U01 | Reserve slots 1–4 | Four unique reservations |
| MP-U02 | Request fifth slot | Rejected; no state corruption |
| MP-U03 | One peer owns two slots | Both map to distinct session players |
| MP-U04 | Same local slot reserved twice | No duplicate |
| MP-U05 | Same character selected twice | Second denied |
| MP-U06 | Spawn with no character | Denied |
| MP-U07 | Cancel or expire selection | Reservation and lock released |
| MP-U08 | Unauthorized peer sends input | Ignored |
| MP-U09 | Invalid/NaN/stale input | Rejected |
| MP-U10 | Duplicate pickup transaction | Applied once |
| MP-U11 | Stale transition acknowledgment | Ignored |
| MP-U12 | Old save revision arrives late | Newer save preserved |
| MP-I01 | 1/2/3/4 local | Correct viewports and device ownership |
| MP-I02 | 1+1 online | Shared authoritative world |
| MP-I03 | 2+2 hybrid | Four characters across two peers |
| MP-I04 | 3+1 hybrid | One peer owns three slots |
| MP-I05 | 2+1+1 hybrid | Three peers, four characters |
| MP-I06 | 1+1+1+1 online | Four peers, four characters |
| MP-I07 | Mid-dungeon join | Character gate + safe baseline |
| MP-I08 | Controller unplug | Other players unaffected |
| MP-I09 | Remote peer disconnect | All owned slots handled |
| MP-I10 | Four simultaneous town entries | Four independent saves |
| MP-I11 | Inventory open while others fight | No global pause or focus theft |
| MP-I12 | 150 ms RTT + loss simulation | No authority bypass or permanent desync |

Log: `session_id`, `peer_id`, `session_player_id`, `local_slot_id`, `transition_id`, `event_id`, save revision, result code, latency, and snapshot bandwidth. Do not expose sensitive local save paths to peers.

## 16. Definition of done

- [ ] Supports 1–4 local players on one PC.
- [ ] Supports four online players on separate PCs.
- [ ] Supports 2+2, 3+1, and 2+1+1 hybrid sessions.
- [ ] Same unassigned controller presses Start twice to enter character selection.
- [ ] No spawn without approved unique character.
- [ ] Fifth slot and duplicate character rejected.
- [ ] Independent local input, camera, HUD, inventory, and menu focus.
- [ ] Host authoritative for world and consequential gameplay transactions.
- [ ] Peer/slot ownership enforced on every player-specific RPC.
- [ ] Late join and scene transitions use readiness/baseline handshake.
- [ ] Disconnect and reconnect policies are tested.
- [ ] Independent revision-aware town autosaves verified for four characters.
- [ ] No duplicate item claim under simultaneous pickup requests.
- [ ] Performance and network regression evidence recorded.
- [ ] All upstream feature contracts and master blueprint cross-references remain consistent.

## 17. Decisions to resolve (OPEN)

1. Local guest-profile persistence and character ownership on shared PCs.
2. Player death/disconnect behavior while their actor remains in the dungeon.
3. Exact reconnect grace period and whether reconnect may transfer devices/PCs.
4. Floor/town transitions when party members are in different locations.
5. Spawn location for mid-dungeon late joins.
6. Lobby readiness and host controls for starting a dungeon run.
7. Loot ownership/trading model (F08).
8. Whether offline solo mode may pause simulation.
9. Direct-IP port defaults, firewall guidance, encryption requirements, and internet exposure policy.
10. Minimum hardware and acceptable FPS for four-camera split-screen.

## 18. First coding milestone

**Begin with MP-01, not combat or UI polish.** Build identity types, peer-to-multiple-player mappings, slot reservations, duplicate-character protection, and headless tests. Then implement F14's local device router and MP-02's two-press join flow. This protects the architecture from a common mistake: treating a controller, a network peer, and a persistent character as the same entity.

**Suggested first PR:** `feat(multiplayer): establish lobby identities and slot contracts`  
**PR exit gate:** MP-U01–MP-U07 pass; no art or network transport required.

---

**Document governance:** The master blueprint overrides this feature document on cross-feature conflicts. Changes to identity, authority, save ownership, or transition contracts require synchronized updates to the blueprint, affected feature specs, and an architecture decision record. This document defines intended behavior and tests; it does **not** assert that multiplayer has been implemented.
