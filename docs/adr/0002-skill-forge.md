---
title: Skill-forge — test-first workflow for authoring skills
status: accepted
date: 2026-09-01
supersedes: null
superseded_by: null
---

# Skill-forge — test-first workflow for authoring skills

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Myelin front-loads human thinking and progressively automates later
stages (facilitated-discovery → ADR → plan → implementation). As the
plugin grows, and especially as it starts to be applied to external
projects in unanticipated domains, the automated stages will need
skills that do not yet exist. Two distinct shapes of that need are
visible:

- **Shape 1 — deliberate, plan-step-driven.** A plan step is
  explicitly *"write skill X"*. Detection is trivial: the plan says
  so. This is the near-term case, and it is on the critical path for
  myelin's own dogfooding — the plugin's next non-trivial work is
  itself the writing of more skills.
- **Shape 2 — reactive, mid-flow.** Some other skill is running and
  hits an activity for which no skill exists; a forge is pulled in
  reactively so work can continue. Detection here is strictly harder
  than the drift problem ADR 0001 flags — how does an agent notice
  the *absence* of a skill? — and it belongs adjacent to the subagent
  orchestrator space that ADR 0001 explicitly parked. Shape 2 is
  therefore deferred until external adoption produces concrete
  incidents to reason from.

Within Shape 1, the current gap is that the four hand-written skills
in `skills/` were authored without any principled workflow, and none
of them ship with their own eval coverage. New skills authored ad-hoc
will replicate that gap.

The tessl platform provides two relevant verbs with a strong cost
asymmetry:

- `tessl review run <skill-path>` — a per-skill static/structural
  review of the `SKILL.md` artifact itself (structure, prose,
  safety). Cheap; can be run frequently in an authoring loop.
- `tessl eval run` — executes every scenario under `evals/` against
  the plugin. Expensive; there is no scenario-selection flag, so
  every scenario present is exercised on every run.

The two verbs map naturally onto the two rungs of a test-first
workflow: `review run` as the fast structural gate, `eval run` as the
slower behavioural one. That gives an analogy that the writing of
skills can borrow directly from `test-first-workflow` for code:
docstrings → failing tests → code becomes frontmatter → failing eval
scenario → skill body.

## Decision

Add a `skill-forge` skill that implements Shape 1: a mandated
test-first workflow for authoring new skills.

**Ordered mandatory steps.**

1. **Frontmatter first.** Author the target skill's `SKILL.md`
   frontmatter — name and description — before anything else. The
   description is the trigger contract: the same role a docstring
   plays for a function.
2. **Hand-crafted minimal failing eval scenario.** Create
   `evals/<skill-name>-N/`, where `<skill-name>` matches the target
   skill's directory name under `skills/` and `N` is the highest
   existing scenario number for *this* skill plus one (starting at
   `0` if none exist). Populate it with `task.md`, `scenario.json`,
   and `criteria.json`. The scenario describes the smallest concrete
   behaviour the skill must eventually satisfy. It is authored by
   hand — not generated — because `tessl scenario generate` runs
   remotely against an uploaded plugin and cannot be the
   "failing-test-before-body" step. Tessl treats scenario directory
   paths as opaque and enumerates any subdirectory of `evals/`
   containing the required files, so per-skill naming is safe.
3. **Skill body until review passes.** Iterate on the `SKILL.md`
   body, running `tessl review run <skill-path>` on each pass, until
   review is green.

**Exit criterion.** Review-green on the new skill *and* a failing (or
not-yet-passing) eval scenario present on disk. Nothing more is
required. `skill-forge` hands control back to the caller at that
point so the enclosing work can proceed.

**Asymmetric pass criteria.**

- **Review must pass.** It is cheap, and it is the structural sanity
  gate: frontmatter well-formed, trigger phrasing coherent, body
  plausible enough to be worth running. Blocking on this costs almost
  nothing.
- **Eval scenario must exist; need not pass.** The failing scenario
  captured in step 2 *is* the improvement queue. Because
  `tessl eval run` has no scenario-selection flag, every subsequent
  eval run automatically picks the new scenario up. No provisional
  status flag, no `_review/` directory, no separate ticketing.
  "Improve later" concretely means: come back and make this scenario
  pass.

**Optional post-forge coverage broadening.** Once the skill body
exists, `tessl scenario generate` (followed by
`tessl scenario download --strategy merge`) may be used to broaden
scenario coverage. This is a deferred improvement step, not part of
the mandatory workflow — the two-step remote-then-download dance
would otherwise block the caller.

**Interaction with ADR 0001.** ADR 0001 mandates per-step directive
wrappers on plan steps that *write or modify executable code*. This
ADR relies on that mechanism being extended so that plan steps whose
work is *"author a new skill"* carry an analogous
`skill-forge`-loader directive. Specifying the exact wording of that
new wrapper is the job of the corresponding plan; the mandate here is
only that the wrapper exists on skill-writing steps by the same
"boilerplate, not paraphrase" convention ADR 0001 established.

## Alternatives considered

- **Shape 2 first (reactive mid-flow detection).** Rejected for
  now. The detection problem is strictly harder than the drift
  problem ADR 0001 already flags, and there is no concrete incident
  yet to reason from. Revisit after external adoption produces one.
- **Symmetric strict pass criteria (both review *and* eval must
  pass).** Rejected. Re-introduces the flow-blocking problem
  `skill-forge` exists to avoid; defeats "good enough to complete the
  current work, improve afterwards".
- **Provisional-status flag plus a `skills/_review/` queue
  directory.** Rejected. The failing eval scenario is a strictly
  superior improvement queue: it is executable, it is automatically
  re-run by every `tessl eval run`, and it defines "properly done" in
  a way a status flag cannot. A separate queue would duplicate
  tracking with no added signal.
- **`tessl scenario generate` as the primary scenario-authoring
  path.** Rejected as the mandatory step. Generation is remote and
  asynchronous, requires the plugin (with the target skill) to be
  uploaded first, and materialises only via a subsequent
  `scenario download`. It therefore cannot occupy the "failing test
  before body" slot. It fits well as post-forge coverage broadening.
- **No skill; keep hand-authoring skills ad-hoc.** Rejected. The
  existing hand-written skills demonstrate the gap: none ship with
  eval coverage. Ad-hoc authoring will keep replicating that gap as
  the plugin grows.

## Consequences

- Every new skill authored via `skill-forge` ships with at least one
  hand-crafted eval scenario from day one — a stricter minimum than
  the four existing skills currently meet. Retrofitting scenarios for
  those four is out of scope for this ADR.
- The per-skill naming rule confines merge collisions to the
  legitimate case: two branches that independently add a scenario
  for the *same* skill can still collide on `<skill-name>-N`, and
  should — that is the case where a human should reconcile scenario
  intent by hand. Two branches adding scenarios for *different*
  skills cannot collide, because their scenarios live in disjoint
  directory namespaces under `evals/`.
- Scenarios materialised later via `tessl scenario download` use
  tessl's own naming (description-slug by default, falling back to
  `scenario-N` when descriptions are absent). Hand-authored
  `<skill-name>-N` directories and downloaded slug-named directories
  will coexist under `evals/`. This is acceptable — tessl enumerates
  by directory presence, not by pattern — and the two conventions
  can be told apart at a glance.
- Coupling to tessl CLI surface. `skill-forge` names
  `tessl review run` and (optionally) `tessl scenario generate` /
  `tessl scenario download` explicitly. CLI renames or semantic
  changes upstream require a coordinated update to the skill body.
- Coupling to ADR 0001. This ADR extends the per-step directive
  mechanism to a new activity ("author a skill"). The `plans` skill
  will need a second boilerplate wrapper — same shape, different
  target skill. Editing ADR 0001's mechanism carelessly could break
  this one.
- Open plan-level empirical questions, to be closed during
  implementation rather than in this ADR:
  1. What is the deduplication key used by
     `tessl scenario download --strategy merge`? Directory name,
     `description`, or something else? (Known negative: `description`
     is *not* a lint-level dedup key — two directories with the same
     description both count as valid — so the risk is confined to
     download-time merge behaviour.)
  2. What is the minimum skill completeness required before
     `tessl scenario generate` produces useful output — frontmatter
     only, or a substantive body?
- Follow-up parked: eval and test *planning* may eventually deserve
  their own skill family. Evals are non-deterministic and warrant
  their own thinking about coverage, criteria, and quality. When that
  lands, `skill-forge` should hand off scenario authoring to the
  eval-planning skill rather than mint scenarios directly. That is a
  future ADR, not a change to this one.

## References

- `docs/adr/0001-artifact-embedded-skill-directives.md` — the
  per-step directive mechanism this ADR extends to skill-writing
  steps.
- `skills/test-first-workflow/SKILL.md` — the analogue for code that
  `skill-forge` mirrors for skills.
- `skills/{adr,facilitated-discovery,plans,test-first-workflow}/SKILL.md`
  — the four hand-written skills that predate `skill-forge` and
  demonstrate the coverage gap it addresses.
