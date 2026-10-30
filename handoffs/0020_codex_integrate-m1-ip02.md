```status
Seq: 0020
Date: 2026-10-30 13:00 PDT
Verdict: IMPLEMENTED
Type: feature
Build/commit: 8a48c0a82670ee9a73e2bb8867b01e49cf349691
Feature/task IDs: M1-IP-02
Reviewed note: 0019
Next owner: deepseek
Next action: Independently verify IP-02 on clean checkout of 8a48c0a82670ee9a73e2bb8867b01e49cf349691 with Godot 4.7.2 Windows and Linux CI, normal and negative-control suites; report any parse/runtime or protocol failures.
```

# M1-IP-02 — Codex integration review of Gemini and Groq drafts

**Agent / branch:** codex / feature/m0-foundation
**Goal:** Review Gemini join-gesture and Groq test drafts from operator CODEX_PACKAGE_IP02.md; correct defects and integrate pure M1-IP-02.
**Scope (files/components):** game/core/input/join_gesture.gd; tests/unit/test_join_gesture.gd; tests/run_all.gd.
**Read:** 00_SHARED_RULES.md, 01_CODEX.md, docs/HANDOFF_PROTOCOL.md, handoffs/0019_codex_delegate-m1-ip02.md, docs/tasks/M1-IP-02-GEMINI.md, docs/tasks/M1-IP-02-GROQ.md, current device_registry.gd, current tests/run_all.gd, operator CODEX_PACKAGE_IP02.md.
**Inputs / existing interfaces:** IP-01 DeviceRegistry; M0 host authorizer remains untouched.
**Constraints / explicitly unresolved decisions:** no transport or UI; no game timeout default; D-001–D-004 OPEN; no main merge.
**Deliverables:** reviewed implementation and expanded regression suite, ready for independent verification.
**Acceptance tests / commands:** Godot 4.7.2 normal run_all, negative control, Windows/Linux CI, handoff checker.
**Return:** code commit 8a48c0a, test status not run here, outstanding integration risk.

## Changed files

- game/core/input/join_gesture.gd — per-device pure Start×2 state machine, explicit intents, host-approval and binding gate, cancellation release intent, disconnect retention.
- tests/unit/test_join_gesture.gd — regression checks for device independence, duplicate requests, invalid input, deadline, assignment, disconnect, cancellation, capacity failure.
- tests/run_all.gd — invoke new suite through existing check() callback.
- handoffs/0020_codex_integrate-m1-ip02.md, LATEST.md, STATUS.md — protocol metadata.

## Commands run

- Codex reviewed uploaded operator package, Gemini/Groq code and repo contract using file and GitHub connector.
- Codex prepared GitHub tree and code commit 8a48c0a82670ee9a73e2bb8867b01e49cf349691.
- **Godot tests NOT RUN in Codex environment** (Godot binary not available). Operator's earlier scratch 106/0 applies only to original drafts, not this reviewed integration.
- **Windows/Linux tests and CI NOT YET VERIFIED** for this code commit.
- No claims of successful execution on integrated commit.

## Assumptions

- `assigned` is an adapter observation of DeviceRegistry state, not authorization; mismatch is rejected.
- `mark_assigned(device_id, true)` must be called only after successful DeviceRegistry.bind_device and host-approved selection. Pure component cannot independently authenticate caller-provided bool.
- `INTENT_RELEASE_RESERVATION` obligates adapter to release an approved host reservation; for in-flight requests, adapter must reconcile and release any late success.
- Solo launch and online invitations are not implemented by this pure state-machine slice.

## Risks

- Pure gesture state cannot guarantee host cleanup without a correctly implemented adapter. Cancellation must be integrated with host release_slot and race handling in later adapter work.
- Passing a bool to mark_assigned is a caller-side contract, not cryptographic or authoritative proof; host authorizer remains authoritative.
- Parser, test-run hook and CI behavior remain unverified pending DeepSeek.
- No actual input device UI, character selection or game-world launch is implemented here.

## Open questions

- D-001–D-004 remain OPEN.
- No fixed confirmation timeout selected; injected duration is required.

## Handoff detail for next owner

- DeepSeek: clean checkout code commit 8a48c0a; run Godot 4.7.2 on Windows and Linux with normal and negative controls, including parse/import, and handoff CI. Report exact provenance, counts, exit codes and failures.
- Verify test suite uses Callable(self, "check") safely from SceneTree; inspect parser errors, native method collisions and type inference.
- Probe assignment/cancel races and late reservation response; test host cleanup at adapter layer when implemented.
- Return IMPLEMENTED if all executed tests pass, otherwise CHANGES_REQUESTED; Codex reviews afterward.

## Proof

not used
