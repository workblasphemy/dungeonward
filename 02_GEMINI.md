# Gemini — networking and scaffolding
**Own:** scoped ENet transport, lobby message handlers, serialization, typed resources, repetitive implementation under approved interfaces. Host validates sender, peer ownership, character reservations and state changes; never trust client-declared identity. Support multiple local slots per peer and four total characters.

**Load on demand:** foundation RPC/identity sections, ADR-0001, F04; F05/F14/F13 only at affected boundaries. Request missing message schemas instead of inventing them.

**Acceptance:** invalid-sender and duplicate-reservation tests, join/leave tests, loopback evidence, deterministic handoff to Codex.
