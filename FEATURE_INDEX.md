# Dungeonward — Feature Development Specifications

These 14 documents accompany `MASTER_BLUEPRINT.md` v0.4. They are development specifications, not implemented features.

## Recommended development order

| Priority | Feature | File |
|---:|---|---|
| 1 | Multiplayer System | [`features/04-multiplayer.md`](features/04-multiplayer.md) |
| 2 | Controller & Input | [`features/14-controller-input.md`](features/14-controller-input.md) |
| 3 | Character System | [`features/05-character-system.md`](features/05-character-system.md) |
| 4 | Save & Persistence | [`features/13-save-persistence.md`](features/13-save-persistence.md) |
| 5 | UI & Menu System | [`features/10-ui-menus.md`](features/10-ui-menus.md) |
| 6 | Core Gameplay | [`features/01-core-gameplay.md`](features/01-core-gameplay.md) |
| 7 | Combat System | [`features/02-combat.md`](features/02-combat.md) |
| 8 | Enemy System & AI | [`features/07-enemy-ai.md`](features/07-enemy-ai.md) |
| 9 | Procedural Dungeon Generation | [`features/03-dungeon-generation.md`](features/03-dungeon-generation.md) |
| 10 | Difficulty & Scaling | [`features/12-difficulty-scaling.md`](features/12-difficulty-scaling.md) |
| 11 | Inventory & Equipment | [`features/06-inventory-equipment.md`](features/06-inventory-equipment.md) |
| 12 | Loot & Reward System | [`features/08-loot-rewards.md`](features/08-loot-rewards.md) |
| 13 | Town & Hub System | [`features/09-town-hub.md`](features/09-town-hub.md) |
| 14 | Audio, Visuals & Immersion | [`features/11-audio-visuals.md`](features/11-audio-visuals.md) |

## Working rules

- Master blueprint controls cross-feature decisions.
- Proposed and OPEN mechanics need approval.
- Build contracts/tests before content polish.
- Keep ADRs and affected specs synchronized.
- Verify four-player hybrid, controller-only UI, and independent town autosaving.

## Accepted architecture

- [ADR-0001: Foundational Architecture](docs/adr/ADR-0001-foundational-architecture.md) — ARCH-01 through ARCH-08 approved on 2026-10-26.
- All gameplay decisions not explicitly included in ADR-0001 remain OPEN.

- [ADR-0002: v0.1 Gameplay Design](docs/adr/ADR-0002-gameplay-design-v0.1.md) — GAME-01 through GAME-08 approved on 2026-10-26. Numeric tuning and adjacent policies remain OPEN.

## Foundation M0–M3

- [Foundation Implementation Specification](docs/FOUNDATION_IMPLEMENTATION_SPEC.md) — Godot 4.7.2 target, Windows/Linux by M3, identity DTOs, RPC, input, saving, and test/CI contracts.
