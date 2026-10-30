```status
Seq: 0003
Date: 2026-10-29 20:55 PDT
Verdict: CHANGES_REQUESTED
Type: test-run
Build/commit: 2976ba3a1dde6f86cce85e3b70c8fc2989f05d86
Feature/task IDs: handoff-protocol
Reviewed note: 0002
Next owner: codex
Next action: Run Steps 1, 2 and 4 on real Windows and Linux machines with logs, then re-review.
```

# Handoff verification — DeepSeek (test execution)

**Agent / branch:** `deepseek` / `feature/m0-foundation`
**Goal:** verify the parts of the handoff system that the building agent could not run (Windows runner, Linux runner, Actions, negative cases).
**Scope:** `tools/test.ps1`, `tools/test.sh`, `.github/workflows/handoff-check.yml`, `tools/check_handoff.py` behaviour on bad input.

**Read:** `handoffs/README.md`, `docs/HANDOFF_PROTOCOL.md`, note `0002`, `tools/test.ps1`, `.github/workflows/handoff-check.yml`.

## Changed files

None. No repository files were modified and nothing was pushed.

## Commands run

Executed by DeepSeek on a Windows 10 x86_64 machine with Godot `4.7.2.stable.official.ed1daf0bf`:

| Step | Command | Result |
|---|---|---|
| 0 | GitHub API branch/commit query | HEAD `8945a31a…`, parent `2976ba3a…` — **PASS** |
| 0 | `git status --porcelain` | **not run** — no `git` in this environment |
| 1 | `powershell -File tools/test.ps1` with `GODOT_BIN` = GUI `win64.exe` | **FAIL** — 5 header lines, `godot: unknown`, **exit 0, zero tests run** |
| 2 | `tools/test.sh` | **not run** — no Linux host, WSL or container |
| 3 | GitHub Actions, run 40889795952 | *Check handoff notes* **success** |
| 3 | GitHub Actions, run 40889796046 | ubuntu **success**, windows **failure** (*Windows negative control*) |
| 4 | `check_handoff.py --self-test` and cases A–G | **not run** — every case requires `git commit` / `git reset` |
| 5 | This note | drafted, not committed |

CI logs return `403 Must have admin rights`, so job and step conclusions are from the API; printed `PASS:` / `RESULT:` lines could not be inspected.

## Assumptions

- The GUI-subsystem binary is a legitimate `GODOT_BIN` choice for a user; the protocol names the console build, but does not forbid the other.
- A green workflow step is acceptable evidence that the job ran, while its printed output remains unverified.

## Risks

1. **`tools/test.ps1` can report success without running tests.** With a GUI-subsystem Godot binary, `$LASTEXITCODE` is unset; `if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }` becomes `exit $null` → exit 0, before import or tests. A run that did nothing is indistinguishable from a pass to anyone reading the exit code.
2. **Foundation workflow remains red** at *Windows negative control* (pre-existing: same step failed at `4af294c`, `521692a`, `8bd82f8`, `8945a31`). Not caused by the handoff commits, but it means the repo's only Windows gate is not trustworthy yet.
3. **`dirty: unknown`** is printed rather than failing, so a note could cite provenance that establishes nothing.

## Open questions

- Should `test.ps1` fail when `commit` is `unknown` (no git), instead of printing `unknown`?
- Is the plain `win64.exe` supported as `GODOT_BIN`, or should the script reject it explicitly?

## Handoff detail for next owner

To close this note:

1. Harden `test.ps1`: throw when `$null -eq $LASTEXITCODE` after invoking the engine, and assert `artifacts/tests.log` exists before success.
2. Run Step 1 with the console build and attach `artifacts/tests.log`.
3. Run Step 2 on Linux and attach the header plus `RESULT:` line.
4. Run Step 4 cases A–G on a throwaway branch; record the exact `FAIL:` line and exit code for each.
5. Triage the Foundation *Windows negative control* failure separately.

## Proof

not used
