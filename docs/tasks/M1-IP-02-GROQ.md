# M1 IP-02 — Groq bounded boilerplate/test assignment

**Status:** Assigned for drafting; NOT implemented or tested.
**Owner:** Groq-hosted coding model (select concrete model at execution). **Reviewer/integrator:** Codex. **Independent tester:** DeepSeek.
**Branch:** `feature/m0-foundation`. No independent push or main merge.

## Scope (disjoint from Gemini)
Draft a self-contained GDScript test file `tests/unit/test_join_gesture.gd` containing a pure test function callable by the existing `tests/run_all.gd` runner. **Do not modify** `run_all.gd` or Gemini's `game/core/input/join_gesture.gd`. The test should accept a constructor/script reference or instantiate `preload("res://game/core/input/join_gesture.gd")` after Codex integration.

## Contract to test
See `docs/tasks/M1-IP-02-GEMINI.md`. No fixed timeout value is approved: tests may inject a clearly labeled fixture window (not a game default), with boundary checks at exactly the deadline. Test device 0 valid, negative ID rejected; two independent controllers; same-controller Start×2; first press no reservation; other device's press cannot confirm; timeout/cancel; assigned Start opens menu; duplicate while pending; host reservation failure; host success transitions to character select, not spawn; explicit binding only after approval; disconnection no silent reassignment; lobby full fails cleanly; solo lobby not blocked by waiting for others.

## Output constraints
- Supply typed GDScript test code, test count and integration instructions; use existing `check(condition, description)` pattern and don't invent unknown method names. If Gemini API differs, provide test cases as fixtures/pseudocode rather than guessing names; Codex will adapt.
- Do not change game architecture or implement lobby transport.
- No fabricated test evidence; mark NOT RUN until DeepSeek executes.
- Include a concise traceability matrix mapping each assertion to approved F14/F04 behavior.

## Acceptance
Codex reviews the tests against the exact Gemini API; DeepSeek runs normal and intentional negative-control suites on Godot 4.7.2 Windows/Linux CI.
