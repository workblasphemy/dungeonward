# Handoffs

Baton-pass notes for this team. Follow [docs/HANDOFF_PROTOCOL.md](../docs/HANDOFF_PROTOCOL.md).

Filename: `NNNN_<slug>_<short-task>.md`. `NNNN` is a four-digit sequence. The next number is one higher than the highest note under this folder or [archive/](archive/README.md). Slugs: `codex`, `gemini`, `claude`, `kimi`, `groq`, `deepseek`, `grok`, `owner`.

Do not edit or delete a note. Moving it into `archive/<milestone>/` at a milestone close is allowed, and only `codex` does that. Sequence numbers are not reused.

[LATEST.md](LATEST.md), [STATUS.md](STATUS.md), and [DECISIONS_NEEDED.md](DECISIONS_NEEDED.md) are the living files. Logs longer than 40 lines go in [logs/](logs/README.md). Copy [_TEMPLATE.md](_TEMPLATE.md) for a new note.

The code commit lands first. The note, LATEST, and STATUS land in the next commit and that commit stays inside this folder. Push both commits together. The working branch is the `Working branch:` line in LATEST.md. Before writing a note, `git pull --rebase` as the protocol's Parallel work section describes.
