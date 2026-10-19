---
title: Keep the local trunk current in begin and land
status: draft
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

2. Tests first, then code.

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   a. In `skills/git-workflow/scripts/tests/begin.sh`, add a helper
      `advance_origin DIR` that clones `DIR/.origin/repo.git`, commits to
      `dev` and pushes. Add five cases, each with `fixture "$R/<name>"
      --trunk dev --remote origin` and `begin` on
      `docs/adr/0002-x.md`:
      - remote ahead, primary on `dev` and clean: after `begin`, local
        `dev` equals `bare_tip`, and so does the new branch.
      - remote ahead, primary parked on `topic` (`--branch topic`, then
        `g switch -q topic`): local `dev` equals `bare_tip`, the primary
        is still on `topic`, and the worktree branch starts at `bare_tip`.
      - the fetch fails: `--remote-url /nonexistent/repo.git`. Exit is 1,
        the output contains `fetch`, no `adr-0002-x` branch exists and
        `.worktrees` does not.
      - local `dev` has a commit the remote lacks: exit 1, output
        contains `fast-forward`, local `dev` unchanged, no branch.
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
   c. Run `bash skills/git-workflow/scripts/tests/run.sh`. All eight new
      cases fail. In `begin.sh`, `begin` exits 0 and branches from the
      stale trunk in the first, second and last cases, and succeeds
      despite the unreachable remote and the diverged trunk in the third
      and fourth. In `land.sh`, the skipped update leaves local `dev`
      behind, prints no note, and the `landed ... as` line shows the
      stale local `dev`, not the merge commit. Existing cases still pass.
      Commit the tests (red), titled `Test that begin and land keep the
      local trunk current (red)`, with the trailer `Derives-From:
      plans/0014-keep-local-trunk-current-after-land.md`, and with the
      plan's `status:` flipped to `in-progress` in the same commit.
   d. In `skills/git-workflow/scripts/git-workflow`:
      - Add `sync_trunk PRIMARY REMOTE TRUNK`. It runs `git -C PRIMARY
        fetch -q REMOTE`, then, when PRIMARY's HEAD is TRUNK,
        `git -C PRIMARY merge -q --ff-only REMOTE/TRUNK`, otherwise
        `git -C PRIMARY fetch -q REMOTE refs/heads/TRUNK:refs/heads/TRUNK`,
        and returns the first failure. Move the primary-path lookup at
        line 323 (`git worktree list --porcelain | awk ...`) into a
        function both commands call.
      - In `cmd_begin`, after the "already exists" check at line 197 and
        before the branch or worktree is created (lines 198-204), when
        the remote is not `none`, call `sync_trunk` and `die 1` with a
        report naming the remote and trunk on failure, creating nothing.
      - In `cmd_land`, replace the `if` at lines 369-371 with a call to
        `sync_trunk` that prints the existing `could not fast-forward`
        note on failure, whether or not the primary is on the trunk. Read
        the merge commit with `git ls-remote "$remote" "refs/heads/$trunk"`
        immediately after the host merge, and use its first seven
        characters in the `landed ... via ... as` line at line 373 in
        place of the local trunk's short SHA (omit ` as <sha>` when
        `ls-remote` fails).
      - Update the text that states the behaviour: the `begin` and `land`
        header comments (lines 14-27 and 233-236), and the exit-1 line at
        line 43, to include begin's stop.
      - `skills/git-workflow/SKILL.md`: line 28 (`begin` also brings the
        local trunk current, or stops with a report) and line 36 (exit 0
        left the primary checkout where it was, or on the trunk where the
        work was in place, and the local trunk is current or a note says
        why not).
      - `skills/git-workflow/references/RULES.md`: add one sentence to
        Rule 6 (the fork point, line 23) that the branch starts from a local trunk
        just fast-forwarded to the remote's, and to Rule 14 (line 91)
        that, with the primary left off the trunk, the local trunk is
        advanced by ref and never by switching the primary; and change
        its closing "HEAD is on trunk" to "HEAD is where it was, or on
        trunk where the work was in place".
      Run the full suite; all pass. Commit (green), titled `Keep the
      local trunk current in begin and land (green)`.

3. Delete this plan in the final commit, titled `Complete plan 0014`,
   whose body says that `begin` now fast-forwards the local trunk or
   stops, `land` keeps it current whether or not the primary is parked,
   and the landed message reports the merge commit. Its trailer:
   `Completes: plans/0014-keep-local-trunk-current-after-land.md`.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` reports 0 failed.
- `git diff dev -- skills/git-workflow/SKILL.md
  skills/git-workflow/references/RULES.md` shows no remaining statement
  that the primary is always left on the trunk.

## Progress notes

None yet.
