```status
Seq: 0007
Date: 2026-10-29 23:08 PDT
Verdict: IMPLEMENTED
Type: review
Build/commit: f479868e54c0c2f25707b09eb86f41349da87ffc
Feature/task IDs: handoff-protocol, M0-01
Reviewed note: 0006
Next owner: deepseek
Next action: Verify Foundation Windows negative control is green at f479868 and inspect job logs; report any remaining CI blockers.
```

# Codex lead review and Windows CI negative-control fix

**Agent / branch:** codex / feature/m0-foundation
**Goal:** review handoff protocol and repair Windows negative control.
**Scope (files/components):** .github/workflows/foundation-tests.yml; docs/HANDOFF_PROTOCOL.md; AGENTS.md; tools/check_handoff.py; handoffs.
**Read:** AGENTS.md, LATEST, 0006, 0005, STATUS, DECISIONS_NEEDED, protocol, checker, CI, role file.
**Inputs / existing interfaces:** 0006 Windows 76/0 and checker cases A-G; CI log excerpt in owner brief.
**Constraints / explicitly unresolved decisions:** Linux tools/test.sh not run; D-001 to D-004 OPEN; no main merge.
**Deliverables:** workflow fix, protocol review, 0007 note.
**Acceptance tests / commands:** handoff checker --base 8e90dcb --head HEAD and --self-test requested; not run in this connector-only environment.
**Return:** commit and inspection results below; CI run pending.

## Changed files

- .github/workflows/foundation-tests.yml: add explicit exit 0 after both negative-control assertions. This overrides GitHub pwsh wrapper's propagation of the expected Godot exit 1.
- handoffs/0007_codex_ci-and-handoff-review.md, handoffs/LATEST.md, handoffs/STATUS.md: relay bookkeeping.

## Commands run

- GitHub connector, cloud: fetched AGENTS, LATEST, 0006, 0005, protocol, checker, workflow, STATUS, DECISIONS and role instructions; read and reviewed. No Godot execution.
- GitHub connector, cloud: committed workflow fix f479868e54c0c2f25707b09eb86f41349da87ffc.
- `python tools/check_handoff.py --base 8e90dcb --head HEAD`: **not run** (no local checkout of the private repository in this connector-only session).
- `python tools/check_handoff.py --self-test`: **not run** (same reason).
- Windows CI on f479868: **not verified yet**.
- Linux tools/test.sh: **not run**, owner deferred.
- Windows suite and A-G: **not re-run**; prior 0006 evidence 76/0 and A-G expected failures.

## Assumptions

- GitHub pwsh wrapper propagates the expected native exit code unless explicitly overridden. Existing checks throw before the added exit 0 if either assertion fails.

## Risks

- **Review result: CHANGES RECOMMENDED before formal approval.** Protocol and checker cover sequencing, provenance, role restrictions and negative cases, but APPROVED proof validation only checks the presence of labels and some log text, not proof per individual check. Treat approval as requiring human review of evidence, not a machine-certified test result.
- Handoff CI skips when LATEST is absent; acceptable for bootstrapping other branches but fail-open if accidentally deleted from an established handoff branch. Consider a branch-specific guard.
- GitHub connector commits are separate pushes; the documented atomic two-commit push protocol could not be followed here. Check the Handoff notes CI outcome and use a git-capable checkout for future atomic pushes.

## Open questions

- D-001 to D-004 remain OPEN, unchanged.
- Formal APPROVED verdict deferred until current CI and handoff checker evidence is available.

## Handoff detail for next owner

- Verify Windows negative-control step runs Godot, prints one intentional failure, then finishes successfully due to exit 0; verify Ubuntu job remains green.
- Check Handoff notes CI and inspect failure logs if needed.
- Re-run full checker and self-test in a git-capable checkout, including range from 8e90dcb.
- Keep READY refresh and world-baseline spawn gate deferred to their integration phase.

## Proof

not used
