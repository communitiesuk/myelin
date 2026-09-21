---
title: Where does history live?
status: proposed
date: 2026-09-16
---

# Where does history live?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Myelin's premise is that the repository is the context. Each stage
from discovery through ADR, plan and implementation produces an
artefact that is more explicit than the one before it, so that the
work further to the right needs less judgement and can run on a
cheaper model. That only holds if what the right-hand agent reads is
the current intention and nothing else.

The rules currently written into the plugin work against that.

- The `adr` skill forbids editing a merged ADR to change the
  decision, requires superseding instead, and forbids deleting the
  superseded record.
- The `plans` skill forbids deleting a plan on completion and forbids
  archiving it elsewhere: `plans/` holds the full lifecycle.

Both rules import a convention from the ADR literature, where the
decision folder is browsed by people and git history is not. Here the
consumers are agents reading the working tree. For them every
superseded ADR and every finished plan is text that must be
recognised as stale and set aside, and that recognition is delegated
to the reader trusted least.

The cost showed up as soon as a plan was written against ADR 0003.
The plan could not be executed as written; the gap was in the ADR,
which had partitioned all work into artefacts with no remainder. The
only permitted repair was a new ADR. The proposed
`0004-bookkeeping-not-an-artefact` ran to 221 lines to add one
exception to a decision nobody had yet implemented, and had to invent
two frontmatter fields (`refines`, `refined_by`) that no skill
documents, so that a reader of ADR 0003 would find the exception
without leaving the file. Every future gap found by a plan would cost
the same.

That plans find gaps is not a failure. A plan is the first executable
reading of a decision, and executing is how gaps become visible. The
assumption that does not survive contact is that an accepted ADR is
complete and everything to its right is implementation. Development
is discovering what earlier decisions missed, and revising them.

Two readers need the history of those revisions, and they need
opposite things. A human wants the trajectory: what was tried, what
was reversed, and why. An agent at the codeface wants the current
state and nothing stale beside it. An ADR author, human or agent,
needs to know which paths are closed so as not to rejoin one. None of
this justifies writing anything twice.

Git already holds every version of every file, with a message
attached to each change. The question this ADR answers is whether
that record is the history, or whether the tree must carry a second
copy.

## Decision

Git history is the record. The working tree holds the current
intention and nothing else.

### The working tree holds only what is current

No file in the tree exists to preserve a version of something that is
no longer true. A stale version lives in git history and nowhere
else. This applies to every artefact the plugin produces: discovery
notes, ADRs, plans, skills and code.

### Artefacts are revised in place

When an ADR is revisited, it is edited. The superseded text is in the
history of the file, reachable with `git log --follow -p`. The
`adr` skill's rules against editing a merged ADR and against deleting
superseded ADRs are withdrawn, and the `supersedes`, `superseded_by`
and `superseded` status vocabulary is withdrawn with them. An ADR is
`proposed` or `accepted`.

The test for whether a revision is an edit or a new ADR: **the title
of an ADR is the question it answers.** If the revision still answers
that question, edit in place. If it answers a new question, write a
new ADR, and edit the old one only where the new decision changes it.
Titles are therefore phrased as questions, so that the test can be
applied by reading the title.

A decision that is reversed outright is deleted, not marked. The
commit that deletes it says why.

The Alternatives section of the current ADR keeps its role. Paths
rejected at decision time exist nowhere else, because they were never
committed anywhere. When a revision reverses an adopted path, the
Alternatives section gains an entry summarising the reversal, because
that is what stops the next author retrying it; the full prior text
is in history. The summary in the tree and the record in history are
not duplicates. One is the current reasoning; the other is what the
reasoning replaced.

### Completed and consumed artefacts leave the tree

An artefact whose purpose was to produce the next artefact leaves the
tree when that purpose is served.

- A **plan** leaves when its work is complete or abandoned. The
  `done` and `abandoned` statuses are withdrawn; both are expressed
  by removal, and the removing commit says which. A `deferred` plan
  stays, because deferred work is still intended.
- A **discovery note** leaves when the ADR it informed is accepted.
- An **ADR** stays for as long as its decision stands. ADRs are the
  current intention; they are consumed continuously, not once.

### History is written for retrieval

The artefacts in the tree form a graph: a plan derives from an ADR,
an ADR from a discovery note, a code change or a skill from a plan.
Because the tree no longer keeps artefacts that have left it, that
graph is recorded in git history, as trailers on commits. Trailers
are the machine-readable half of a commit message: git parses them
natively (`git interpret-trailers`,
`git log --format='%(trailers:key=...)'`) and they are searchable
with `git log --grep`.

**The graph is append-only.** An edge between two artefacts is added
by exactly one commit, and that commit carries the trailer for it.
Edges are never modified; a relationship that changes is a new edge,
added by the commit that changes it. The table below is therefore
exhaustive: it lists every kind of edge and the event that adds it.
An event not in the table adds no edge, and a change to an artefact's
content that leaves its edges as they were carries no trailer for
them.

The vocabulary:

| Trailer | On the commit that | Value |
| --- | --- | --- |
| `Derives-From:` | establishes that an artefact derives from another: the first commit on the artefact's branch, or a later commit that re-points it | path of the upstream artefact; one trailer per direct upstream |
| `Revises:` | changes what an accepted ADR decides | path of the ADR |
| `Consumed-By:` | removes a discovery note | path of the ADR it informed |
| `Completes:` | removes a plan whose work is done | path of the plan |
| `Abandons:` | removes a plan whose work will not be done | path of the plan |

Values are repository-relative paths. A commit may carry several
trailers, and a key may repeat. `Derives-From` names direct
upstreams only: a skill produced by a plan step names the plan, not
the ADR behind it, which is one hop away through the plan's own
`adr:` field. `Revises` is for changes to the decision; a typo fix
does not carry it, and nor does an edit to a `proposed` ADR, which is
still being drafted.

Trailers record edges between artefacts. Structure inside an
artefact, such as the order of docstring, test and code commits
under `test-first-workflow`, belongs to the governing skill under
ADR 0003's delegation of commit cadence, and carries no trailer.

The prose body of a `Revises`, `Abandons` or deleting commit must say
what changed and why, in sentences. Trailers carry the edge; the body
carries the reason. Neither is optional.

While an artefact is in the tree, its frontmatter names what it
derives from, as plans already do with `adr:`. Once it leaves, the
trailer on the removing commit names what it produced. Between the
two, and the identifier shared by the branch names ADR 0003 mandates,
the artefact graph is recoverable from history alone, without an
index.

ADR 0003's no-fast-forward merge brackets the commits that belong to
one artefact, and its prohibition on squash merging now protects
this too: a squash discards the individual commits, and their
trailers with them.

### Revising an ADR revises its plans

An ADR is not frozen at merge. It is frozen only with respect to work
in flight against it. When an ADR is revised, every plan in the tree
whose `adr:` field names it is, on the same branch, either revised to
match or set to `deferred` with a reason naming the revision. No plan
targets a decision that has changed under it.

### The bookkeeping exception is adopted as a revision to ADR 0003

The decision proposed on branch `adr-0004-bookkeeping-not-an-artefact`
stands on its merits: a change with no independent truth condition is
bookkeeping, needs no branch of its own, and rides with the change
that makes it true. It is adopted, and recorded by revising ADR 0003
in place. The `refines` and `refined_by` fields it proposed are not
adopted; the relation they expressed is what `Revises` records.

### A history skill will exist

Removing stale text from the tree is acceptable only because it stays
retrievable. A skill will answer questions about history from git,
for two consumers:

- The `adr` skill, before an ADR is written: for this topic, which
  paths are closed, with the reason and source of each. Closed paths
  come from two places, the Alternatives sections of current ADRs
  and the `Revises` history, and the skill reads both.
- A human, on demand: open questions about why and when something
  changed.

This ADR commits to the skill existing and to the conventions above
being what it reads. How it works, whether one skill serves both
consumers, and whether it is a skill or a script, is a different
question and is deferred to a separate ADR. Until it exists,
`git log --follow -p` and `git log --grep` are the retrieval path.

## Alternatives considered

- **Keep ADRs immutable and chain them with `supersedes` and
  `refines`.** The current rule. Rejected: every superseded and
  refined version stays in the agent's read set, and the filtering
  is delegated to the agent. The refining-ADR path cost 221 lines
  for one exception.
- **Keep ADRs immutable and move stale ones to an archive folder.**
  The human can still browse and the tree has one live copy per
  decision. Rejected: it builds a second graph by hand in markdown,
  every revision costs a full rewrite, and the agent still has to be
  told where not to look.
- **Keep ADRs immutable and have agents read only a derived layer**
  (skills and plans compiled from ADRs). Closest to what happens
  today. Rejected: the derived layer restates the ADR, and keeping
  the two in step is the drift already observed between the skills
  and the decisions behind them.
- **Make ADRs complete enough not to need revision.** Rejected:
  plans are the first executable reading of a decision and find gaps
  by executing. No amount of upfront care substitutes for that.
- **Keep done plans in the tree with a status field.** Rejected: no
  consumer at the codeface reads a finished plan, and the history
  skill retrieves it for anyone who does.
- **An index file recording artefact relationships.** Rejected: it
  duplicates what frontmatter and trailers already record, and it
  must be maintained by hand.
- **Prose-only commit messages, no trailers.** Rejected: the
  relationships would have to be inferred from sentences, which is
  the kind of judgement the history skill exists to remove.
- **Design the history skill in this ADR.** Rejected: by the
  question test it is a different question, and its shape has open
  problems that need their own discovery. See
  `docs/discovery/0001-history-skill.md`.

## Consequences

- The `adr` skill changes: question-shaped titles, the edit-or-new
  test, the withdrawal of the immutability and no-delete rules, a
  smaller frontmatter schema, the `Revises` commit rule, and the
  rule that revising an ADR revises its plans.
- The `plans` skill changes: `done` and `abandoned` become removal
  with `Completes` and `Abandons`, the no-delete and no-archive rules
  are withdrawn, and the introducing commit carries `Derives-From`.
- The `facilitated-discovery` skill changes: a discovery note leaves
  the tree when the ADR it informed is accepted, with `Consumed-By`.
- The git-workflow skill that plan 0003 specifies must carry the
  trailer vocabulary, since it is the skill that lands commits.
  Plan 0003 is revised accordingly under the rule above.
- ADR 0003 is revised in place for the first time: the bookkeeping
  exception is folded in, and its claim that the `adr` skill's
  prohibition on editing a merged ADR "becomes meaningful" is
  removed, since that prohibition is withdrawn.
- ADRs 0001 to 0003 lose the `supersedes` and `superseded_by`
  fields. Plans 0001 and 0002, both done, leave the tree.
- The human trajectory is now only as good as commit discipline.
  Every revising and removing commit must carry its trailer and its
  reason, and the agent writing the commit has to be told so. That
  is the job of the git-workflow skill and of the governing skills'
  commit rules, and it is the cost of not writing history twice.
- Agents may edit ADRs casually where before they could not. The
  `Revises` trailer with a mandatory reason, the no-fast-forward
  merge, and human acceptance at merge are what stand in the way.
- The artefact graph is recoverable but not yet cheaply queryable.
  The history skill is a separate ADR and its absence is felt until
  it lands.
- The trailer vocabulary is exhaustive but not closed. A decision
  that adds an artefact kind or a new relation between kinds adds a
  row, by revising this ADR. Splitting tests from code into separate
  artefacts, for example, would add an edge for verification.
- An ADR revised because another ADR was decided has no edge in the
  table. The cause is in the body of the `Revises` commit. Whether
  that needs a trailer is for the history skill's ADR to find out
  from real history.
- The vocabulary allows several direct upstreams, but the plan
  schema allows one ADR. A plan is the implementation of one answer
  to one question, and that stands until a plan genuinely needs
  otherwise. Using a decision is not deriving from it: plan 0003
  uses `skill-forge`, which ADR 0002 decided, and derives from ADR
  0003 alone.
- Until the history skill exists, the `adr` skill carries the
  interim path itself: an author reads every ADR in the tree before
  writing, which the tree-is-current rule makes a bounded task, and
  lists under References each ADR whose decision the new one relies
  on or constrains, saying which. References records what a decision
  uses; `Derives-From` records what an artefact was produced from.
- The "one ADR per decision" principle survives with a sharper
  boundary: one ADR per question.

## References

- `docs/adr/0003-git-workflow.md` — branch per artefact; the
  no-squash rule that now also protects trailers; the naming rule
  that gives related artefacts one identifier.
- `docs/adr/0001-artifact-embedded-skill-directives.md` — the
  plugin's cost gradient from left to right, which this ADR
  protects.
- Branch `adr-0004-bookkeeping-not-an-artefact` — the refining ADR
  whose cost prompted this decision, and whose content is adopted
  as a revision to ADR 0003.
- `docs/discovery/0001-history-skill.md` — open questions for the
  history skill.
- `git-interpret-trailers(1)` — the trailer format and tooling.
- Nygard, "Documenting Architecture Decisions" (2011) — the source of
  the immutability convention this ADR withdraws, written for a
  decision folder browsed by people.
