# ADR-0002 — Dungeonward v0.1 Gameplay Design Decisions

> **Status:** ACCEPTED  
> **Date:** 2026-10-26  
> **Authority:** Explicit project-owner approval of eight gameplay decisions  
> **Supersedes:** Prior provisional choices on these eight topics only  
> **Related:** [ADR-0001](ADR-0001-foundational-architecture.md)

## Context

The v0.3 architecture is approved, but key gameplay defaults remained provisional. The project owner explicitly selected eight v0.1 gameplay behaviors to stabilize cross-feature implementation contracts. This ADR records exactly those choices without approving adjacent unresolved details.

## Accepted decisions and implementation consequences

### GAME-01 — Four core attributes

**Approved:** Strength, Dexterity, Vitality, Magic are the four core character attributes. No fifth core attribute (including Endurance) in v0.1.

**Contract implications:** F05 stat schema, F02 damage formulas, F06 equipment modifiers; exact derived-stat coefficients remain OPEN.

### GAME-02 — Death and recovery

**Approved:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items.

**Contract implications:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.

### GAME-03 — Personal instanced multiplayer loot

**Approved:** Each eligible player receives personal instanced loot; there is no competition to pick up another player's drops.

**Contract implications:** F08 reward authority generates player-scoped grants/visibility; F06 atomic inventory transactions. Eligibility, reward quantity, and optional trading remain OPEN.

### GAME-04 — Party-majority dungeon transitions

**Approved:** The party advances dungeon floors together after a majority vote of eligible active party members.

**Contract implications:** F01/F03/F04 implement host-owned vote and synchronized transition barrier. Majority means strictly more than half of eligible voters. Eligible roster, vote timeout, ties, abstentions, and disconnected voters need explicit policies before coding.

### GAME-05 — Persistent couch profiles

**Approved:** Couch co-op uses separate local owner profiles; guest characters persist across sessions instead of being temporary.

**Contract implications:** F05 local profile registry and character UUIDs; F13 profile-isolated save directories. Guest export, migration, profile deletion, and account linking remain OPEN.

### GAME-06 — Simple v0.1 combat

**Approved:** v0.1 includes basic attacks, spells, jumping, and a simple dodge. Complex parries, stamina-gated basic attacks, and advanced combo systems are not part of the required v0.1 combat scope.

**Contract implications:** F02 actions and F14 default mappings; exact dodge cooldown/invulnerability, spell costs, and weapon timing remain OPEN.

### GAME-07 — Difficulty and rewards

**Approved:** Offer four difficulty presets, bounded custom sliders, and modest capped reward bonuses tied to approved difficulty settings.

**Contract implications:** F12 versioned profile and caps, F08 reward multiplier integration. Preset names, exact caps and reward curve remain OPEN.

### GAME-08 — Slot-based grid inventory

**Approved:** Use a slot-based grid inventory, not a weight-based or category-only inventory as the default v0.1 model.

**Contract implications:** F06 grid-slot transaction schema and F10 controller-first grid UI. Dimensions, stack limits, equipment slots, and overflow policy remain OPEN.

## Integration invariants

- F05 has exactly four core attributes: Strength, Dexterity, Vitality, Magic. Derived stats may exist but are not a fifth core attribute.
- Death recovery retains items and equipment; the gold penalty must be a single host-validated idempotent currency transaction, never a client-side debit.
- Personal loot grants and world pickup visibility are scoped by eligible `session_player_id` / `character_id`; duplicate reward events cannot grant twice.
- A floor transition requires a host-authorized majority vote, then a shared F04 readiness/baseline barrier. Do not allow a single client to load the next floor unilaterally.
- Couch guests have stable local owner profiles and persistent save paths, independent of input-device IDs.
- Simple dodge is a required action. Stamina/parry/advanced combos are not required v0.1 dependencies.
- Reward bonuses are capped, host-resolved, and visible to players; their numeric bounds must be specified before balancing.
- Grid inventory positions and operations are validated by the host and saved as revisioned character state.

## Not decided by this ADR

- Attribute formulas, point allocation, XP curve, stat caps, respec mechanics.
- Gold loss percentage/flat amount, respawn location, invulnerability window, dungeon failure rules.
- Loot eligibility, drop quantity, trading/gifting, shared quest rewards, instancing for chests.
- Vote eligibility (including downed/disconnected players), vote duration, ties, timeout, abstentions, host override.
- Guest export/import, name uniqueness, profile deletion, storage limits.
- Spell list, mana costs, dodge frames/cooldown, ranged weapon support beyond existing design goals.
- Preset names, exact slider limits, bonus multipliers, reward anti-exploit constraints.
- Inventory grid dimensions, item footprint (single vs multi-cell), stack sizes, sorting, overflow and trading.
- Any feature explicitly deferred by ADR-0001 (host migration, cloud saves, public matchmaking, etc.).

## Implementation gates

1. M0 multiplayer identity and lobby contracts proceed unchanged under ADR-0001.
2. F05 character schema must lock the four-attribute keys before persistence implementation.
3. F01/F04/F03 must agree on a vote state machine and eligible roster policy before implementing floor advancement.
4. F06/F08 must share player-scoped item grant and grid-slot transaction DTOs before implementing loot.
5. F12 must publish bounded preset/custom settings and reward cap data before F08 reward balancing.
6. F13 must isolate persistent guest profile saves and maintain revision monotonicity.

## Verification

- Four attributes serialize, load, and compute effective stats without a fifth core attribute.
- Death debits gold at most once and preserves all item instance IDs/equipment.
- Two players cannot claim each other's personal drops; each eligible player can claim their own reward once.
- Two-player majority requires 2 yes; three-player majority requires 2 yes; four-player majority requires 3 yes, subject to approved eligibility policy.
- Persistent couch guest profiles survive app restart and cannot overwrite each other.
- Basic attack, spell, jump, and dodge work with controller-only input and host authority.
- Difficulty bonuses never exceed the approved cap; host/client snapshots agree.
- Grid item moves/equips are atomic and duplicate network requests cannot duplicate items.

## Change control

To change an approved decision, create an amending or superseding ADR and update the master blueprint plus every affected feature specification. Approval records are design decisions, **not** claims of implementation or testing.
