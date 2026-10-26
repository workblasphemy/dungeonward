# ADR-0001 — Dungeonward v0.1 Foundational Architecture Approval

> **Status:** ACCEPTED  
> **Date:** 2026-10-26  
> **Decision authority:** Explicit user approval of ARCH-01 through ARCH-08  
> **Applies to:** `MASTER_BLUEPRINT.md` and all feature specifications  
> **Scope:** Architectural foundation only; gameplay options remain unresolved.

## Context

Dungeonward requires 1–4 player local, online and hybrid co-op, character-gated joining, reliable per-character persistence, and a modular Godot 4 codebase. These eight architectural contracts were presented together and explicitly approved by the project owner.

## Accepted decisions

### ARCH-01 — Host-authoritative ENet

**Decision:** Use peer-hosted Godot 4 ENet with host-authoritative shared world simulation. Start with LAN/direct IP; matchmaking, dedicated servers and host migration are not approved for v0.1.

**Implementation consequence:** Transport abstraction, sender-bound RPC authorization, host-owned simulation; disconnect ends session when host leaves.

### ARCH-02 — Four character slots

**Decision:** Enforce at most four active or reserved character slots per session, independent of network-peer count. One peer may own multiple local players.

**Implementation consequence:** Distinct peer_id, local_slot_id, session_player_id and character_id; capacity and duplicate-identity tests.

### ARCH-03 — Mandatory character selection

**Decision:** Unassigned controller Start once prompts; Start twice on same device requests reservation and opens character selection/creation. Only host-approved unique character may spawn.

**Implementation consequence:** Separate join gesture, reservation, selection, world sync, spawn; no automatic spawn on controller connection.

### ARCH-04 — Independent input and UI

**Decision:** Each local player has isolated device assignment, camera, viewport, HUD and focus. Multiplayer menus never globally pause gameplay.

**Implementation consequence:** Local-only device routing and viewports; per-player UI focus; disconnect/rebind path.

### ARCH-05 — Persistent character ownership

**Decision:** Each character has a stable UUID and owning local profile/device; no duplicate active/reserved character in one session. Character profiles work across solo, local, online and hybrid.

**Implementation consequence:** Ownership registry, session lock, versioned character metadata; do not conflate ENet peer IDs with persistent identity.

### ARCH-06 — Town-based autosaving

**Decision:** Independent per-character saves: immediate on entering town; while in town dirty changes debounce ~2 seconds and dirty state is saved every 30 seconds; revisioned validated snapshots, atomic replacement and backup.

**Implementation consequence:** F13 per-character scheduler and serialized write queues; host validates gameplay state, owning device stores character. Town exit/normal shutdown flush where possible.

### ARCH-07 — Shared dungeon simulation

**Decision:** One shared authoritative active dungeon floor per party in v0.1. Host supplies seed, generator version, validated layout descriptor and mutable state; synchronized scene transitions.

**Implementation consequence:** F03 generator/validator + F04 transition barrier and late-join baseline; no independent simultaneous floors in v0.1.

### ARCH-08 — Modular Godot architecture

**Decision:** Use typed/versioned resources and DTOs, small focused services, reusable actor components, documented interfaces and automated tests.

**Implementation consequence:** Prefer composed session services over a monolithic autoload; require ADR and affected-spec updates for shared contract changes.

## Cross-contract invariants

- `network peer ≠ local input slot ≠ session player ≠ persistent character`.
- No actor spawns without approved character selection and valid host slot reservation.
- Four-player cap counts reserved and active character slots, not connected peers.
- Gameplay authority is host-side; persistent character file ownership remains with the character's owning local profile/device.
- Local UI/input ownership is never derived from an untrusted remote device identifier.
- Save revisions never regress, and a save is not reported successful before the write is confirmed.
- World loading/late joins use a scene readiness barrier and authoritative mutable-state baseline.

## Explicitly NOT approved by this decision

- Exact attributes/XP formulas; death penalties; loot distribution; inventory format; trading; friendly fire; advanced combat mechanics.
- Party floor-transition voting/teleport behavior, reconnect grace time, guest-profile export rules, final controller layout.
- Cloud saves, public matchmaking, relay/NAT traversal, dedicated servers, host migration, console release, simultaneous independent floors.
- Exact save encryption, internet-facing security model, or guaranteed recovery after abrupt host failure.

## Implementation contracts / first milestone

1. **MP-01** defines `PlayerSlot`, `PeerRecord`, `SlotReservation`, `SessionPlayerRegistry`, `LobbyService` and deterministic slot/character ownership tests.
2. **F14** consumes MP-01 registry interfaces to route devices locally and implement Start×2 joining.
3. **F05** validates character selection/creation; **F04** alone approves spawn.
4. **F13** owns versioned save files, revisions, town-trigger scheduling, backup and recovery.
5. **F03** produces a versioned floor descriptor; **F04** distributes authoritative run state and handles transition barriers.

## Verification gates

- Unit tests: four reservations accepted, fifth denied, duplicate character denied, one peer owns multiple slots, release is idempotent.
- Integration: 4-local, 4-online, 2+2, 3+1, and 2+1+1 hybrid configurations.
- Character selection must precede spawn for every join path.
- Four independent town autosaves must retain distinct profiles and monotonically increasing revisions.
- Multiplayer menu focus is isolated; late join world state matches the host.

## Change control

Changes to accepted contracts require a new ADR superseding or amending this one and simultaneous updates to the master blueprint and affected feature documents. No code implementation or tests are claimed by this ADR.
