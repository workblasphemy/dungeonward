```status
Seq: 0018
Date: 2026-10-30 12:10 PDT
Verdict: APPROVED
Type: review
Build/commit: ff77d66da50db2590631c034232b9c48b90cf2b7
Feature/task IDs: M1-IP-01, handoff-protocol
Reviewed note: 0017
Next owner: codex
Next action: Implement IP-02 Start×2 join state machine as a bounded M1 slice; preserve solo, couch co-op, online invite, and hybrid lobby paths without forcing a full lobby.
```

# Codex review — accept M1-IP-01 and authorize IP-02

**Agent / branch:** codex / feature/m0-foundation
**Goal:** review DeepSeek 0017 and decide whether IP-01 meets acceptance and IP-02 may begin.
**Scope:** review and handoff metadata only; no game code changes.
**Read:** handoffs/LATEST.md, 0017_deepseek_verify-m1-ip01.md, STATUS.md, DECISIONS_NEEDED.md, 0016, 01_CODEX.md, handoff protocol.
**Inputs / existing interfaces:** local device-to-slot registry at ff77d66; Godot 4.7.2.
**Constraints / explicitly unresolved decisions:** D-001–D-004 remain OPEN; do not merge main or implement unapproved tuning.
**Deliverables:** acceptance decision and next bounded task.

## Decision

**APPROVED — M1-IP-01.** DeepSeek verified the corrected registry from a genuine clean checkout at ff77d66. The previous native method collision no longer prevents compilation. The Windows normal suite passed 97/0 and the intentional negative control reported 98/1 with nonzero exit. Foundation CI passed on Windows and Ubuntu, and the handoff-check workflow passed. Independent checker cases A–G rejected invalid changes as designed, while the valid control passed.

**IP-02 authorized:** implement the pure Start×2 same-device join gesture and interface to the existing lobby reservation boundary, without spawning on Start #1, without stealing assigned devices, and without inventing a timeout value. A pre-world lobby must allow online invites, optional couch co-op, mixed parties (up to four), or starting solo; this is an architectural requirement, not a claim those features are implemented.

## Changed files

- handoffs/0018_codex_approve-m1-ip01.md (this note)
- handoffs/LATEST.md
- handoffs/STATUS.md
- No code files.

## Commands run

- Read current branch handoff, STATUS, decisions, and DeepSeek 0017 using GitHub connector.
- DeepSeek at Windows 10 x86_64, Godot 4.7.2.stable.official.ed1daf0bf, clean clone ff77d66: `run_all.gd` **97 checks, 0 failures, exit 0**.
- DeepSeek negative control: **98 checks, 1 intentional failure, exit 1**.
- GitHub Actions Foundation run 41110979558: success (Windows and Ubuntu), reported by DeepSeek.
- GitHub Actions Handoff run 41110979666: success, reported by DeepSeek.
- DeepSeek checker A–G: seven expected failures, valid control exit 0.
- Current Codex session: no Godot or checker execution; review based on 0017's evidence.
- `tools/test.ps1` not run by DeepSeek at this build; native Linux not run; Ubuntu CI covers Linux runner.

## Assumptions

- IP-01 acceptance is limited to pure device ownership and registry semantics, not complete input UI, controller hardware testing or character selection.
- Start×2 confirmation window is a proposed default; no numeric tuning is approved by this review.

## Risks

- Broken GDScript can hang the test runner; bounded `--quit-after` is recommended as a separate test-hardening task.
- Device reconnect with a new OS device ID requires explicit rebind policy later.
- A genuine online invite transport and world-start gate are later integration slices, not IP-02's pure state-machine deliverable.

## Open questions

- D-001–D-004 remain OPEN and unchanged.
- Confirmation timeout remains unapproved; IP-02 should use a configurable injected deadline or request a decision before fixing its numeric default.

## Handoff detail for next owner

- Begin IP-02 Start×2 join state machine with per-device confirmation, no reservation on first press, and no duplicate joins.
- Use the M0 host reservation boundary, keeping separate local device, local slot, peer and session-player identities.
- Include tests for two simultaneous devices, assigned-device Start, timeout/cancel, capacity, and solo lobby entry.
- Keep work on feature/m0-foundation; no main merge.

## Proof

- Command: `godot --headless --path . --script res://tests/run_all.gd`
- OS/environment: Windows 10 x86_64, clean checkout ff77d66
- Godot version: 4.7.2.stable.official.ed1daf0bf
- Who/where: DeepSeek, handoff 0017
- Log: 0017_deepseek_verify-m1-ip01.md, 97 checks / 0 failures, exit 0

- Command: `godot --headless --path . --script res://tests/run_all.gd -- --self-test-failure`
- OS/environment: Windows 10 x86_64, clean checkout ff77d66
- Godot version: 4.7.2.stable.official.ed1daf0bf
- Who/where: DeepSeek, handoff 0017
- Log: 0017_deepseek_verify-m1-ip01.md, 98 checks / 1 intentional failure, exit 1

- Command: Foundation CI workflow
- OS/environment: GitHub Actions Windows and Ubuntu
- Godot version: 4.7.2.stable.official.ed1daf0bf
- Who/where: GitHub Actions run 41110979558, reported by DeepSeek 0017
- Log: https://github.com/workblasphemy/dungeonward/actions/runs/41110979558

- Command: handoff checker A–G and control
- OS/environment: Windows 10 x86_64, Python 3.14, real Git clone
- Godot version: not applicable
- Who/where: DeepSeek, handoff 0017
- Log: 0017_deepseek_verify-m1-ip01.md, A–G rejected, control 0 failures
