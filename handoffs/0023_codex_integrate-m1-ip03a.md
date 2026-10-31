```status
Seq: 0023
Date: 2026-10-30 18:20 PDT
Verdict: IMPLEMENTED
Type: feature
Build/commit: 39c50d29ed2092909d6c106099f6d4f0ba71d521
Feature/task IDs: M1-IP-03A
Reviewed note: 0022
Next owner: deepseek
Next action: Independently run Godot 4.7.2 Windows and Ubuntu tests on code commit 39c50d29ed2092909d6c106099f6d4f0ba71d521; include negative control, suite-count/abort probes, and report parse/runtime failures to Codex.
```

# M1-IP-03A — Codex integration of Gemini/Groq drafts

**Agent / branch:** codex / feature/m0-foundation
**Goal:** Integrate a pure local per-device input router and independent regression suite.
**Scope (files/components):** game/core/input/local_input_router.gd; tests/unit/test_local_input_router.gd; tests/run_all.gd.
**Read:** 00_SHARED_RULES.md, 01_CODEX.md, ADR-0001, ADR-0003, 14-controller-input.md, docs/tasks/M1-IP-03A-GEMINI.md, docs/tasks/M1-IP-03A-GROQ.md, operator CODEX_PACKAGE_IP03A.md.
**Inputs / existing interfaces:** DeviceRegistry slot_for_device, device_is_connected, bind/unbind/reconnect; pure JoinGesture remains separate.
**Constraints / explicitly unresolved decisions:** D-001–D-004 OPEN; no final action mapping, default timeout, transport DTO, scene or network command.
**Deliverables:** reviewed router and regression tests, test-runner hook and count guard.
**Acceptance tests / commands:** tools/test.ps1 and tools/test.sh on Godot 4.7.2; negative control; suite completion/abort probe.
**Return:** Code commit 39c50d29ed2092909d6c106099f6d4f0ba71d521; tests not run in Codex environment.

## Changed files

- game/core/input/local_input_router.gd — validated injected allowlist; per-device sequence watermark; registry-owned slot resolution; rejection without watermark mutation; trusted reset.
- tests/unit/test_local_input_router.gd — 38 authored assertions covering independent routing, invalid input, stale and duplicate sequences, lifecycle and ownership.
- tests/run_all.gd — loads and runs router suite with completion flag and minimum 34-check guard.
- handoffs/0023_codex_integrate-m1-ip03a.md, LATEST.md, STATUS.md — handoff metadata.

## Commands run

- GitHub connector: inspected live branch, DeviceRegistry, runner and handoff protocol.
- Reviewed operator Gemini/Groq package. Operator diagnostic only: 36/0 on throwaway patched copy, not shipped.
- GitHub connector: created reviewed code commit 39c50d29ed2092909d6c106099f6d4f0ba71d521.
- Godot execution in Codex environment: **NOT RUN**; Godot 4.7.2 executable unavailable.
- Windows/Linux CI on integrated commit: **NOT VERIFIED**.
- Runner completion flag is best-effort: Godot runtime aborts can prevent control returning; DeepSeek must probe this and propose stronger guard if needed.

## Assumptions

- Adapter provides trusted monotonic per-device sequence and explicit reset only for new streams.
- Action allowlist is injected, with no default gameplay actions.
- DeviceRegistry is the sole local device-slot owner; router never changes assignments.

## Risks

- Pure API cannot enforce trusted adapter ownership of reset; an untrusted caller could reset sequence.
- Constructor invalid allowlist fails closed, but caller receives errors only through subsequent set_allowed_actions/route_action.
- Minimum count/completion guard may not detect Godot script runtime aborts, as the operator reported; independent abort test is required.
- No input scene, UI focus, network transport or host reservation adapter is implemented in this slice.

## Open questions

- D-001–D-004 remain OPEN.
- Should later adapter expose a restricted lifecycle reset capability rather than direct router method?

## Handoff detail for next owner

- DeepSeek: verify Godot 4.7.2 syntax and full normal suite on clean Windows and Ubuntu; record counts, exit codes and CI URLs.
- Run negative-control failure and deliberate runtime abort probe. If aborted suite exits 0, mark CHANGES_REQUESTED for a stronger fail-closed runner.
- Check ownership isolation and rejected watermark invariants; return any failures to Codex with exact reproduction.
- Do not approve own implementation; Codex reviews independent evidence.

## Proof

not used
