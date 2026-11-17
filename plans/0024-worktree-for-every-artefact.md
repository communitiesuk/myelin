---
title: A worktree for every artefact branch
status: in-progress
adr: 0003
date: 2026-11-17
deferred_reason: null
---

# A worktree for every artefact branch

## Reference

Implements the revision of `docs/adr/0003-git-workflow.md` merged in
f8f2a93 (PR #201): every artefact branch is created with its own
worktree at `.worktrees/<branch>`, there is no in-place path, no
session works in the primary checkout, and the plugin's documentation
tells new teams that the worktree path is longer. ADR 0007's restatement
of the rule is already reconciled (b572550). Closes seeds #143
(concurrent sessions collide) and #112 (dropped files trip `begin`).
Seed #200 (strays in the primary checkout) is not this plan's.

## Deferrals

The revision's auto-defer (2578335) left 22 `Defers:` against ADR 0003,
each "until a plan derives from it". This plan's introducing commit
carries `Derives-From: docs/adr/0003-git-workflow.md`, so its landing
brings all 22 due, and `land` refuses this plan's branch without a
discharge verdict for each (ADR 0012). Each was judged against the
revised ADR by reading it.

| Downstream | Verdict | Why | Where |
| --- | --- | --- | --- |
| `skills/git-workflow/scripts/tests/begin.sh` | `Defers:` to this plan, then `Reconciles:` | tests branching in place | Step 1 |
| `skills/git-workflow/scripts/tests/check.sh` | `Defers:`, then `Reconciles:` | tests the `contention=` line | Step 2 |
| `skills/git-workflow/scripts/tests/land.sh` | `Defers:`, then `Reconciles:` | `--where in-place` fixtures and in-place landing | Step 3 |
| `skills/git-workflow/SKILL.md` | `Defers:`, then `Reconciles:` | description, "isolates ... when", exit 0 | Step 4 |
| `skills/git-workflow/references/RULES.md` | `Defers:`, then `Reconciles:` | Rule 5 and Rule 14 | Step 4 |
| `.claude/skills/release/SKILL.md` | `Defers:`, then `Reconciles:` | branches with `git switch -c` in the primary checkout, expects HEAD on `dev` throughout, and switches the primary at merge | Step 6 |
| `evals/git-workflow-0/criteria.json`, `scenario.json` | `Defers:`, then `Reconciles:` | name the contention check as the reason for isolating | Step 7 |
| `skills/git-workflow/scripts/tests/lib.sh`, `contract.sh`, `run.sh` | `Confirms:` | fixture builder, `--help` words and runner state no isolation rule; `--dirty` stays a legitimate fixture | Landing |
| `skills/plans/SKILL.md`, `skills/facilitated-discovery/SKILL.md` | `Confirms:` | say `begin` and "edit in place" (a file edit), never when it isolates | Landing |
| `evals/plan-numbering-0/criteria.json`, `scenario.json`, `setup.sh`, `task.md` | `Confirms:` | score only the number a plan is given, which does not depend on where its branch lives | Landing |
| `docs/adr/0006-where-do-captured-ideas-live.md`, `docs/discovery/0003-escalation-and-orchestration.md`, `docs/discovery/0005-compression-and-handover.md` | `Confirms:` | none states the isolation rule; a note records the thinking of its time | Landing |
| `.gitignore`, `AGENTS.md` | `Confirms:` | `.worktrees/` is already ignored; `AGENTS.md` states no isolation rule | Landing |

That is 8 files re-deferred and 14 confirmed: 22.

**Landing.** After the closing pass, if any, and before `land`, commit,
empty, `Account for ADR 0003's deferrals at plan 0024's landing`,
carrying:

- one `Confirms:` for each of the 14 files the table confirms at
  Landing, its body giving the reasons in the table.
- for each of the eight files the table reconciles in a step,
  `Defers: <file> plans/0024-worktree-for-every-artefact.md until plan 0024's implementation lands`,
  its body saying the implementation branch reconciles them. ADR
  0011's anchor rule governs a chain's root, here ADR 0003; a re-defer
  answers to ADR 0012's escape alone (the same course as plan 0023,
  f30cec3).

The implementation branch's first commit carries
`Derives-From: plans/0024-worktree-for-every-artefact.md`, so `land`
refuses it until each of the eight carries `Reconciles:`. The
trailers go in the same last paragraph as `Co-Authored-By`.

Not downstream of ADR 0003 in the graph, and so carrying no verdict,
but edited because they state the rule or depend on in-place work:
`README.md` (Step 5), `evals/git-workflow-1/`, `evals/plans-0/` and
`evals/plans-1/` (Step 7), `skills/git-workflow/scripts/tests/autodefer.sh`
(Steps 1 and 3) and `discharge.sh` (Step 3), and the comments in
`skills/git-workflow/scripts/git-workflow.sh`.

## Steps

Steps 1 to 9 run on one implementation branch, `chore-worktree-for-every-artefact`.
Begin it with `begin skills/git-workflow/scripts/git-workflow.sh --slug worktree-for-every-artefact`,
and work in `dir=` by absolute path. Until this plan lands, the installed
rule governs how that branch is made, and the installed script, not the
one being edited, does the `begin` and the `land` throughout.

1. **`begin` always makes a worktree, and makes it under the primary checkout.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   In `skills/git-workflow/scripts/git-workflow.sh`, `cmd_begin`:
   - stop reading `contention=` from `check`; delete the in-place
     branch (`git switch -c` in the primary checkout);
   - take `root` from `primary_checkout`, not
     `git rev-parse --show-toplevel`. Run from inside a worktree, `begin`
     now nests the new worktree inside that one
     (`.worktrees/a/.worktrees/b`), which this ADR's
     `.worktrees/<branch>` inside the repository does not mean, and
     every session now runs from a worktree;
   - the doc-comment says so: no in-place branching; strays and a
     dirty primary checkout do not change where the branch goes, though
     `begin` still makes `sync_trunk`'s stops, unchanged; and `begin` never touches the primary checkout's
     files (its trunk update excepted).

   Tests, `skills/git-workflow/scripts/tests/begin.sh` (red first):
   - replace "in place: on the trunk and clean, the primary checkout
     moves" with: on a clean trunk, `dir=` is `.worktrees/<branch>`,
     the primary checkout is still on the trunk at the same tip, and
     the config files are copied;
   - on the trunk with an untracked file only (the #112 case): a
     worktree, the stray untouched;
   - `begin` run from inside an existing worktree puts the new one at
     `<primary>/.worktrees/<branch>`, not under the first;
   - two `begin`s on different slugs in one repository with no remote,
     the second while the first's worktree exists: both succeed, at
     distinct `.worktrees/` paths;
   - rename "worklist ... in place" to match; keep the worktree tests;
   - fix the file's header comment (line 1, "branch in place or into a
     worktree");
   - correct `skills/git-workflow/scripts/tests/autodefer.sh`'s comment
     that `begin` is in-place on a clean trunk.

   Commits, in order: docstring and the test changes failing, then
   the code. The first carries
   `Derives-From: plans/0024-worktree-for-every-artefact.md`; the last
   carries `Reconciles: skills/git-workflow/scripts/tests/begin.sh`.
   Flip this plan's `status` to `in-progress` in the first.

2. **`check` stops reporting contention.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   In `git-workflow.sh`: delete `derive_contention` and the
   `contention=` line from `cmd_check`, and from its doc-comment, the
   header's `check` summary and the "Prints four lines" comment (now
   three). In `skills/git-workflow/scripts/tests/check.sh`, replace the
   three `contention:` tests with one asserting that, on a clean trunk,
   on a dirty trunk and on another branch, the output is exactly
   `trunk=`, `remote=`, `host=` and no `contention=` line; fix the file's
   header comment. Red first, then code.
   The last commit carries `Reconciles: skills/git-workflow/scripts/tests/check.sh`.

3. **`land` has no in-place path, and refuses the primary checkout.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   In `cmd_land`: delete `inplace` and both `git switch -q "$trunk"`
   lines (the no-remote merge and before the host merge); the
   "primary checkout on neither" stop remains the guard for the local
   merge. Add to step 1's refusals (exit 2, nothing changed): the
   artefact's checkout is the primary checkout, with a message saying
   artefact branches live in `.worktrees/<branch>` and `land` runs from
   there; the existing refusal for HEAD on the trunk is unchanged. Update
   the doc-comments (the header's `land` summary, steps 1, 3 and 4,
   "Where the work was in place", and the `stop` and
   `cleanup_after_merge` text) to say the primary checkout is left
   where it was, always.

   Tests, `skills/git-workflow/scripts/tests/land.sh` (red first):
   - `artefact` loses `--where`; every fixture is a worktree, so the
     ~25 callers drop `--where in-place`. The `g switch -q -c topic`
     that forced a worktree becomes an option, `--park`, that parks the
     primary on `topic` before `begin`; m3, k1 to k3 and wc1, which
     assert a primary off the trunk, pass it;
   - primary-checkout assertions that it "must stay on the branch" or
     that the refusal "must change nothing" by naming the artefact
     branch (lines 85, 148, 204, 495) now expect `dev`, because the
     primary never leaves the trunk;
   - the `abandoning` helper begins "in place" and commits no
     `.worktrees/` ignore line; it now begins a worktree, and commits
     the line as `artefact` does (line 46) so `begin` leaves nothing
     uncommitted; ab5 drops `--where`. The `abandonment` helper (abg1 to
     abg4, including the skill-deleted tests) has the same gap, and the
     `revision` helper's comment that `begin` is in place and `wd` is the
     repository root is stale: fix both, and correct the "begun in place"
     comments;
   - rev9 asserts that the primary is still on `adr-0001-one` after the
     hard stop; it is on `dev`. r3 lands from the primary on branch
     `empty`, which `land` now refuses for being the primary checkout
     before it reaches "nothing since the fork point"; build `empty` as a
     worktree and land that, so the test still tests the empty branch;
   - in `skills/git-workflow/scripts/tests/autodefer.sh`, test 8 lands
     the repository root (`land "$R/t5"`), which `land` now refuses;
     land `$R/t5/.worktrees/adr-0001-one`. In
     `skills/git-workflow/scripts/tests/discharge.sh`, test 14's `base`
     commits no `.worktrees/` ignore line, so the `.gitignore` that
     `begin` writes in the worktree stays uncommitted and `land`
     refuses it as dirty before the check under test; commit the line
     in `base`. Run all three files (`land.sh`, `autodefer.sh`,
     `discharge.sh`) after Step 1's change and fix any other test that
     fails the same way;
   - new: `land` run from the primary checkout on an artefact branch
     exits 2, naming `.worktrees/`, and changes nothing;
   - rename the "merge in place" tests to say what they test; the
     primary ends on the trunk because it never left it; fix m2's stale
     comments ("primary back on trunk", "the helper's own switch to
     topic"), which no longer describe the fixture;
   - update the header's coverage line for git-workflow-0 #3.

   The last commit carries `Reconciles: skills/git-workflow/scripts/tests/land.sh`.

4. **State the rule in the skill and its rules file.**

   `skills/git-workflow/SKILL.md`: in `description`'s opening sentence
   (its trigger and skip clauses unchanged), "worktree isolation on
   contention" becomes "a worktree for every artefact". In "The two moments":
   `begin` "creates the branch together with its worktree" instead of
   isolating "when the checkout is not on the trunk or is dirty", and
   "Work in `dir=` and nowhere else" gains "never in the primary
   checkout"; the `land` exit 0 bullet loses "or on the trunk where the
   work was in place"; the exit 2 bullet adds running `land` from the
   primary checkout. "What the script decides": "whether to isolate and
   where" becomes "where the worktree goes". "Do not": the stash and
   `git add -A` line is unchanged, including "that is what the
   worktree is for", which stays true.
   `skills/git-workflow/references/RULES.md`: retitle Rule 5 "Every
   artefact branch gets its own worktree" (keep the number; evals cite
   it), give the command, the reason (parallel sessions share one HEAD in
   the primary checkout, and a check made once at branching cannot hold),
   that git refuses a branch checked out twice so no lock is needed, and
   that the `.worktrees/` ignore-line paragraph is unchanged, and drop the
   "When you isolate" lead-in of the paragraph on working inside the
   worktree (the rest, never touching the primary checkout's files, stays); Rule 14:
   cut the "Work done in the primary checkout returns that checkout to
   trunk" sentence, "Where the work was isolated" (the primary checkout
   never moves), and "or on trunk where the work was in place", and qualify "`git worktree list` shows only the primary checkout" to the artefact's own worktree being gone (other sessions' remain); Rule 11's
   refused-merge paragraph loses "primary checkout not returned to trunk"
   from the state left behind, since Rule 14 never returns it.
   Do not edit `.claude/skills/tessl__git-workflow/`; it is a merged
   install of `dev`.
   Commit: `Document a worktree for every artefact in git-workflow (plan 0024 Step 4)`,
   carrying `Reconciles: skills/git-workflow/SKILL.md` and
   `Reconciles: skills/git-workflow/references/RULES.md`.

5. **Document the worktree path for new teams.**
   Location: `README.md`. In "Opinions", replace the
   "Isolation on contention" bullet with "A worktree for every artefact
   branch" (`.worktrees/<branch>`, gitignored; your own checkout stays
   on the trunk and is not worked in); in the skills list (line 62),
   "isolated into a worktree on contention" becomes "in its own
   worktree". Add a short subsection after "Opinions", "Working in a
   worktree": the files are under `.worktrees/<branch>`, a longer path
   than the checkout's; review the change in the pull request, or ask
   the agent to open the file; the agent works by absolute path; the
   worktree is removed when the branch merges, and an unmerged
   experiment's stays. No trailer verdict: `README.md` is not in the
   downstream graph. Commit:
   `Tell new teams where worktrees are (plan 0024 Step 5)`.

6. **Reconcile the release skill.**
   `.claude/skills/release/SKILL.md` (not code, no wrapper): the primary
   checkout stays on `dev`. The skill's section 2 creates the branch with its
   worktree (`git worktree add .worktrees/chore-release-<version> -b chore-release-<version> dev`)
   and the later steps work in it by absolute path. Section 9 merges the
   pull request without local branch deletion, as `land` does, since
   `gh pr merge --delete-branch` cannot delete a branch a worktree
   holds; then, at that one point, removes the worktree, deletes the
   branch and fast-forwards the primary, which is already on `dev`
   (replacing `git switch dev && git pull --ff-only origin dev`);
   section 11's primary-or-scratch rule keeps; section 12 checks that
   the worktree and branch are gone and the primary is on `dev`. Commit:
   `Reconcile the release skill to a worktree per release branch (plan 0024 Step 6)`,
   carrying `Reconciles: .claude/skills/release/SKILL.md`.

7. **Update the evals.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Here the evals are the tests. `--context .` already carries the new
   rule, so a run before editing cannot fail on it: once a fixture is
   edited, run it with Step 8's command plus `--context-commit <fork>`,
   where `<fork>` is `git merge-base dev HEAD`, which sources the old
   skill (expect a failure), and again without it (expect a pass). If
   the old-skill run does not fail, say so in Progress notes and rely on
   the unit tests for that change.
   - `evals/git-workflow-0/`: the fixture is dirty on the trunk, which
     the old rule isolated too, so it does not tell the rules apart.
     Make it a clean trunk: drop the README edit, `benchmark-notes.txt`
     and the untracked `.venv/` (an untracked file would make the old
     rule isolate too); `node_modules/` is already gitignored, so add
     nothing. Reword the criteria and `scenario.json` ("isolate into a
     worktree", "the contention check must select isolation") to "every
     artefact branch gets a worktree", and every description of the
     trunk as dirty, in `criteria.json`'s context, `scenario.json` and
     `setup.sh`'s comments. Rewrite "The primary checkout's own files
     are untouched" as: no path tracked at `fixture-base-dev` differs
     from it (`git diff --name-only fixture-base-dev` in the primary
     prints nothing, so staging the harness does cannot trip it), its
     `HEAD` is still `fixture-base-dev`, and the branch was never
     checked out, with a PRECONDITION: it scores 0 unless `<branch>`
     exists with the ADR committed, so an agent that does nothing
     fails. In "Configuration copied ...", drop the `.venv` clauses
     (keep the settings copy and `node_modules`) and do not move them:
     `skills/git-workflow/scripts/tests/begin.sh` (lines 91-95) already
     asserts that `.venv/` and `node_modules/` are never copied and stay
     in the base checkout, and an eval tests only what cannot be tested
     elsewhere. Fix the setup.sh comments (lines 224 and 288-292). The
     old rule branched in place on the clean trunk, so the old-skill run
     should fail on the right thing.
   - `evals/git-workflow-1/`: the primary sits on `main`, off the trunk;
     reword "the skill's contention check must isolate into a
     worktree" in `criteria.json`'s context and "Rule 5 selects
     isolation" in the "Isolated into a worktree" criterion to "every
     artefact branch gets a worktree", and the setup.sh comment
     "the contention check must select isolation" (line 235); its
     criterion that in-place branching is the failure stays true.
   - `evals/plans-0/` and `evals/plans-1/`: their fixtures check the
     plan branch out in the primary checkout. `plans-0` lands, and
     `land` now refuses that; build the branch as a worktree at
     `.worktrees/plan-0001-forecast-source` with the primary on `dev`,
     using `git worktree add --relative-paths` so it survives the harness
     moving the fixture, and check `git worktree list` in the first
     run's solution directory.
     `plans-1` never reaches `land` (it stops at an escalation), but its
     fixture and context would describe a layout the workflow no longer
     produces; change it the same way. In each, say in `task.md` and the
     `criteria.json` context where the plan is ("checked out in place"
     goes), and fix the `setup.sh` comments that say "checked out in
     place".
   Commit: `Reconcile the git-workflow evals to a worktree per artefact (plan 0024 Step 7)`,
   carrying `Reconciles: evals/git-workflow-0/criteria.json` and
   `Reconciles: evals/git-workflow-0/scenario.json`.

8. **Run the tests and the evals.**
   - `bash skills/git-workflow/scripts/tests/run.sh` and
     `bash skills/history/scripts/tests/run.sh` pass.
   - Run, as plan 0012 did, for `s` in `git-workflow-0` and
     `git-workflow-1` with `-n 3`, and for `s` in `plan-numbering-0`,
     `plans-0`, `plans-1`, `adr-0` and `adr-1` without it (once each):

     ```sh
     tessl eval run evals/$s --context . --skip-baseline --agent claude --model deepseek-v4.1-flash -n 3 -f --label "plan 0024 $s" --wait --json --yes
     ```

     `-f` re-runs previously solved cases, so the paired runs of Step 7
     (old skill, new) are not served from tessl's cache.
     `deepseek-v4.1-flash` is the model `git-workflow`'s `compatibility`
     cites. Read each activation
     record and scorer reasoning, so a failure is classed as "never
     ran the script" or "worked in the primary checkout", not
     "merged wrongly".
   - If a `Confirms:` in the Landing table proves wrong, reconcile that
     file in this step, with its own `Reconciles:`.
   - Update `git-workflow`'s `compatibility` frontmatter to cite the new
     runs and bars if the numbers moved; leave the floor unchanged
     unless they fall below the bars cited there.
   Record the results in Progress notes. Commit:
   `Record the runs of the git-workflow evals (plan 0024 Step 8)`.

9. **Complete.** Delete this plan. Commit `Complete plans/0024-worktree-for-every-artefact.md`
   with the trailer

   ```
   Completes: plans/0024-worktree-for-every-artefact.md
   ```

   and a body that says what the plan produced, and which of the 22
   deferred files were reconciled (8) and which confirmed (14). Add
   `Fixes #143` and `Fixes #112` lines before the trailers so the
   merge closes both seeds.

## Verification

- `begin` on a clean trunk, on a dirty trunk and from inside another
  worktree each print `dir=<primary>/.worktrees/<branch>`; the primary
  checkout is unchanged (`git -C <primary> status --porcelain --untracked-files=no`
  and `rev-parse HEAD` equal before and after).
- Two `begin`s on different slugs in one repository, the second while the
  first's worktree exists, both succeed at distinct worktrees (the
  Step 1 test; a repository with a remote is not claimed).
- `check` prints three lines and no `contention=`.
- `land` from the primary checkout on a non-trunk branch exits 2;
  from the worktree it merges with two parents and leaves the primary
  on the trunk.
- `grep -rn --exclude=check.sh 'contention=\|isolation on contention\|on contention' skills evals/git-workflow-0 evals/git-workflow-1 README.md`
  and `grep -rn -i 'where the work was in place\|--where\|checked out in place\|begun in place\|in-place branching' skills evals --exclude-dir=git-workflow-1 --exclude=git-workflow.sh`
  find nothing (`evals/git-workflow-1`'s criterion names in-place
  branching as the failure, rightly; `check.sh`'s test of the absent
  `contention=` line and `git-workflow.sh`'s `begin` doc-comment,
  "no in-place branching", are the other rightful hits). Other "in place" hits are about editing a file, and
  `evals/scenario-0`'s "contention" is database write contention.
- After landing, `git worktree list` shows no worktree for
  `chore-worktree-for-every-artefact` (other sessions' may remain).
- `history outstanding-deferrals` lists none whose origin is
  `docs/adr/0003-git-workflow.md`, and none naming
  `plans/0024-worktree-for-every-artefact.md`: the eight re-deferred
  files each carry `Reconciles:`.

## Progress notes

- Step 1: the "untracked stray only" test (#112) passes under the old
  code as well, since the old contention check counted untracked files
  as dirt and isolated; it stays as a guard. The "from inside a
  worktree" test parks the primary off the trunk so that the old code
  makes its first worktree too and fails on the nesting alone.
