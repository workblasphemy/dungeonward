```status
Seq: 0011
Date: 2026-10-30 00:50 PDT
Verdict: IMPLEMENTED
Type: test-run
Build/commit: 55ed5f6a086b27c9ae84470d5fa302f2368a88ce
Feature/task IDs: M0-01
Reviewed note: 0010
Next owner: owner
Next action: Decide M0-01 acceptance. The suite is 83 checks, not the 84 predicted in 0010; M0 still lacks transport, world barrier, joining and persistence.
```

# release_slot verification — DeepSeek

**Agent / branch:** deepseek / feature/m0-foundation
**Scope:** m0_request_authorizer.gd release_slot() and additions in tests/run_all.gd at 55ed5f6.

## Verdict

The boundary works. Windows suite passes locally, the independent probe covers additional cases, and CI's Ubuntu leg covers Linux execution. The suite is **83 checks, not 84**: seven assertions were added, not eight (76 + 7 = 83).

## Commands run

Executed by DeepSeek, Windows 10 x86_64, Godot 4.7.2.stable.official.ed1daf0bf, against the reconstructed tree at 55ed5f6:

| Command | Result |
|---|---|
| `godot --headless --path . --script res://tests/run_all.gd` | 83 checks, 0 failures, exit 0 |
| same `-- --self-test-failure` | 84 checks, 1 failure, exit 1 |
| `--script res://tests/audit_release.gd` (independent probe) | 25 observations, 0 failures |
| CI Foundation at 55ed5f6 (run 41020981327) | success, both legs |
| CI Handoff check at 55ed5f6 (run 41020981359) | failure — code-only push, as ruled in 0009 |

Native Linux: not run. Ubuntu CI is Linux evidence.

## Independent probe

- Seven malformed payloads rejected INVALID_MESSAGE without mutation.
- Foreign sender and unknown session ID give identical OK responses without mutation.
- Wrong well-formed token is non-disclosing and does not mutate.
- Authorized release removes seat; replay identical; new request ID idempotent.
- Same request ID and different payload conflicts.
- ACTIVE release frees capacity for reuse; sender 0 and negative sender rejected.

## Findings

1. Count discrepancy informational: seven release assertions, not eight.
2. No defects found in release_slot.
3. Replay cache still stores token for 60 seconds (bounded, accepted tradeoff). ACTIVE is a lifecycle state, not spawn/world gate. refresh_pending remains host-internal.

## M0 readiness recommendation

M0-01 contract verified on Windows and both CI legs. M0 milestone not complete: host RPC transport, world-baseline/spawn barrier, device joining, persistence absent. Those are scoped to M1–M3. Owner acceptance decision needed before starting M1. D-001 through D-004 remain OPEN.

## Handoff detail for next owner

Correct expected count to 83 in subsequent notes. Decide M0-01 acceptance. Native Linux suite optional beyond Ubuntu CI.

## Proof

not used
