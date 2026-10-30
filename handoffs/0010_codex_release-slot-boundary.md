```status
Seq: 0010
Date: 2026-10-30 00:33 PDT
Verdict: IMPLEMENTED
Type: feature
Build/commit: 55ed5f6a086b27c9ae84470d5fa302f2368a88ce
Feature/task IDs: M0-01
Reviewed note: 0009
Next owner: deepseek
Next action: Verify release_slot authorization, idempotency, CI Windows/Linux and the M0 acceptance gates; return a test-run note.
```

# M0 release-slot authorizer and M1 readiness audit

**Agent / branch:** codex / feature/m0-foundation
**Goal:** complete the missing M0 release-slot request boundary before M1.
**Scope (files/components):** game/core/network/m0_request_authorizer.gd and tests/run_all.gd.
**Read:** AGENTS.md, handoffs/LATEST.md, 0009, STATUS, DECISIONS_NEEDED, FOUNDATION_IMPLEMENTATION_SPEC.md, registry, authorizer, tests.
**Inputs / existing interfaces:** registry.release() returns non-disclosing OK for unknown or unauthorized seats; _invoke provides per-peer replay and message validation.
**Constraints / explicitly unresolved decisions:** no ENet or world spawn; D-001–D-004 remain OPEN.
**Deliverables:** release_slot request boundary and negative tests.
**Acceptance tests / commands:** Godot Windows/Linux test runners and handoff checker; verification delegated.
**Return:** commits and unverified test status.

## Changed files

- game/core/network/m0_request_authorizer.gd: release_slot() requires request_id, session_player_id and reservation_token; validates exact keys/types and token length; routes through registry.release().
- tests/run_all.gd: eight checks for foreign release, unchanged seat, malformed token, authorized release, seat cleanup and idempotent retries.

## Commands run

- GitHub connector: fetched and reviewed current code, spec and handoff metadata; performed two source commits.
- Godot 4.7.2 Windows and Linux: **not run** in this session.
- `python tools/check_handoff.py --self-test`: **not run**.
- `python tools/check_handoff.py --base ... --head HEAD`: **not run**.
- Previous 76/0 Windows and CI success refer to the previous build, not this change.

## Assumptions

- release_slot remains a pure host boundary; caller obtains sender_peer_id and now_ms from trusted host context, never from the payload.

## Risks

- The connector performs separate pushes; the handoff validator may reject intermediate code-only pushes. Use a git-capable workspace for future two-commit atomic pushes.
- A future transport adapter must not allow replay of an old request_id across a new session epoch. No network transport exists at M0.
- This change is not tested and must not be called green until DeepSeek/CI verifies it.

## Open questions

- M0 acceptance: no concrete host RPC transport, world-baseline barrier, device joining, persistence or save flow yet. These are M1–M3 scope, not evidence of M0 completion.
- D-001–D-004 remain owner OPEN.

## Handoff detail for next owner

- Execute Windows and Linux Foundation tests and negative controls; expected normal count 84 if the eight new assertions execute.
- Probe foreign vs unknown release, malformed token, authorized cleanup, replay idempotency and sender isolation.
- Inspect handoff CI; confirm no regressions.
- Provide M0 readiness recommendation; do not start M1 without an acceptance decision.

## Proof

not used
