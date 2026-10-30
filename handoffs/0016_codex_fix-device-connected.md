```status
Seq: 0016
Date: 2026-10-30 11:54 PDT
Verdict: IMPLEMENTED
Type: fix
Build/commit: 2d95288af9e761786e78a5c1c79340439e57da39
Feature/task IDs: M1-IP-01
Reviewed note: 0015
Next owner: deepseek
Next action: Verify corrected M1-IP-01 on Windows and Ubuntu CI, including normal and negative-control suites; return test-run handoff before IP-02.
```

# Codex fix — M1 device registry inherited method collision

**Agent / branch:** codex / feature/m0-foundation
**Goal:** apply DeepSeek's exact CHANGES_REQUESTED correction.
**Scope:** game/core/input/device_registry.gd and tests/run_all.gd.
**Read:** 0015, LATEST, STATUS, M1 device registry and test references.
**Constraints:** M0 approved; M1 authorized; D-001–D-004 unchanged.
**Deliverables:** method rename and handoff for fresh CI.
**Acceptance:** Godot 4.7.2 Windows and Ubuntu normal and negative tests.

## Changed files

- game/core/input/device_registry.gd: `is_connected` renamed to `device_is_connected` to avoid inherited `Object.is_connected` override.
- tests/run_all.gd: two call sites renamed.

## Commands run

- GitHub connector source updates at e8a98f9 and 2d95288.
- No local Godot executable run in this session.
- DeepSeek tested equivalent patch on Windows 10, Godot 4.7.2: 97 checks/0 failures; negative 98/1 intentional; independent 29/0.
- CI on this exact corrected commit: **not verified**.
- Handoff checker and native Linux: not run here.

## Assumptions

- The verified DeepSeek patch is equivalent to the committed rename.

## Risks

- CI hung on previous commit because parser failure left test SceneTree alive. A bounded test runner timeout is a separate hardening slice.
- Connector pushes each commit independently; handoff checker may flag code-only intermediate pushes.

## Open questions

- Fresh CI status of corrected build; no new product decisions.

## Handoff detail for next owner

- Verify new Windows and Ubuntu CI for 2d95288 and report run IDs.
- If green, hand off IP-02 Start×2 join gesture implementation.
- Pre-game lobby requirement: host may invite online players, allow couch co-op, mix both, or enter the world alone. No forced full lobby.

## Proof

not used
