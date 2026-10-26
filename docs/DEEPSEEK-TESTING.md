# DeepSeek: reproduce M0 shell validation

Use the existing checkout and working branch; do not push, merge or alter the
architecture. Read `00_SHARED_RULES.md`, `07_DEEPSEEK.md`, Foundation v0.5 §9/14,
and this guide. No credentials or services are needed for the smoke tests.
Installation needs HTTPS access to GitHub release assets. Use only Godot 4.7.2.

## Linux x86_64 (from repository root)

```bash
python3 tools/install_godot.py
export GODOT_BIN="$PWD/.tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"
"$GODOT_BIN" --headless --version
./tools/test.sh
```

In this cloud machine use the installed writable-path wrapper instead:

```bash
cd /workspace/dungeonward
GODOT_BIN=/workspace/.local/bin/dungeonward-godot ./tools/test.sh
```

## Windows x64 / PowerShell (from repository root)

```powershell
python tools/install_godot.py
$env:GODOT_BIN = "$PWD/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
& $env:GODOT_BIN --headless --version
./tools/test.ps1
```

The console executable is required to capture Windows output reliably. No Windows
machine access is implied by these instructions. Run only on an authorized runner.

## Expected checks and evidence

Both wrappers import the project, run `tests/run_all.gd`, then boot the configured
main scene headlessly. Expected result: **5 checks, 0 failures**, exit 0 and no
Godot errors. These tests cover the version, main-scene configuration, resource
load, scene instantiation and status label. They do not validate gameplay.

The underlying commands, after verifying `GODOT_BIN`, are:

```text
<GODOT_BIN> --headless --path . --editor --import
<GODOT_BIN> --headless --path . --script res://tests/run_all.gd
<GODOT_BIN> --headless --path . --quit-after 2
```

Failure propagation probe (expected exit 1, not a passing test run):

```bash
./tools/test.sh --self-test-failure
```

```powershell
./tools/test.ps1 --self-test-failure
```

Run the normal wrapper again afterward to restore current successful logs.
Capture the shell exit code immediately (`$?` in Bash, `$LASTEXITCODE` in
PowerShell). Return OS/architecture, engine output, `git rev-parse HEAD`,
`git status --short`, exact command, exit code, check counts and `artifacts/`
logs. Local uncommitted changes are not identified by the base commit SHA alone.
Keep failed, passed and unrun results separate. Visual output and hardware input
require separate manual testing; headless success does not establish those.

## Future bounded boilerplate tickets (not delegated)

- **Gemini:** once fields/interfaces are approved, generate a small set of typed
  Resource declarations or UI view bindings from one reviewed example. Limit the
  task to named files; require Godot import and fixture tests.
- **Groq:** with the actual hosted model identified, fill approved fixture tables,
  repetitive validation cases or content data from an exact schema. Require parse
  and expected-output checks. Do not invent stats, APIs or identifiers.

Neither task is needed for the current tiny shell. Codex retains architecture,
identity, authority, save ownership, CI and integration decisions. No work has
been delegated and no external model capability has been assumed.
