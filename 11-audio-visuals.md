# DUNGEONWARD — Feature 11: Audio, Visuals & Immersion

> **Version:** 0.1 · **Status:** Development specification, not implemented  
> **Master authority:** [`MASTER_BLUEPRINT.md`](MASTER_BLUEPRINT.md) v0.5  
> **Milestones:** M4–M8  
> **Prerequisites/integration:** F01, F02, F03, F07, F10, F14  
> **Engine:** Godot 4.7.2 / GDScript · **Updated:** 2026-10-26

> **Architecture approval:** ARCH-04, ARCH-08 **ACCEPTED** (2026-10-26). See [`ADR-0001-foundational-architecture.md`](ADR-0001-foundational-architecture.md). This approval does **not** resolve proposed gameplay choices or OPEN decisions.


## Accepted gameplay contracts — ADR-0002

The following design choices are **approved**, not optional proposals. See [`ADR-0002-gameplay-design-v0.1.md`](ADR-0002-gameplay-design-v0.1.md).

- **GAME-02 — Death and recovery:** On death, the character respawns with a modest gold penalty and retains all equipped and carried items. **Integration:** F01 death flow, F02 death event, F05 recovery state, F06 atomic currency debit, F09 safe respawn, F13 save revision. Exact penalty and respawn timing/location remain OPEN.
- **GAME-06 — Simple v0.1 combat:** v0.1 includes basic attacks, spells, jumping, and a simple dodge. Complex parries, stamina-gated basic attacks, and advanced combo systems are not part of the required v0.1 combat scope. **Integration:** F02 actions and F14 default mappings; exact dodge cooldown/invulnerability, spell costs, and weapon timing remain OPEN.

Exact numerical tuning and related policies identified as OPEN in ADR-0002 still require separate approval.

## 1. Purpose

Establish a cohesive original stylized low-poly dark-fantasy identity with responsive audio/VFX and scalable four-camera rendering.

## 2. Locked requirements

1. Use original assets and music; concept sheets are references, not assets to copy from other games.
2. Readable silhouettes and telegraphs take priority over ornamental effects.
3. Combat actions, hits, damage, loot, UI confirmation, and dungeon transitions provide immediate feedback.
4. Effects and audio cues are event-driven and do not alter authoritative gameplay.
5. Accessibility settings include adjustable screen shake, subtitles, audio levels, and non-color-only status cues.
6. Performance must be profiled with 1, 2, and 4 local cameras and hybrid network play.

## 3. Proposed / not yet approved

These are options shown in concepts or useful extensions, **not** committed v0.1 requirements. Resolve before implementation:

- Detailed art bible and palette
- Voice acting
- Dynamic music layers
- Advanced weather/time of day
- High-end particles, postprocessing, adaptive haptics

## 4. Data and resource contracts

| Resource / DTO | Required fields and intent |
|---|---|
| `VisualStyleGuide` | palette, silhouette rules, scale, materials, lighting budgets |
| `AudioCueDefinition` | cue_id, bus, variants, pitch/volume ranges, concurrency cap |
| `VFXDefinition` | effect_id, event trigger, lifetime, LOD, max simultaneous |
| `FeedbackEvent` | event_id, actor ID, action type, position, intensity, timestamp |

Use explicit IDs, versioned serializable DTOs, and custom Godot `Resource` definitions for static content. Validate bounds and references before use. Never serialize live scene trees as persistent data.

## 5. Proposed scenes and services

- `FeedbackBus` subscribes to authoritative events and triggers local presentation.
- `AudioManager` owns buses, ducking, concurrency limits, and 3D attenuation.
- `VFXPool` reuses effects and applies per-viewport budget/LOD.
- `EnvironmentProfile` defines fog, light, ambience, and biome palettes.
- `AccessibilityPresentationSettings` overrides camera shake, flashes, subtitles, and feedback intensity.

**Godot implementation guidance:** Keep pure calculations in testable `RefCounted`/utility classes, presentation in scenes/`Control` nodes, and session/world services in composed session-owned nodes. Avoid a monolithic autoload. Treat service names as proposed contracts until the first implementation ADR.

## 6. Interfaces and cross-feature events

- `combat_hit(event_id, position, damage_type)` → impact VFX/SFX/haptic intent.
- `enemy_telegraph(actor_id, attack_id, timing)` → readable animation/audio cue.
- `loot_spawned(event_id, rarity)` → pickup glow/audio consistent with F08.
- `biome_changed(biome_id)` → environment and music profile.
- F14 owns device-specific rumble output; F11 emits abstract feedback intensity only.

All gameplay-affecting requests return explicit success/error codes, carry stable actor/player identity and revisions where applicable, and are idempotent when retried.

## 7. Network authority and local presentation

**Authority baseline:** F04's host owns shared gameplay state and consequential transactions. Clients send input or requests, never final combat/item/currency outcomes. One network peer may represent multiple local player slots; resolve `session_player_id` through the registry and validate the actual sender. Local controllers, cameras, viewports, menu focus, and glyphs are not replicated.

**Replication baseline:** Use reliable revisioned events for durable changes and bounded snapshots for transient presentation. Late joiners receive an authoritative baseline before actor activation. Avoid applying duplicate event IDs. Purely cosmetic UI/audio may be predicted locally but cannot modify authoritative state.

## 8. Persistence and recovery

F13 owns save formats, write queues, backup, migration, and per-character revision checks. Any persistent character mutation marks that **specific character** dirty. On entering town, request an immediate save; while in town, save dirty state every **30 seconds** and debounce changes by about **2 seconds**. Flush on town exit/normal shutdown where possible. Each owning device stores its character profile using host-validated in-session state. Never let stale snapshots overwrite newer confirmed saves.

For world/run state, distinguish optional dungeon-session recovery from mandatory character town autosaves. Log and surface failed writes rather than claiming success.

## 9. Controller-first UI and accessibility

All player-facing operations must be possible with an assigned gamepad, including four-way split-screen. Each local player has independent UI focus. Respect F14 remapping, dead zones, glyph families, and device reassignment; one player's menu cannot pause the active multiplayer world. Use scalable fonts, readable iconography, and color-independent status cues.

## 10. Edge cases and failure handling

- Four viewports can multiply particle/dynamic-light cost: cap effects by viewport and priority.
- Network event replay: avoid duplicate one-shot sounds using event IDs.
- Audio source far from a player: spatialize per listener policy without fourfold amplification.
- Colorblind or low-flash mode: cues remain readable through shape/sound/text.
- Device without haptics: feedback degrades gracefully.

## 11. Development work packages

- [ ] **AV-01:** Create art/audio style guide and asset conventions.
- [ ] **AV-02:** Implement event-driven audio/VFX/feedback.
- [ ] **AV-03:** Create environment and UI feedback profiles.
- [ ] **AV-04:** Add accessibility and device-haptics bridge.
- [ ] **AV-05:** Profile/optimize split-screen and document asset pipeline.

Each package should be a reviewable change with a reproducible demo, tests, and a documented interface contract. Prioritize data/authority before content and polish.

## 12. Test plan

- [ ] Hits and interactions emit exactly one logical feedback event.
- [ ] Four-way split-screen meets measured frame-time budget on agreed hardware.
- [ ] All essential telegraphs are perceivable with effects reduced.
- [ ] Audio sliders/subtitles/shake settings persist per approved policy.
- [ ] No copyrighted reference assets are included in builds.

**Shared regression matrix:** test solo offline, two/four local, four online, and 2+2 hybrid wherever the feature changes shared state; simulate disconnect, duplicate messages, late joins, and save/reload. Record Godot version, test seed, network conditions, and reproduction steps.

## 13. Definition of done

- [ ] One polished stone-dungeon and town presentation profile exists.
- [ ] Combat, loot, UI, and transitions have readable feedback.
- [ ] Performance profile records 1/2/4 camera measurements.
- [ ] Accessibility controls demonstrably affect presentation.

Additionally: code review complete, automated tests pass, no known progression-blocking issue, gamepad-only workflow verified, multiplayer authority boundaries verified, and master/related specs updated when contracts change.

## 14. Dependencies and decisions

**Required coordination:** F01, F02, F03, F07, F10, F14. F04 is authoritative for peer/player ownership and RPC validation; F05 for persistent character identity; F13 for save schema and town autosave; F14 for device routing; F10 for per-player UI focus.

**Before implementation:** approve the relevant OPEN proposals in §3; document decisions affecting other features in an ADR and update `MASTER_BLUEPRINT.md` together with this file.

## 15. First implementation slice

Start with **AV-01 — Create art/audio style guide and asset conventions**. Build the smallest data-only prototype and test its invariants before adding final assets or broad content. Then complete packages in order while keeping all cross-feature interfaces stable.

---

**Document governance:** Master blueprint overrides this file on conflicts. Concept sheets are aesthetic references, not binding specifications. No section claims that the feature has been coded, integrated, or tested.
