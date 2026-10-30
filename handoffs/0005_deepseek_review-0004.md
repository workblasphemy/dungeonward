```status
Seq: 0005
Date: 2026-10-29 21:50 PDT
Verdict: IMPLEMENTED
Type: review
Build/commit: fe33106f0ced5afb4494a923a8c3a12a1da7c920
Feature/task IDs: handoff-protocol
Reviewed note: 0004
Next owner: owner
Next action: Commit the three generated .uid files, then run cases A–G on a git-capable checkout and tools/test.sh on Linux.
```

# Review of 0004 — DeepSeek

**Agent / branch:** `deepseek` / `feature/m0-foundation`
**Reviewed:** note `0004` (`IMPLEMENTED`), diff `8945a31…954ca2c`, `handoffs/logs/0004_windows_test-ps1.log`
**Scope:** `tools/test.ps1`, `tools/test.sh`, `docs/HANDOFF_PROTOCOL.md`, the Windows log

## Verdict

The fix closes the note-0003 defect. Both new fail-fast guards were reproduced here with real exit codes, the Windows log is internally consistent with the 76-check suite, and the protocol sentence now matches the behaviour. **IMPLEMENTED**, with two follow-ups below.

## Commands run

Run by DeepSeek on Windows 10 x86_64, PowerShell 5.1, Godot `4.7.2.stable.official.ed1daf0bf` (windowed build — the only one available here).

| Check | Command | Result |
|---|---|---|
| Repo state | GitHub API | HEAD `954ca2c1…`, parent `fe33106f…` — **PASS** |
| Diff scope | compare `8945a31…954ca2c` | 8 files: `test.ps1` +23/−4, `test.sh` +8/−0, protocol 1 sentence, notes/logs — **PASS**, matches the claim |
| Guard 1: no git | `powershell -File tools/test.ps1`, `GODOT_BIN` = windowed build, no git on PATH | header, then `FAIL: git provenance is unknown; run from a git checkout with git on PATH`, **EXIT 1** — **PASS** |
| Guard 2: no engine exit code | same, with a stub `git` on PATH returning the real SHA/branch/clean (**synthetic provenance, guard test only**) | header, then `FAIL: Godot did not report a version and exit code; set GODOT_BIN to the Godot 4.7.2 *_console.exe build`, **EXIT 1** — **PASS** |
| Windows log | `handoffs/logs/0004_windows_test-ps1.log` | header `commit: fe33106…`, `dirty: clean`, `godot: 4.7.2.stable.official.ed1daf0bf`; 76 `PASS:` lines; `RESULT: 76 checks, 0 failures`; `EXIT: 0` — **PASS** (read, not re-executed) |
| Linux suite | — | **not run** — deferred by the owner; no Linux/WSL/container |
| Cases A–G | — | **not run** — see Risks |

The note-0003 failure is closed in both directions: the old path exited 0 with no tests, and each of its two preconditions now exits 1 with a specific message.

## Review notes

1. **`.uid` files must be committed — MEDIUM, process.** `954ca2c` does not add the three `.uid` files that the editor import generated (`reservation_token_provider.gd.uid`, `lobby_registry.gd.uid`, `m0_request_authorizer.gd.uid`); only `tests/run_all.gd.uid` is tracked. The 0004 log is valid because the header was captured *before* the import created them. **Every later run on that clone will report `dirty: dirty`**, and `docs/HANDOFF_PROTOCOL.md` says a dirty log cannot be used as proof — so the next `test-run` note would have no usable provenance. Committing the three files fixes it permanently (Godot 4.4+ expects them tracked).
2. **`test.sh` propagates engine failures implicitly — LOW.** It relies on `set -euo pipefail` for a non-zero engine exit, where `test.ps1` now has an explicit `Assert-EngineExit` with a message. Behaviour is correct; only the diagnostic is thinner. Optional parity improvement.
3. **`test.ps1` invokes `--version` twice — INFO.** Once for the header probe, once for `artifacts/version.log`. Harmless (~0.5 s), noted for completeness.
4. **Log credibility — INFO.** I could not re-execute the exact console-binary run (only the windowed build is present here), but the log's 76 assertion names match the suite at `954ca2c` exactly, and CI's Windows test step is green at this commit. I treat it as credible, not independently reproduced.

## Still not run

- **Linux `tools/test.sh` suite** — deferred by the owner. Not inferred from Windows.
- **Cases A–G** — no `git` on this machine and no `dulwich`/`pygit2`, so no commits, no `--base…--head` range, and no `git reset --hard`. Every case in the guide depends on that. They remain the only unverified part of the checker's failure behaviour.

## Handoff detail for next owner

1. `git add game/core/identity/reservation_token_provider.gd.uid game/core/lobby/lobby_registry.gd.uid game/core/network/m0_request_authorizer.gd.uid` and commit — restores `dirty: clean` for future runs.
2. Run cases A–G on any machine with git (`tmp/handoff-negative-test`, never pushed), recording each `FAIL:` line and exit code.
3. Run `tools/test.sh` on Linux when available.
4. Codex: triage the Foundation *Windows negative control* step (unchanged, still red, predates this work).

## Proof

not used
