---
title: Keep the local trunk current in begin and land
status: in-progress
adr: 0003
date: 2026-10-19
deferred_reason: null
---

# Keep the local trunk current in begin and land

## Reference

Implements `docs/adr/0003-git-workflow.md`, for GitHub issue #55. Verifying
a human's merge is out of scope (issue #103). No related plans are in the
tree.

## Steps

1. Begin the code branch: `bash skills/git-workflow/scripts/git-workflow
   begin skills/git-workflow/scripts/git-workflow --slug
   keep-local-trunk-current`, and work in the `dir=` it prints. Run the
   baseline: `bash skills/git-workflow/scripts/tests/run.sh` reports 0
   failed.

2. Docstrings first.

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Line numbers in steps 2 and 4 are as of b5949b4, before this step's
   commit. In `skills/git-workflow/scripts/git-workflow`, update the
   comments that state the behaviour: the `begin` and `land` entries of the usage
   header (lines 14-27); the exit-1 line (line 43), to include begin's
   stop; `begin`'s function comment (lines 127-149), to say it fetches and
   fast-forwards the local trunk first, or exits 1 and creates nothing; and
   `land`'s function comment (lines 214-254): step 3's "afterwards fetch
   and fast-forward" (lines 236-237), made to apply whether or not the
   primary is parked, and to say that a primary on the trunk with tracked
   changes, behind the remote, gets a note and no fast-forward, and step 4's confirm-HEAD sentences (lines 250-254),
   made to say a parked primary is left where it was. Add the comment
   heading `sync_trunk` (below); its body comes in step 4. Commit,
   titled `Document that begin and land keep the local trunk current`,
   with the trailer `Derives-From:
   plans/0014-keep-local-trunk-current-after-land.md`, and with the plan's
   `status:` flipped to `in-progress` in the same commit.

3. Tests, then red.

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   a. In `skills/git-workflow/scripts/tests/begin.sh`, add a helper
      `advance_origin DIR` that clones `DIR/.origin/repo.git`, switches to
      `dev` (the bare repository's HEAD names no branch), commits and pushes. Add six cases, each with `fixture "$R/<name>"
      --trunk dev --remote origin` and `begin` on
      `docs/adr/0002-x.md`:
      - remote ahead, primary on `dev` and clean: after `begin`, local
        `dev` equals `bare_tip`, and so does the new branch.
      - remote ahead, primary parked on `topic` (`--branch topic`, then
        `g switch -q topic`): local `dev` equals `bare_tip`, the primary
        is still on `topic`, and the worktree branch starts at `bare_tip`.
      - the fetch fails: `--remote-url /nonexistent/repo.git`. Exit is 1,
        the output contains `could not fetch`, no `adr-0002-x` branch
        exists and `.worktrees` does not.
      - primary on `dev` and clean, with a local `dev` commit the remote
        lacks (the remote not ahead, so `merge --ff-only` alone would
        pass): exit 1, output contains `could not fast-forward`, local
        `dev` unchanged, no branch. In the same case, repeat with the
        remote ahead too (diverged).
      - primary on `dev` with a tracked file modified, remote ahead: exit
        1, output contains `could not fast-forward`, local `dev` and the
        file unchanged, no branch.
      - `dev` checked out in another worktree (`g worktree add
        "$R/trunk-wt" dev`, primary parked on `topic`), remote ahead:
        exit 1, no branch, that worktree's `dev` unchanged. Git refuses
        a fetch into a branch checked out in a worktree; this depends on
        the installed git version.
      `begin.sh` has no `bare_tip`; copy the one-line helper from
      `land.sh`.
   b. In `skills/git-workflow/scripts/tests/land.sh`, after the last
      `github:` case, add three cases named `t "github: ..."`, each with
      `artefact "$R/x" --remote origin --where worktree` (primary left on
      `topic`), `githubify` and `land`. Each asserts exit 0, that the
      primary's HEAD is still `topic`, and that the output contains
      `as <short bare_tip dev>`, the merge commit:
      - parked primary: `git rev-parse dev` in the primary equals
        `bare_tip`, and its `git status --porcelain` is unchanged.
      - local `dev` diverged (after `artefact`, `g switch -q dev`,
        commit, `g switch -q topic`): output contains `could not
        fast-forward`, local `dev` is unchanged.
      - `dev` checked out in another worktree, behind (`g worktree add
        "$R/trunk-wt" dev` after `artefact`): output contains `could not
        fast-forward`, and that worktree's HEAD and status are unchanged.
   c. Run `bash skills/git-workflow/scripts/tests/run.sh`. All nine new
      cases fail. In `begin.sh`, `begin` exits 0 and branches from the
      stale trunk in the first, second, fifth and last cases, and
      succeeds despite the unreachable remote and the diverged or ahead
      trunk in the third and fourth. In `land.sh`, the skipped update
      leaves local `dev` behind, prints no note, and the `landed ... as`
      line shows the stale local `dev`, not the merge commit. Existing
      cases still pass. Commit the tests (red), titled `Test that begin
      and land keep the local trunk current (red)`.

4. Code, then green.

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   In `skills/git-workflow/scripts/git-workflow`:
   - Add `sync_trunk PRIMARY REMOTE TRUNK`, which prints nothing on
     success and, on failure, one line and returns 1. Every git command in it is
     `git -C PRIMARY`, and git's own stderr is suppressed: the one line is
     the report. It runs `git -C PRIMARY fetch -q REMOTE`; if that fails the
     line is `could not fetch REMOTE`. Every later failure prints `could
     not fast-forward TRUNK to REMOTE/TRUNK: local TRUNK has commits
     REMOTE/TRUNK lacks; push them if they belong on the trunk, or reset
     TRUNK to REMOTE/TRUNK if they do not` when the ancestry check fails,
     and `could not fast-forward TRUNK to REMOTE/TRUNK` otherwise. Then,
     whatever the primary's position: `git -C PRIMARY merge-base
     --is-ancestor TRUNK REMOTE/TRUNK` must pass, so a
     local trunk with commits the remote lacks stops here and never
     reaches a `merge`. If the two are equal it returns 0. Otherwise,
     when PRIMARY's HEAD is TRUNK it requires `git -C PRIMARY status
     --porcelain --untracked-files=no` to be empty (a dirty primary behind the remote
     stops: begin never touches its files) and runs `git -C PRIMARY
     merge -q --ff-only REMOTE/TRUNK`; when it is not, it runs `git -C
     PRIMARY fetch -q REMOTE refs/heads/TRUNK:refs/heads/TRUNK`, which git refuses where TRUNK is
     checked out in another worktree. Move the primary-path lookup at line
     323 (`git worktree list --porcelain | awk ...`) into a function both
     commands call.
   - In `cmd_begin`, after the "already exists" check at line 197 and
     before the branch or worktree is created (lines 198-204), when the
     remote is not `none`, set `msg=$(sync_trunk ...)` and, on failure,
     `die 1 "$msg; no branch created"`.
   - In `cmd_land`, replace the `if [ "$(git -C "$primary" rev-parse --abbrev-ref HEAD)" = "$trunk" ]`
     block (lines 369-371) with `sync_trunk`,
     printing `git-workflow: note: $msg` on failure, whether or not the
     primary is on the trunk. Read the merge commit with `git ls-remote
     "$remote" "refs/heads/$trunk"` immediately after the host merge, and
     use its first seven characters in the `landed ... via ... as` line
     at line 373 in place of the local trunk's short SHA (omit ` as
     <sha>` when `ls-remote` fails).
   - Drop the note at line 290 (`primary checkout is on X, not the
     trunk`): a parked primary is now expected.
   - `skills/git-workflow/SKILL.md`: line 28, in `begin`'s paragraph (`begin` also brings the
     local trunk current, or stops with a report; when it exits 1, relay
     the report in full and do not create the branch by hand), line 36 (exit 0 left
     the primary checkout where it was, or on the trunk where the work
     was in place, and the local trunk is current or a note says why not).
   - `skills/git-workflow/references/RULES.md`: in Rule 6 (line 23), one
     sentence that, where a remote exists, the branch starts from a local
     trunk just fast-forwarded to the remote's, which is not integration
     and so not Rule 10's merge; and in Rule 14 (line 91) that, with the
     primary left off the trunk, the local trunk is advanced by ref and
     never by switching the primary, and its closing "HEAD is on trunk"
     becomes "HEAD is where it was, or on trunk where the work was in
     place".
   Run the full suite; all pass. Commit (green), titled `Keep the local
   trunk current in begin and land (green)`.

5. Delete this plan in the final commit, titled `Complete plan 0014`,
   whose body says that `begin` now fast-forwards the local trunk or
   stops, `land` keeps it current whether or not the primary is parked,
   and the landed message reports the merge commit. Its trailer:
   `Completes: plans/0014-keep-local-trunk-current-after-land.md`. Then,
   from the code branch's `dir=`, land it: `bash
   skills/git-workflow/scripts/git-workflow land` exits 0.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` reports 0 failed.
- `grep -n "on the trunk\|on trunk\|where it was"
  skills/git-workflow/SKILL.md skills/git-workflow/references/RULES.md
  skills/git-workflow/scripts/git-workflow` shows no statement that the
  primary is always left on the trunk, and the wrapped `land` header
  entry in the script (lines 14-27) is read to say the same.

## Progress notes

- Step 1: `begin` ran in place; the branch is `chore-keep-local-trunk-current`
  in the primary checkout. Baseline 58 tests, 0 failed.
- Step 2: `sync_trunk`'s comment heading lands with a stub body
  (`return 1`), unused until step 4.
- Step 3, deviation: the `begin.sh` case for a local trunk with commits
  the remote lacks repeats the diverged half on its own fixture
  (`$R/k4d`) rather than the first half's. Against the old script the
  first half creates `adr-0002-x`, so a repeat on the same fixture failed
  on "branch already exists" instead of on the missing sync; on a fresh
  fixture each half fails for the reason step 3c gives.
- Step 3, additions beyond the listed assertions: the ahead and diverged
  halves also assert the output contains `local dev has commits origin/dev
  lacks`, the worktree-held-trunk case in `begin.sh` also asserts `could
  not fast-forward` and that the other worktree is still on `dev`, and a
  `has_branch` helper tests for absence. Red: 67 tests, 9 failed, exactly
  the nine new cases.
- Step 4: `cleanup_after_merge` keeps its positional `trunk` argument but
  no longer reads it, since the note that used it is dropped. Green: 67
  tests, 0 failed; `shellcheck` clean.
