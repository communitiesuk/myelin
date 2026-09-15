---
title: Bookkeeping is not an artefact
status: proposed
date: 2026-09-15
supersedes: null
superseded_by: null
refines: 0003-git-workflow.md
---

# Bookkeeping is not an artefact

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

This ADR was prompted by `plans/0003-git-workflow.md`. That plan
implements ADR 0003, and an independent review of it against the ADR
found the coverage complete and no unauthorised additions — but found
that the plan could not be executed as written, and that the cause
was not in the plan. The gap was invisible while ADR 0003 was only
being read. It appeared the moment something tried to execute against
it.

ADR 0003 makes the artefact the unit of work, and partitions all work
into artefacts with no remainder:

> Work not governed by any skill is still an artefact and still gets
> its own branch.

That sentence leaves no category for changes that record the state of
work rather than constitute it. Three cases surfaced, all the same
shape:

- **A plan's status field.** `plans/0003-git-workflow.md` flips to
  `status: done` when the work it describes finishes. The `plans`
  skill requires that transition to ride with the change that makes
  it true. ADR 0003 requires every change to belong to an artefact,
  and the plan artefact's own branch was merged long before. Read
  strictly, a one-word frontmatter edit needs a branch and a merge of
  its own — at which point it can no longer ride with anything,
  because it lands as a separate merge at a different time.
- **`.worktrees/` in a target repository's `.gitignore`.** The git
  workflow needs that line present before it creates the first
  worktree in a repository that lacks it. Writing it is a
  modification to a tracked file at the exact moment "branch before
  edit" forbids one, in service of an artefact that is not that line.
- **`weeknotes/` in this repository's `.gitignore`** (commit
  `055f637`) went straight onto `main` with no branch, in the course
  of clearing the tree for other work.

The first two are cases where ADR 0003, applied literally, produces a
rule that is not merely heavy but incoherent. The third is a case
where it was quietly ignored.

## Decision

### The test

A change is **bookkeeping** when it has no independent truth
condition: it is true only because some other work is true.

A plan's `status: done` is not true because it was typed. It is true
because the work it describes finished. Branch for it alone and the
branch records nothing, because nothing happened that the branch could
hold.

A change that would still need to be made had the accompanying work
not happened is **work**, whatever file it touches.

### The rule

Bookkeeping is not an artefact. It does not get its own branch. It
rides with the change that makes it true, on that change's branch.

Bookkeeping that has nothing to ride on is not bookkeeping. If no
accompanying work makes it true, it has an independent truth
condition, and it is work.

### Classification is relational

Whether a change is bookkeeping is a property of the relationship
between the change and the work in hand — never of the file it
touches, and never of a designated section within a file. The same
line in the same file classifies both ways:

| Change | Classification | Why |
| --- | --- | --- |
| Adding `.worktrees/` to this repository's `.gitignore` as a deliverable implementing ADR 0003 | work | Independently true; independently verifiable by `git check-ignore`. It is the point of the change, not a record of another. |
| The git workflow adding `.worktrees/` to a target repository's `.gitignore` while creating a worktree | bookkeeping | Incidental to producing some other artefact. Has no truth of its own. |
| `weeknotes/` in `.gitignore` (`055f637`) | work | Nothing else made it true. It should have had a branch. |

### Scope

This decision governs ADR 0003's branch-per-artefact rule and nothing
else. Bookkeeping is exempt from needing its own branch. It is not
exempt from anything else: it is committed, reviewed and merged like
any other change, and the governing skill's commit cadence continues
to decide what a commit holds.

### The escape hatch is closed by the test

"It is only bookkeeping" would otherwise justify editing trunk
directly for anything inconvenient to branch. The truth-condition test
is what forecloses that, and it is part of this decision rather than
its rationale. Applying it requires asking what makes the change true,
which is answerable without judgement about effort or convenience.

### Recording the relation to ADR 0003

This ADR refines ADR 0003 and supersedes nothing. The ADR frontmatter
gains two fields to express that, mirror images of the pair that
already exist:

- `refines`: null, or the filename of the ADR this one narrows or
  adds to without replacing. Set here.
- `refined_by`: null, or the filename of an ADR that refines this
  one. Set on the refined ADR in the same commit that introduces the
  refining one.

The backlink is written into the refined ADR itself, not into an
index or a sibling file. An agent implementing against ADR 0003 must
find this ADR without leaving that file, or it will implement the
unqualified rule with full confidence. That is the principle ADR
0001 already applies to directives — the pointer lives in the
artefact so it is present every time the artefact is opened — and
it is priced at the point of consumption, where the lighter model
sits, not at the point of authoring.

Adding `refined_by` to an accepted, merged ADR changes none of its
decisions. Under the test above it is bookkeeping: it is true only
because the refining ADR exists, and it rides with that ADR's commit.

The provenance recorded in Context — which plan and which review
prompted this decision — is deliberately prose and not a field. It is
read by people and by future discovery, not by implementers, so it
carries no consumer cost and needs no structure.

## Alternatives considered

- **Enumerate which files or sections are bookkeeping** — for example,
  frontmatter is bookkeeping and body is work. Rejected: `.gitignore`
  has no sections, and the same line in it classifies both ways
  depending on why it is being written. A file-based or section-based
  rule gives the wrong answer in the case that prompted this ADR.
- **Treat all work governed by no skill as bookkeeping.** Rejected:
  far too broad, and it reverses ADR 0003's deliberate decision that
  ungoverned work is still an artefact. It would exempt most one-off
  changes from branching altogether.
- **Leave it to each plan to judge case by case.** Rejected: a plan
  may only implement what was decided. A plan introducing this
  category would be a new architectural commitment smuggled in as
  detail, and the resulting skill would carry a rule with no ADR
  behind it.
- **Supersede ADR 0003.** Rejected: everything 0003 decides still
  stands. This adds a category it lacks; it reverses nothing.
- **Amend ADR 0003 in place.** Rejected: it is accepted and merged,
  and the `adr` skill forbids amending a merged ADR to record a new
  decision. A backlink is not an amendment of that kind.
- **Require bookkeeping to be a separate commit on the accompanying
  branch.** Rejected as out of scope: commit cadence belongs to the
  governing skill under ADR 0003, and this ADR should not take back a
  delegation 0003 made deliberately.
- **An ADR index listing relations between ADRs.** Needs no schema
  change and is bidirectional without editing any ADR. Rejected
  because it is consumed on the right: an implementer opening ADR
  0003 would have to know the index exists, read it, notice the
  entry, and fetch this ADR. Each is a step a lighter model silently
  omits, and the failure is an unqualified rule implemented with
  confidence. Structure in the file reduces inference; an index adds
  a hop.
- **Prose-only linkage, no fields.** Rejected for the forward
  direction for the same reason: a sentence under References must be
  noticed and interpreted, a field is literal. Retained for
  provenance, which no implementer consumes.

## Consequences

- "Branch before edit" acquires an explicit exception, which weakens
  it. The truth-condition test is the whole of what bounds that
  exception, so the test must appear in the skill body as a rule,
  not as commentary.
- The `plans` skill's requirement that status transitions ride with
  the changes that justify them stops contradicting ADR 0003 and
  becomes derivable from it.
- The artefact-type vocabulary shrinks. A token for work governed by
  no skill now covers less than it would have, because bookkeeping
  has been removed from that category rather than given a token of
  its own.
- The git workflow may write `.worktrees/` into a target repository's
  `.gitignore` when creating the first worktree there, without
  violating its own first rule.
- Classification must be performed per change rather than looked up.
  This is a judgement the workflow did not previously require,
  mitigated by the test being a single question with a factual
  answer.
- The `adr` skill's frontmatter schema must document `refines` and
  `refined_by`, and the rule that the backlink rides with the
  refining ADR's commit. Until it does, the fields exist in two ADRs
  and nowhere else.
- Refinements can chain. An implementer of an ADR refined three times
  walks three hops. `supersedes` already exists for consolidating a
  chain that has grown long enough to hurt, and remains the answer.
- An eval scenario should cover a bookkeeping change, or the rule is
  asserted in the skill body and tested nowhere.

## References

- `docs/adr/0003-git-workflow.md` — *refined by this ADR.* The
  branch-per-artefact decision; its total partition of work into
  artefacts is the gap addressed here.
- `docs/adr/0001-artifact-embedded-skill-directives.md` — the
  pointer-lives-in-the-artefact principle that the `refined_by`
  backlink applies.
- `plans/0003-git-workflow.md` — *prompted this ADR.* The plan whose
  review surfaced the gap.
- `skills/adr/SKILL.md` — one ADR per decision; merged ADRs are
  superseded, not amended; frontmatter schema this ADR extends.
- `skills/plans/SKILL.md` — status transitions ride with the changes
  that justify them.
- Commit `055f637` — `weeknotes/` on `main` without a branch, the
  calibration case for the test.
