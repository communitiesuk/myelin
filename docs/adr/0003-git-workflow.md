---
title: Where does work happen, and how does it land?
status: accepted
date: 2026-09-04
---

# Where does work happen, and how does it land?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Myelin's skills currently govern what work produces, but nothing
governs where that work happens or how it lands. The consequence is
visible in the plugin's own history.

Commit `1e7d948` ("Execute plan 0002: skill-forge") landed ADR 0002,
plan 0002, the eval scenario and the skill body as a single commit on
`main`, while `plans/0002-skill-forge.md` records that the work was
executed on branch `adr-0002-skill-forge`. The granular commits
existed on the branch and were squashed away on the way in. Two rules
already written into the plugin depend on that not happening:

- `test-first-workflow` mandates a red test commit and a separate
  green code commit, on the stated grounds that this "makes the
  contract auditable in git history". A squash merge removes exactly
  that evidence from the base branch.
- The `adr` skill's prohibition on editing a *merged* ADR was the
  second reason when this was written; ADR 0004 withdraws that rule,
  and it no longer bears on this decision.

Both rules were written for right-hand implementation work and are
not being applied to left-hand decision work. Decision artefacts —
discovery notes, ADRs, plans — are version-controlled output like any
other, but they are produced before there is a plan to hang a branch
off, and in practice the branch gets cut after the files have already
been written, or not at all.

A secondary problem is portability. This plugin is intended for use
across other projects, and those projects do not share a convention.
Across the author's repositories the default branch is variously
`main`, `master` or `develop`; five carry a `dev` integration branch
and the rest do not; branch naming ranges over `feature/*`, `feat/*`,
`majerr-*`, `fix-*` and bare personal names. Any rule that names a
branch literally will be wrong in most repositories, so the workflow
must derive its targets rather than be told them.

## Decision

Adopt a branch-per-artefact workflow, isolated on contention, landed
through the host's pull-request mechanism where one exists, with
integration that preserves commit structure.

### The unit of work is an artefact

An **artefact is what one skill produces in one invocation**:

| Governing skill | Artefact |
| --- | --- |
| `facilitated-discovery` | one discovery note |
| `adr` | one ADR |
| `plans` | one plan |
| `test-first-workflow` | one working code change |
| `skill-forge` | one skill |

The git workflow never defines "artefact" itself; it defers to the
governing skill, which already defines its own boundaries and exit
criteria. Work not governed by any skill is still an artefact and
still gets its own branch.

### Branch before edit

No file is created or modified until a branch exists for the artefact
being produced. This applies to markdown decision artefacts exactly
as it applies to code. The base checkout stays on the trunk and is
never worked in directly.

### Isolate on contention, not by default

A branch is created in the primary checkout when that checkout is on
trunk and clean. When it is not — because another artefact is already
in flight there, or the tree is dirty — the branch is created together
with a worktree at `.worktrees/<branch>` inside the repository, which
is gitignored.

Both conditions are readable without judgement, from `git rev-parse
--abbrev-ref HEAD` and `git status --porcelain`. Nothing has to be
inferred about whether work is "parallel", which is knowledge an agent
does not have about the author's other sessions.

The checkout is therefore still never worked on while it is on trunk
— it branches in place — and concurrent strands still never contend
for one working tree. The common case of a single strand keeps the
file paths a reader expects, and the extra path depth of a worktree is
paid only when isolation is the point.

### Fork point is derived, not configured

The trunk to branch from is the first of: a local `dev` branch, a
local `develop` branch, the branch named by
`refs/remotes/origin/HEAD`, or — where that symbolic ref is unset —
the repository's existing default branch. This reproduces the
intended behaviour across every repository examined without any
per-repository configuration: repositories carrying a `dev` trunk get
the trunk workflow, and single-developer repositories branch from
`main`, `master` or `develop` directly.

### Naming

`<artefact-type>-NNNN-slug` where the artefact carries a number, so
`adr-0003-git-workflow` and `plan-0003-git-workflow` share the
identifier of the artefact they produce. `<type>-<slug>` where there
is no number.

### Commit cadence is delegated

This workflow owns where work happens and how it lands. It never
specifies what a commit contains. The governing skill decides that,
and the skills deliberately disagree with one another —
`test-first-workflow` mandates three commits in one order,
`skill-forge` three in another, `plans` requires status transitions
to ride with the changes that justify them.

### Bookkeeping is not an artefact

A change is **bookkeeping** when it has no independent truth
condition: it is true only because some other work is true. A plan's
`status: done` is not true because it was typed; it is true because
the work it describes finished. A change that would still need to be
made had the accompanying work not happened is **work**, whatever
file it touches.

Bookkeeping does not get its own branch. It rides with the change
that makes it true, on that change's branch. Bookkeeping that has
nothing to ride on is not bookkeeping: if no accompanying work makes
it true, it has an independent truth condition, and it is work.

Classification is relational. Whether a change is bookkeeping is a
property of the relationship between the change and the work in hand,
never of the file it touches, and never of a designated section
within a file. The same line in the same file classifies both ways:

| Change | Classification | Why |
| --- | --- | --- |
| Adding `.worktrees/` to this repository's `.gitignore` as a deliverable implementing this ADR | work | Independently true; independently verifiable by `git check-ignore`. It is the point of the change, not a record of another. |
| The git workflow adding `.worktrees/` to a target repository's `.gitignore` while creating a worktree | bookkeeping | Incidental to producing some other artefact. Has no truth of its own. |
| `weeknotes/` in `.gitignore` (`055f637`) | work | Nothing else made it true. It should have had a branch. |

This exception governs the branch-per-artefact rule and nothing else.
Bookkeeping is exempt from needing its own branch. It is not exempt
from anything else: it is committed, reviewed and merged like any
other change, and the governing skill's commit cadence continues to
decide what a commit holds.

"It is only bookkeeping" would otherwise justify editing trunk
directly for anything inconvenient to branch. The truth-condition
test is what forecloses that, and it is part of this decision rather
than its rationale. Applying it requires asking what makes the change
true, which is answerable without judgement about effort or
convenience.

### Integration preserves structure

A branch is merged into the branch it forked from, with `--no-ff`.
The no-fast-forward merge is what brackets the commits belonging to
one artefact. Squashing is prohibited: it is what removed the
red/green sequence from `main` in `1e7d948`, it would leave the
auditability claim in `test-first-workflow` false, and it discards
the individual commits' trailers, which ADR 0004 requires in order to
record the artefact graph. A fast-forward is also avoided, because it
keeps the individual commits but loses the record of which artefact
they belonged to.

Merging is not mandatory. An experiment may remain unmerged; its
branch and worktree are left in place and are never removed
automatically.

### Integration goes through a pull request where the host offers one

A branch is proposed and landed through the host's pull-request
mechanism whenever the repository has a remote whose host provides
one. A local merge is the **fallback**, used when there is no such
remote — not an equal alternative chosen by preference.

This reverses the original form of this decision, which treated a
local merge as the normal path and a pull request as what happens
"where integration goes through GitHub". The reason for the original
was that a pull request is ceremony for a single-developer project.
That is a cost model for a *human* — a web UI, a wait on a colleague,
a context switch. An agent performing the same steps pays none of it,
and this workflow is designed to be executed by an agent. What remains
once the ceremony argument is removed is that a pull request is
strictly stronger.

What it is stronger at is **enforcement**, and only that. The
platform can refuse a squash merge and refuse a direct push to trunk,
so the rules above stop depending on an agent remembering them. It
buys no review: an agent that opens a pull request and immediately
merges it has been reviewed by nobody. Any claim that this provides
human acceptance would be false, and the absence is the reason a
separate decision is needed about when an agent may land its own work
and when it must escalate. Until that decision exists, the agent
lands its own work.

**The host is an implementation detail.** This decision names the
mechanism — a pull request, merged so as to preserve commit structure
— and never the tool that performs it. Naming a platform here would
repeat, one level up, the error this ADR exists to correct: the
conventions it replaced hardcoded a `dev` trunk and `feature/*`
naming that held in only a minority of repositories. Which command
implements the mechanism belongs to whatever skill knows the host.

Two properties of the mechanism are not negotiable, and hosts commonly
default against both: the merge must create a merge commit with two
parents, and it must not squash. Where a host's default merge action is
a squash — as at least one major host's is — the action must be stated
explicitly rather than accepted, and squash and rebase merges should be
disabled at the repository level wherever the host allows it, so that
the prohibition is enforced rather than merely written down. Which
host, and which setting, is for the skill that knows the host.

### A plan merges when it is written

A plan's branch is merged as soon as the plan is written and
reviewed, before implementation against it begins. A plan is not held
back until the work it describes is finished.

Two things go wrong otherwise, both observed. ADR 0004 requires that
revising an ADR revises every plan **in the tree** whose `adr:` field
names it, on the same branch; a plan on an unmerged branch is outside
the reach of that rule and cannot be edited from the ADR's branch at
all. And a plan abandoned before its branch merged produces no
removing commit on trunk, so the `Abandons` trailer has nothing to
attach to and the plan leaves no reachable record — the file was
never in the tree to be removed from it.

Merging on creation makes ADR 0004's "in the tree" true by
construction, so that rule needs no broadening. It also fixes the
order of work: implementation branches fork from a trunk that already
carries the plan, which is what allows the plan's own removal on
completion to be a `git rm` of a file that is actually there.

### Worktree bootstrap is split

Where a worktree is used, it receives tracked files only. Git offers
no option to populate it with ignored files and cannot: ignored files
are not in the object database. The two categories of missing file
are treated differently:

- **Small configuration files** — `.claude/`, `.env`, `.mcp.json` and
  similar — are copied into the new worktree from the base checkout.
  Without this, an agent working in a fresh worktree loses the
  permissions granted in `.claude/settings.local.json` and prompts
  for the very commands this workflow depends on.
- **Built dependencies** — `.venv/`, `node_modules/` and similar —
  are not copied. They cannot be copied safely, and provisioning them
  requires per-repository knowledge. Responsibility stays with the
  governing skill, which must have a working environment in order to
  execute anything. Decision artefacts are markdown and need nothing
  installed, so the majority of artefacts are unaffected.

`post-checkout` is the native seam for repository-specific bootstrap:
it fires on `git worktree add`, and hooks are shared across all
worktrees of a repository. Repositories may use it; this workflow
does not require it.

### Cleanup

On merge, the branch is deleted and, where the work was isolated, the
worktree is removed. Once dependencies have been installed into a
worktree, `git worktree remove` requires `--force`, because it refuses
to remove a worktree containing untracked files.

Work done in the primary checkout returns that checkout to trunk on
merge. Without this, the next artefact branches from the previous
artefact rather than from trunk.

## Alternatives considered

- **One branch per decision, spanning ADR to implementation.** Tidier
  — one identifier for a whole chain of work, and what was in fact
  done for ADR 0002. Rejected because the ADR would only ever be
  merged alongside the thing it authorised, so it would have no
  `Revises` history of its own and no moment at which it could be
  reviewed as a decision.
- **Squash merge.** Rejected: it is the direct cause of the problem
  in `1e7d948`.
- **A local merge as the normal path, with a pull request only "where
  integration goes through GitHub".** The original form of this
  decision, reversed here. It rested on a pull request being ceremony
  for a single-developer project, which is a cost model for a human
  and not for the agent that executes this workflow. It also left the
  condition untested: unlike the fork point, which is derived, and
  contention, which is checked, "where integration goes through
  GitHub" had no test attached — so on a protected trunk the workflow
  would merge locally, succeed, and then fail to push, leaving trunk
  diverged with the artefact apparently landed.
- **Requiring a human to approve every pull request.** Rejected here
  as the wrong default and deferred as a question in its own right.
  Applied to everything it makes each cheap revision cost a review,
  which is the friction that made local merges attractive in the
  first place. What is wanted is that an agent lands its own work
  when confidence has been earned and escalates when it has not, and
  deciding how that confidence is established is a separate decision.
- **Naming the platform tool in this decision.** Rejected: it repeats
  one level up the error this ADR corrects. The mechanism is stable
  across hosts; the command is not.
- **Holding a plan's branch unmerged until its work is done.** What
  was in fact done for plan 0003, and reversed above. It puts the plan
  outside the reach of ADR 0004's rule that revising an ADR revises
  its plans, and leaves an abandoned plan with no reachable record
  because its file never entered the tree.
- **Always work in a worktree, never in the primary checkout.** The
  original form of this decision, rejected on first contact with it:
  drafting this ADR at
  `.worktrees/adr-0003-git-workflow/docs/adr/` was meaningfully more
  onerous than drafting it at `docs/adr/`, for no benefit while only
  one strand was in flight. That toll falls on every user's first
  artefact, before they have experienced the collision it prevents.
  The conditional rule keeps the isolation and drops the toll, at the
  cost of a state check before branching.
- **Branch without a worktree at all.** Rejected: concurrent strands
  then contend for one working tree.
- **Per-repository configuration of trunk and naming.** Rejected: the
  derivation rule above reproduces the intended behaviour everywhere
  it was tested, and configuration that must be maintained per
  repository will not be.
- **Adopting the conventions in `IFS_research/CLAUDE.md` directly.**
  These were the starting point for this decision, but they hardcode
  a `dev` trunk and `feature/*` naming that hold in only a minority
  of the repositories concerned.
- **Amending the previous commit for trivial work.** Considered for
  cases too small to warrant an artefact, such as a typo. Rejected
  because amending after a push rewrites published history; trivial
  work takes a short-lived branch like anything else.
- **Enumerating which files or sections are bookkeeping** — for
  example, frontmatter is bookkeeping and body is work. Rejected:
  `.gitignore` has no sections, and the same line in it classifies
  both ways depending on why it is being written. A file-based or
  section-based rule gives the wrong answer in the case that prompted
  the exception.
- **Treating all work governed by no skill as bookkeeping.**
  Rejected: far too broad, and it reverses the deliberate decision
  above that ungoverned work is still an artefact. It would exempt
  most one-off changes from branching altogether.
- **Leaving bookkeeping to each plan to judge case by case.**
  Rejected: a plan may only implement what was decided. A plan
  introducing this category would be a new architectural commitment
  smuggled in as detail, and the resulting skill would carry a rule
  with no ADR behind it.
- **Requiring bookkeeping to be a separate commit on the accompanying
  branch.** Rejected: commit cadence belongs to the governing skill
  under the delegation above, and the exception does not take back a
  delegation made deliberately.
- **Enforcing the workflow with a `PreToolUse` hook.** A hook is
  executed by the harness and could refuse edits made on a trunk
  branch through the tools its matcher names, which a skill cannot
  guarantee. Deliberately out of scope:
  prompting a skill to load is a separate concern with its own
  mechanisms, and this ADR decides the workflow's content, not its
  enforcement.

## Consequences

- "Branch before edit" acquires a bounded exception, which weakens
  it. The truth-condition test is the whole of what bounds that
  exception, so the test must appear in the skill body as a rule,
  not as commentary.
- Classification as bookkeeping or work is performed per change
  rather than looked up. This is a judgement the workflow did not
  previously require, mitigated by the test being a single question
  with a factual answer.
- An eval scenario should cover a bookkeeping change, or the rule is
  asserted in the skill body and tested nowhere.
- The red/green commit sequence mandated by `test-first-workflow` and
  `skill-forge` survives on the base branch, making the auditability
  those skills claim actually true.
- The workflow carries no per-repository configuration and can be
  applied to a new repository without being told anything about it.
- Landing now depends on the network and on the host being reachable,
  where before a merge was a local operation. A repository with no
  remote takes the fallback path and is unaffected; a repository whose
  host is unreachable cannot land an artefact at all.
- Whether a pull request is available has to be established, not
  assumed. It is the same shape of check as the contention check —
  does a remote exist, and does its host offer the mechanism — and
  like the fork point it must be derived rather than configured.
- The content of this decision now splits across a boundary. The rules
  that hold everywhere — branch before edit, one branch per artefact,
  the bookkeeping test, fork-point derivation, contention, naming,
  and the required *outcome* of integration — are separable from the
  commands that realise integration on a particular host. Whether
  that becomes two skills is a decision for whatever implements this,
  but the boundary is now in the decision rather than latent in it.
- A pull request merged by the agent that opened it records no human
  acceptance. Anything that needs review has to say so and be
  escalated deliberately, and until the escalation rule exists there
  is nothing in this decision that stops an agent landing a bad
  artefact. This is the single largest gap the revision opens.
- Merging a plan on creation means a plan is public before the work
  it describes has been attempted, so a plan found defective during
  implementation is corrected by a revision commit on trunk rather
  than by amending an unmerged branch. That is the intended
  behaviour — a plan is an artefact of record, not a draft — but it
  makes plan revisions visible and frequent.
- Because a merge returns the primary checkout to trunk clean, a
  single-threaded plan never triggers the contention check and never
  creates a worktree. Isolation is exercised only by genuine
  parallelism. Anything that sets out to demonstrate the isolation
  path has to create real contention rather than rely on a dirty
  tree.
- More branches and more merges: a single piece of work that
  previously produced one commit now produces a discovery note, an
  ADR, a plan and an implementation, each with its own branch, merge
  and review point. This is heavier than the current practice,
  particularly in single-developer repositories.
- An artefact isolated into a worktree begins without installed
  dependencies. Harmless for markdown artefacts; for implementation
  artefacts the governing skill must provision before it can run
  anything.
- `.worktrees/` accumulates a directory per *concurrent* artefact
  rather than per artefact, and requires the cleanup discipline
  described above.
- The primary checkout is no longer reliably on trunk, so its branch
  and cleanliness must be checked before branching. This is the price
  of dropping the unconditional rule, and it weakens the
  no-negotiation property slightly: the workflow now has two paths
  rather than one, even though the choice between them is
  mechanical.
- The invariant "no artefact lands on trunk unmerged" is enforceable
  outside the agent altogether — by a `pre-commit` hook refusing
  commits made on trunk, or by branch protection on the remote. Hooks
  live in the common directory, so one covers every worktree of a
  repository; `.git/hooks` is not version-controlled, so this is
  per-clone unless `core.hooksPath` points at a committed directory.
  This half is most of what `1e7d948` actually cost.
- The invariant "branch before edit" is not enforceable that way. It
  depends on the skill being loaded, and a `PreToolUse` hook would
  cover only the write paths its matcher names — this ADR was itself
  written with a shell heredoc, which a matcher on the file-editing
  tools would not have caught. Matching "a shell command that writes
  a file" is not decidable in general. This half remains the concern
  explicitly parked above.

## References

- `docs/adr/0001-artifact-embedded-skill-directives.md`
- `docs/adr/0002-skill-forge.md`
- `docs/adr/0004-where-does-history-live.md` — the trailer vocabulary
  the no-squash rule protects, and the rule that revising an ADR
  revises its plans, which the merge-on-creation decision above makes
  reachable for every plan.
- `skills/test-first-workflow/SKILL.md` — red/green commit mandate
- `skills/skill-forge/SKILL.md` — frontmatter/scenario/body commits
- `skills/plans/SKILL.md` — status transitions ride with changes
- `skills/adr/SKILL.md` — revision rules
- Commit `1e7d948` — the squashed execution that prompted this
  decision. The plan it executed, `plans/0002-skill-forge.md`, was
  retired from the tree at `a552a82` and is reachable there.
- `githooks(5)`, `post-checkout` — fires on `git worktree add`
