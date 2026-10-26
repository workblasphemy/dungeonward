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
