---
title: Keep the local trunk current after a land from an off-trunk primary
status: draft
adr: 0003
date: 2026-10-19
deferred_reason: null
---

# Keep the local trunk current after a land from an off-trunk primary

## Reference

Implements `docs/adr/0003-git-workflow.md`, for GitHub issue #55. No
related plans are in the tree.

## The defect

On the host path, `cmd_land` fetches and fast-forwards the local trunk
only when the primary checkout's HEAD is the trunk
(`skills/git-workflow/scripts/git-workflow:367-369`). When the artefact
was isolated and the primary is parked on another branch, the step is
skipped and the local trunk stays behind `origin` after a successful
land. The no-remote path has no `origin` to fall behind, so it is
unaffected.

## The fix

Fast-forward the local trunk without checking it out, using
`git fetch <remote> refs/heads/<trunk>:refs/heads/<trunk>`, only when
the primary is not on the trunk. Git refuses the update, and the script
prints a note and carries on, when the local trunk has diverged
(non-fast-forward) or is checked out in any worktree. The primary's
HEAD and files are never touched.

The other two options in #55 are not taken. Returning the primary to
the trunk contradicts ADR 0003's "Where the work was isolated the
primary checkout never moved" (Rule 14 in
`skills/git-workflow/references/RULES.md`: "confirm its branch, do not
check it out") and Rule 5's "its dirty state belongs to somebody else's
work in progress". Leaving only the note keeps the local trunk behind.
No ADR change is needed: the ADR does not mention the trunk
fast-forward, so the plan adds behaviour inside it.

## Steps

1. Branch and fixtures: none needed beyond this plan's branch. Run the
   baseline: `bash skills/git-workflow/scripts/tests/run.sh` passes.

2. Tests first, then code.

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   a. Add three cases at the end of
      `skills/git-workflow/scripts/tests/land.sh`, using the existing
      `artefact "$R/x" --remote origin --where worktree` (which leaves
      the primary on `topic`), `githubify` and `land` helpers. Name each
      `t "github: ..."`:
      - primary parked on `topic`: after `land` exits 0,
        `git rev-parse dev` in the primary equals `bare_tip "$R/x" dev`,
        the primary's HEAD is still `topic`, and its `git status
        --porcelain` is unchanged.
      - local `dev` diverged (before landing, from the primary: `g
        switch -q dev`, commit, `g switch -q topic`): exit 0, output
        contains `could not fast-forward`, local `dev` is unchanged,
        primary still on `topic`.
      - `dev` checked out in another worktree (`g worktree add
        "$R/trunk-wt" dev` before landing, with that worktree's `dev`
        behind): exit 0, output contains `could not fast-forward`, and
        that worktree's HEAD and status are unchanged.
   b. Run `bash skills/git-workflow/scripts/tests/run.sh
      skills/git-workflow/scripts/tests/land.sh`; the first case fails
      (the local trunk is behind). The diverged and checked-out cases
      pass already, as regressions. Commit the tests (red).
   c. In `skills/git-workflow/scripts/git-workflow`, replace the `if`
      at lines 367-369 so that the on-trunk branch is unchanged and an
      `else` branch runs
      `git -C "$primary" fetch -q "$remote" "refs/heads/$trunk:refs/heads/$trunk" 2>/dev/null || printf 'git-workflow: note: could not fast-forward %s to %s/%s\n' "$trunk" "$remote" "$trunk"`.
      Run the full suite; all pass. Commit (green).

3. Update the text that states the behaviour, in the same commit as the
   code or after it:
   - the `land` header comment, step 3, at
     `skills/git-workflow/scripts/git-workflow:234-235`
     ("afterwards fetch and fast-forward the local trunk"): say that
     when the primary is off the trunk the trunk is updated by ref
     without checking it out, or left with a note.
   - `skills/git-workflow/SKILL.md:36`: exit 0 says it "left the primary
     checkout on the trunk"; change to "left the primary checkout where
     it was, or on the trunk where the work was in place", and say the
     local trunk was fast-forwarded or a note says why not.
   - `skills/git-workflow/references/RULES.md`, Rule 14: add one
     sentence that, with the primary left off the trunk, the local trunk
     is advanced by ref and never by switching the primary.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` reports 0 failed.
- By hand in a scratch repository with a GitHub-style remote, as in the
  issue's repro: land from a worktree with the primary on another
  branch; `git rev-parse <trunk> origin/<trunk>` prints one SHA and
  `git rev-parse --abbrev-ref HEAD` in the primary prints the other
  branch.

## Progress notes

None yet.
