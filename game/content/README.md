# Future authored content

`weapons/` and `bosses/` reserve locations for future content only. No weapons,
bosses, stats or combat behavior are implemented in M0.

Proposed conventions awaiting ADR-0003 review:

- Typed Resources describe authored definitions; reusable scenes/components supply
  behavior. Keep content data separate from player-specific runtime state.
- Refer to content by stable namespaced IDs (for example `dungeonward:example`),
  never display names, filesystem paths supplied by clients, or array positions.
- Define schema version, required fields and validation tests before creating bulk
  content. Renaming a file must not silently change an item's persistent identity.
- Weapon definitions may reference reviewed action components; boss scenes compose
  reviewed actor components. Neither may mutate saves or bypass host authority.
- A content registry and compatibility policy require a separate reviewed contract;
  M0 adds no dynamic registry, plugin loader or new gameplay values.
