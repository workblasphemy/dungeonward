# Decisions needed

Questions only the owner can close. A BLOCKED note adds a row. Do not delete rows. Status is `OPEN` or `DECIDED`. When the owner decides, fill the decision and the date.

| ID | Question | Options | Raised by | Blocking | Status | Decision |
|---|---|---|---|---|---|---|
| D-001 | `DUNGEONWARD_AI_CAPABILITY_ROUTING_v0.3.md` is only on `main` (`a5aeca4`), not on `feature/m0-foundation`. Bring it onto this branch? | Copy the file onto this branch without merging `main`. Leave it only on `main`. | [0001](0001_grok_handoff-protocol.md) | none | OPEN | — |
| D-002 | [docs/DEEPSEEK-TESTING.md](../docs/DEEPSEEK-TESTING.md) hardcodes `cd /workspace/dungeonward`. Fix it? | Replace it with repo-root commands. Keep it as a cloud-only example. | [0001](0001_grok_handoff-protocol.md) | none | OPEN | — |
| D-003 | [ADR-0001](../ADR-0001-foundational-architecture.md) says "Godot 4" in the context and in the ARCH-01 decision. Update that wording to 4.7.2? | Amend the accepted ADR text to Godot 4.7.2. Leave the accepted wording. The pinned engine stays 4.7.2 in the foundation spec and shared rules. | [0001](0001_grok_handoff-protocol.md) | none (do not edit the ADR until the owner decides) | OPEN | — |
| D-004 | May a task invent unspecified numeric tuning? | No. Tuning stays OPEN until the owner sets each value. The owner adds a decision row before that number is used. | [0001](0001_grok_handoff-protocol.md) | any task that would lock a new number | OPEN | — |
