# Dungeonward AI team v0.2 — token-optimized

**Quick start:** Give an agent `agents/00_SHARED_RULES.md`, its one role file, and a filled `templates/TASK_HANDOFF.md`. Add only relevant **excerpts** from `reference/docs/` and source files. The `reference/` directory is included for convenient retrieval, **not** for ingestion in full.

| Agent | Role file | Default docs to fetch *only when needed* |
|---|---|---|
| Codex | `01_CODEX.md` | Foundation, ADR-0001, affected feature |
| Gemini | `02_GEMINI.md` | F04, foundation identity/RPC, ADR-0001 |
| Claude Opus | `03_CLAUDE_OPUS.md` | F11, asset references, optional F02/F06 |
| Kimi K3 | `04_KIMI_K3.md` | F10/F11, optional F14/F06 |
| Grok | `05_GROK.md` | F02/F07/F01 |
| Groq model | `06_GROQ.md` | Exact interface/example only |
| DeepSeek | `07_DEEPSEEK.md` | Test commands, affected spec/logs |

**Workflow:** scoped task → branch → implementation → actual tests on available OS → Codex review → user-approved integration. Never feed all reference docs to every agent. For long sessions, replace stale chat history with a short current-state handoff (branch, files, decisions, failures, next step). Don't repeatedly resend standing rules within a session.

**Authority:** existing `reference/docs/` contains approved decisions and open questions. These agent briefs are task routing instructions, not new game-design approvals. If there is a conflict, stop and surface it.

## M0 foundation development

The minimal Godot project shell and test infrastructure are implemented on
`feature/m0-foundation`. Identity, lobby, transport and persistence are not yet
implemented. Existing specifications remain at repository root; their proposed
nested documentation paths are not actual paths in this checkout.

Use exactly **Godot 4.7.2 stable**. Install a checksum-pinned official x64 build:

```sh
python tools/install_godot.py
# Linux
GODOT_BIN="$PWD/.tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64" ./tools/test.sh
```

```powershell
# Windows PowerShell
python tools/install_godot.py
$env:GODOT_BIN = "$PWD/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
./tools/test.ps1
```

Both runners verify the engine, import the project, run the nonempty shell tests,
and start the main scene headlessly. Logs and revision/platform metadata go to
ignored `artifacts/`. Pass `--self-test-failure` to either runner to intentionally
verify nonzero failure propagation. The reported commit is the base commit when
working changes have not been committed; it does not identify an uncommitted diff.
Open `project.godot` in the same engine for visual development. In the cloud use
`GODOT_BIN=/workspace/.local/bin/dungeonward-godot ./tools/test.sh`; that wrapper
sets writable Godot data/config/cache directories.

GitHub Actions runs the same checks on Windows and Linux after an authorized push
or PR. Windows evidence is pending; M0 is not complete. See
[ADR-0003](ADR-0003-modular-extensible-architecture.md) for proposals awaiting
review and [M0 evidence](docs/M0-INITIALIZATION.md) for actual validation.

For exact independent execution steps see [DeepSeek testing](docs/DEEPSEEK-TESTING.md).
Reserved domains live in `game/core/`; future content, UI and world boundaries are
explained in the README files under `game/`. Empty directories reserve ownership,
not implemented features or finalized APIs.
