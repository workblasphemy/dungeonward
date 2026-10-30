```status
Seq: 0014
Date: 2026-10-30 00:55 PDT
Verdict: IMPLEMENTED
Type: feature
Build/commit: 38c8d72a0cd0720e0f59af04eb90742621611b10
Feature/task IDs: M1-IP-01
Reviewed note: 0013
Next owner: deepseek
Next action: Verify M1 device registry on Windows and Ubuntu CI; audit disconnect ownership, invalid IDs, no silent reassignment; report any failures.
```

# M1 IP-01 — pure local device ownership

**Agent / branch:** codex / feature/m0-foundation
**Goal:** implement the first M1 slice: controller-to-local-slot ownership without network or persistence coupling.
**Scope:** game/core/input/device_registry.gd; tests/run_all.gd.
**Read:** 00_SHARED_RULES.md, 01_CODEX.md, FOUNDATION_IMPLEMENTATION_SPEC.md section 7, 14-controller-input.md, LATEST, STATUS, DECISIONS.
**Inputs / existing interfaces:** local slot 0–3; peer_id and character_id are distinct from device IDs.
**Constraints:** no new numeric tuning; four slots from approved capacity; D-001–D-004 remain open.
**Deliverables:** pure RefCounted registry and tests.
**Acceptance tests:** Godot 4.7.2 Windows/Linux test scripts, negative control, CI.
**Return:** two code commits, tests pending.

## Changed files

- game/core/input/device_registry.gd: unique device↔slot ownership, explicit unbind, disconnect retaining ownership, same-device reconnect, sorted nonsecret assignment snapshots.
- tests/run_all.gd: 14 checks including load and negative cases. Expected normal 97 checks (83+14), to be verified.

## Commands run

- GitHub connector: created implementation commit fed5a7ac18b0c327f5ee220e4d17f68217b78b86 and test commit 38c8d72a0cd0720e0f59af04eb90742621611b10.
- Windows/Linux Godot: **not run** in this session.
- GitHub Actions for latest code: **not yet verified**.
- Handoff checker: **not run** in this session.

## Assumptions

- Device ID is a nonnegative transient local identifier. Device-to-slot assignment is explicit and only made after the join flow authorizes it.
- A disconnected controller remains assigned; new OS device IDs require explicit rebind policy later.

## Risks

- No Godot scene/input event integration yet; this is a pure contract slice, not a working Start×2 UI.
- Future local input adapter must never confuse device_id with peer_id.
- Connector pushes are separate and may violate the two-commit one-push handoff rule; verify CI.

## Open questions

- None new; D-001–D-004 remain OPEN.

## Handoff detail for next owner

- Run normal tests and negative control on Windows and Ubuntu; inspect Godot parser warnings.
- Probe 4 devices, fifth rejection by occupied slots, hotplug, explicit unbind, same device rebind, invalid IDs, and snapshot isolation.
- Next M1 slice after approval: IP-02 Start×2 join state machine; do not implement unapproved timeout tuning.

## Proof

not used
