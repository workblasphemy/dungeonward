```status
Seq: 0021
Date: 2026-10-30 13:10 PDT
Verdict: IMPLEMENTED
Type: test-run
Build/commit: 8a48c0a82670ee9a73e2bb8867b01e49cf349691
Feature/task IDs: M1-IP-02
Reviewed note: 0020
Next owner: codex
Next action: Accept M1-IP-02 and name the next slice; the join gesture has no adapter or UI wiring yet.
```

# M1-IP-02 verified — DeepSeek

**Agent / branch:** `deepseek` / `feature/m0-foundation`
**Scope:** `game/core/input/join_gesture.gd`, `tests/unit/test_join_gesture.gd`, `tests/run_all.gd` at `8a48c0a`.

## Verdict

**Verified.** Clean checkout of `8a48c0a`, Windows Godot 4.7.2: **129 checks, 0 failures**; negative control **130 checks, 1 failure, exit 1**. The handoff checker passes on the range, and both workflows are green at the push head.

## Results

| Check | Result |
|---|---|
| Clean checkout `8a48c0a` (working tree empty) | confirmed |
| `run_all.gd` | **129 checks, 0 failures, exit 0** |
| negative control | **130 checks, 1 failure, exit 1** |
| `check_handoff.py --base 9b29abe --head HEAD` | `RESULT: ok (0 failures, 0 warnings)` |
| CI Foundation run [41118940764](https://github.com/workblasphemy/dungeonward/actions/runs/41118940764) | **success** |
| CI Handoff check run [41118941103](https://github.com/workblasphemy/dungeonward/actions/runs/41118941103) | **success** |

**CI nuance worth recording:** there are **no workflow runs for `8a48c0a` itself**. It is an intermediate commit in a multi-commit push, and GitHub only runs workflows for the push head (`9b29abe`). The head tree contains the same code plus handoff metadata, so the CI evidence does cover this code — but it is attributed to `9b29abe`, not to `8a48c0a`. `0020`'s wording ("CI for 8a48c0a") is therefore not literally obtainable; this note is the closest truthful statement.

Native Linux: **not run**; the Ubuntu job is the Linux evidence.

## Code review notes

- The gesture is pure: no `DeviceRegistry` handle, no transport, no scene. `assigned` is an *observation* passed in by the caller, and `start_pressed(..., assigned = true)` cannot jump a device to `ASSIGNED` (`ASSIGNMENT_MISMATCH`). Good.
- `mark_assigned` requires both `SELECTING` and `binding_confirmed`, so a caller cannot self-assign without the registry step.
- `cancel` from `RESERVING` or `SELECTING` returns `INTENT_RELEASE_RESERVATION`, and `disconnect_device` on `ASSIGNED` retains ownership — both match IP-01 semantics.
- `unbind_device` clears state silently when the device is not `ASSIGNED`; only the assigned case demands confirmation. Consistent, worth knowing.
- Tests access script constants through the instance (`g.STATE_CONFIRMING`); that resolves correctly in 4.7.2 — no parse warnings observed.

## Observations (low, no action required for acceptance)

1. **Boundary choice differs from M0.** `expire()` and the `CONFIRMING` re-press both use strict `now > deadline`, so a press exactly at the deadline still confirms. The M0 registry chose `now >= deadline` for expiry. Not a bug — but the two layers now disagree at the boundary, and only one of them should be treated as the house convention.
2. **No upper bound on `confirmation_window_ms`.** A caller can pass a very large window and hold a device in `CONFIRMING` indefinitely. The adapter owns this value, so it is a caller-trust question, not a defect.
3. **`INTENT_RELEASE_RESERVATION` is an obligation, not an action.** If the adapter drops it, a host reservation leaks. Worth an explicit adapter test when the wiring lands.

## Remaining M1 gaps

No adapter, no UI, no scene wiring, no transport. Solo launch and online invitations are outside this slice. D-001–D-004 remain OPEN.

## Handoff detail for next owner

1. Accept M1-IP-02 and name the next slice (adapter wiring is the natural follow-on, since the pure machine now has no consumer).
2. Consider aligning the expiry comparison with the M0 convention, or document why the two differ.

## Proof

not used
