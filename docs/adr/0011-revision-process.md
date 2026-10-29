---
title: How does a revision account for everything downstream of it?
date: 2026-10-28
---

# How does a revision account for everything downstream of it?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

When an upstream artefact is revised, nothing enumerates what
downstream must change with it (seed #92). Each ripple — a plan that
now targets a changed decision, a skill written from that plan — has
been found by hand.

The retrieval exists: `history downstream <path>` (ADR 0010) returns
the transitive `Derives-From` graph of an artefact plus its `Revises`
history. What is missing is the *process* that takes that list,
assigns each item a verdict, makes a missing verdict visible, and
gates on it.

ADR 0004 already decides part of this: on a revision's branch, every
plan whose `adr:` names the revised ADR is "revised to match or set to
`deferred`". That obligation is narrow in two ways — it reaches only
ADR → plan, and an unaffected plan is handled by silence, not by an
explicit record. This ADR generalises it.

## Decision

### Scope: ADR → plan → skill, consuming the history graph

The revision process covers the links stable today: ADR → plan →
skill (plans link by `adr:`; skills link transitively through their
plan). Its input is the `downstream:` list from
`history downstream <path>` (ADR 0010). The process **consumes** that
query; it never re-traverses git itself.

### Each durable, in-tree downstream artefact gets a verdict

Verdicts apply only to durable artefacts present in the tree: skills,
code, ADRs, and plans still in the tree (deferred or in progress). For
each of these on the `downstream:` list, the revision records on the
same branch exactly one verdict:

- **Reconciled** — edited to match the changed decision; the touching
  commit corroborates, but the verdict trailer (below) is what the
  gate reads;
- **Deferred** — applies to any durable, in-tree downstream (skill,
  code, or plan), and only when reconciliation is blocked
  on a durable, in-tree artefact's own future change — at minimum an
  accepted ADR; a seed or a plan is too ephemeral to anchor on (ADR
  0004's escape, narrowed further here). The **origin** is that
  artefact, named directly — never its upstream. The condition is the
  origin's path plus a description, load-bearing only when the path
  alone yields more than one candidate event; the description
  disambiguates — e.g. naming the upstream the origin is reconciled
  *to*. It is due, with zero judgement, once a commit landing on
  trunk **after this deferral** carries a keyed trailer targeting the
  origin: `Reconciles: <origin>` (until `<Y>` is reconciled to `<U>`,
  the description naming `<U>`, matched by a co-landing
  `Revises: <U>` on the same branch), `Revises: <origin>` (the origin
  is an ADR revised directly), or `Derives-From: <origin>` (the
  origin produces a new downstream). The match may be asserted by the
  landing agent, not necessarily a human. Never open-ended — if
  nothing specific blocks it, reconcile now or record *Confirmed*.
  Discharging a due deferral is ADR 0012's;
- **Confirmed** — a downstream found unaffected, recorded explicitly.
  This is now primarily a **discharge-time re-verdict** (ADR 0012): an
  untouched downstream is confirmed when the reconciling plan arrives
  and leaves it alone, rather than judged unaffected up front by the
  reviser.

**The blast-radius default.** The revision enumerates its transitive
downstream — the blast radius — up front: a readout of how much work
revising this ADR implies. (This is the `downstream:` worklist `begin`
already surfaces; see below.) It records *Reconciled* for what it edits
on its own branch, and marks the untouched remainder *Deferred* until a
plan derives from this ADR — conservatively, without per-item
judgement. That per-item judgement is deferred to discharge (ADR 0012),
where each deferred downstream is re-verdicted *Reconciled* (the plan
touched it) or *Confirmed* (it did not).

A **completed plan has left the tree** (ADR 0004: a plan leaves when
its work is complete) and is not revised. Its place in the
`downstream:` list is informational — showing which durable outputs
trace to this ADR — and the revision of those outputs is carried by
**new plans**, not by editing the gone plan. The completeness
requirement is thus scoped to durable, in-tree artefacts; removed
artefacts need no verdict. Filtering the list to what is in the tree
is the plan's.

This generalises ADR 0004's "Reconciled or Deferred" from ADR → plan to
the whole in-tree graph, and adds the explicit *Confirmed*
verdict so an unaffected artefact is **recorded as Confirmed**,
not silently skipped — the hand-found ripple seed #92 names.

Verdicts are recorded as **trailers**, for the reasons ADR 0004
adopted them: append-only, machine-readable, and timestamped by the
commit they sit on — so *when* a verdict was made is intrinsic, the
staleness problem trailers were introduced to solve. These are new
edge types that **extend ADR 0004's exhaustive trailer table**, an
extension made by the revision of ADR 0004 (a dependency this ADR
carries). They are **cross-edges**: `Revises`/`Clarifies` are the
self-edges (an ADR to itself), whereas a verdict links the revised ADR
to a *different* durable downstream (the `Derives-From`/`Completes`
family). The trailer **names that downstream in its value**, read from
the revision's side — "the revision Reconciled / Confirmed / Deferred
`<D>`" — because the *Confirmed* verdict has no commit
touching the downstream to carry it, and the gate must know which
downstream a verdict covers; being on the branch that carries
`Revises` scopes it to this revision. The keys are defined in ADR
0004's trailer table; the gate's parsing stays the plan's. The gate
checks that a verdict is present,
not that its claim is true; a verdict is the reviser's assertion.

### A missing verdict is visible, and the gate is `land`

A verdict is missing when a durable, in-tree artefact — the filtered
`downstream:` list, not the raw one — has no verdict on the branch.
The gate refuses to land such a branch and names each artefact still
without a verdict.

The gate runs at **`land`**, not at `begin`:

- `land` already stops a `Revises` branch — a decision branch, landed
  by a human (ADR 0003) — and already parses trailers. The
  verdict-completeness check is the same shape of mechanical check at a
  moment that already exists and already does decision-branch work; no
  new gate moment is introduced.
- Completeness can only be checked once the verdicts exist. `begin` is
  before any edit, so it has nothing to gate; a hard gate there would
  block the branch before the work that satisfies it could be done.
- It is where ADR 0004's obligation already bites — "on the same
  branch", at landing. Generalising leaves the enforcement point
  unchanged.

`begin` still has a use: surfacing the `downstream:` worklist so the
reviser sees the scope up front. That is advisory and blocks nothing.
Verdicts are recorded on the branch as trailers `land` can check
without judgement.

### Out of scope: eval scenarios

Eval scenarios are **not** in the revision graph, and are deferred to
the test-production process (seed #119). The limitation is two-part:
(a) evals carry no `Derives-From` link — authored inline during
skill-forge, they never reach `land`'s gate; and (b) their authoring
workflows have no revision lifecycle — `test-first-workflow` is
append-only but for an "invalid test" escape hatch framed for
mistakes, and `skill-forge` skips evals on a body-only edit and bars
retrofitting. Decomposing those workflows (the test-production
separation) is harness-era work, also #119.

Release schedule and distribution are a separate boundary, also out of
scope (discovery 0004 territory).

## Alternatives considered

- **Gate at `begin`, or at both `begin` and `land` as hard gates.**
  Rejected: before any edit there is no verdict to check, so `begin`
  can only enumerate, not gate; a hard gate there blocks the branch
  before its work can be done. `begin` is kept as the advisory
  worklist.
- **Re-traverse the graph inside the revision process.** Rejected: ADR
  0010 already decided the transitive downstream query is the history
  skill's, and ADR 0004 rejected building a second graph. The process
  consumes `history downstream`.
- **Keep ADR 0004's "Reconciled or Deferred" with no *Confirmed*
  verdict.** Rejected: an unaffected artefact is then skipped
  with no record, which is the silent gap seed #92 names. The explicit
  verdict is what makes *Confirmed* auditable.
- **Record verdicts in frontmatter or prose.** Rejected: neither is
  timestamped by its commit, so *when* a verdict was made is not
  intrinsic — the staleness problem, and inconsistent with ADR 0004's
  trailer rationale. Verdicts are trailers.
- **Put eval scenarios in the graph now.** Rejected and deferred to
  #119: evals carry no `Derives-From`, and their authoring workflows
  have no revision lifecycle to hang a verdict on.
- **Anchoring a deferral's condition on the driving upstream `U`**
  rather than on the awaited artefact itself. Rejected: the deferral
  must point at the artefact whose own change discharges it; `U` is
  the disambiguating description, not the anchor. The false-trigger
  worry — an unrelated revision wrongly satisfying the condition — is
  handled by the description and the specific reconciliation event,
  not by moving the anchor. External, non-repo conditions (dates,
  "when someone gets round to it") are excluded as unevaluable
  against trunk.
- **Pre-specifying the to-be-created artefact's path in the origin.**
  Rejected: history-based artefact numbering allocates the new path
  only at creation, so the origin cannot name it up front; the
  condition anchors on the origin's existing path instead, and the
  new path is discovered at check time.
- **A mandatory structured `kind` tag** (e.g. `produced:<kind>`), or a
  description required on every deferral. Superseded: the origin's
  path is load-bearing on its own except where it resolves to more
  than one candidate event, and only then does a description earn its
  keep.

## Consequences

- This ADR depends on revising accepted ADR 0004, with three effects:
  (i) its ADR → plan "Reconciled or Deferred" obligation generalises to
  the ADR → plan → skill verdict set; (ii) verdict trailer edge types
  join its exhaustive table; and (iii) its currently open-ended
  `deferred` escape is narrowed to require a named blocking condition.
- `land` gains a check that consumes the history skill's `downstream`
  query, coupling the gate to that script; a repository without it
  cannot run the gate.
- A *Confirmed* verdict is a claim nothing re-derives.
  The gate enforces that a verdict exists, not that it is right; the
  ADR 0008 reviewer's fidelity check is the complementary judgement.
- This ADR keeps the reviser-asserts-verdicts model. We may eventually
  separate the provision of verdicts from the revision itself — a
  separate verdict-giver (seed #124, the role-concentration theme of
  #119 and ADR 0008).
- Narrowing the deferral's condition to `origin-path + description`
  makes ADR 0012's due-deferral check mechanical: `land` tests
  `Reconciles: <origin>`, `Revises: <origin>`, or
  `Derives-From: <origin>` against trunk, no judgement required to
  decide whether a deferral is due.
- Evals stay outside the revision graph until #119; a revision that
  should change an eval leaves no verdict and no gate catches it.
- "Downstream" here is the *production graph* (`Derives-From`: ADR →
  plan → skill/code), not everything that logically depends on an
  artefact. One ADR building on or constraining another is recorded in
  prose References, not a `Derives-From` edge — deliberately, since
  `Derives-From` is acyclic by construction and inter-ADR dependencies
  are not — so a revision never mechanically surfaces the ADRs that
  logically depend on it. This ADR is the first instance: 0011 is a
  logical downstream of 0004 but not a graph one, so revising 0004 will
  not surface 0011 via `history downstream`. Deferred to seed #120,
  which touches the decision-decomposition question (seed #94).
- The production graph records what was *produced from* a decision
  (`Derives-From`, immutable), not what it currently *governs* (scope,
  which a revision changes). So the gate cannot see an artefact a
  revision newly brings **into** scope (no edge — a false negative),
  and it keeps surfacing one a revision pushes **out of** scope (the
  edge persists — a false positive). Determining current governance is
  **planning-stage** work (the `plans` skill), not a graph traversal.
  Deferred to seed #125 (cf. #120, #94).

## References

- `docs/adr/0004-where-does-history-live.md` — the ADR → plan
  "Reconciled or Deferred" obligation this ADR generalises to the
  in-tree graph; the exhaustive trailer table that verdict trailers
  extend, by a revision of 0004 — including its `Defers:` row, which
  this model generalises beyond plans to any durable downstream; the
  tree-is-current rule that rules out a second index.
- `docs/adr/0010-history-retrieval.md` — the transitive
  `history downstream` query this process consumes, without
  re-traversing git.
- `docs/adr/0003-git-workflow.md` — `land` stops a `Revises` branch
  and parses trailers, the moment this gate attaches to; and
  plan-merge-on-creation, which makes a revised ADR's plans "in the
  tree" so the downstream set is complete.
- `docs/adr/0008-stage-reviews.md` — the review loop a revision is
  drafted under; its reviewer's fidelity check complements this gate.
- `skills/history/SKILL.md` — the `downstream:` output this consumes.
- `docs/adr/0012-discharging-deferrals.md` — discharges a deferral
  stated in the form defined here once it comes due, re-verdicting the
  deferred downstream and reinstating `Confirms:` as a discharge
  verdict for the conservative case the blast-radius default produces.
- Seed #92 — the gap this answers. Seed #119 — the test-production
  process that owns evals.
