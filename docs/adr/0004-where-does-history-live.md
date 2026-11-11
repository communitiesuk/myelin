---
title: Where does history live?
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

An artefact in the tree that is revisited is edited, not replaced. The
superseded text is in the history of the file, reachable with
`git log --follow -p`. The `adr` skill's rules against editing a
merged ADR and against deleting superseded ADRs are withdrawn, and the
`supersedes`, `superseded_by` and `superseded` status vocabulary is
withdrawn with them. An ADR carries no status: one not yet on the
trunk is proposed, on its own branch (the branch that adds it); on the
trunk it is accepted, and stays accepted while a revision of it is in
flight (ADR 0009).

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
  stays, because deferred work is still intended; a plan may be
  deferred only when its reconciliation is blocked on specific named
  other work (such as another revision landing), never open-ended. The
  `Defers:` verdict generalises this beyond the plan lifecycle: it
  marks any durable downstream (skill, code, or plan) as deferred
  pending reconciliation — for a plan it keeps the plan in the tree, as
  above; for a skill or code it is a staleness marker, those never
  leaving the tree on completion.
- A **discovery note** leaves when the ADR or ADRs it informed are
  accepted. A note that informs none is decided against, and leaves by
  a deleting commit carrying `Abandons`, whose body says why.
- **Source material** — any file brought in from outside the
  repository's workflow as input to discovery, imported or not — lives
  in `docs/discovery/sources/`, whose path marks it as consumable
  input and keeps it out of note numbering. A discovery note records
  what is drawn from it. It leaves on the branch of the last note
  drawing on it, by a later commit carrying `Consumed-By` naming each
  note it informed. Source material that informed no note leaves
  with `Abandons` instead.
- An **ADR** stays for as long as its decision stands. ADRs are the
  current intention; they are consumed continuously, not once.

### History is written for retrieval

The artefacts in the tree form a graph: a plan derives from an ADR, an
ADR from a discovery note, a code change or a skill from a plan. Its
roots have no upstream in the repository: for example a bootstrap,
source material, or a discovery note from a conversation with nothing
in the repository to derive from. Because the tree no longer keeps
artefacts that have left it, that graph is recorded in git history, as
trailers on commits. Trailers are the machine-readable half of a
commit message: git parses them natively (`git interpret-trailers`,
`git log --format='%(trailers:key=...)'`) and they are searchable with
`git log --grep`.

**The graph is append-only.** An edge between two artefacts is added
by exactly one commit, and that commit carries the trailer for it.
Edges are never modified; a relationship that changes is a new edge,
added by the commit that changes it. An edge may be circular — from an
artefact back to itself — as both `Revises` and `Clarifies` are. The
table below is therefore exhaustive: it lists every kind of edge and
the event that adds it, and `Origin`, the one trailer recording a
root's provenance rather than an edge. An event not in the table adds
no edge, and nor does a change that genuinely leaves an artefact's
edges as they were, such as drafting on an ADR's own branch before it
merges.

The vocabulary:

| Trailer | On the commit that | Value |
| --- | --- | --- |
| `Derives-From:` | establishes that an artefact derives from another: the first commit on the artefact's branch, or a later commit that re-points it | path of the upstream artefact; one trailer per direct upstream |
| `Revises:` | changes what an accepted ADR decides | path of the ADR |
| `Origin:` | adds a root: the first commit, other than a decision's, that adds an artefact with no upstream in the repository | its provenance: in words, such as the conversation or seed a note came from, or as a pinned `<owner>/<repo>@<rev>[:<path>]` |
| `Clarifies:` | edits in place an artefact already in the tree: for a discovery note or source material any edit; for any other artefact an edit changing no decision and no behaviour (typo, citation, metadata, or an uncaught cross-reference); a self-edge, as `Revises` is on an in-place revision | path of the artefact edited |
| `Consumed-By:` | removes a consumed artefact: a discovery note, or source material | path of what it informed; one trailer per artefact informed |
| `Completes:` | removes a plan whose work is done | path of the plan |
| `Abandons:` | removes an artefact decided against: a plan whose work will not be done, a discovery note that informs no ADR, or source material that informed no note | path of the artefact |
| `Reconciles:` | revises a durable downstream to match the changed decision | path of that downstream |
| `Confirms:` | examines a durable downstream and finds it still correct | path of that downstream |
| `Defers:` | defers reconciling a durable downstream artefact, blocked on named other work | path of that downstream artefact; carries its named blocking condition |

Values are repository-relative paths, except `Origin`'s and the
blocking condition `Defers` carries. A commit may carry several
trailers, and a key may repeat. `Derives-From` names direct upstreams
only: a skill produced by a plan step names the plan, not the ADR
behind it, which is one hop away through the plan's own `adr:` field.
It is also the one trailer that cannot self-reference — an artefact
does not derive from itself. `Revises` is for changes to the decision;
an edit made on the ADR's own branch before it merges is still
drafting and carries no trailer. An in-place edit that changes no
decision and no behaviour carries `Clarifies` instead: a self-edge,
the same shape `Revises` takes on an in-place revision. That is a typo
fix, a citation repair, a metadata change, or a cross-reference update
not caught when the referencing artefact was created; for a discovery
note or source material, which decide nothing, it is any edit. For an
ADR, the two differ only in what they record — `Revises` for a change
to the decision, `Clarifies` for a change to its expression. A
revising edit carries `Revises`; only a non-revising edit carries
`Clarifies`, and `land` sends it direct to trunk, with no human pull
request. A substantive change to a skill or code derives from a plan;
a substantive change to a plan carries `Reconciles:`, the verdict on a
revised ADR's downstream, found through the `Derives-From` graph the
history skill retrieves (ADR 0011).

`Origin` exists because, without it, `land` refuses a first commit
with no upstream in the repository, and such a root's provenance lives
at best in a prose header (#182). It marks a commit, not a kind of
file. It records where a root came from; the file itself is still
copied in. A root is where traversal stops. It is not the origin of a
`Defers` condition (ADRs 0010, 0011), the artefact in the repository a
deferral is blocked on. Source material enters on its own branch,
whose first commit carries `Origin:` and adds only that material; a
note drawing on it derives from it on the note's own branch. Of what a
root commit adds, only source material leaves the tree; bootstrap
files such as `tessl.json`, `.claude/` and `AGENTS.md` never do.

The three verdict trailers are the cross-edge counterpart to those
self-edges: `Revises` and `Clarifies` link an artefact to itself,
whereas a verdict links the revised ADR to a *different* durable
downstream named in its value. Introducing them extends this
exhaustive vocabulary, which is why their keys are defined here;
reading those keys and enforcing the verdicts — the gate's parsing —
belong to ADR 0011's plan.

Trailers record edges between artefacts, and `Origin` a root's
provenance. Structure inside an artefact, such as the order of
docstring, test and code commits under `test-first-workflow`, belongs
to the governing skill under ADR 0003's delegation of commit cadence,
and carries no trailer.

`land` accepts a first commit carrying `Abandons` naming a path that
existed at the fork point, as it does `Clarifies`, so a branch that
only abandons an artefact lands without riding on another.

The prose body of a `Revises`, `Clarifies`, `Abandons` or deleting commit
must say what changed and why, in sentences. Trailers carry the edge;
the body carries the reason. Neither is optional.

While an artefact is in the tree, its frontmatter names what it
derives from, as plans already do with `adr:`. Once it leaves, the
trailer on the removing commit names what it produced. A root's
introducing commit names where it came from. Between these, and the
identifier shared by the branch names ADR 0003 mandates, the
artefact graph is recoverable from history alone, without an index.

ADR 0003's no-fast-forward merge brackets the commits that belong to
one artefact, and its prohibition on squash merging now protects
this too: a squash discards the individual commits, and their
trailers with them.

### Revising an ADR accounts for what is downstream of it

When an ADR is revised, every durable downstream artefact in the tree
must be accounted for. The full obligation to reconcile what the
revision changes under it, and the verdicts that discharge it, lives in
ADR 0011 as that obligation's single owner; the scope is stated here,
the rule is not restated.

### The bookkeeping exception is adopted as a revision to ADR 0003

The decision proposed at tag `rejected/adr-0004-bookkeeping` stands
on its merits: a change with no independent truth condition is
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
- **A `status` field of `proposed` or `accepted`.** The original form
  of this decision, reversed by ADR 0009. Nothing set the field at
  merge, so ADR 0008 landed accepted while saying `proposed`; an ADR's
  place in git already says which it is.
- **Prose-only commit messages, no trailers.** Rejected: the
  relationships would have to be inferred from sentences, which is
  the kind of judgement the history skill exists to remove.
- **Design the history skill in this ADR.** Rejected: by the
  question test it is a different question, and its shape has open
  problems that need their own discovery. See
  `docs/discovery/0001-history-skill.md`.
- **A non-revising ADR edit carries no trailer.** This ADR's original
  position. Reversed: `land` refuses a standalone branch carrying
  neither `Derives-From` nor a decision trailer, so an untrailered
  edit could not land without a human-mediated merge — friction for a
  typo fix. `Clarifies` removes that friction: such an edit now adds
  an edge, a self-edge, instead of none.
- **An open-ended `deferred` escape.** This ADR's original form let a
  plan be deferred with any reason naming the revision. Narrowed: a
  deferral must name the specific other work its reconciliation is
  blocked on, so a landed decision cannot be left unreconciled
  indefinitely.
- **`Clarifies` for ADRs only.** This ADR's previous form: other
  artefacts left the tree rather than being edited. Reversed: a landed
  discovery note could not be revised, because `land` demanded a
  `Derives-From` whose every value was a duplicate, cyclic or false
  edge (#184).
- **Every artefact has an upstream in the repository.** This ADR's
  previous form. Reversed: a bootstrap, an artefact imported from
  another repository, or a file written outside any project has none,
  so `land` refused it and its provenance lived at best in prose (#182).
- **A discovery note informs one ADR.** This ADR's previous form, with
  `Consumed-By` naming that ADR. Reversed: material may inform several
  ADRs or none.
- **An `Amends:` trailer for in-place edits to non-ADR artefacts.**
  Rejected: a second self-edge key, where widening one row serves.
- **Let `land` infer the case, with no trailer** — exempting a diff
  that only edits existing files under `docs/discovery/`, a diff that
  only deletes them, or a first commit that only adds new ones.
  Rejected: the edge, or the root's provenance, would go unrecorded,
  and the exemption is a special case.
- **An external `Derives-From` for a root.** Rejected: a loose local
  file has no `<owner>/<repo>@<rev>` to name. An external reference
  survives as one form of `Origin:` value.
- **Source material alongside the notes in `docs/discovery/`.** Not
  chosen; it lives in `docs/discovery/sources/`.
- **A discovery note abandoned by a trailerless deletion.** This ADR's
  previous form. Reversed: `land` refused a branch that only deleted
  the note, so the deletion had to ride on another branch (#191); and
  with no edge, history could not tell a decision from a mistaken
  deletion.
- **Widen `Clarifies` to cover deletions.** Rejected: it would land,
  but leave no edge saying "decided against".
- **Infer abandonment from a deletion with no `Consumed-By`.**
  Rejected: a mistaken deletion would read as a decision, and `land`
  would still refuse the standalone branch.
- **Mark a note `status: abandoned` by a `Clarifies` edit before
  deleting it.** Not chosen: it restores a status this ADR removed and
  splits abandonment into two steps.
- **Every file an `Origin:` commit adds is consumable.** Rejected:
  bootstrap files must never leave the tree.

## Consequences

- The `adr` skill changes: question-shaped titles, the edit-or-new
  test, the withdrawal of the immutability and no-delete rules, a
  smaller frontmatter schema, and the `Revises` commit rule.
- The `plans` skill changes: `done` and `abandoned` become removal
  with `Completes` and `Abandons`, the no-delete and no-archive rules
  are withdrawn, and the introducing commit carries `Derives-From`.
- The `facilitated-discovery` skill changes: a discovery note leaves
  the tree when the ADR or ADRs it informed are accepted, with
  `Consumed-By`, or when abandoned, with `Abandons`; a landed note is
  revised in place. Its entry
  points, which assume a conversation with a human present, are left
  to the implementing plan.
- The git-workflow skill that plan 0003 specifies must carry the
  trailer vocabulary, route a `Clarifies` branch to trunk, and accept an
  `Abandons` first commit, neither requiring `Derives-From`, since it is
  the skill that lands commits.
  It also lands a root carrying `Origin:`, where the history skill
  stops traversal. Plan 0003 is revised accordingly under ADR
  0011.
- An artefact imported from now on records its provenance in
  `Origin:`, not in a prose header such as "Imported from myelin…".
  Earlier imports are not rewritten.
- ADR 0003 is revised in place for the first time: the bookkeeping
  exception is folded in, and its claim that the `adr` skill's
  prohibition on editing a merged ADR "becomes meaningful" is
  removed, since that prohibition is withdrawn. Its land rule carries
  the exceptions: a decision, `Clarifies` or `Abandons` naming a path
  that existed at the fork point, or `Origin:`.
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
- An in-place edit that changes no decision and no behaviour carries
  `Clarifies`, a self-edge needing no `Derives-From`, on any artefact
  in the tree, as does any edit to a discovery note or source
  material. Ride-along on the causing artefact's branch stays and
  is preferred when a cross-reference is caught at creation time;
  `Clarifies` is for edits made standalone, after the fact.
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
- Tag `rejected/adr-0004-bookkeeping` — the refining ADR whose cost
  prompted this decision, and whose content is adopted as a revision
  to ADR 0003. An annotated tag rather than a branch: the commit
  stays reachable without appearing as work in flight, and the tag
  object carries the reason the path was closed.
- `docs/discovery/0001-history-skill.md` — open questions for the
  history skill.
- `docs/adr/0006-where-do-captured-ideas-live.md` — the developed
  capture as a discovery note.
- `docs/adr/0010-history-retrieval.md` — the `Defers` condition,
  whose origin a root is not.
- `docs/adr/0011-revision-process.md` — the reconciliation of a
  revised ADR's downstreams, and the verdicts that discharge it.
- Issues #182, #184 and #191 — the root, the revision of a landed
  discovery note, and its abandonment.
- `git-interpret-trailers(1)` — the trailer format and tooling.
- Nygard, "Documenting Architecture Decisions" (2011) — the source of
  the immutability convention this ADR withdraws, written for a
  decision folder browsed by people.
