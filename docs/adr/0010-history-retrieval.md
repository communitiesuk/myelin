---
title: What does the history skill retrieve, and how is it built?
date: 2026-10-27
---

# What does the history skill retrieve, and how is it built?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

ADR 0004 moved superseded and completed content out of the working
tree and committed to a history skill that makes it retrievable again,
but deferred the skill's own design. Two consumers now press on that
gap. ADR 0008 names the skill as the ADR reviewer's first real need —
today the reviewer reads `docs/adr/` and `git log` directly. The
revision process (seed #92), the next skill planned after this one,
needs the same graph traversal to find what a revised ADR's plans and
code must follow.

A read-only prototype against this repository's real history (nine
ADRs with `Derives-From`/`Revises`/`Clarifies`/`Completes` trailers and
`## Alternatives considered` sections — see
`docs/discovery/0001-history-skill.md`, 2026-10-27 entry) established
how the skill is built. The constraint, from that note and from ADR
0008's own growth problem, is that v1 need only be **just good
enough** to support the on-ramp to a single-turn orchestration
harness.

## Decision

### Scope: two deterministic queries and a recall-biased prune

v1 answers two questions, both reading git directly:

- **Closed paths.** For a topic, which paths are closed, with the
  reason and source of each. The reviewer's need from ADR 0008.
- **Downstream/graph.** What derives from or revises a given artefact.
  The revision process's need.

A **recall-biased title/keyword prune** scopes the topic input (an
artefact path, a keyword, or a candidate ADR title) against existing
titles and `## Alternatives considered` bullets before anything is
read in full. Human open-ended queries and detecting "open" (the
absence of a decision) are out of scope for v1.

### How it is built: a script, plus one bounded model step

A deterministic retrieval script does the traversal; no step of it
needs a model except deciding, for the closed-paths query, which
pruned candidates are on the topic. That step is narrow because each
candidate's Alternatives bullet is a pre-written summary, not source
text to interpret.

- **The downstream/graph query needs no model**, and resolves edges
  from trailer fields, never commit-message prose.
- **Graph identity must survive artefact-number reuse**: a number is
  not a stable key. The plan settles the keying mechanism.
- **The downstream query is transitive**: ADR → plan → code is a
  closure, not a single lookup, matching what the revision process
  needs.
- **The two closed-path sources overlap and must be deduped**, not
  treated as disjoint. The plan settles the dedupe mechanism.

### What is deferred

Tuning or validating the prune at scale, human open-ended queries, and
detecting "open" are deferred. No scaling index is built now: the
prune is an additive, cheap mechanism, and whether it holds at a
larger ADR count is an empirical question this v1 does not answer.

## Alternatives considered

- **A conversational skill, judged turn by turn.** Rejected on
  prototype evidence: both queries are deterministic traversals over
  trailers and in-tree sections, and only topic-relevance needs a
  model. Building the skill as a script with one bounded model step
  keeps the judgement to that single narrow place, and gives eval
  criteria and other skills a script they can call directly rather
  than a conversation they must hold.
- **Treating the two closed-path sources as disjoint**, which is what
  discovery note 0001 and ADR 0004 both assumed. The prototype
  disproved it: current ADRs already restate most reversed paths in
  their Alternatives sections. That assumption does not survive
  contact with real history, so the skill dedupes instead, preferring
  the in-tree entry.
- **A pure subject-string grep for the downstream query.** Rejected:
  it picks up ADR 0008's review-record commits, which name an
  artefact's path in their subject line but carry no graph trailer.
  The query must filter on the trailer field.
- **Keying the graph on the artefact number.** Rejected: number reuse
  is real in this repository's own history (`plans/0004-releases.md`
  and `plans/0004-where-does-history-live.md`), so a number is not a
  stable key. The full path is.
- **Building a scaling index now.** Not chosen. ADR 0004 already
  rejected a hand-maintained index file as duplicating what trailers
  record; that rejection still holds. The cheap, additive recall-biased
  prune is what v1 adds instead, and tuning it at a larger ADR count
  is deferred rather than solved speculatively now.

## Consequences

- The `adr` skill's reviewer gains the closed-paths query it has
  lacked since ADR 0008, and can stop reading `docs/adr/` and `git
  log` directly for that purpose once the skill is implemented.
- The revision process (#92) can build its "what must change
  downstream" step directly on the downstream/graph query rather than
  re-deriving graph traversal itself.
- Because the prune is recall-biased, it costs false positives (an
  irrelevant ADR read and discarded) rather than false negatives (a
  closed path silently missed, which would reopen a settled decision).
- Left open and deferred: tuning the prune's recall at a larger ADR
  count, human open-ended queries, detecting "open", and the "one
  skill or two" question discovery note 0001 raised. Only the
  script-level shape (one script, two modes) is decided here; whether
  a human-facing skill wraps the queries separately remains deferred.
- The topic-input contract (path, keyword, or title, pruned the same
  way) is settled by this ADR; the eval fixture and the skill's
  name/trigger contract are left to `adr` and `skill-forge` to produce
  when the skill is built.

## References

- `docs/adr/0004-where-does-history-live.md` — commits to the skill
  existing and to the trailer vocabulary and Alternatives convention
  it reads; the rejection of a hand-maintained index, which this ADR
  leaves standing.
- `docs/adr/0008-stage-reviews.md` — names the skill as the ADR
  reviewer's first real need, and the interim path (reading
  `docs/adr/` and `git log` directly) this ADR's implementation
  retires.
- `docs/discovery/0001-history-skill.md` — the upstream discovery
  note, including the 2026-10-27 prototype-findings entry this
  decision is built from.
- Issue #92, the revision process — the next skill planned, which
  shares this ADR's graph substrate.
