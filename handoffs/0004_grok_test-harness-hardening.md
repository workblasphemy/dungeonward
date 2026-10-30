```status
Seq: 0004
Date: 2026-10-29 21:15 PDT
Verdict: IMPLEMENTED
Type: fix
Build/commit: fe33106f0ced5afb4494a923a8c3a12a1da7c920
Feature/task IDs: handoff-protocol
Reviewed note: 0003
Next owner: owner
Next action: Run tools/test.sh on Linux and the check_handoff.py deliberate-failure cases A–G on a throwaway branch, then hand the logs to deepseek or codex for review.
```

# Test harness hardening — Grok

**Agent / branch:** `grok` / `feature/m0-foundation`
**Goal:** close the silent-success defect DeepSeek reported in note 0003 and run the Windows suite for real.
**Scope (files/components):** `tools/test.ps1`, `tools/test.sh`, `docs/HANDOFF_PROTOCOL.md` (one sentence).
**Return:** changed files; executed commands/results or `not run`; assumptions; risks; review needed.

## What note 0003 found, and what was done

- **Accepted: `test.ps1` could exit 0 having run nothing.** Reproduced on GlubGlub with the original script: git absent from PATH, `GODOT_BIN` = windowed `Godot_v4.7.2-stable_win64.exe`, five header lines, **exit 0**. It needs both conditions; with git present the old script already failed at the version check.
- **Accepted: `unknown` provenance was treated as usable.** Both scripts now stop with a non-zero exit if `commit`, `branch` or `dirty` is `unknown`, and if the `godot` header is `unknown`.
- **Accepted: null exit code.** `test.ps1` clears `LASTEXITCODE` before every engine call and treats a missing exit code as failure, with a hint to use the `*_console.exe` build. It never runs `exit $null`.
- **Declined: extra `tests.log` existence check.** The script already throws unless `tests.log` contains `RESULT: N checks, 0 failures` with N ≥ 1, which cannot pass if the file is missing.

## Changed files

- `tools/test.ps1`: provenance and engine fail-fast, `Assert-EngineExit` helper used for `--version` and inside `Invoke-Engine`.
- `tools/test.sh`: same provenance and engine fail-fast after the header.
- `docs/HANDOFF_PROTOCOL.md`: the provenance paragraph now says unknown fields stop the script and that Windows needs the `*_console.exe` build.
- `handoffs/logs/0004_windows_test-ps1.log`: full Windows run output.

## Commands run

All run by Grok on the owner's Windows PC (GlubGlub, Windows 10.0.26300, PowerShell 5.1) in a fresh clone, unless noted.

| Check | Result |
|---|---|
| Original `test.ps1`, windowed build, git absent | header only, **EXIT 0** (defect reproduced) |
| New `test.ps1`, windowed build, git present | `FAIL: Godot did not report a version and exit code…`, **EXIT 1** |
| New `test.ps1`, windowed build, git absent | `FAIL: git provenance is unknown…`, **EXIT 1** |
| New `test.ps1`, `GODOT_BIN` points at a missing file | `FAIL: Godot did not report…`, **EXIT 1** |
| New `test.ps1`, `Godot_v4.7.2-stable_win64_console.exe`, clean tree at `fe33106f0ced5afb4494a923a8c3a12a1da7c920` | header `dirty: clean`, `godot: 4.7.2.stable.official.ed1daf0bf`, `RESULT: 76 checks, 0 failures`, **EXIT 0**; log: [0004_windows_test-ps1.log](logs/0004_windows_test-ps1.log) |
| New `test.sh` outside a git repo (Grok's Linux workspace, Godot 4.7.2 present) | `FAIL: git provenance is unknown…`, **EXIT 1**; `bash -n` ok |
| `python tools/check_handoff.py --self-test` | `SELF-TEST: ok` |
| `python tools/check_handoff.py --base 8945a31 --head HEAD` | all PASS lines, `RESULT: ok (0 failures, 0 warnings)` |
| Full `tools/test.sh` suite on Linux | **not run** |
| `check_handoff.py` deliberate-failure cases A–G | **not run** |

## Assumptions

- The official `Godot_v4.7.2-stable_win64.exe.zip` from godotengine/godot-builds was used; it was unpacked to `%LOCALAPPDATA%\Godot472` on GlubGlub.

## Risks

- The Foundation workflow's *Windows negative control* step is still red. It predates the handoff work and was not touched.
- The editor import created three untracked `.uid` files (`game/core/identity/reservation_token_provider.gd.uid`, `game/core/lobby/lobby_registry.gd.uid`, `game/core/network/m0_request_authorizer.gd.uid`). Godot 4.4+ expects `.uid` files to be committed; they were left uncommitted for codex to decide.

## Open questions

- None new. D-001 to D-004 stay OPEN.

## Handoff detail for next owner

1. Linux: `GODOT_BIN=<4.7.2 binary> ./tools/test.sh; echo "EXIT: $?"` from a clean checkout; expect `RESULT: N checks, 0 failures` and `EXIT: 0`.
2. Cases A–G from the DeepSeek verification guide on `tmp/handoff-negative-test`, never pushed; record each `FAIL:` line and exit code.
3. Codex: decide on the `.uid` files and triage *Windows negative control*.

## Proof

not used
