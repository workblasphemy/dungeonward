# Agent instructions

When told to "check the new .MD", "check for the new .MD and work", "check handoffs", or a similar short phrase, follow [docs/HANDOFF_PROTOCOL.md](docs/HANDOFF_PROTOCOL.md) before any other work.

Read [handoffs/LATEST.md](handoffs/LATEST.md), the note it names, [handoffs/STATUS.md](handoffs/STATUS.md), and [handoffs/DECISIONS_NEEDED.md](handoffs/DECISIONS_NEEDED.md). Tell the owner the latest verdict, Build/commit, and your plan, then continue unless the owner says stop. Do the work. Leave a new numbered handoff note.

Slugs for filenames, `Next owner`, and `Claimed by`: `codex`, `gemini`, `claude`, `kimi`, `groq`, `deepseek`, `grok`, `owner`. Verdict APPROVED is only for filename slugs `codex` and `owner`.

Commit product changes first. Commit the note, LATEST.md, and STATUS.md next, and do not touch paths outside `handoffs/` in that second commit. Push those commits together. Work on the working branch named in [handoffs/LATEST.md](handoffs/LATEST.md) (currently `feature/m0-foundation`). Do not merge to `main` or push another branch unless the owner approves. Codex integrates. Before writing a note, `git pull --rebase` and take the next sequence number from that tree.
