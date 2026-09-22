---
name: git-workflow
description: Governs where work happens in a git repository and how it lands — branch-per-artefact, worktree isolation on contention, and integration that preserves commit structure. TRIGGER on any task about to create or modify a file in a git repository, before the first edit — a discovery note, an ADR, a plan, or code alike, all need a branch first. SKIP for read-only exploration that edits nothing, and for work already proceeding on an artefact branch this workflow created.
---

# Git workflow

Use this whenever you are about to create or modify a file in a git
repository. It is the standing rule for **where** work happens and
**how** it lands. It applies to markdown decision artefacts — discovery
notes, ADRs, plans — exactly as it applies to code. The most common way
to get this wrong is to treat a document as not really being work.

This skill owns two things and no others: the branch an artefact is
produced on, and the merge that lands it. It never says what a commit
contains. That belongs to the governing skill.

## The procedure, in order

Before the first edit:

1. Derive the trunk. Never read it from configuration or from prose.
2. Run the contention check. Branch in place, or isolate into a
   worktree.
3. Name the branch after the artefact.
4. Create the branch — and, where isolating, the worktree — and bootstrap
   its configuration.

Then, and only then, edit.

To land:

5. Commit, with `Derives-From:` on the branch's first commit.
6. Propose and land through the host's pull-request mechanism where the
   repository has a remote whose host offers one; merge locally where it
   does not. Either way the result is a two-parent merge commit, never
   squashed and never fast-forwarded.
7. Clean up: delete the branch, remove the worktree, return the primary
   checkout to trunk.

Each numbered step is a rule below, in the same order.

## Rule 1 — Branch before edit

No file is created or modified until a branch exists for the artefact
being produced. This applies to markdown decision artefacts exactly as
it applies to code. The base checkout stays on the trunk and is never
worked in directly.

There is one bounded exception, Rule 4. There are no others. If you find
yourself about to write a file and cannot name the branch it belongs on,
stop and go back to the procedure above.

## Rule 2 — One branch per artefact

An **artefact is what one skill produces in one invocation**:

| Governing skill | Artefact |
| --- | --- |
| `facilitated-discovery` | one discovery note |
| `adr` | one ADR |
| `plans` | one plan |
| `test-first-workflow` | one working code change |
| `skill-forge` | one skill |

**This skill never defines "artefact" itself.** It defers to the
governing skill, which already defines its own boundaries and exit
criteria. Do not invent a boundary here, and do not split or merge an
artefact because it would make the branching tidier.

Work governed by no skill is still an artefact and still gets its own
branch.

## Rule 3 — Commit cadence is delegated

This skill never specifies what a commit contains. The governing skill
decides that, and the governing skills deliberately disagree with one
another: `test-first-workflow` mandates three commits in one order,
`skill-forge` three in another, `plans` requires status transitions to
ride with the changes that justify them. The disagreement is the point —
the delegation is deliberate, not an oversight to be tidied up here.

## Rule 4 — Bookkeeping is not an artefact

**The test.** A change is **bookkeeping** when it has no independent
truth condition: it is true only because some other work is true. A
plan's completion is not true because it was typed; it is true because
the work it describes finished. A change that would still need to be
made had the accompanying work not happened is **work**, whatever file
it touches.

**The rule.** Bookkeeping does not get its own branch. It rides with the
change that makes it true, on that change's branch. Bookkeeping that has
nothing to ride on is not bookkeeping: if no accompanying work makes it
true, it has an independent truth condition, and it is work, and it
takes a branch like anything else.

**Classification is relational.** Whether a change is bookkeeping is a
property of the relationship between the change and the work in hand —
never of the file it touches, and never of a designated section within a
file. The same line in the same file classifies both ways:

| Change | Classification | Why |
| --- | --- | --- |
| Adding `.worktrees/` to a repository's `.gitignore` as a deliverable implementing a decision to adopt this workflow | work | Independently true; independently verifiable by `git check-ignore`. It is the point of the change, not a record of another. |
| This workflow adding `.worktrees/` to a target repository's `.gitignore` while creating a worktree | bookkeeping | Incidental to producing some other artefact. Has no truth of its own. |
| `weeknotes/` in `.gitignore`, added on its own account | work | Nothing else made it true. It should have had a branch. |

**The scope.** This exception governs the branch-per-artefact rule and
nothing else. Bookkeeping is exempt from needing its own branch. It is
not exempt from anything else: it is committed, reviewed and merged like
any other change, and the governing skill's commit cadence continues to
decide what a commit holds. Whether bookkeeping shares a commit with the
artefact or sits in its own commit on the same branch is not this
skill's business.

"It is only bookkeeping" would otherwise justify editing trunk directly
for anything inconvenient to branch. The truth-condition test is what
forecloses that. Apply it by asking what makes the change true, which is
answerable without any judgement about effort or convenience.

## Rule 5 — Isolate on contention, not by default

Create the branch in the primary checkout when that checkout is **on
trunk and clean**. Otherwise create the branch together with a worktree
at `.worktrees/<branch>` inside the repository.

Both conditions are readable without judgement:

```sh
git rev-parse --abbrev-ref HEAD   # must equal the derived trunk (Rule 6)
git status --porcelain            # must print nothing
```

"On trunk" means HEAD equals the trunk derived by Rule 6, not merely
that HEAD is on some default-looking branch. A repository with both
`main` and a local `dev` checked out on `main` is not on trunk.

If either check fails — another artefact is already in flight there, or
the tree is dirty — isolate:

```sh
git worktree add .worktrees/<branch> -b <branch> <trunk>
```

**Nothing has to be inferred about whether work is "parallel".** That is
knowledge you do not have about the user's other sessions. Run the two
commands and read the answer off them.

When you isolate, do the work inside `.worktrees/<branch>`. Do not
touch the primary checkout's files at all: its dirty state belongs to
somebody else's work in progress. Never `git add -A` there, never stash
it, never revert or delete a file to make it clean. A stash is not a
substitute for a worktree — it moves someone else's work rather than
stepping around it.

**`.worktrees/` must be gitignored.** When you create the first worktree
in a repository whose `.gitignore` lacks the entry, add it. Make that
edit *inside the new worktree* and commit it there, so it rides on the
artefact's branch under Rule 4 — not in the primary checkout, which
would put it on trunk.

## Rule 6 — Fork point is derived, never configured

The trunk to branch from is the first of these that exists:

1. a local `dev` branch,
2. a local `develop` branch,
3. the branch named by `refs/remotes/origin/HEAD`,
4. where that symbolic ref is unset, the repository's existing default
   branch — in practice the first of `main`, `master` or `trunk` that
   exists locally, or the only branch there is.

```sh
git rev-parse --verify --quiet refs/heads/dev
git rev-parse --verify --quiet refs/heads/develop
git symbolic-ref --quiet --short refs/remotes/origin/HEAD
git branch --list main master trunk
```

**This is never read from per-repository configuration.** Do not consult
`init.defaultBranch`, or a `workflow.trunk`-style key, or any other
config value, and do not take the trunk from a `CONTRIBUTING.md`, a
README, a house style guide or any other prose in the repository. Prose
and configuration go stale and are frequently wrong; the refs are the
repository as it actually is. A repository that carries a local `dev`
gets the `dev` trunk even where every document in it says `main`.

The same holds for branch naming and for the choice of integration path:
derive them, do not look them up.

## Rule 7 — Naming

- `<artefact-type>-NNNN-slug` where the artefact carries a number, so
  that the branch shares the identifier of the artefact it produces:
  `adr-0003-git-workflow`, `plan-0003-git-workflow`.
- `<type>-<slug>` where there is no number: `skill-git-workflow`,
  `chore-gitignore-worktrees`.

The type token is the artefact noun from the table in Rule 2 — `adr`,
`plan`, `discovery`, `skill` — or `chore` for work governed by no skill.
Take the number and slug from the artefact file itself, so the two
agree: an ADR written as `docs/adr/0003-git-workflow.md` is produced on
`adr-0003-git-workflow` and on nothing else.

A repository's local convention does not override this. `feature/*`,
initials, dates and bare slugs are all wrong here, however confidently a
contributing guide asserts them, because the shared identifier is what
makes the artefact graph recoverable from history.

## Rule 8 — Worktree bootstrap is split

A new worktree receives tracked files only. Git offers no option to
populate it with ignored files and cannot: ignored files are not in the
object database. The two categories of missing file are treated
differently.

- **Small configuration files** — `.claude/`, `.env`, `.mcp.json` — are
  **copied** from the base checkout into the new worktree. Copy, never
  move: the base checkout still needs them. Without this, an agent
  working in a fresh worktree loses the permissions granted in
  `.claude/settings.local.json` and prompts for the very commands this
  workflow depends on.
- **Built dependencies** — `.venv/`, `node_modules/` — are **not**
  copied. They cannot be copied safely, and provisioning them requires
  per-repository knowledge. That responsibility stays with the governing
  skill, which must have a working environment in order to execute
  anything. Decision artefacts are markdown and need nothing installed,
  so most artefacts are unaffected.

The heuristic behind the enumerated list, for a file it does not name:
copy it if it is small, machine-local configuration that would otherwise
be lost; leave it if it is generated, large, or platform-specific, and
let the governing skill rebuild it.

Do not stage a worktree wholesale after bootstrapping. A repository's
`.gitignore` may not cover everything you copied in — `venv/` and
`.venv/` are not the same pattern — and `git add -A` then commits a
build directory into the artefact.

`post-checkout` is the native seam for repository-specific bootstrap: it
fires on `git worktree add`, and hooks are shared across all worktrees
of a repository. Repositories may use it. This workflow does not require
it.

## Rule 9 — Trailers: history is written for retrieval

The artefacts in a repository form a graph — a plan derives from an ADR,
an ADR from a discovery note, a code change or a skill from a plan — and
because completed artefacts leave the tree, that graph is recorded in
git history as trailers on commits. This is the skill that lands
commits, so it is the skill that must get them right.

**The graph is append-only.** An edge between two artefacts is added by
exactly one commit, and that commit carries the trailer for it. Edges
are never modified; a relationship that changes is a new edge, added by
the commit that changes it.

**The table is exhaustive.** It lists every kind of edge and the event
that adds it. An event not in the table adds no edge, and a change to an
artefact's content that leaves its edges as they were carries no trailer
for them.

| Trailer | On the commit that | Value |
| --- | --- | --- |
| `Derives-From:` | establishes that an artefact derives from another: the first commit on the artefact's branch, or a later commit that re-points it | path of the upstream artefact; one trailer per direct upstream |
| `Revises:` | changes what an accepted ADR decides | path of the ADR |
| `Consumed-By:` | removes a discovery note | path of the ADR it informed |
| `Completes:` | removes a plan whose work is done | path of the plan |
| `Abandons:` | removes a plan whose work will not be done | path of the plan |

Values are repository-relative paths. A commit may carry several
trailers, and a key may repeat.

**`Derives-From` sits on the first commit of an artefact's branch** and
names **direct upstreams only**, one trailer per upstream. A skill
produced by a plan step names the plan, not the ADR behind it, which is
one hop away through the plan's own `adr:` field. An ADR names the
discovery note it was written from. Before the first commit, ask what
this artefact was produced from and write the path down; a repository
that keeps discovery notes usually has the answer sitting in the
directory the task pointed you at.

Trailers go in the trailer block at the end of the commit message, one
per line, in `Key: value` form — not in prose. `git interpret-trailers`
and `git log --format='%(trailers:key=Derives-From,valueonly)'` are what
read them back, and neither can see a sentence.

Because `Derives-From` belongs on the branch's **first** commit, do not
commit bookkeeping ahead of the artefact. Commit the artefact first, or
commit both together; the `.worktrees/` ignore entry from Rule 5 must
not become the first commit on the branch.

**Trailers record edges between artefacts.** Structure *inside* an
artefact — such as the order of docstring, test and code commits under
`test-first-workflow` — belongs to the governing skill under Rule 3's
delegation of commit cadence, and carries no trailer.

**The body carries the reason.** The prose body of a `Revises`,
`Abandons` or deleting commit must say what changed and why, in
sentences. Trailers carry the edge; the body carries the reason. Neither
is optional.

## Rule 10 — Integration preserves structure

State the outcome first, because it holds on every path:

> A branch lands as a **merge commit with two parents**, into the branch
> it forked from. Never squashed. Never fast-forwarded.

The no-fast-forward merge is what brackets the commits belonging to one
artefact. Squashing is prohibited for two reasons. It removes the
red/green commit sequence that `test-first-workflow` and `skill-forge`
mandate, which would leave the auditability those skills claim false.
And **a squash discards trailers**: it discards the individual commits,
and their trailers with them, and the artefact graph recorded in history
goes with them.

The local form is:

```sh
git merge --no-ff <branch>
```

Run it from a checkout that has the trunk checked out — normally the
primary checkout. Trunk cannot be checked out in two worktrees at once,
so you cannot merge into it from the artefact's own worktree. A dirty
primary checkout does not block the merge as long as the merge touches
different paths, which is the usual case for an artefact developed in
isolation; it is not a reason to disturb the files already sitting
there.

A fast-forward is avoided too: it keeps the individual commits but loses
the record of which artefact they belonged to.

## Rule 11 — A pull request is the default; a local merge is the fallback

A branch is proposed and landed **through the host's pull-request
mechanism whenever the repository has a remote whose host provides
one**. A local merge is the **fallback**, used when there is no such
remote. These are not equal alternatives chosen by preference.

Check availability; do not assume either way, and do not read the answer
out of a contributing guide:

```sh
git remote          # prints nothing → no remote → local merge fallback
```

Like the fork point, this is derived and never read from per-repository
configuration. A repository with no remote takes the local merge, even
where its documentation instructs a pull request — there is nothing to
open one against, and you must not create a remote in order to follow
that instruction. Inventing an `origin`, or leaving the artefact
unlanded because a pull request was impossible, are both failures to
land.

**The host is an implementation detail, and this skill does not know
it.** This skill names the mechanism — a pull request, merged so as to
preserve commit structure — and never the tool that performs it. The
commands for a particular host belong to a **platform skill, which does
not yet exist**. Until it does, `git-workflow` implements the fallback
path only, and the host-specific half is deferred rather than forgotten.
Naming a platform here would repeat, one level up, the error this
workflow exists to correct: conventions that hardcode a trunk and a
naming scheme holding in only a minority of repositories.

Where a remote exists, use whatever host tooling the session already
provides, and hold it to Rule 10's outcome: a two-parent merge commit,
explicitly not a squash. Hosts commonly default against both properties
— at least one major host squashes by default — so state the merge
action explicitly rather than accepting the default, and disable squash
and rebase merges at the repository level wherever the host allows it,
so the prohibition is enforced rather than merely written down. Which
host and which setting is for the skill that knows the host.

**What a pull request buys, and what it does not.** It buys
**enforcement**, and only that: the platform can refuse a squash and
refuse a direct push to trunk, so the rules above stop depending on an
agent remembering them. It buys **no review**. An agent that opens a
pull request and immediately merges it has been reviewed by nobody. Do
not describe a merged pull request as approved, accepted or signed off;
it records no human acceptance. The agent lands its own work until a
separate decision says otherwise.

## Rule 12 — A plan merges when it is written

A plan's branch is merged as soon as the plan is written and reviewed,
**before implementation against it begins**. A plan is not held back
until the work it describes is finished.

Two things go wrong otherwise, both observed:

- Revising an ADR revises every plan **in the tree** whose `adr:` field
  names it, on the same branch. A plan on an unmerged branch is outside
  the reach of that rule and cannot be edited from the ADR's branch at
  all.
- A plan abandoned before its branch merged produces no removing commit
  on trunk, so `Abandons` has nothing to attach to and the plan leaves
  no reachable record — the file was never in the tree to be removed
  from it.

Merging on creation also fixes the order of work: implementation
branches fork from a trunk that already carries the plan, which is what
makes the plan's own removal on completion a `git rm` of a file that is
actually there.

## Rule 13 — Merging is not mandatory

An experiment may remain unmerged. Its branch and worktree are left in
place and are **never** removed automatically. Do not tidy up a branch
or a `.worktrees/` directory you did not create, and do not treat an
unmerged branch as an error to be cleaned away. Cleanup happens on
merge, and only on merge.

## Rule 14 — Cleanup on merge

Once the artefact has landed:

```sh
git worktree remove .worktrees/<branch>   # --force once dependencies are installed
git branch -d <branch>
```

`git worktree remove` requires `--force` where dependencies have been
installed into the worktree, because it refuses to remove a worktree
containing untracked files. It does not delete the now-empty
`.worktrees/` parent directory; leaving that behind is fine.

Work done **in the primary checkout returns that checkout to trunk** on
merge. Without this, the next artefact branches from the previous
artefact rather than from trunk.

Where the work was isolated, the primary checkout was never moved and
needs no returning. **Confirm its branch, do not check it out.**
`git rev-parse --abbrev-ref HEAD` answers the question; `git checkout
<trunk>` against a checkout already on trunk changes nothing and writes
a spurious `checkout: moving from <trunk> to <trunk>` line into the
reflog, which is the record that shows where work actually happened.

After cleanup, `git branch` shows no artefact branch, `git worktree
list` shows only the primary checkout, and HEAD is on trunk.

## Do not

- Do not create or modify a file before the branch for it exists. This
  is the rule that is actually broken in practice, and markdown is where
  it gets broken.
- Do not commit an artefact directly onto trunk. If a commit has landed
  on trunk that should not have, say so rather than quietly leaving it.
- Do not read the trunk, the branch name, or the integration path out of
  `CONTRIBUTING.md`, a README, or git configuration. Derive all three.
- Do not squash. Do not fast-forward. Do not rebase a branch onto trunk
  in place of merging it — all three destroy the bracket around the
  artefact, and the first destroys its trailers as well.
- Do not run `git add -A` or `git commit -a` in a checkout whose dirty
  state is not yours. It sweeps someone else's work into your artefact.
- Do not `git stash` a checkout to get it clean enough to branch in.
  That is what the worktree is for.
- Do not copy `.venv/`, `node_modules/` or any other built dependency
  into a worktree, and do not commit one.
- Do not move `.claude/`, `.env` or `.mcp.json` into a worktree. Copy
  them; the base checkout still needs them.
- Do not add a remote, or push, in order to satisfy an instruction to
  open a pull request in a repository that has no remote.
- Do not leave an artefact unlanded because the host's mechanism was
  unavailable. Take the fallback.
- Do not write a relationship between artefacts as a sentence and call
  it recorded. It goes in a trailer.
- Do not define "artefact" here, adjust an artefact's boundary to suit
  the branching, or specify what a commit contains. Rules 2 and 3 defer
  all three to the governing skill.
- Do not remove somebody else's branch or worktree.
- Do not check out a branch that is already checked out, to reassure
  yourself. Read HEAD instead.

## When you may deviate

- **Read-only exploration.** This skill does not apply. Reading,
  searching and running tests that change no file need no branch.
- **Work already proceeding on an artefact branch this workflow
  created.** You are past the branching decision; carry on. Do not
  re-derive the trunk or branch again mid-artefact.
- **Bookkeeping.** Rule 4's exception, and only on the terms Rule 4
  states: it rides with the change that makes it true, and it is exempt
  from needing a branch and from nothing else.
- **A repository that is not a git repository, or a path outside any
  repository.** Nothing here applies; say so rather than running
  `git init` to make it apply.
- **The user explicitly says to work on trunk, or not to branch.**
  Follow the instruction, and note the deviation in your reply so it is
  visible rather than silent.

Deviating because the workflow feels heavy for the change in hand is not
on this list. A one-line change takes a short-lived branch like anything
else; amending the previous commit instead rewrites published history.
