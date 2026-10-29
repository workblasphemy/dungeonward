# ADR-0003 — Modular and extensible architecture

Status: ACCEPTED — approved by project owner 2026-10-28. Originally proposed 2026-10-26.
Authority: ADR-0001 and ADR-0002 remain accepted and unchanged.

## Approved requirements carried forward

ARCH-01–08 require host-authoritative ENet, four character slots, distinct peer/local-slot/session-player/character identities, validated selection before spawn, isolated local presentation and input, owner-device revisioned saves, a shared seeded floor and modular typed/versioned contracts. GAME-01–08 remain unchanged. Modularity does not authorize matchmaking, host migration, cloud saves, arbitrary remote execution or new gameplay policies.

## Proposed implementation contracts

1. Use `game/core/<domain>` for foundational services and `game/content/` for extensible game content. Keep the master blueprint, foundation specification, ADRs, agent instructions, and feature specifications at the repository root. Reserve `docs/` for supporting development guides and test evidence. Any future documentation relocation requires updated references and validation before merging.
2. Compose session-scoped services in a minimal `SessionBootstrap` entrypoint when services exist. Pass dependencies explicitly; avoid a service locator, global event bus and unrelated autoloads. The initial shell needs no autoload.
3. Separate pure identity/lobby state from Godot scene, transport, device, clock and filesystem adapters. Inject a monotonic clock and token source into the lobby for deterministic expiry tests; production tokens must be cryptographically unpredictable.
4. Expose narrow typed operations and stable error codes. Never expose mutable registry internals or generic RPC dispatch. Read-only snapshots must not let callers mutate host state. Capture the authenticated sender inside RPC handlers; a payload cannot establish identity.
5. Use versioned Resources for authored content and explicitly validated DTOs for wire/save data. Protocol, save and content schema versions have separate compatibility decisions. Reject unsupported versions without mutation; migrations need fixtures before enabling them.
6. Extend by adding focused components/adapters and explicit composition, not dynamic downloaded plugins. No public mod API, runtime code loading or backwards-compatibility promise is approved here.
7. Test pure contracts independently; test adapters on Windows and Linux. Replay, expiry, duplicate identity, stale revision and cleanup coverage precede transport implementation.

These are approved implementation conventions drawn from Foundation v0.5; they do not change the approved gameplay rules. Current code implements only the project shell and test infrastructure. No placeholder service APIs or wire formats are locked by this ADR.

## Content, presentation and gameplay extension conventions

Reserve authored weapon and boss definitions under `game/content/`; use stable
content IDs, schema versions and validated typed Resources. Boss behavior belongs
to composed actor components, not a giant inheritance tree. UI scenes consume
view data and emit intent through explicit controllers; they do not own gameplay
or persistence. Future gameplay services live in focused domains and are composed
through explicit dependencies. See `game/core/README.md`, `game/content/README.md`
and `game/ui/README.md` for boundaries. These conventions add no gameplay,
modding API, public extension compatibility promise or final content schema.

## Consequences and alternatives

Explicit dependencies add small amounts of wiring but keep ownership and lifecycle visible. A global service locator is simpler initially but hides dependencies and cleanup; an elaborate plugin framework adds unneeded compatibility and security obligations. Both are deferred. Folder names and adapter interfaces may change during review without changing approved gameplay.

## Review and implementation gates

The project owner approved these contracts with the canonical documentation layout clarification on 2026-10-28. Add identity DTOs and an in-memory registry only after the initial harness has actual Linux and Windows evidence, as required by Foundation v0.5 §14. Transport, controllers, persistence and gameplay remain later milestones. Any accepted change to existing contracts requires concurrent blueprint and affected-spec updates under ADR-0001. This proposal does not supersede it.
