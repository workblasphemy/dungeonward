# DUNGEONWARD — AI Capability Routing & Delegation Policy
**Version:** 0.3 | **Status:** Proposed workflow; not a gameplay/architecture ADR | **Engine:** Godot 4.7.2

## Purpose
Minimize expensive model tokens **and** wasted iteration. Assign tasks based on their failure cost, verifiability, and the tools an agent can actually run—not model branding alone. This is a **provisional engineering assessment**, not a benchmark or claim that these particular models have passed Dungeonward tests. Re-evaluate after measured trial tasks.

## Core principle
**Cheap drafting → deterministic checks → expert integration** works for bounded, testable code. It does **not** work well for subjective visual assets without a visual feedback loop. Never confuse fast text generation with successful execution or production-quality art.

## Model routing (practical recommendations)
| Agent | Prefer for | Avoid as sole owner | Verification gate |
|---|---|---|---|
| **Codex / ChatGPT** | Architecture, cross-system integration, Godot repository edits, test harness, authoritative networking/security and save invariants | Spending premium reasoning on repetitive data entries | Runs project/tests; reviews diff; approves integration |
| **Claude Opus** | Hard debugging, code/architecture review, Blender **tool scripts**, rig/export automation, complex animation logic | Guaranteeing high-quality finished character/weapon meshes from a text prompt | Blender executes script; render inspected; geometry/rig/export checked |
| **Gemini** | Bulk typed GDScript scaffolds, resource definitions, serializers, UI wiring, **bounded networking implementation** under approved RPC contracts | Designing trust boundaries or owning multiplayer security without review | Godot parse/import, tests, Codex authority review |
| **Groq-hosted model** | Very repetitive, short, low-risk code/data transforms, template filling | Large multi-file edits, deep architecture, visual asset production; quality depends on the **specific model** hosted | Lint/parse and snapshot/unit tests; discard failures quickly |
| **Kimi K3** | UI layout/code variants, shader drafts, style-system implementation, large-context reference analysis | Assuming attractive mockups imply usable Godot scenes; unreviewed networking/persistence | Screenshots at target resolutions, navigation/input checks, performance |
| **Grok** | Alternative combat ideas, tuning prototypes, AI behavior sketches, short experimental mechanics | Shipping core combat architecture or deterministic network logic without review | Playtest, frame/latency measurements, regressions |
| **DeepSeek** | Independent Windows/Linux execution, failure reproduction, test writing and targeted fixes; may run on user's PC when authorized | Treating its written opinion as evidence of test success | Command, OS, Godot version, exit status, logs, repro steps |

**Caveat:** “Kimi K3”, “DeepSeek 4.1 Flash”, and a Groq deployment can differ by provider/version/configuration. Validate the *actual accessible model and tools*. Model strengths above are hypotheses to test, not independently measured comparative results.

## Task classes: who should do what?
**GREEN — delegate to Gemini or Groq first (low ambiguity; easy to verify)**
- Typed `Resource` declarations based on approved fields; data schemas and validation helpers.
- Repetitive GDScript class stubs, test fixtures, data importers, item definitions, localization scaffolds.
- Unit tests for existing contracts; straightforward UI bindings after interface definitions.
- Mechanical refactors with precise input/output and automated tests.

**YELLOW — Gemini/Kimi/Grok draft; Codex or Claude owns integration**
- ENet message handlers after Codex specifies authority, ownership and RPC contracts.
- Procedural generation algorithms with seed/replay tests.
- UI scenes, theme variants and shaders with screenshot/performance acceptance tests.
- Enemy behavior and combat prototypes with explicit gameplay metrics.
- Blender Python **utilities**: batch naming, export, LOD setup, simple parametric props.

**RED — premium engineer or specialist from the start**
- Player identity, reservation race conditions, host authority, security and anti-duplication.
- Character save migration, atomic writes, ownership and recovery.
- Architecture decisions changing shared interfaces or multiple systems.
- Performance bugs, nondeterministic multiplayer bugs and hard cross-platform failures.
- High-quality character/creature sculpting, polished weapon silhouettes, skinning and expressive animation **without reliable visual tooling**: use a real 3D artist, curated assets, or an asset-focused 3D generation workflow with human visual approval. LLM-authored Blender scripts are not a reliable substitute.

## Blender reality check (important)
Text models can write Blender Python and produce **simple parametric meshes**, scene setup, procedural materials, batch processing and export automation. They are generally much less reliable at producing polished, art-directed, game-ready organic models and animations from text alone. Failure modes: primitive-looking topology, bad silhouettes, incorrect UVs, broken rigs, excess polygons, scale/orientation errors, and unusable exports.

**Acceptable Blender delegation:** “Create a configurable low-poly crate generator with a deterministic seed, <= 600 triangles, UVs, origin at base, and export to GLB; run Blender headless and provide a rendered preview.”  
**Poor delegation:** “Model all Dungeonward bosses in Blender, production-ready,” without reference, renderer, asset QA or an artist.

**Asset pipeline gate:** reference/style brief → blockout → 3-view or turntable render → visual approval → topology/UV/rig/animation QA → GLB export → Godot import test → in-game lighting/scale inspection. Stop after blockout if silhouette/style fails; do not burn multiple AI iterations on an unsuitable method.

## Budgeted escalation policy
1. **Define an acceptance test first.** If success cannot be observed, improve the brief before delegating.
2. **Choose cheapest plausible executor** for GREEN; choose capable lead for RED. Send only shared rules, role file, relevant spec sections and touched interfaces.
3. **One bounded attempt** with explicit files, constraints and tests. For visual work, require a preview at the first iteration.
4. **Allow at most one targeted repair** for a specific, evidenced failure. No vague “keep trying until good.”
5. **Escalate** to Codex/Claude, a domain tool, or human review if the same failure persists, the agent invents APIs, changes unrelated modules, cannot execute required tools, or produces poor visual results.
6. **Reject unverified claims.** “Implemented” means files exist; “tested” means actual logs; “game-ready asset” means visual and technical gates passed.
7. **Review and merge** via Codex only after tests, diff inspection and user's publication/merge approval.

## Small calibration trials before committing a model to a discipline
Run the **same brief** with comparable constraints and a fixed time/token budget. Record:
- **Correctness:** Godot 4.7.2 import/parse, tests passed, platform parity.
- **Intervention:** number of human corrections, broken unrelated files, retry count.
- **Cost:** input/output tokens, wall-clock time, paid usage.
- **Quality:** maintainability, modularity, visual fidelity where applicable.

Suggested 30–60 minute trials:
1. **Gemini vs Groq:** generate a typed item-resource schema + validation tests from a fixed contract.
2. **Gemini vs Codex:** implement a *mock* slot reservation state machine (not live network security); test duplicate reservations, fifth slot, disconnect.
3. **Kimi vs Gemini:** build a controller-navigable inventory panel from a fixed UI mockup; compare actual screenshots.
4. **Claude Blender vs dedicated asset workflow:** produce one low-poly sword *and* exportable GLB with UV/triangle budget; compare silhouette and in-Godot result.
5. **DeepSeek:** independently reproduce the exact same Windows/Linux smoke test, with logs.

**Promote a model only after repeatable success.** If a cheaper model takes three failed attempts, it may be more expensive than a premium model doing it once.

## M0-specific allocation
- **Codex (owner):** repository inspection, modular project layout, project.godot, startup scene, architectural contracts, CI design and merge review.
- **Gemini (optional):** bounded GDScript scaffolds and test fixtures **after** Codex defines file paths and interfaces.
- **Groq (optional):** mechanical boilerplate only; no requirement to involve it when M0 code volume is small.
- **DeepSeek (independent tester):** Windows and Linux headless smoke tests, exact logs and environment reports.
- **Claude:** consult only for a genuinely difficult design/review issue.
- **Kimi/Grok:** skip M0. **No Blender modeling in M0.**

**Efficiency note:** M0 may be faster with Codex + DeepSeek alone. Multi-agent handoffs have overhead; use Gemini/Groq only when the task is large enough to save net time.

## Reusable delegation ticket (copy/paste)
```text
TASK: [one bounded outcome]
OWNER: [AI]   REVIEWER: [AI]
READ: agents/00_SHARED_RULES.md; agents/[ROLE].md; [exact relevant spec sections/files]
DO NOT READ: unrelated feature specs unless a dependency is discovered
FILES ALLOWED: [paths]
CONTRACTS: [existing APIs/IDs/invariants that cannot change]
DELIVERABLE: [specific files/diff]
ACCEPTANCE: [commands/tests/screenshots/asset checks]
BUDGET: one implementation + one evidence-based fix; then escalate
REPORT: changed files, exact tests/results, limitations, open issues
RULES: no unrelated refactors; no silent version changes; no merge/push without approval
```

## Non-negotiable Dungeonward invariants
- Godot **4.7.2** target; do not silently substitute engine versions.
- GitHub; Windows and Linux functional by end of M3.
- Host-authoritative ENet; **four total character slots**, including hybrid couch/online.
- Separate peer, local-slot, session-player and persistent-character identities.
- Persistent separate local profiles; ownership-safe town saves; shared synchronized dungeon.
- Modular, data-driven content and UI; stable identifiers; explicit interfaces and regression tests.
- Other approved architecture/gameplay choices remain governed by ADR-0001/0002; this document changes none of them.

## Update policy
Maintain a lightweight `docs/AI_TRIAL_RESULTS.md` with model/version, task, tests, time, retries and verdict. Reassign roles based on measured outcomes, not loyalty to a vendor.
