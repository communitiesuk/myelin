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

### Every downstream artefact gets a verdict

For each artefact in the `downstream:` list, the revision records on
the same branch exactly one verdict:

- **revised** — edited to match the changed decision, evidenced by a
  commit touching it;
- **deferred** — a plan set to `deferred` with a reason naming the
  revision (ADR 0004's existing escape, kept);
- **checked and still correct** — examined and found unaffected,
  recorded explicitly.

This generalises ADR 0004's "revised or deferred" from ADR → plan to
the whole transitive graph, and adds the explicit *checked and still
correct* verdict so an unaffected artefact is **recorded as checked**,
not silently skipped — the hand-found ripple seed #92 names. The gate
checks that a verdict is present, not that its claim is true; a
verdict is the reviser's assertion.

### A missing verdict is visible, and the gate is `land`

A verdict is missing when the `downstream:` list contains an artefact
with no verdict on the branch. The gate refuses to land such a branch
and names each artefact still without a verdict.

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
Verdicts are recorded on the branch in a form `land` can check without
judgement; the exact syntax is left to the plan.

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
- **Keep ADR 0004's "revised or deferred" with no *checked and still
  correct* verdict.** Rejected: an unaffected artefact is then skipped
  with no record, which is the silent gap seed #92 names. The explicit
  verdict is what makes "checked" auditable.
- **Put eval scenarios in the graph now.** Rejected and deferred to
  #119: evals carry no `Derives-From`, and their authoring workflows
  have no revision lifecycle to hang a verdict on.

## Consequences

- This builds on ADR 0004: its ADR → plan "revised or deferred" rule
  becomes the ADR → plan → skill verdict trichotomy here. ADR 0004's
  narrower section now has a more general statement elsewhere, a
  coupling to keep consistent.
- `land` gains a check that consumes the history skill's `downstream`
  query, coupling the gate to that script; a repository without it
  cannot run the gate.
- A *checked and still correct* verdict is a claim nothing re-derives.
  The gate enforces that a verdict exists, not that it is right; the
  ADR 0008 reviewer's fidelity check is the complementary judgement.
- The verdict-recording syntax is left to the plan. If it is a trailer,
  it extends ADR 0004's trailer table, which that ADR leaves open to
  extension by revision.
- Evals stay outside the revision graph until #119; a revision that
  should change an eval leaves no verdict and no gate catches it.

## References

- `docs/adr/0004-where-does-history-live.md` — the ADR → plan
  "revised or deferred" obligation this ADR generalises to the
  transitive graph; the trailer graph a verdict may extend; the
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
- Seed #92 — the gap this answers. Seed #119 — the test-production
  process that owns evals.
