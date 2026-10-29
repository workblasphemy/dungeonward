# Dungeonward — Feature Development Specifications

These 14 documents accompany `MASTER_BLUEPRINT.md` v0.5. They are development specifications, not implemented features.

## Recommended development order

| Priority | Feature | File |
|---:|---|---|
| 1 | Multiplayer System | [`04-multiplayer.md`](04-multiplayer.md) |
| 2 | Controller & Input | [`14-controller-input.md`](14-controller-input.md) |
| 3 | Character System | [`05-character-system.md`](05-character-system.md) |
| 4 | Save & Persistence | [`13-save-persistence.md`](13-save-persistence.md) |
| 5 | UI & Menu System | [`10-ui-menus.md`](10-ui-menus.md) |
| 6 | Core Gameplay | [`01-core-gameplay.md`](01-core-gameplay.md) |
| 7 | Combat System | [`02-combat.md`](02-combat.md) |
| 8 | Enemy System & AI | [`07-enemy-ai.md`](07-enemy-ai.md) |
| 9 | Procedural Dungeon Generation | [`03-dungeon-generation.md`](03-dungeon-generation.md) |
| 10 | Difficulty & Scaling | [`12-difficulty-scaling.md`](12-difficulty-scaling.md) |
| 11 | Inventory & Equipment | [`06-inventory-equipment.md`](06-inventory-equipment.md) |
| 12 | Loot & Reward System | [`08-loot-rewards.md`](08-loot-rewards.md) |
| 13 | Town & Hub System | [`09-town-hub.md`](09-town-hub.md) |
| 14 | Audio, Visuals & Immersion | [`11-audio-visuals.md`](11-audio-visuals.md) |

## Working rules

- Master blueprint controls cross-feature decisions.
- Proposed and OPEN mechanics need approval.
- Build contracts/tests before content polish.
- Keep ADRs and affected specs synchronized.
- Verify four-player hybrid, controller-only UI, and independent town autosaving.

## Accepted architecture

- [ADR-0001: Foundational Architecture](ADR-0001-foundational-architecture.md) — ARCH-01 through ARCH-08 approved on 2026-10-26.
- All gameplay decisions not explicitly included in ADR-0001 remain OPEN.

- [ADR-0002: v0.1 Gameplay Design](ADR-0002-gameplay-design-v0.1.md) — GAME-01 through GAME-08 approved on 2026-10-26. Numeric tuning and adjacent policies remain OPEN.

## Foundation M0–M3

- [Foundation Implementation Specification](FOUNDATION_IMPLEMENTATION_SPEC.md) — Godot 4.7.2 target, Windows/Linux by M3, identity DTOs, RPC, input, saving, and test/CI contracts.
