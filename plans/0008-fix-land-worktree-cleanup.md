---
title: Fix land's worktree cleanup so the host merges and the script cleans up
status: in-progress
adr: 0003
date: 2026-09-25
deferred_reason: null
---

# Fix land's worktree cleanup so the host merges and the script cleans up

## Reference

Fixes a defect in the implementation of `docs/adr/0003-git-workflow.md`
(the `land` cleanup path). Behaviour the ADR specifies — two-parent
merge, remote branch deleted, worktree and local branch cleaned up,
primary left on trunk — is unchanged; only *which component* performs
the teardown moves. So this is a defect fix, not a revision: ADR 0003
is not edited. Captured as GitHub seed #46; no related plans are in the
tree.

## The defect

`land` merges correctly but its worktree cleanup misbehaves whenever
the artefact was isolated into a worktree. Observed twice on
2026-09-25 via two triggers:

- primary checkout parked on another artefact branch, off-trunk (#46);
- primary checkout on trunk but dirty, so `begin` isolated and `land`
  ran from inside the worktree (PR #52).

Root cause: the GitHub host module runs
`gh pr merge --merge --delete-branch`
(`skills/git-workflow/scripts/hosts/github`). Real `gh` on
`--delete-branch` deletes the remote branch, then tries to delete the
local branch — removing its worktree **without `--force`**. The
worktree holds the untracked config files `begin` copies in, so gh
cannot remove it, prints
`! Could not remove worktree …; skipping local branch delete … use --force`,
and bails; only then does the script's own `cleanup_after_merge`
force-remove it. The result is correct but the message looks like a
failure and the exit is nonzero.

The 48 shell tests miss it because `tests/stub-gh` reproduces only gh's
*remote-side* merge, not its *local* branch/worktree side-effects, so
every test stays green while reality fails.

## Fix

One owner for teardown: the host merges; the script cleans up.

- `skills/git-workflow/scripts/hosts/github`: merge only —
  `gh pr merge <branch> --merge` (drop `--delete-branch`); update its
  usage comment.
- `skills/git-workflow/scripts/git-workflow`: `cleanup_after_merge`
  takes `remote`, `cd`s to the primary checkout before removing the
  worktree (so removal never pulls the running process's CWD away),
  keeps the `--force` worktree removal and local `branch -d/-D`, and —
  when a remote exists — deletes the remote branch itself
  (`git -C "$primary" push --delete`, best-effort), replacing what
  `--delete-branch` used to do. Both call sites pass `remote`. Update
  `land`'s contract comment to say the host merges and the script owns
  cleanup including the remote branch.
- `skills/git-workflow/scripts/tests/stub-gh`: stop deleting the remote
  branch, matching the module's new contract (the script now does it,
  and the two must not race).

## Steps

Step 1's first commit flips this plan to `in-progress`. All work is
shell scripts and shell tests — no tessl credits.

### Step 1 — Fix the cleanup path, tests first

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Order within the step, observable in the commit sequence (tests before
code):

1. In `skills/git-workflow/scripts/tests/land.sh`, add regression cases
   that fail against the current script and pass after the fix:
   - **land from inside the worktree, both triggers.** A helper that
     runs `land` from the *worktree* (`$wd`), for (a) primary off-trunk
     and (b) primary on-trunk-but-dirty, both GitHub. Assert each:
     `exit=0`; output contains neither `could not remove worktree` nor
     `contains modified`; the `.worktrees/…` dir is gone; local branch
     gone; `dev` has two parents; primary ends on `dev`.
   - **remote branch is deleted by the script.** In a successful GitHub
     merge, assert the branch is absent from the bare origin.
2. Teach `tests/stub-gh` to emulate real gh only *when `--delete-branch`
   is passed*: attempt a non-`--force` worktree removal and local branch
   delete in the caller's repo, printing gh's warning on failure. This
   makes the current (flag-passing) module reproduce the bug, so the
   step-1 cases fail now; once the module drops the flag the emulation
   never fires and they pass. Then remove the stub's own remote-branch
   deletion so the new remote-branch assertion is the script's to
   satisfy.
3. Apply the fix in `hosts/github`, `git-workflow` and confirm the suite
   goes green.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` — all green, including
  the new regression and remote-branch cases.
- Reverting the `--delete-branch` drop makes the new inside-the-worktree
  cases fail again (proves they exercise the path, not a vacuous pass).
- No `tessl eval run`: the mechanism is covered by shell tests, per the
  eval-vs-unit-test division.
- Real-world smoke (no credits): a subsequent worktree-isolated `land`
  prints no `could not remove worktree` line and exits 0.
- On completion, close seed #46, referencing the landing commit.

## Progress notes

- 2026-09-25: Plan written from the #46 diagnosis and the second
  reproduction on PR #52's land. Governed by ADR 0003; no ADR change
  because behaviour is unchanged. Ironically, landing this plan and its
  fix will run through the same worktree-isolated `land` path (primary
  is dirty), so the fix is exercised on its own way in.
