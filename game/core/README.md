# Core module boundaries

Reserved Foundation v0.5 domains; these directories contain no implemented services:

- `identity`: peer, local-slot, session-player and persistent-character records.
- `lobby`: session-scoped reservations and character locks.
- `network`: ENet adapter and sender-bound authorization.
- `input`: device ownership and local input routing.
- `characters`: profile definitions and local ownership validation.
- `save`: owner-device storage and town-save scheduling.
- `world`: shared-world transitions and readiness barriers.

Keep deterministic domain logic independent of scene trees, rendering and transport.
Inject clocks, storage and transport at composition boundaries when implemented.
No autoload is needed for the current shell. See ADR-0003 for proposed interfaces;
these reserved paths do not finalize APIs or implement multiplayer/persistence.
