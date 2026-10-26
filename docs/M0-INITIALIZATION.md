# M0 initialization evidence

Date: 2026-10-26. Branch: `feature/m0-foundation`.
Base revision: `e81a2627f62b1932e6524d851e718e54d85d0eaa`.
Initial validation was performed on a working diff against this base revision.
The owner subsequently authorized committing and pushing the M0 scaffold to
`feature/m0-foundation`; main must not be merged or changed.

Latest access recheck: `origin/main` is now
`a5aeca4998ba818ccc3206e9693ddb56790de599`, which adds only
`DUNGEONWARD_AI_CAPABILITY_ROUTING_v0.3.md`. Reviewed via `git show origin/main:...`;
no remote commit was merged and the branch base remains unchanged. Foundation
v0.5 and the shared/role instructions are unchanged on the remote.

## Scope and authority

Reviewed shared rules, Codex role, ADR-0001/0002, Foundation v0.5 and relevant
blueprint architecture sections. Repository read access verified using
`git ls-remote origin HEAD`. Approved architecture/gameplay remain unchanged.
ADR-0003 is proposed, not accepted. Existing documentation is preserved in place.

Reviewable steps are: (1) project scene and text/ignore rules; (2) nonempty shell
tests and cross-platform runners; (3) checksum-pinned installation and CI;
(4) ADR-0003 proposal and development documentation. No services, identity APIs,
network play or save formats are implemented by this initial step.

## Executed on Linux x86_64

- Official 4.7.2 release tag exists. Linux archive matched official SHA-512.
- `tools/install_godot.py` downloaded and verified the pinned Linux build.
- Engine reports `4.7.2.stable.official.ed1daf0bf`.
- `GODOT_BIN=/workspace/.local/bin/dungeonward-godot ./tools/test.sh`:
  project import, 5 checks / 0 failures, and main-scene headless startup passed.
- Same runner with `--self-test-failure`: intentional failure exits nonzero.
- Normal runner repeated after the failure probe: passed.
- `git diff --check`: passed.

Raw current-run logs are in ignored `artifacts/`; no Windows results are implied.

## Remaining gates and smallest next actions

The official Windows 4.7.2 archive also passed pinned SHA-512 verification and
contains the console executable used by CI; it was not executed.
Windows execution is unavailable in this Linux workspace. CI defines Windows
and Linux jobs with verified Godot 4.7.2 downloads and artifact uploads. After
owner review, authorize publishing this branch to run GitHub Actions, or run
`tools/test.ps1` on an authorized Windows x64 machine and provide the logs.
Require both Foundation checks in GitHub branch protection before integration;
this change does not modify repository settings.

Foundation v0.5 section 14 gates identity DTO/registry work on actual Windows
and Linux harness evidence. That next step remains pending. No Windows GUI,
physical-controller or mixed-OS networking tests have run. M0 exit criteria are
not met yet. At the time of initial validation, no push, merge, release or environment
publication had been performed. Branch push is now authorized; merge, release
and environment publication remain outside scope.
A project license remains undecided and must be selected before public release.

## Initial structure follow-up

Reserved Foundation domains under `game/core`, content folders for future weapons
and bosses, and documented UI/world boundaries. Added DeepSeek's exact test
commands and bounded Gemini/Groq boilerplate candidates. No gameplay or service
interfaces were implemented; no delegation occurred. Shell-only scope is complete;
full M0 remains incomplete (Windows evidence and identity/lobby/authorizer work).
