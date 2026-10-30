```status
Seq: 0019
Date: 2026-10-30 12:20 PDT
Verdict: IN_PROGRESS
Type: docs
Build/commit: 4239e7e8666711cd55b8e5aec2568cb20f80a220
Feature/task IDs: M1-IP-02
Reviewed note: 0018
Next owner: gemini
Next action: Draft pure join_gesture.gd from docs/tasks/M1-IP-02-GEMINI.md; Groq independently drafts test fixtures per docs/tasks/M1-IP-02-GROQ.md. Codex reviews and integrates both.
```

# M1 IP-02 — delegation contracts established

**Agent / branch:** codex / feature/m0-foundation
**Goal:** begin M1 IP-02 by delegating bounded, disjoint boilerplate to Gemini and Groq while retaining Codex engineering review.
**Scope:** two task specifications under docs/tasks; no game code changes.
**Read:** 0018, LATEST, STATUS, DECISIONS_NEEDED, 02_GEMINI.md, 06_GROQ.md, 14-controller-input.md, 04-multiplayer.md, 05-character-system.md, device_registry.gd, lobby_registry.gd, m0_request_authorizer.gd, FOUNDATION_IMPLEMENTATION_SPEC.md.
**Inputs:** approved IP-01 registry, M0 request authorizer and host reservation.
**Constraints:** D-001–D-004 remain OPEN. Do not invent timeout tuning, implement transport or merge main.
**Deliverables:** concrete Gemini and Groq task briefs.
**Acceptance:** Codex audits submitted code, DeepSeek independently executes Godot 4.7.2 tests.

## Changed files

- docs/tasks/M1-IP-02-GEMINI.md — pure join gesture state-machine implementation contract.
- docs/tasks/M1-IP-02-GROQ.md — disjoint test fixtures and regression cases.
- handoffs/0019_codex_delegate-m1-ip02.md, LATEST.md and STATUS.md.

## Commands run

- Read relevant specifications and current source through GitHub connector.
- Created docs task commit 4239e7e8666711cd55b8e5aec2568cb20f80a220.
- No Gemini or Groq model invocation available in this session; **drafting not yet executed**.
- No Godot tests run; no implementation committed.
- CI pending on documentation handoff.

## Assumptions

- Gemini and Groq receive task briefs through the repository and return draft files for Codex review.
- Confirmation duration must be injected by caller; no new fixed default approved.
- A pre-world lobby supports solo, optional couch, online invites and hybrid; IP-02 handles only local gesture, not invitations.

## Risks

- Work is delegated but not completed; don't label it IMPLEMENTED.
- Groq test names must match Gemini's actual reviewed API; Codex owns adaptation.
- A disconnected controller's slot cannot be stolen without explicit release.

## Open questions

- D-001–D-004 remain OPEN; no new numeric default approved.

## Handoff detail for next owner

- Gemini: produce join_gesture.gd against bounded contract; hand back source, no push without coordination.
- Groq: produce test_join_gesture.gd against bounded contract; hand back source, no push without coordination.
- Codex: review both, integrate with run_all.gd, run CI and assign DeepSeek independent verification.

## Proof

not used
