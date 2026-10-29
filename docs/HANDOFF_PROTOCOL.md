# Handoff protocol

Every model on this team reads the latest handoff before starting and leaves a new one when it stops. The user prompts one model at a time. The model finds the note here; the user does not have to point at the file.

Branch: `feature/m0-foundation`. Codex integrates. Do not merge to `main` or push any other branch unless the owner approves that push.

Living files, and the only ones a reader must open:

- [handoffs/LATEST.md](../handoffs/LATEST.md) — newest status block, link, gist, and `Next seq`
- [handoffs/STATUS.md](../handoffs/STATUS.md) — one row per feature or task ID
- [handoffs/DECISIONS_NEEDED.md](../handoffs/DECISIONS_NEEDED.md) — questions only the owner can close
- the note those files name

Rules for the folder: [handoffs/README.md](../handoffs/README.md). Blank note: [handoffs/_TEMPLATE.md](../handoffs/_TEMPLATE.md).

## Short trigger

If the user says any of these, do this protocol before other work. Do not search for a different task.

- `Check for the new .MD and work.`
- `check the new .MD`
- `check handoffs`
- a close variant such as "read the latest handoff and continue" or "pick up the baton"

## Before you edit

1. Stay on `feature/m0-foundation`. Run `git rev-parse HEAD`.
2. Read [handoffs/LATEST.md](../handoffs/LATEST.md), the note it links, [handoffs/STATUS.md](../handoffs/STATUS.md), and [handoffs/DECISIONS_NEEDED.md](../handoffs/DECISIONS_NEEDED.md). If LATEST names a note newer than the one you last saw, read that note.
3. Read its `Verdict` and `Build/commit`. Compare HEAD with `Build/commit`. HEAD is still that build when it matches, or when every commit after `Build/commit` only touches `handoffs/` (notes, LATEST, STATUS, DECISIONS, logs, archive). If a later commit touches any other path, read those commits and any newer notes before you act.
4. Tell the owner the latest verdict, `Build/commit`, and your plan. Then continue. Do not wait for confirmation unless the owner says stop.
5. Act on the verdict:
   - **IMPLEMENTED:** the next actor is whoever `Next owner` names (normally `deepseek` tests new work; `codex` reviews a passing test-run). If that slug is you, do `Next action`. If it is not, say so and do not take the task.
   - **CHANGES_REQUESTED:** fix the listed items. Do not widen the task.
   - **APPROVED:** start `Next action`. Only `codex` may set this verdict, and only with the proof below. If the proof is missing, flag that and do not treat the note as approval.
   - **BLOCKED:** do not work around the block. Tell the owner what is needed.
   - **IN_PROGRESS:** if you are `Next owner`, continue that task. Otherwise do not start a second copy.
6. Read [00_SHARED_RULES.md](../00_SHARED_RULES.md), the ADRs the task touches ([ADR-0001](../ADR-0001-foundational-architecture.md) ARCH-01 through ARCH-08, [ADR-0002](../ADR-0002-gameplay-design-v0.1.md) GAME-01 through GAME-08, [ADR-0003](../ADR-0003-modular-extensible-architecture.md)), and any specs the note names. Also read your role file: [01_CODEX.md](../01_CODEX.md), [02_GEMINI.md](../02_GEMINI.md), [03_CLAUDE_OPUS.md](../03_CLAUDE_OPUS.md), [04_KIMI_K3.md](../04_KIMI_K3.md), [05_GROK.md](../05_GROK.md), [06_GROQ.md](../06_GROQ.md), or [07_DEEPSEEK.md](../07_DEEPSEEK.md).
7. If the note conflicts with those approved ADRs, flag the conflict and do not follow the conflicting part. Do not invent approvals. Unspecified numeric tuning stays OPEN.
8. Claim the task in STATUS before other edits. If `Claimed by` is already set, do not touch the task. Tell the owner who holds it. If it is clear (`—`), set `Claimed by: <slug> @ <seq> since <YYYY-MM-DD HH:MM TZ>` using the next seq from LATEST, and commit only [handoffs/STATUS.md](../handoffs/STATUS.md) before other work. A claim with no note of that seq, whose `since` time is 24 hours or older, is stale. Only the owner or `codex` may clear a stale claim.
9. Models without the repo do not claim. The owner claims, or skips the claim, because the owner runs those chats one at a time. See "No repo access".

## When you stop

Do this when you finish, when you are blocked, or when you are out of tokens.

1. Add a new note. Never edit or delete an older note. Moving a note into [handoffs/archive/](../handoffs/archive/README.md) is not an edit. Only `codex` does that, at a milestone close, and LATEST, STATUS, and DECISIONS stay current. Sequence numbers are global and never restart. The next number is one higher than the highest `NNNN` under `handoffs/` and `handoffs/archive/**`.
2. Filename: `handoffs/NNNN_<slug>_<short-task>.md`. `NNNN` is four digits. Slug is exactly one of: `codex`, `gemini`, `claude`, `kimi`, `groq`, `deepseek`, `grok`, `owner`. The short task is lowercase words separated by hyphens.
3. Two commits, pushed together. The code commit comes first and does not add a note. The next commit adds the note and updates LATEST and STATUS (and DECISIONS or logs when needed). That note commit must not change any path outside `handoffs/`. `Build/commit` is the code commit's hash, the commit you built or tested on. It is not the note commit, which cannot contain its own hash. Push both commits in one push. [tools/check_handoff.py](../tools/check_handoff.py) evaluates the whole push range. A push of the code commit alone fails when that range changes paths outside `handoffs/` and `docs/` and does not add a new note.
4. Clear `Claimed by` on every row you release (set it back to `—`).
5. Overwrite LATEST with the new status block, a link to the note, a 3–5 line gist, and `Next seq: NNNN` (the next free number). Do not make the reader guess the next number.
6. Keep one STATUS row per feature or task ID. Update rows you judged. Do not delete rows.

A BLOCKED note must add an OPEN row to [handoffs/DECISIONS_NEEDED.md](../handoffs/DECISIONS_NEEDED.md).

## Status block

Put this fence first. Keys stay in this order.

```status
Seq: 0001
Date: YYYY-MM-DD HH:MM TZ
Verdict: IMPLEMENTED
Type: docs
Build/commit: <full hash of the code commit you built or tested on>
Feature/task IDs: handoff-protocol
Reviewed note: none
Next owner: codex
Next action: One line, done by the Next owner slug.
```

- `Date` is required. Example: `2026-10-29 13:57 UTC`.
- `Reviewed note` is a sequence number (`0003`) or `none`. It is not a filename.
- `Next owner` is one slug: `codex`, `gemini`, `claude`, `kimi`, `groq`, `deepseek`, `grok`, or `owner`. Do not write a role title.
- `Verdict` is `APPROVED`, `IMPLEMENTED`, `CHANGES_REQUESTED`, `BLOCKED`, or `IN_PROGRESS`.
- `Type` is `review`, `feature`, `fix`, `test-run`, or `docs`.

## Note body

After the status fence, use the [TASK_HANDOFF.md](../TASK_HANDOFF.md) headings exactly:

```markdown
# Agent task handoff (fill only applicable fields)
**Agent / branch:**
**Goal:**
**Scope (files/components):**
**Read:** `00_SHARED_RULES.md`, your role file (`01_CODEX.md` through `07_DEEPSEEK.md`), then ONLY: [specific docs/sections/source files]
**Inputs / existing interfaces:**
**Constraints / explicitly unresolved decisions:**
**Deliverables:**
**Acceptance tests / commands:**
**Return:** changed files; executed commands/results or `not run`; assumptions; risks; review needed.
```

Then these sections only:

- `## Changed files`
- `## Commands run`
- `## Assumptions`
- `## Risks`
- `## Open questions`
- `## Handoff detail for next owner`
- `## Proof` when Verdict is APPROVED (write `not used` otherwise)

Do not add a `Next up` section. `Next owner` and `Next action` are the only assignment.

`## Commands run` lists each command, who ran it, where it ran, and the real result, or `not run`. Never claim a check passed if it was not run.

Keep the note under about 150 lines. Link to files. A log longer than 40 lines goes in [handoffs/logs/](../handoffs/logs/README.md) as `handoffs/logs/NNNN_*.log`, and the note links to that path. The checker warns above 150 lines and does not fail the run for length.

## Verdicts

| Verdict | Meaning | Next actor |
|---|---|---|
| APPROVED | `codex` checked one commit and it is safe to build on. Every check has proof. | Whoever `Next action` addresses. |
| IMPLEMENTED | A feature, fix, docs change, or passing test-run has landed and is waiting. | Whoever `Next owner` names (normally `deepseek` tests new work; `codex` reviews a passing test-run). |
| CHANGES_REQUESTED | Review, or a test-run, found problems. The note lists them. | `Next owner` fixes those items. |
| BLOCKED | Work cannot continue. Say what is needed, usually an owner decision. Add a DECISIONS row. Do not work around it. | `owner` |
| IN_PROGRESS | You stopped before the task was done. | `Next owner` continues it. |

Hard rule: Verdict APPROVED is allowed only when the filename slug is `codex`, and only when each claimed check records the exact command, OS/environment, Godot version, and log (pasted if it is 40 lines or fewer, otherwise a committed `handoffs/logs/NNNN_*.log` path). If any of that is missing, use IMPLEMENTED or CHANGES_REQUESTED. `deepseek` test-run notes use IMPLEMENTED when every test that was run passed, or CHANGES_REQUESTED when any failed. `deepseek` never sets APPROVED.

## Tests

`deepseek` in a plain chat cannot run Godot. Default flow: the owner runs `tools/test.ps1` on Windows or `tools/test.sh` on Linux and pastes the log. `deepseek`, or whichever model is writing the note, turns that into a `test-run` note. A model that really has the machine (a coding CLI or this repo's workspace) may run the tests itself. The note says who ran the command and where.

Logs longer than 40 lines are saved by the owner, when the owner ran the tests, to `handoffs/logs/NNNN_*.log`. The note links to that path. A model with the repo saves that file itself in the note commit.

## Decisions

[handoffs/DECISIONS_NEEDED.md](../handoffs/DECISIONS_NEEDED.md) is a table: ID (`D-001` upward), question, options, raised by (note seq), blocking task, status `OPEN` or `DECIDED`, and the decision plus date. Do not delete rows. A BLOCKED note adds one OPEN row. When the owner decides, set `DECIDED` and fill the decision and date.

## Claims

`Claimed by` uses a slug: `<slug> @ <seq> since <YYYY-MM-DD HH:MM TZ>`. Example: `grok @ 0002 since 2026-10-29 14:05 UTC`. Clear is `—`. The claim commit touches only STATUS.md, so it does not need a note of its own. Clear the claim in the note commit.

## No repo access

Plain chats (ChatGPT, DeepSeek, and any model that cannot see the repo) still follow this file. The owner pastes LATEST, STATUS, and DECISIONS. The model does not invent a HEAD it cannot see.

The reply contains three markdown blocks and nothing else mixed into them:

1. **NOTE** — the full new note, saved as `handoffs/NNNN_<slug>_<short-task>.md`. Take `NNNN` from LATEST `Next seq`. Do not guess.
2. **LATEST** — the full replacement for `handoffs/LATEST.md`, including the status block, the link, a 3–5 line gist, and the new `Next seq`.
3. **STATUS** — the updated row or rows, including `Claimed by` cleared to `—`.

The owner commits those three blocks, or asks `codex` to commit them, as the note commit (handoffs only) after any code commit. Claims for these chats are made by the owner or skipped.

If the owner ran the tests, the owner saves logs longer than 40 lines to `handoffs/logs/NNNN_*.log`. The NOTE block links to that path. Do not paste those logs into the note.

## Starter prompts

One-time setup, for a chat that does not auto-read the repo. Paste once per session:

```text
Before doing anything, open the dungeonward repo on branch feature/m0-foundation, read docs/HANDOFF_PROTOCOL.md, then handoffs/LATEST.md, handoffs/STATUS.md, and handoffs/DECISIONS_NEEDED.md. Tell me the latest verdict, Build/commit, and your plan, then continue unless I say stop. Follow the protocol and leave a handoff note with a status block when you finish.
```

Short trigger, after that session can see the repo (or after [AGENTS.md](../AGENTS.md) was read):

```text
Check for the new .MD and work.
```

## CI

[tools/check_handoff.py](../tools/check_handoff.py) is stdlib only. [handoff-check.yml](../.github/workflows/handoff-check.yml) runs it on push and pull_request to `feature/m0-foundation`. It does not change the foundation test workflow.

On the push range it fails when:

- a commit adds `handoffs/NNNN_<slug>_<task>.md` and also changes a path outside `handoffs/`
- the range changes a path outside `handoffs/` and `docs/` and does not add a new note
- a numbered note is missing a status field, uses a bad Verdict or Type, uses a slug outside the fixed list, sets APPROVED with a slug other than `codex`, or sets `Reviewed note` to something other than `none` or an existing seq
- `Build/commit` is not a hash in the history of HEAD
- sequence numbers are duplicated under `handoffs/` or `handoffs/archive/**`
- LATEST does not name the highest note, disagree with that note's status block, or carry the right `Next seq`

It warns, and does not fail, when a note is over 150 lines. An all-zero push base skips the range check and still checks the tree.

This workflow reports failures. It does not block the push unless the owner turns on GitHub branch protection. Do not turn that on yourself.

## Roles

| Slug | File | Work |
|---|---|---|
| `codex` | [01_CODEX.md](../01_CODEX.md) | Lead and integrator. Only slug that may set APPROVED. Archives notes. May clear a stale claim. |
| `gemini` | [02_GEMINI.md](../02_GEMINI.md) | Networking |
| `claude` | [03_CLAUDE_OPUS.md](../03_CLAUDE_OPUS.md) | Blender and animation |
| `kimi` | [04_KIMI_K3.md](../04_KIMI_K3.md) | UI |
| `grok` | [05_GROK.md](../05_GROK.md) | Gameplay prototypes |
| `groq` | [06_GROQ.md](../06_GROQ.md) | Boilerplate |
| `deepseek` | [07_DEEPSEEK.md](../07_DEEPSEEK.md) | Test execution. Test-run notes are IMPLEMENTED or CHANGES_REQUESTED, never APPROVED. |
| `owner` | — | The user. Runs local Godot tests, commits no-repo blocks, decides OPEN rows, clears stale claims. |
