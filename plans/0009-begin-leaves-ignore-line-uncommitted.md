---
title: Fix begin's bookkeeping commit and config copy, and bring git-workflow-0 up to date
status: in-progress
adr: 0003
date: 2026-09-28
deferred_reason: null
---

# Fix begin's bookkeeping commit and config copy, and bring git-workflow-0 up to date

## Reference

Fixes two defects in the implementation of `docs/adr/0003-git-workflow.md`
(the script's `begin`), and brings `evals/git-workflow-0` into line with
ADR 0003's revision that a branch adding an ADR is merged by a human
(PR 33). Behaviour the ADR specifies is unchanged, so ADR 0003 is not
edited. Found by plan 0005 Step 6 on 2026-09-28; plan 0005 Step 7 waits
on this plan's Step 4.

## The defects

**1. `begin`'s bookkeeping commit makes `land` refuse.** When the
repository's `.gitignore` lacks `.worktrees/`, `begin` adds the line in
the new worktree and commits it on the artefact branch
(`skills/git-workflow/scripts/git-workflow`, "Gitignore the worktree
directory this workflow creates"). That commit has no trailer and is the
first commit since the fork point, so `land` exits 2: "the first commit
since the fork point carries no Derives-From trailer". Every first
worktree-isolated artefact in a repository hits it. Reproduced locally
on the `git-workflow-0` fixture; the eval's agents recovered only by
squashing.

The fix: `begin` adds the line and leaves it **uncommitted** in the
worktree, and says so in its output, so the line rides on the artefact's
first commit — which carries the trailer. Rule 4 (bookkeeping rides with
the change that makes it true) is met without a commit that records
nothing of its own. `references/RULES.md` currently instructs "commit it
there"; that sentence changes.

**2. `begin`'s configuration copy nests.** `copy_if_present` runs
`cp -R "$root/.claude" "$wt/.claude"`. Where `.claude/` is tracked, it
already exists in the new worktree, so `cp` copies the primary's
`.claude/` *inside* it: `settings.local.json` lands at
`.claude/.claude/settings.local.json`, where the harness never reads it,
and the worktree silently loses its local permissions. This is how
`.claude/.claude/skills/release/SKILL.md` was committed in `44198a1`.

The fix: copy only what git does not track, file by file into the same
relative path, never overwriting a file already present in the worktree.
Remove the stray tracked `.claude/.claude/` in the same change.

The 48 shell tests miss both: every `begin.sh` fixture already ignores
`.worktrees/`, and none tracks a directory that is also copied.

## The instrument

`evals/git-workflow-0` asks for an ADR in a repository with no remote
and scores a local two-parent merge into `dev` plus cleanup. Its
criteria predate PR 33 (last edited 2026-09-22). Under the script,
`land` correctly stops with exit 3 ("this branch is a decision and there
is no remote to propose it on"), and the merge, merge-shape, branch-name
(read from the merge reflog) and cleanup criteria score 0. Plan 0005
Step 6's after runs scored 37, 49, 41 for that reason.

## Steps

Step 1's first commit flips this plan to `in-progress`.

### Step 1 — `begin` leaves the ignore line uncommitted

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

1. Update `begin`'s contract comment: where it adds `.worktrees/` to
   `.gitignore` it leaves the change uncommitted in the worktree and
   prints `include=.gitignore` after `dir=`; it makes no commit.
2. In `skills/git-workflow/scripts/tests/begin.sh`, add cases on a
   fixture whose `.gitignore` lacks `.worktrees/` and whose primary is
   dirty: the worktree's HEAD equals the trunk tip; `git status
   --porcelain` in the worktree shows exactly ` M .gitignore`; the
   worktree's `.gitignore` contains `.worktrees/`; the output carries
   `include=.gitignore`. And on a fixture that already ignores it: no
   `include=` line.
3. In `skills/git-workflow/scripts/tests/land.sh`, an end-to-end case
   with no remote and a non-decision artefact (a plan path): `begin` on
   that fixture, commit the artefact and `.gitignore` together with a
   `Derives-From` trailer, `land` exits 0 with a two-parent merge.
4. Confirm the new cases fail, then change `begin`, and confirm the
   whole suite is green.
5. Update `references/RULES.md` ("add it inside the new worktree and
   commit it there") and the `begin` paragraph of `SKILL.md` to say the
   line is left uncommitted and goes into the artefact's first commit
   when `begin` prints `include=`.

### Step 2 — `begin` copies configuration without nesting

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

1. Update the `copy_if_present` contract comment: copies files that git
   does not track, each to the same relative path in the worktree,
   without overwriting.
2. In `begin.sh`, a case whose fixture tracks `.claude/skills/x.md` and
   has an ignored `.claude/settings.local.json`: after `begin`, the
   worktree has `.claude/settings.local.json`, has no `.claude/.claude`,
   and `git status --porcelain` in the worktree is empty.
3. Confirm it fails, fix `copy_if_present`, confirm the suite is green.
4. Remove `.claude/.claude/` from the tree.

### Step 3 — Bring `git-workflow-0`'s criteria up to date

Edit `evals/git-workflow-0/criteria.json` (and the `context` paragraph)
so a correct run is the exit-3 end state: the ADR is committed on an
`adr-0003-<slug>` branch forked from `dev`; `dev` still equals
`fixture-base-dev` and `main` still equals `fixture-base-main`; the
branch and its worktree are kept (a decision awaits a human); the
primary checkout's dirt is exactly as the fixture left it; the
`.worktrees/` line rides on the branch; the branch's first commit
carries `Derives-From: docs/discovery/0001-event-volume.md`. Replace
the merge, merge-shape and cleanup criteria rather than weakening them:
a run that merges the ADR itself now **fails**. Read the branch name
from `git branch`, not the merge reflog. Run `tessl eval lint evals/`.

### Step 4 — Measure (about 40 credits)

On `deepseek-v4.1-flash`, `--context . --skip-baseline --agent claude`:

1. `evals/git-workflow-0`, `-n 3`, with this plan's changes. Bar: median
   at least 87, plan 0005 Step 6's bar for this scenario.
2. `evals/git-workflow-0`, `-n 1`, with the `v0.1.1` body as context
   (a worktree at the tag; `--context-commit` does not work for a plugin
   context). It must score under 87: the old body merges the ADR
   locally, which the updated criteria now fail. This is the
   per-criterion check that the changed criteria discriminate.

Record run ids and per-repeat scores here and in plan 0005's Progress
notes, where they replace Step 6's `git-workflow-0` after runs.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` — all green,
  including the new `begin` and `land` cases.
- Reverting either fix makes its new cases fail again.
- In this repository, `begin` into a worktree leaves
  `.claude/settings.local.json` in place and no `.claude/.claude`.
- `tessl eval lint evals/` is clean.
- Step 4's two runs meet their bars.

## Progress notes

- 2026-09-28: Plan written from plan 0005 Step 6's `git-workflow-0`
  collapse. Defect 1 reproduced by hand on the fixture; defect 2 seen
  when `begin` created this plan's own worktree.
