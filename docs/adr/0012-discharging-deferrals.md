---
title: How is a deferral discharged once its condition is met?
date: 2026-10-28
---

# How is a deferral discharged once its condition is met?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

ADR 0011 defined the `deferred` verdict (`Defers: <D> <condition>`): a
revision may defer reconciling a durable downstream `D`, blocked on
named other work, typically "until the revision of ADR `Y` lands."
0011 explicitly handed off what happens once that condition is met to
seed #126. #126 was later decomposed, scoping this ADR to the
discharge mechanism alone: what `land` does once a deferral's blocker
has landed.

The driving concern is alignment: the repository is the context
models consume, so it must read as current intent. The corrosive event
is not a deferral existing — `Defers:` already records that honestly —
it is a deferral going **silent**: its blocker lands, and nothing
ever revisits `D`. Myelin has no per-path ownership, so whoever lands
the blocker is able to edit `D`; this ADR assigns the discharge
obligation to them, not to `D`'s original author.

A query over **outstanding obligations** (deferrals with no later
discharging verdict) is a different thing from ADR 0010's deferred
"detecting open" question, which is about a human's on-the-fly query
over the graph. Extending the history skill with the former is a
plain surface addition to 0010, not an un-deferral of the latter.

## Decision

### Outstanding and due

A deferral `Defers: <D> <condition>` is **outstanding** while no later
verdict (`Reconciles:`/`Confirms:`/`Defers:`) targets the same `D`. An
outstanding deferral becomes **due** the moment its named condition is
satisfied — the blocking work has landed on trunk.

### Persistent visibility, scoped hard-stop

Every due deferral is surfaced at every `land`, on every branch, until
it is resolved — a slip is never one-shot and self-heals on the next
`land` anywhere in the repository.

Landing **blocks** on a due deferral only on the one branch whose
landing is what satisfies that deferral's condition (the branch
carrying, in the motivating case, `Revises: <Y>`). That branch *is*
the promised work coming due, so it is where reconciliation is forced.
Every other branch gets visibility only: the due deferral is reported,
nothing it does gates on it.

### The escape

On the blocking branch, the lander must resolve each due deferral
before it lands, by recording one verdict against `D`, on that same
branch:

- **`Reconciles: D`** — `D` is revised to match the now-current
  decision; or
- **`Confirms: D`** — examined and still correct; or
- **`Defers: D <fresh condition>`** — re-deferred, only when the new
  condition (a) differs from the one just satisfied and (b) is itself
  evaluable as currently unmet. A re-defer that re-cites the
  just-satisfied condition is not a valid escape.

This reuses ADR 0011's verdict vocabulary and trailer keys (ADR 0004)
without adding new ones: discharging a deferral is recorded the same
way reconciling any other downstream is, just on a different branch —
the blocker's, not the original deferring revision's.

### Scope of the check

The check this ADR adds is a lookup by *blocker*, not by *downstream of
the ADR being revised*: it asks which outstanding deferrals name, as
their blocking condition, the artefact a branch is about to land —
the reverse of ADR 0011's existing "what is downstream of the revised
ADR" gate. Both checks run at `land`, and both must pass; neither
subsumes the other.

### Prerequisites, and their order

This mechanism needs two things that do not yet exist, and is decided
now but cannot run until both land:

- **A graph-expressible condition form** — "satisfied" and "unmet"
  must be mechanically evaluable against trunk, which needs a
  `Revises: 0011` slice tightening how a blocking condition is stated.
- **An outstanding-deferrals query** — enumerate outstanding deferrals
  and evaluate each condition against trunk, which needs a
  `Revises: 0010` slice adding it to the history skill, consumed by
  `land` rather than re-derived.

Neither prerequisite depends on this ADR: the dependency is a build
order, not a cycle.

## Alternatives considered

- **Warn-only, everywhere, with no hard-stop.** Rejected: it would
  never force reconciliation, leaving a due deferral exactly as
  silent-able as an undischarged one is today.
- **An unconditional or global hard-stop**, blocking any `land` while
  any due deferral exists anywhere. Rejected: it halts work that has
  nothing to do with the deferral, which is the opposite of what a
  deferral exists to permit.
- **Attaching the discharge obligation to `D`'s "owner."** Retracted:
  Myelin has no per-path ownership, so there is no such party distinct
  from whoever happens to land the blocker.
- **Allowing a re-defer that re-cites the same, now-satisfied
  condition.** Disallowed: that would make `deferred` a permanent
  escape rather than a bounded one.

## Consequences

- Decided now, shippable only once both prerequisites land. Until
  then, outstanding deferrals exist but nothing checks whether they
  are due.
- `land`'s due-deferral check is not scoped to one branch's own
  revision the way ADR 0011's verdict-completeness gate is: it must
  consult outstanding deferrals across the whole graph, every time it
  runs. That is a wider check than `land` has needed before.
- Because there is no per-path ownership, the obligation to discharge
  `D` falls on whoever lands `D`'s blocker, who may be unconnected to
  `D` or to the revision that deferred it. The re-defer escape is what
  keeps that cost bounded rather than open-ended.
- Tightening the condition form itself (making "until `Y` lands"
  mechanically checkable) is a separate `Revises: 0011` slice, not
  part of this decision.
- Eval scenarios remain outside the revision graph per ADR 0011; a
  discharge that should touch an eval leaves no verdict and nothing
  here catches it.

## References

- `docs/adr/0011-revision-process.md` — defines the `deferred` verdict
  and the `Reconciles:`/`Confirms:`/`Defers:` vocabulary this ADR
  reuses for discharge; hands off discharge itself to this ADR; fixes
  the gate at `land`, not `begin`, which this ADR follows.
- `docs/adr/0004-where-does-history-live.md` — the exhaustive trailer
  table carrying the verdict keys, and the append-only graph convention
  that lets a later commit, on a different branch, discharge an
  earlier one's deferral.
- `docs/adr/0010-history-retrieval.md` — the history skill this ADR's
  outstanding-deferrals query extends; its deferred "detecting open"
  scope is a different question (human open-ended queries), not the
  outstanding-obligations query this ADR needs.
- `docs/adr/0003-git-workflow.md` — `land` as the enforcement point
  already doing decision-branch work, which this ADR adds to.
- Seed #126 — the gap this ADR answers.
