# DUNGEONWARD — Foundation Implementation Specification

> **Version:** 0.5 · **Status:** implementation-ready proposal; **not implemented or tested**  
> **Date:** 2026-10-26  
> **Target engine:** Godot **4.7.2** (project-owner-selected; verify that the exact binary/version is available on each runner before execution)  
> **Source control:** GitHub; Windows and Linux development workspaces  
> **Platform acceptance:** Windows and Linux functional by the end of M3  
> **Authority:** `MASTER_BLUEPRINT.md` v0.5, ADR-0001, ADR-0002; this spec cannot silently change approved decisions.

## 1. Plain-English explanation of the contracts

- **Identity DTO** (data transfer object): a small record that tells the game *which computer, controller slot, session player, and saved character* an action belongs to. These are **four different identities**; mixing them up causes players to control one another or overwrite saves.
- **Slot reservation**: when someone joins, the host temporarily holds one of four seats while that person chooses a character. It expires or is canceled if selection never completes. Reserving is **not** spawning.
- **RPC validation**: an RPC is a message sent between computers. Validation means the host checks who actually sent the message, whether they control the referenced player, and whether the requested action is allowed. Never trust a claimed sender ID inside a message.
- **Session lifecycle**: the steps from creating/joining a lobby, choosing characters, loading the world, playing, disconnecting, and ending a session. Each step has allowed transitions and cleanup rules.
- **Local device ownership**: on a given PC, a controller belongs to exactly one local player slot at a time. The device is **not** the player's permanent identity.
- **Slot lifecycle**: a seat moves from empty → reserved → character selected → ready/active → released. Each transition is explicit and testable.
- **Automated testing**: repeatable commands that check these rules and return pass/fail logs without a human clicking through everything. DeepSeek may run them locally on the user's PC or in its Linux workspace when granted execution access; GitHub Actions provides an independent CI gate.

## 2. Approved baseline and implementation assumptions

**Approved:** Godot 4.7.2 selection, GitHub source control, Windows+Linux functional by M3, DeepSeek may execute tests on the user's PC as well as Linux workspaces, and all ARCH-01–08/GAME-01–08 decisions remain in force. **No repository URL or execution permission is implied.**

**Proposed implementation defaults (not separate gameplay approvals):** typed GDScript; Godot's built-in unit-test-friendly `--headless --script` runner to avoid a mandatory external test plugin; ENet for network transport; JSON-compatible dictionaries on RPC boundaries; versioned `Resource` definitions for static game content; local profile UUIDs in `user://profiles/`; GitHub Actions on `ubuntu-latest` and `windows-latest`. Exact Godot runner binaries and CI installation method must be verified.

**Scope M0–M3:** M0 foundational contracts/tests; M1 local input and lobby joins; M2 ENet hybrid authority, synchronization and per-player viewports; M3 independent character saves and a minimal town save region. Combat, loot, procedural content and polish remain stubs unless needed for a vertical integration test.

## 3. Repository layout (proposed, exact)

```text
dungeonward/
├── project.godot
├── README.md
├── 00_SHARED_RULES.md
├── 01_CODEX.md                  # role files through 07_DEEPSEEK.md
├── TASK_HANDOFF.md
├── FEATURE_INDEX.md
├── MASTER_BLUEPRINT.md
├── FOUNDATION_IMPLEMENTATION_SPEC.md
├── ADR-0001-foundational-architecture.md
├── ADR-0002-gameplay-design-v0.1.md
├── ADR-0003-modular-extensible-architecture.md
├── 01-core-gameplay.md          # feature specs through 14-controller-input.md
├── LICENSE                      # choose before first public release
├── .gitignore                   # Godot cache/builds/user data
├── .gitattributes               # normalize text line endings
├── .github/workflows/
│   └── foundation-tests.yml
├── docs/                        # M0 evidence only; specifications stay at root
│   ├── M0-INITIALIZATION.md
│   └── DEEPSEEK-TESTING.md
├── game/
│   ├── main.tscn
│   ├── autoload/session_bootstrap.gd
│   ├── core/identity/{peer_record,player_slot,slot_reservation}.gd
│   ├── core/lobby/{session_player_registry,lobby_service}.gd
│   ├── core/network/{network_gateway,rpc_authorizer}.gd
│   ├── core/input/{device_registry,join_gesture,input_router}.gd
│   ├── core/characters/{character_profile,character_repository}.gd
│   ├── core/save/{save_repository,save_scheduler}.gd
│   ├── core/world/{world_transition_coordinator,town_region_tracker}.gd
│   ├── ui/{lobby,character_select,player_hud}/
│   └── world/{minimal_town,graybox_player}/
├── tests/
│   ├── run_all.gd
│   ├── unit/{test_lobby,test_identity,test_join,test_save}.gd
│   ├── integration/{test_local_slots,test_rpc_authority,test_town_saves}.gd
│   └── fixtures/
├── tools/
│   ├── install_godot.py
│   ├── test.sh
│   └── test.ps1
└── artifacts/                    # ignored: logs/reports
```

Specification paths in this tree match this checkout: design documents stay at the repository root, which is the layout ADR-0003 proposes leaving in place until a later reconciliation. `docs/` holds M0 evidence and the DeepSeek test guide. Entries under `game/`, `tests/`, and `tools/` that are not in the checkout remain proposed.

**Autoload rule:** only `SessionBootstrap` (or similarly minimal entrypoint) is global. Session services are composed and injected, not scattered across unrelated autoload singletons. `project.godot` and `.tscn` must use relative `res://` paths and case-correct file names.

## 4. Identity data contracts (M0, normative proposal)

| Field | Type | Purpose / rule |
|---|---|---|
| `peer_id` | int | ENet multiplayer peer ID for this connection; transient; host typically ID 1; never a character ID |
| `local_slot_id` | int | Per-peer local index `0..3`; not globally unique |
| `session_player_id` | int | Host-assigned, positive, unique within a session; never reused while session active |
| `owner_profile_id` | String UUID | Persistent local profile owning saves; never derived from device or peer ID |
| `character_id` | String UUID | Persistent character identifier; unique across active and reserved selections |
| `reservation_token` | String | Host-generated unpredictable opaque token; short-lived; never used as a password for a user account |
| `reservation_expires_at_ms` | int | Host monotonic deadline; host-only interpretation |
| `slot_state` | enum | `EMPTY`, `RESERVED`, `CHARACTER_SELECTED`, `READY`, `ACTIVE`, `RELEASING` |
| `state_revision` | int | Host-monotonic revision for slot transitions and replication |

**PeerRecord:** `peer_id`, `connection_state`, `owned_session_player_ids[]`, `last_seen_ms` (host-local), `revision`.

**PlayerSlot:** `session_player_id`, `peer_id`, `local_slot_id`, `slot_state`, `owner_profile_id?`, `character_id?`, `reservation_token_hash?`, `revision`.

**SlotReservation:** `reservation_token`, `peer_id`, `local_slot_id`, `session_player_id`, `expires_at_ms`, `reservation_state`, `revision`. Store only token hash in persistent diagnostics; raw token only for live session messages.

**CharacterProfile (minimal M0–M3):** `schema_version`, `owner_profile_id`, `character_id`, `display_name`, `level`, `xp`, `attributes: {strength, dexterity, vitality, magic}`, `gold`, `inventory_revision`, `save_revision`; inventory/equipment payloads are added in F06. Names are presentation, not unique IDs.

**Identity invariants:** (1) at most 4 slots in `RESERVED|CHARACTER_SELECTED|READY|ACTIVE`; (2) `(peer_id,local_slot_id)` maps to at most one non-empty slot; (3) `session_player_id` never belongs to two peers; (4) a `character_id` cannot appear in two active/reserved selections; (5) client cannot allocate `session_player_id`; (6) only owning profile may load/write local character save; (7) released tokens cannot reactivate a slot.

**Validation bounds (initial proposed):** `local_slot_id` 0–3, display name 1–24 visible characters after sanitization, reservation TTL 60 seconds, max four active/reserved slots. TTL and name length are implementation defaults and may be adjusted without changing approved gameplay contracts.

## 5. Lobby and join state machine

```text
Device: UNASSIGNED --Start#1--> CONFIRMING --Start#2 (same device)--> RESERVING
               ^                  | timeout/cancel                    |
               |                  v                                   v
               +--------------- UNASSIGNED                    CHARACTER_SELECT
                                                                     |
                                                    create/select valid profile
                                                                     v
Host slot: EMPTY --> RESERVED --> CHARACTER_SELECTED --> READY --> ACTIVE
                \             \               \             \        \
                 \             +-- timeout -----+-- cancel ----+-- disconnect --> RELEASING --> EMPTY
                  +-- capacity error --> no slot allocated
```

1. Start #1 only shows a prompt for an **unassigned** device; never reserves a slot or spawns.
2. Start #2 from the **same device** within a proposed 10-second confirmation window requests a host reservation. Assigned devices use Start for their own menu.
3. Host checks `(peer_id, local_slot_id)` uniqueness and capacity, then allocates `session_player_id` and token.
4. Character selection UI loads the *owning device's* local profiles. Character ID is submitted with reservation token and expected save schema/revision.
5. Host checks reservation validity, sender ownership, duplicate character lock, profile claim (to the extent verifiable for peer-hosted sessions), and compatibility. Host cannot cryptographically prove a remote user's local file ownership without a separate identity service; **do not claim strong remote account authentication**.
6. Host confirms `CHARACTER_SELECTED`, then `READY` only after world baseline/scene readiness. Spawn occurs once, on transition to `ACTIVE`.
7. Cancel, timeout, disconnect, or rejected character selection releases locks and capacity. Cleanup is idempotent.
8. On reconnect, do **not** silently rebind a character. Rejoin must pass host validation; reconnect grace and resume are deferred until explicitly specified.

**Capacity examples:** 4 local on one peer; 2+2; 3+1; 2+1+1; 1+1+1+1. Fifth reservation rejected, including while four seats are only reserved. If a remote peer disconnects, release *all* its owned slots and character locks.

## 6. RPC validation and session lifecycle

**Host-side RPC rules:**

1. Receive RPC and immediately obtain `multiplayer.get_remote_sender_id()` inside the RPC handler; do not accept a payload's `peer_id` as proof.
2. Resolve sender's registered `session_player_id` / `local_slot_id` pair. Validate session state and slot ownership.
3. Check reservation token where applicable, schema version, payload types, lengths, rate limits, expected revision and idempotency key.
4. Validate requested action against authoritative world/character state; apply exactly once, increment revision, send result to owning peer, broadcast necessary state deltas.
5. On rejection, return a stable error code without changing state. Avoid sending another player's private profile data.
6. RPC functions are explicit allowlists with `@rpc` annotations; do not expose generic remote property mutation, arbitrary resource paths, or arbitrary method dispatch.

**Messages (draft wire contract; finalize as M0 code types):**

| Message | Direction | Payload | Validation |
|---|---|---|---|
| `request_slot` | client→host | `request_id`, `local_slot_id`, `protocol_version` | sender, capacity, local-slot uniqueness, rate limit |
| `slot_result` | host→client | `request_id`, `accepted`, `session_player_id?`, `reservation_token?`, `error_code?`, `revision` | targeted to sender |
| `select_character` | client→host | `request_id`, `session_player_id`, `reservation_token`, `character_id`, `owner_profile_id`, `save_schema`, `save_revision` | token+sender, unique character, compatibility |
| `character_result` | host→client | `request_id`, `accepted`, `error_code?`, `revision` | targeted to owner |
| `client_world_ready` | client→host | `transition_id`, `session_player_id`, `baseline_revision` | active transition, owning sender, correct baseline |
| `submit_input` | client→host | `session_player_id`, `input_sequence`, `client_tick`, axes/buttons | active ownership, rate, range, sequence |
| `state_delta` | host→client | `world_revision`, actor state changes | host-origin only; monotonic |
| `release_slot` | client→host | `request_id`, `session_player_id`, `reservation_token?` | owning sender, idempotent |

**Session states:** `OFFLINE` → `HOSTING|CONNECTING` → `LOBBY` → `LOADING_WORLD` → `IN_WORLD` → `RETURNING_TO_TOWN` → `LOBBY|SHUTTING_DOWN` → `OFFLINE`. Error/disconnect paths must close sockets, cancel reservations, free actors and prevent stale RPCs from applying to a new session. Every session has an opaque `session_id` and `session_epoch`; network messages carry/are checked against current epoch where appropriate.

**M0 scope:** identity registry, local in-memory lobby, pure authorization tests and message DTOs. **M2 scope:** actual ENet RPC transport, replicated actors, scene barrier, hybrid sessions. Do not claim network play is complete at M0.

## 7. Local devices and split-screen (M1–M2)

- Listen for Godot joypad connect/disconnect and route device IDs only inside that machine. No device ID is persistent character identity.
- Each `device_id` maps to zero or one `local_slot_id`; each local slot maps to zero or one active `session_player_id`.
- Local input routing produces a normalized `InputCommand` per slot per tick. Never poll a global action state to control every actor.
- For four controllers, create four distinct input contexts and four viewports/cameras/HUDs; the same game world is rendered into each viewport.
- Keyboard/mouse is assigned to one configured local slot by default; multi-keyboard support is not required.
- On disconnect, pause **only that local player's input**, show a reconnect/rebind overlay, preserve host-owned slot state pending explicit disconnect policy. No automatic reassignment.
- Test Start×2 from the same unassigned device, simultaneous Start on two devices, cancel/timeout, and Start on an already assigned device.
- Layout proposals: one viewport full; two equal halves; three two top plus one bottom; four 2×2. The three-player layout is provisional and must be accessibility-tested.

## 8. Character persistence and minimal town (M3)

- Store profiles under `user://profiles/<owner_profile_id>/characters/<character_id>.json`; reject traversal and unknown UUIDs.
- Save envelope: `schema_version`, `character_id`, `owner_profile_id`, `revision`, `written_at_utc`, `checksum`, `payload`.
- On authoritative town entry, immediately enqueue a save for that character; when dirty while in town, debounce by approximately 2 seconds and save at least every 30 seconds while dirty; request flush on town exit and normal shutdown.
- Serialize writes per character. Reject older revisions; use temp file, flush/close, backup last-known-good, then replacement with verified recovery behavior on Windows **and** Linux. Do not assume rename semantics are identical; test failure injection.
- Host validates character progression during play; the owning device stores the latest confirmed snapshot. If host and owning device are different, send only the owning character's snapshot through a validated message; await owner-side save acknowledgment before reporting success.
- Save failure must show error and keep dirty data available for retry; do not silently claim success. A minimal town with safe-zone collider and one spawn point is sufficient for M3.
- Persistent guest profiles survive restart and cannot overwrite another guest's character. A controller swap must not move save ownership.
- M3 need not implement full inventory, merchants, loot, or death penalties, but schemas must leave versioned extension points for them.

## 9. Cross-platform build and testing contract

**Operating systems:** Windows x64 and Linux x86_64 are the proposed first targets. The user has requested both functioning by M3. No macOS/console acceptance is implied. Windows and Linux are first-class development environments from M0 onward.

**Version discipline:** use the same exact Godot 4.7.2 executable/build on each runner if available; verify with `godot --version` (or platform-specific binary). If unavailable, do not substitute a different engine version silently; document blocker and ask for approval.

**Text/repo discipline:** UTF-8, LF text normalization via `.gitattributes`, case-sensitive path checks on Linux, no absolute Windows drive paths, no hardcoded Linux home paths, no committed `.godot/` cache, exported binaries, credentials, or `user://` saves. Git LFS for large source assets if needed; choose policy before adding large assets.

**Test levels:**

1. **Static:** Godot project import/load, parse errors, missing resource paths, warnings reviewed; verify engine version.
2. **Unit:** headless GDScript tests for registry, slot transitions, duplicate-character prevention, validation, save revision logic, vote majority math (later).
3. **Integration:** launch multiple headless Godot processes on loopback for host/client protocol tests; exercise 1+1, 2+2, 3+1, 2+1+1 where practical; collect deterministic logs and bounded timeouts.
4. **Manual smoke:** Windows and Linux GUI launch, controller detection, two-press joining, multiple local cameras, town save/restart. Human verification is required for actual gamepad hardware and visual legibility unless test hardware is attached.
5. **Failure injection:** duplicate/reordered messages, malformed IDs, invalid tokens, disconnects, full slots, interrupted saves, stale revisions, world-load timeouts.

**Test harness:** `tests/run_all.gd` runs as a Godot `SceneTree` script and exits with `quit(0)` on pass or nonzero on fail; no mandatory third-party framework. `tools/test.sh` and `tools/test.ps1` use an explicit configurable Godot binary path and save JUnit XML (optional first iteration) plus plain logs. Do not write a test runner that silently swallows nonzero exit codes.

**Suggested commands (after harness is implemented):**

```bash
# Linux / DeepSeek workspace
GODOT_BIN=/path/to/godot ./tools/test.sh
# Underlying Godot invocation:
/path/to/godot --headless --path . --script res://tests/run_all.gd
```

```powershell
# Windows / user PC, Codex or DeepSeek with approved local access
$env:GODOT_BIN = 'C:\path\to\Godot.exe'
./tools/test.ps1
# Underlying Godot invocation:
& $env:GODOT_BIN --headless --path . --script res://tests/run_all.gd
```

These are **target commands**, not proof that scripts or tests already exist.

**CI (GitHub Actions):** trigger on PR and push to protected main; matrix Windows/Linux; pin verified Godot version and download source/checksum; run headless import and tests; upload logs even on failure. If runner cannot install the specified version, fail visibly. Require both platform checks before merging foundation changes.

**DeepSeek test-executor role:** may edit/test in its Linux workspace and, if explicitly configured and permitted, run the same scripts on the user's Windows PC. Require it to return: commit SHA, OS, exact Godot version, full command, exit code, test counts, relevant log excerpt, and artifacts. DeepSeek's report is evidence only if logs can be inspected. Do not assume it can run a local PC command unless the user has granted the required environment access. Never give automated agents blanket permission to alter unrelated PC files, secrets, firewall, router, or GitHub settings.

## 10. GitHub workflow and agent collaboration

- GitHub repository name/URL and public/private setting remain to be chosen; do not fabricate a remote.
- Proposed branch naming: `feature/m0-identity`, `feature/m1-local-join`, `feature/m2-enet-hybrid`, `feature/m3-save-town`.
- Small pull requests with an issue/spec reference, updated tests, Windows/Linux evidence, and a concise change log.
- DeepSeek may draft or run tests; final merge should occur only after user review/approval of concrete changes. Avoid simultaneous edits to the same files from Windows and Linux workspaces.
- Record tool/version mismatches and architectural changes in ADRs; update `MASTER_BLUEPRINT.md` and relevant feature specs in the same PR.
- GitHub Actions secrets remain in GitHub secret storage, never in repository files or agent logs.

## 11. Work packages and acceptance gates

### M0 — Identity and project skeleton

- [ ] `project.godot` opens in the approved engine on both OSes.
- [ ] GitHub repo initialized with cross-platform text and ignore rules.
- [ ] Pure identity DTOs, slot enum and session registry implemented.
- [ ] `LobbyService` reserves/rejects/releases slots, validates duplicate characters, enforces 4-player cap.
- [ ] Pure RPC authorizer validates sender/slot mapping and stale revisions.
- [ ] Headless tests run on Windows and Linux, with logs and nonzero exit on failure.
- [ ] `MP-01` evidence includes 4 accepted reservations, fifth rejected, multi-slot same peer, duplicate-character rejected, timeout cleanup, idempotent release.

**M0 exit:** project loads and the in-memory lobby/identity contracts pass headless tests on both OSes. No playable multiplayer is implied.

### M1 — Local joining and character selection

- [ ] Device registry, Start×2 join gesture, per-player input contexts.
- [ ] Character creation/selection UI and persistent local owner-profile IDs.
- [ ] Four local slots can select distinct characters; assigned Start opens own menu.
- [ ] Independent local viewport/HUD prototype; no focus crossover.
- [ ] Automated join state tests and manual Windows/Linux gamepad smoke evidence.

**M1 exit:** four local players can be identified, assigned and gated through character selection without spawning prematurely.

### M2 — ENet and shared world

- [ ] Host/client LAN/direct-IP session and validated RPC transport.
- [ ] Authoritative graybox actor spawn and movement; baseline synchronization.
- [ ] Hybrid 2+2, 3+1, 2+1+1 and four-online configurations tested where hardware/processes allow.
- [ ] Disconnect cleanup, late join, world loading barrier, and duplicate RPC defenses.
- [ ] Windows↔Linux interoperability test (host on each OS in separate runs).

**M2 exit:** cross-platform hybrid session enters a shared graybox world with authoritative state and isolated local input.

### M3 — Town, saves, recovery

- [ ] Minimal town region and independent per-character entry events.
- [ ] Profile-isolated, versioned character saves; 2s debounce, 30s dirty interval, entry trigger, exit flush.
- [ ] Atomic/backup recovery and save revision protection tested on Windows and Linux.
- [ ] Persistent couch guests reload after restart; no profile collisions.
- [ ] Host-authoritative snapshot delivery and owner-device acknowledgment.
- [ ] Exported or runnable Windows and Linux builds complete the town save/reload smoke scenario.

**M3 exit:** Windows and Linux builds function, including mixed-OS network session, independent town autosaving and character persistence. Exact packaging/distribution target will be set before M3 export work.

## 12. Test case catalog (minimum)

| Test ID | Scenario | Pass condition |
|---|---|---|
| M0-01 | Reserve 4 slots | Four unique `session_player_id`s, capacity count 4 |
| M0-02 | Reserve 5th slot | Stable `LOBBY_FULL`, no state mutation |
| M0-03 | Two slots on one peer | Both valid and independently mapped |
| M0-04 | Same local slot twice | Second request rejected or idempotently resolved; no extra capacity |
| M0-05 | Duplicate character selection | One approved; second rejected |
| M0-06 | Reservation expires | Slot and character locks released once |
| M0-07 | Forged RPC sender/slot | Rejected with no state change |
| M0-08 | Replayed request ID | No duplicate reservation or mutation |
| M1-01 | One Start press | Prompt only; no reservation/spawn |
| M1-02 | Two Starts on same device | Character selection opens after reservation |
| M1-03 | Start on assigned device | Own menu only; no fifth join |
| M1-04 | Four controllers | No cross-input or cross-focus |
| M2-01 | 2+2 mixed peers | Four independent actors and inputs |
| M2-02 | Windows host/Linux client | Same authoritative world state |
| M2-03 | Linux host/Windows client | Same authoritative world state |
| M2-04 | Late join during load | Spawn only after ready/baseline barrier |
| M3-01 | Town entry for four players | Four independent immediate save requests |
| M3-02 | Dirty while in town | Debounced save and 30s interval behave as specified |
| M3-03 | Crash/interrupted write | Recover valid primary/backup without false success |
| M3-04 | Stale save revision | Newer save is not overwritten |
| M3-05 | Guest profile restart | Character state persists independently |

## 13. Risks, limitations and open implementation choices

1. **Godot 4.7.2 availability:** project owner selected this version; verify actual binaries for Windows/Linux and CI. No fabricated version validation.
2. **Internet connectivity:** LAN/direct IP does not guarantee connectivity through NAT/firewalls; relay, matchmaking and router configuration are not approved v0.1 deliverables.
3. **Remote identity security:** UUID + ownership claims are not strong online authentication. Document trust boundary; don't imply anti-cheat/account security is complete.
4. **Testing access:** DeepSeek may run tests on the PC only within the permissions and workspace the user provides; require logs. No claim that agents are connected right now.
5. **Controller hardware:** CI can test input routing logic, not automatically prove physical four-gamepad behavior on every OS.
6. **Save guarantees:** atomicity and crash recovery differ by OS/filesystem; fault injection on both platforms is mandatory.
7. **Performance:** four-camera budget and minimum hardware remain OPEN; profile before promising a frame-rate target.
8. **Implementation defaults:** reservation TTL, confirmation window, naming limits, three-player viewport arrangement, and profile migration policy can be amended during M0–M3 via recorded review.

## 14. First task to delegate

**M0-01 — Repository skeleton + test harness.** Create the Godot 4.7.2 project structure, portable `tools/test.sh` and `tools/test.ps1`, a deterministic `tests/run_all.gd`, `.gitignore`, `.gitattributes`, and a GitHub Actions matrix for Linux/Windows. Prove both OSes can run the exact same empty/smoke test before adding network code. **Do not claim the runner works until actual Windows and Linux logs are attached.** Then implement M0-02 identity DTOs and M0-03 reservation registry.

---

**Document status:** This is a foundation implementation contract and task plan, not an implementation artifact. All eight architecture and eight gameplay decisions are preserved; remaining tuning and policy details are explicitly OPEN.
