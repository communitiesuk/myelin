---
name: git-workflow
model: sonnet
compatibility: Needs a sonnet-class model or stronger. Measured 2026-09-23 on evals/git-workflow-1, same body, three repeats each - claude-sonnet-5 94/100/100, deepseek-v4-flash 18/0/0, where the weak model merged into trunk or never branched.
description: Governs where work happens in a git repository and how it lands — branch-per-artefact, worktree isolation on contention, and integration that preserves commit structure. TRIGGER on any task about to create or modify a file in a git repository, before the first edit — a discovery note, an ADR, a plan, or code alike, all need a branch first. SKIP for read-only exploration that edits nothing, and for work already proceeding on an artefact branch this workflow created.
---

# Git workflow

Use this whenever you're about to create or modify a file in a git repository. It is the standing rule for **where** work happens and **how** it lands. Markdown decision artefacts — discovery notes, ADRs, plans — are work exactly as code is; treating a document as not really work is the usual failure. This skill owns three things: the branch an artefact is produced on, the merge that lands it, and the trailers that record the artefact graph. It never says what a commit *contains* — Rule 3 delegates cadence. Rationale is in `docs/adr/0003-git-workflow.md` and `docs/adr/0004-where-does-history-live.md`; follow the rules from here rather than re-deriving them from there.

## The procedure

Mandatory and ordered — do not skip, do not merge, do not reorder. Steps 1–4 happen **before the first edit**. You have not begun the deliverable until they are done.

1. Derive the trunk (Rule 6). Never from configuration or prose.
2. Run the contention check (Rule 5): branch in place, or isolate into a worktree.
3. Name the branch after the artefact (Rule 7).
4. Create the branch — and, where isolating, the worktree — and bootstrap its configuration (Rule 8).
5. **Now edit.**
6. Commit. The branch's first commit carries `Derives-From:` (Rule 9).
7. Land it: a pull request where the repository has a remote, `git merge --no-ff` where there is none (Rules 10–11). A two-parent merge commit either way. If the pull request cannot be opened, or its merge is refused, push the branch, stop here and report (Rule 11); step 8 runs only on merge.
8. Clean up: delete the branch, remove the worktree, return the primary checkout to trunk (Rule 14).

If you are at step 5 and cannot name the branch you are on, stop and go back to step 1. An artefact that was written but never committed and merged has not been produced.

## Rule 1 — Branch before edit

No file is created or modified until a branch exists for the artefact being produced. The base checkout stays on the trunk and is never worked in directly. Rule 4 is the one bounded exception; there are no others.

## Rule 2 — One branch per artefact

An **artefact is what one skill produces in one invocation**:

| Governing skill | Artefact |
| --- | --- |
| `facilitated-discovery` | one discovery note |
| `adr` | one ADR |
| `plans` | one plan |
| `test-first-workflow` | one working code change |
| `skill-forge` | one skill |

**This skill never defines "artefact" itself.** The governing skill already defines its own boundaries and exit criteria. Do not invent a boundary here, and do not split or merge an artefact because it would make the branching tidier. Work governed by no skill is still an artefact and still gets its own branch.

## Rule 3 — Commit cadence is delegated

This skill never specifies what a commit contains. The governing skill decides, and the governing skills deliberately disagree with one another (`test-first-workflow`, `skill-forge` and `plans` each mandate a different cadence). The delegation is deliberate; do not tidy it up here.

## Rule 4 — Bookkeeping is not an artefact

**The test.** A change is **bookkeeping** when it has no independent truth condition: it is true only because some other work is true. A change that would still need to be made had the accompanying work not happened is **work**, whatever file it touches.

**The rule.** Bookkeeping does not get its own branch; it rides with the change that makes it true, on that change's branch. Bookkeeping with nothing to ride on has an independent truth condition — it is work, and it takes a branch like anything else.

**Classification is relational** — a property of the relationship between the change and the work in hand, never of the file it touches or of a designated section within a file. The same line in the same file classifies both ways:

| Change | Classification | Why |
| --- | --- | --- |
| Adding `.worktrees/` to a repository's `.gitignore` as a deliverable implementing a decision to adopt this workflow | work | Independently true; independently verifiable by `git check-ignore`. It is the point of the change, not a record of another. |
| This workflow adding `.worktrees/` to a target repository's `.gitignore` while creating a worktree | bookkeeping | Incidental to producing some other artefact. Has no truth of its own. |
| `weeknotes/` in `.gitignore`, added on its own account | work | Nothing else made it true. It should have had a branch. |

**The scope.** The exemption is from needing its own branch and from nothing else: bookkeeping is committed, reviewed and merged like any other change, and Rule 3 still decides what a commit holds. Apply the test by asking what makes the change true; "it is only bookkeeping" is not an answer.

## Rule 5 — Isolate on contention, not by default

Branch in the primary checkout when that checkout is **on trunk and clean**. Otherwise branch together with a worktree at `.worktrees/<branch>` inside the repository. Both conditions are readable without judgement, and **nothing has to be inferred about whether work is "parallel"** — run the commands and read the answer off them.

```sh
git rev-parse --abbrev-ref HEAD   # must equal the trunk derived by Rule 6, not merely a default-looking branch
git status --porcelain            # must print nothing
git worktree add .worktrees/<branch> -b <branch> <trunk>   # if either check fails
```

When you isolate, work inside `.worktrees/<branch>` and do not touch the primary checkout's files at all: its dirty state belongs to somebody else's work in progress. Never `git add -A` there, never stash it, never revert or delete a file to make it clean.

**`.worktrees/` must be gitignored.** Where the repository's `.gitignore` lacks the entry, add it *inside the new worktree* and commit it there, so it rides on the artefact's branch under Rule 4 — not in the primary checkout, which would put it on trunk.

## Rule 6 — Fork point is derived, never configured

The trunk to branch from is the first of these that exists:

1. a local `dev` branch,
2. a local `develop` branch,
3. the branch named by `refs/remotes/origin/HEAD`,
4. where that symbolic ref is unset, the repository's existing default branch — in practice the first of `main`, `master` or `trunk` that exists locally, or the only branch there is.

```sh
git rev-parse --verify --quiet refs/heads/dev
git rev-parse --verify --quiet refs/heads/develop
git symbolic-ref --quiet --short refs/remotes/origin/HEAD
git branch --list main master trunk
```

Never from configuration — not `init.defaultBranch`, not a `workflow.trunk`-style key, not any other value — and never from prose in a `CONTRIBUTING.md`, a README or a house style guide. A repository that carries a local `dev` gets `dev` even where every document in it says `main`. The same holds for branch naming and for the integration path: derive them, do not look them up.

## Rule 7 — Naming

- `<artefact-type>-NNNN-slug` where the artefact carries a number, so the branch shares the artefact's identifier: `adr-0003-git-workflow`, `plan-0003-git-workflow`.
- `<type>-<slug>` where there is no number: `skill-git-workflow`, `chore-gitignore-worktrees`.

The type token is the artefact noun from Rule 2's table — `adr`, `plan`, `discovery`, `skill`, or `code` for a `test-first-workflow` code change — or `chore` for work governed by no skill. Take the number and slug from the artefact file itself, so the two agree: an ADR written as `docs/adr/0003-git-workflow.md` is produced on `adr-0003-git-workflow` and on nothing else. A repository's local convention does not override this; `feature/*`, initials, dates and bare slugs are all wrong here, however confidently a contributing guide asserts them.

## Rule 8 — Worktree bootstrap is split

A new worktree receives tracked files only. Ignored files are not in the object database, so git cannot populate them.

- **Small configuration files** — `.claude/`, `.env`, `.mcp.json` — are **copied** from the base checkout into the new worktree. Copy, never move: the base checkout still needs them. Without this you lose the permissions in `.claude/settings.local.json`.
- **Built dependencies** — `.venv/`, `node_modules/` — are **not** copied. Provisioning them needs per-repository knowledge and stays with the governing skill.
- **Anything neither list names**: copy it if it is small, machine-local configuration that would otherwise be lost; leave it if it is generated, large or platform-specific.

Do not stage a worktree wholesale after bootstrapping: `.gitignore` may not cover what you copied in (`venv/` and `.venv/` are not the same pattern) and `git add -A` then commits a build directory into the artefact. `post-checkout` is the native seam for repository-specific bootstrap — repositories may use it, this workflow does not require it.

## Rule 9 — Trailers: history is written for retrieval

Artefacts form a graph — a plan derives from an ADR, an ADR from a discovery note, a code change or a skill from a plan — and because completed artefacts leave the tree, that graph is recorded in git history as trailers on commits.

**The graph is append-only.** Exactly one commit adds an edge and carries the trailer for it. Edges are never modified; a relationship that changes is a new edge, added by the commit that changes it. **The table is exhaustive**: an event not in it adds no edge, and a change to an artefact's content that leaves its edges as they were carries no trailer.

| Trailer | On the commit that | Value |
| --- | --- | --- |
| `Derives-From:` | establishes that an artefact derives from another: the first commit on the artefact's branch, or a later commit that re-points it | path of the upstream artefact; one trailer per direct upstream |
| `Revises:` | changes what an accepted ADR decides | path of the ADR |
| `Consumed-By:` | removes a discovery note | path of the ADR it informed |
| `Completes:` | removes a plan whose work is done | path of the plan |
| `Abandons:` | removes a plan whose work will not be done | path of the plan |

Values are repository-relative paths. A commit may carry several trailers, and a key may repeat. Trailers go in the trailer block at the end of the commit message, one per line, in `Key: value` form — not in prose. `git interpret-trailers` and `git log --format='%(trailers:key=Derives-From,valueonly)'` read them back, and neither can see a sentence.

**`Derives-From` sits on the first commit of the artefact's branch, whatever that commit contains**, and names **direct upstreams only**, one trailer per upstream. A skill produced by a plan step names the plan, not the ADR behind it, which is one hop away through the plan's own `adr:` field. An ADR names the discovery note it was written from. Before the first commit, ask what this artefact was produced from and write the path down.

**Trailers record edges between artefacts.** Structure *inside* an artefact — such as the docstring/test/code commit order under `test-first-workflow` — belongs to the governing skill under Rule 3 and carries no trailer. **The body carries the reason**: the prose body of a `Revises`, `Abandons` or deleting commit must say what changed and why, in sentences. Trailers carry the edge, the body carries the reason, and neither is optional.

## Rule 10 — Integration preserves structure

> A branch lands as a **merge commit with two parents**, into the branch it forked from. Never squashed. Never fast-forwarded.

The no-fast-forward merge is what brackets the commits belonging to one artefact. A squash discards the individual commits and their trailers with them, and destroys the red/green sequence `test-first-workflow` and `skill-forge` mandate. A fast-forward keeps the commits but loses the record of which artefact they belonged to.

```sh
git merge --no-ff <branch>
```

Run it from a checkout that has the trunk checked out — normally the primary checkout, since trunk cannot be checked out in two worktrees at once, so you cannot merge into it from the artefact's own worktree. A dirty primary checkout does not block the merge as long as the merge touches different paths, which is the usual case; it is not a reason to disturb the files already sitting there.

## Rule 11 — A pull request is the default; a local merge is the fallback

Propose and land **through the host's pull-request mechanism whenever the repository has a remote whose host provides one**. The local merge is the **fallback**, used when there is no such remote — not an equal alternative chosen by preference. Check with `git remote`: no output means no remote, which means the fallback. Like the fork point, this is derived and never read from configuration or a contributing guide, so a repository with no remote takes the local merge even where its documentation instructs a pull request. Do not invent an `origin`, and do not leave the artefact unlanded in a repository with no remote because a pull request was impossible there; both are failures to land. A refused merge where a remote exists is a different case, below.

**The host is an implementation detail this skill does not know.** The commands for a particular host belong to a **platform skill, which does not yet exist**; until it does, `git-workflow` implements the fallback path only. Where a remote exists, use whatever host tooling the session already provides and hold it to Rule 10's outcome: state the merge action explicitly rather than accepting a default (at least one major host squashes by default), and disable squash and rebase merges at the repository level wherever the host allows it, so the prohibition is enforced rather than merely written down.

**A refused merge ends the procedure at step 7.** When the pull request is open and its merge is refused — by the host, or by the harness's permission layer — stop and report: the pull request URL, the exact command that was refused, and the state left behind (branch pushed, worktree kept, primary checkout not returned to trunk, because Rule 14 runs on merge and nothing merged). Say that allowing the merge command in the harness's permission settings, for example `Bash(gh pr merge *)`, lets future artefacts land unattended. Do **not** take the local-merge fallback: it exists for a repository with no remote, and here it would bypass whoever refused. Do not describe the artefact as landed.

**No host tooling is not the no-remote case.** The fallback is selected by one fact, `git remote` printing nothing, and by nothing else. Where a remote exists but the session has no command that can open a pull request — no `gh`, no host API, or one that fails for want of credentials — push the branch, then stop and report exactly as for a refusal, naming the command that was missing or failed. The pushed branch is what the human opens the pull request from; a local merge into trunk is not a substitute for it, and neither is cleaning up as if something had merged.

**A pull request buys enforcement, and only that.** The platform can refuse a squash and refuse a direct push to trunk. It buys **no review**: an agent that opens a pull request and immediately merges it has been reviewed by nobody. Do not describe such a merge as approved, accepted or signed off. **A decision is landed by a human.** If the branch adds a file under `docs/adr/` or any of its commits carries a `Revises` trailer, push, open the pull request, stop and report, exactly as for a refused merge; do not merge it. Every other artefact the agent lands itself.

## Rule 12 — A plan merges when it is written

A plan's branch merges as soon as the plan is written and reviewed, **before implementation against it begins**; it is not held back until the work it describes is finished. A plan on an unmerged branch is out of reach of an ADR revision that edits every plan in the tree, and if abandoned it leaves no removing commit for `Abandons` to attach to. Merging on creation also fixes the order of work: implementation branches fork from a trunk that already carries the plan.

## Rule 13 — Merging is not mandatory

An experiment may remain unmerged. Its branch and worktree are left in place and are **never** removed automatically. Do not tidy up a branch or a `.worktrees/` directory you did not create, and do not treat an unmerged branch as an error to be cleaned away. Cleanup happens on merge, and only on merge.

## Rule 14 — Cleanup on merge

```sh
git worktree remove .worktrees/<branch>   # --force once dependencies are installed
git branch -d <branch>
```

`--force` is required where dependencies were installed, because removal refuses on untracked files. The now-empty `.worktrees/` parent may stay. Work done **in the primary checkout returns that checkout to trunk**, or the next artefact branches from the previous one. Where the work was isolated the primary checkout never moved: **confirm its branch, do not check it out** — `git rev-parse --abbrev-ref HEAD` answers the question, while `git checkout <trunk>` against a checkout already on trunk changes nothing and writes a spurious line into the reflog. After cleanup, `git branch` shows no artefact branch, `git worktree list` shows only the primary checkout, and HEAD is on trunk.

## Do not

- Do not create or modify a file before the branch for it exists. This is the rule actually broken in practice, and markdown is where it breaks.
- Do not commit an artefact directly onto trunk. If a commit has landed on trunk that should not have, say so rather than quietly leaving it.
- Do not read the trunk, the branch name or the integration path out of `CONTRIBUTING.md`, a README, or git configuration. Derive all three.
- Do not squash, fast-forward, or rebase a branch onto trunk in place of merging it — all three destroy the bracket around the artefact, and the first destroys its trailers as well.
- Do not run `git add -A` or `git commit -a` in a checkout whose dirty state is not yours, and do not `git stash` a checkout to get it clean enough to branch in. That is what the worktree is for.
- Do not copy `.venv/`, `node_modules/` or any other built dependency into a worktree or commit one; do not *move* `.claude/`, `.env` or `.mcp.json` into one — copy them, the base checkout still needs them.
- Do not add a remote or push to satisfy an instruction to open a pull request in a repository that has no remote, and do not leave an artefact unlanded there because a pull request was impossible. Take the fallback.
- Do not merge locally, or push a local merge to trunk, because a pull request could not be opened or its merge was refused. `git remote` printed a remote, so the fallback does not apply: push the branch, stop and report (Rule 11).
- Do not write a relationship between artefacts as a sentence and call it recorded. It goes in a trailer.
- Do not define "artefact" here, adjust an artefact's boundary to suit the branching, or specify what a commit contains. Rules 2 and 3 defer all three to the governing skill.
- Do not remove somebody else's branch or worktree.
- Do not check out a branch that is already checked out, to reassure yourself. Read HEAD instead.

## When you may deviate

- **Read-only exploration.** This skill does not apply. Reading, searching and running tests that change no file need no branch.
- **Work already proceeding on an artefact branch this workflow created.** You are past the branching decision; carry on. Do not re-derive the trunk or branch again mid-artefact.
- **Bookkeeping.** Rule 4's exception, on Rule 4's terms only: it rides with the change that makes it true, and it is exempt from needing a branch and from nothing else.
- **A path outside any git repository.** Nothing here applies; say so rather than running `git init` to make it apply.
- **The user explicitly says to work on trunk, or not to branch.** Follow the instruction, and note the deviation in your reply so it is visible rather than silent.

Deviating because the workflow feels heavy for the change in hand is not on this list. A one-line change takes a short-lived branch like anything else; amending the previous commit instead rewrites published history.
