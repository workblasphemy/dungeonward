```status
Seq: 0017
Date: 2026-10-30 12:05 PDT
Verdict: IMPLEMENTED
Type: test-run
Build/commit: ff77d66da50db2590631c034232b9c48b90cf2b7
Feature/task IDs: M1-IP-01, handoff-protocol
Reviewed note: 0016
Next owner: codex
Next action: Accept M1-IP-01 and authorize IP-02 (Start×2 join state machine).
```

# M1-IP-01 verified from a real checkout; checker A–G independently reproduced — DeepSeek

## Verdict

**Verified, and this time from a genuine clone with real history** — no reconstructed files. Windows: 97/0 and 98/1. Ubuntu and Windows CI: both green at this commit. The checker's seven negative cases were re-run independently on a throwaway branch: all seven fail with the expected message and exit 1, and the control passes.

## Environment

- Real clone of `workblasphemy/dungeonward`, branch `feature/m0-foundation`, **HEAD `ff77d66da50db2590631c034232b9c48b90cf2b7`**, working tree clean.
- Windows 10 x86_64, Godot `4.7.2.stable.official.ed1daf0bf`, git 2.53.0, Python 3.14.
- No network was needed for the test runs; the clone was obtained once over HTTPS.

## Results

| Check | Result |
|---|---|
| `run_all.gd` | **97 checks, 0 failures, exit 0** |
| negative control `-- --self-test-failure` | **98 checks, 1 failure, exit 1** (one injected) |
| CI Foundation run [41110979558](https://github.com/workblasphemy/dungeonward/actions/runs/41110979558) | **success** |
| CI Handoff check run [41110979666](https://github.com/workblasphemy/dungeonward/actions/runs/41110979666) | **success** |

The parser blocker from 0015 is gone: `device_is_connected` is present, the script compiles, and the suite runs to completion instead of hanging.

**`tools/test.ps1` itself was not executed** — it requires the `*_console.exe` build, and only the windowed binary is installed here. The suite and negative control were run directly with the same flags; the runner's own behaviour was verified separately in 0004/0008.

## Checker cases A–G (independent re-run)

Run on `tmp/handoff-negative`, branched from `ff77d66`, never pushed, branch deleted afterwards.

| Case | Primary `FAIL:` | Exit |
|---|---|---|
| A — code change, no note | `push range changes files outside handoffs/ and docs/ without adding handoffs/NNNN_<slug>_<task>.md` | 1 |
| B — note + code in one commit | `commit … adds a handoff note and also changes files outside handoffs/` | 1 |
| C — `Verdict: DONE` | `Verdict 'DONE' is not one of APPROVED, BLOCKED, CHANGES_REQUESTED, IMPLEMENTED, IN_PROGRESS` | 1 |
| D — `APPROVED`, slug deepseek | `Verdict APPROVED is only allowed when the filename slug is codex or owner` + missing Proof fields | 1 |
| E — duplicate Seq | `duplicate sequence 0016: …` | 1 |
| F — note added, LATEST stale | `LATEST.md does not name the highest note` + `Next seq` mismatch | 1 |
| G — `0017_chatgpt_test.md` | `filename must be NNNN_<slug>_<short-task>.md with slug one of: …` | 1 |
| control — valid note, LATEST updated | none, `RESULT: ok (0 failures, 0 warnings)` | **0** |

C, D, E and F also report LATEST-consistency failures, which is expected: a rejected note legitimately leaves LATEST out of step.

Two harness mistakes of mine were corrected before the final run and are noted for transparency: the first attempt wrote notes to the repository root instead of `handoffs/`, and used `Type: test` instead of the permitted `test-run`. Both produced spurious failures; the table above is from the corrected run.

## Findings

1. **No defect found in M1-IP-01.** Registry semantics hold: unique device↔slot binding, reassignment refused, disconnected devices keep ownership and cannot be stolen, explicit unbind frees the slot, assignments are sorted and expose only non-secret fields.
2. **Carried from 0015, still worth fixing:** a script that fails to parse makes the runner hang rather than fail (the SceneTree never reaches `quit()`). A `--quit-after` on the test invocation would turn a 10-minute timeout into a 1-second failure.
3. **Process observation:** two commits in this range carry the identical message (`e8a98f9`, `2d95288`); harmless, but worth squashing in future pushes.

## Handoff detail for next owner

1. Accept M1-IP-01; IP-02 (Start×2 join) can start.
2. Consider the `--quit-after` hardening for the test scripts.
3. Native Linux `tools/test.sh` is still unrun — the Ubuntu CI job covers the same script, but it is CI, not native.

## Proof

not used
