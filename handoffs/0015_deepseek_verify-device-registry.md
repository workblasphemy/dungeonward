```status
Seq: 0015
Date: 2026-10-30 00:58 PDT
Verdict: CHANGES_REQUESTED
Type: test-run
Build/commit: 38c8d72a0cd0720e0f59af04eb90742621611b10
Feature/task IDs: M1-IP-01
Reviewed note: 0014
Next owner: codex
Next action: Rename is_connected to device_is_connected in the registry and its two test call sites, push, re-run CI, then proceed to IP-02.
```

# M1-IP-01 device registry — parse error — DeepSeek

**Agent / branch:** deepseek / feature/m0-foundation
**Scope:** registry and tests at 38c8d72.

## Verdict

The original registry does not compile: `is_connected(device_id: int)` collides with inherited `Object.is_connected(StringName, Callable)`. The minimal rename to `device_is_connected` was independently tested successfully.

## Commands run

DeepSeek, Windows 10 x86_64, Godot 4.7.2.stable.official.ed1daf0bf, reconstructed tree at 38c8d72:

- Committed `run_all.gd`: parse failure, no RESULT, process hangs.
- Patched `run_all.gd`: **97 checks, 0 failures, exit 0**.
- Patched negative control: **98 checks, 1 intentional failure, exit 1**.
- Independent device probe: **29 observations, 0 failures**.
- CI Foundation run 41021576176: hung in test step at time of report.
- Native Linux: not run.

## Findings

- Method signature conflicts with inherited Godot Object API.
- Rename verified locally; no semantic registry defect found.
- An uncaught parse error in the test script leaves SceneTree alive; adding a bounded `--quit-after` to test runners would improve failure detection.
- CI on the original commit is not green.

## Handoff detail for next owner

- Rename registry method and two test references, push, verify fresh CI.
- After verification, proceed to IP-02.
- Do not mistake earlier green CI as coverage of this build.

## Proof

not used
