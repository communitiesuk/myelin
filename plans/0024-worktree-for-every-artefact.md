---
title: A worktree for every artefact branch
status: draft
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
tells new teams that the worktree path is longer. Closes seeds #143
(concurrent sessions collide) and #112 (dropped files trip `begin`).
Seed #200 (strays in the primary checkout) and #84 (numbering race)
are not this plan's.

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
| `evals/git-workflow-0/criteria.json`, `scenario.json` | `Defers:`, then `Reconciles:` | name the contention check as the reason for isolating | Step 6 |
| `skills/git-workflow/scripts/tests/lib.sh`, `contract.sh`, `run.sh` | `Confirms:` | fixture builder, `--help` words and runner state no isolation rule; `--dirty` stays a legitimate fixture | Landing |
| `skills/plans/SKILL.md`, `skills/facilitated-discovery/SKILL.md` | `Confirms:` | say `begin` and "edit in place" (a file edit), never when it isolates | Landing |
| `evals/plan-numbering-0/criteria.json`, `scenario.json`, `setup.sh`, `task.md` | `Confirms:` | score the number a plan is given; no remote, so the local merge works from a trunk-parked primary (Step 7 re-checks it) | Landing |
| `docs/adr/0006-where-do-captured-ideas-live.md`, `docs/discovery/0003-escalation-and-orchestration.md`, `docs/discovery/0005-compression-and-handover.md` | `Confirms:` | none states the isolation rule; a note records the thinking of its time | Landing |
| `.claude/skills/release/SKILL.md` | `Confirms:` | its worktree is a scratch one for publishing | Landing |
| `.gitignore`, `AGENTS.md` | `Confirms:` | `.worktrees/` is already ignored; `AGENTS.md` states no isolation rule | Landing |

That is 7 files re-deferred and 15 confirmed: 22.

**Landing.** After the closing pass, if any, and before `land`, commit,
empty, `Account for ADR 0003's deferrals at plan 0024's landing`,
carrying:

- one `Confirms:` for each of the 15 files the table confirms at
  Landing, its body giving the reasons in the table.
- for each of the seven files the table reconciles in a step,
  `Defers: <file> plans/0024-worktree-for-every-artefact.md until plan 0024's implementation lands`,
  its body saying the implementation branch reconciles them. ADR
  0011's anchor rule governs a chain's root, here ADR 0003; a re-defer
  answers to ADR 0012's escape alone (the same course as plan 0023,
  f30cec3).

The implementation branch's first commit carries
`Derives-From: plans/0024-worktree-for-every-artefact.md`, so `land`
refuses it until each of the seven carries `Reconciles:`. The
trailers go in the same last paragraph as `Co-Authored-By`.

Not downstream of ADR 0003 in the graph, and so carrying no verdict,
but edited because they state the rule or depend on in-place work:
`README.md` (Step 5), `evals/git-workflow-1/`, `evals/plans-0/` and
`evals/plans-1/` (Step 6), and the comments in
`skills/git-workflow/scripts/git-workflow.sh` and
`skills/git-workflow/scripts/tests/autodefer.sh`.

## Steps

Steps 1 to 8 run on one implementation branch, `chore-worktree-for-every-artefact`.
Begin it with `begin skills/git-workflow/scripts/git-workflow.sh --slug worktree-for-every-artefact`.
The script that runs is still the old one, which branches in place when
the primary checkout is on a clean trunk. That is what this plan removes:
if `begin` prints `dir=` as the primary checkout, move the branch into
`.worktrees/chore-worktree-for-every-artefact` by hand before editing
(`git switch dev`, then `git worktree add` it, then copy `.claude/`
across) and say so in the first commit's body. From Step 1 on, work in
`dir=` and use absolute paths.

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
   - the doc-comment says so: no in-place branching, strays and a dirty
     primary checkout trigger nothing, and `begin` never touches the
     primary checkout's files (its trunk update excepted).

   Tests, `skills/git-workflow/scripts/tests/begin.sh` (red first):
   - replace "in place: on the trunk and clean, the primary checkout
     moves" with: on a clean trunk, `dir=` is `.worktrees/<branch>`,
     the primary checkout is still on the trunk at the same tip, and
     the config files are copied;
   - on the trunk with an untracked file only (the #112 case): a
     worktree, the stray untouched;
   - `begin` run from inside an existing worktree puts the new one at
     `<primary>/.worktrees/<branch>`, not under the first;
   - rename "worklist ... in place" to match; keep the worktree tests;
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
     `g switch -q -c topic` that forced one goes too and the ~25 callers
     drop `--where in-place`;
   - new: `land` run from the primary checkout on an artefact branch
     exits 2, naming `.worktrees/`, and changes nothing;
   - rename "merge in place" and "Clarifies: an in-place edit" tests to
     say what they test; the primary ends on the trunk because it never
     left it;
   - update the header's coverage line for git-workflow-0 #3.

   The last commit carries `Reconciles: skills/git-workflow/scripts/tests/land.sh`.

4. **State the rule in the skill and its rules file.**

   `skills/git-workflow/SKILL.md`, not `description`'s trigger or skip
   clauses: in `description`, "worktree isolation on contention"
   becomes "a worktree for every artefact". In "The two moments":
   `begin` "creates the branch together with its worktree" instead of
   isolating "when the checkout is not on the trunk or is dirty", and
   "Work in `dir=` and nowhere else" gains "never in the primary
   checkout"; the `land` exit 0 bullet loses "or on the trunk where the
   work was in place"; the exit 2 bullet adds running `land` from the
   primary checkout. "What the script decides": "whether to isolate and
   where" becomes "where the worktree goes". "Do not": the stash and
   `git add -A` line keeps its rule and loses its reason ("that is what
   the worktree is for" stays true).
   `skills/git-workflow/references/RULES.md`: retitle Rule 5 "Every
   artefact branch gets its own worktree" (keep the number; evals cite
   it), give the command, the reason (parallel sessions share one HEAD in
   the primary checkout, and a check made once at branching cannot hold),
   that git refuses a branch checked out twice so no lock is needed, and
   that the `.worktrees/` ignore-line paragraph is unchanged; Rule 14:
   cut the "Work done in the primary checkout returns that checkout to
   trunk" sentences and "or on trunk where the work was in place".
   Do not edit `.claude/skills/tessl__git-workflow/`; it is a merged
   install of `dev`.
   Commit: `Document a worktree for every artefact in git-workflow (plan 0024 Step 4)`,
   carrying `Reconciles: skills/git-workflow/SKILL.md` and
   `Reconciles: skills/git-workflow/references/RULES.md`.

5. **Document the worktree path for new teams.**
   Location: `README.md`, because ADR 0007 makes it the surface a new
   user reads before running anything and the `release` skill's README
   gate keeps it true; the ADR names none. In "Opinions", replace the
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

6. **Update the evals.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   Here the evals are the tests; run each before editing (step 7 gives
   the command) so the failure being fixed is seen.
   - `evals/git-workflow-0/criteria.json`, `scenario.json` and the
     setup.sh comments (lines 224 and 288-292), and
     `evals/git-workflow-1/criteria.json` and setup.sh comments: the
     fixtures stay dirty and off-trunk, which now tests that the
     primary checkout is untouched; reword "the contention check must
     select isolation" and "Rule 5 selects isolation" to "every
     artefact branch gets a worktree".
   - `evals/plans-0/` and `evals/plans-1/`: their fixtures check the plan
     branch out in the primary checkout, from which `land` now refuses.
     Build it as a worktree at `.worktrees/plan-0001-forecast-source`
     with the primary on `dev`, and say in `task.md` and the
     `criteria.json` context where the plan is ("checked out in place"
     goes).
   - `evals/adr-0/` and `evals/adr-1/`: their criteria read the repo
     at `solution/` with HEAD on `dev`; where one reads the working
     tree rather than `git show <branch>:<path>`, read the branch.
   Commit: `Reconcile the git-workflow evals to a worktree per artefact (plan 0024 Step 6)`,
   carrying `Reconciles: evals/git-workflow-0/criteria.json` and
   `Reconciles: evals/git-workflow-0/scenario.json`.

7. **Run the tests and the evals.**
   - `bash skills/git-workflow/scripts/tests/run.sh` and
     `bash skills/history/scripts/tests/run.sh` pass.
   - Run `tessl eval run` on `evals/git-workflow-0` and
     `evals/git-workflow-1`, three repeats each, on deepseek-v4-flash
     (the model `git-workflow`'s `compatibility` cites), and on
     `evals/plan-numbering-0`, `evals/plans-0`, `evals/plans-1`,
     `evals/adr-0` and `evals/adr-1` once each. Read each activation
     record and scorer reasoning, so a failure is classed as "never
     ran the script" or "worked in the primary checkout", not
     "merged wrongly".
   - If a `Confirms:` in the Landing table proves wrong (plan-numbering-0
     is the one at risk), reconcile that file in this step, with its
     own `Reconciles:`.
   - Update `git-workflow`'s `compatibility` frontmatter to cite the new
     runs and bars if the numbers moved; leave the floor unchanged
     unless they fall below the bars cited there.
   Record the results in Progress notes. Commit:
   `Record the runs of the git-workflow evals (plan 0024 Step 7)`.

8. **Complete.** Delete this plan. Commit `Complete plans/0024-worktree-for-every-artefact.md`
   with the trailer

   ```
   Completes: plans/0024-worktree-for-every-artefact.md
   ```

   and a body that says what the plan produced, and which of the 22
   deferred files were reconciled and which confirmed. Add
   `Fixes #143` and `Fixes #112` lines before the trailers so the
   merge closes both seeds.

## Verification

- `begin` on a clean trunk, on a dirty trunk and from inside another
  worktree each print `dir=<primary>/.worktrees/<branch>`; the primary
  checkout is unchanged (`git -C <primary> status --porcelain` and
  `rev-parse HEAD` equal before and after).
- Two `begin`s run concurrently from the primary checkout both succeed,
  with distinct worktrees.
- `check` prints three lines and no `contention=`.
- `land` from the primary checkout on a non-trunk branch exits 2;
  from the worktree it merges with two parents and leaves the primary
  on the trunk.
- `grep -rn -i 'contention\|in place\|in-place' skills evals README.md`
  finds no statement that `begin` isolates only on contention; the
  remaining hits are "edit in place" about a file.
- `git worktree list` after landing shows only the primary checkout.
- `history outstanding-deferrals` lists none whose origin is
  `docs/adr/0003-git-workflow.md`.

## Open items

- `docs/adr/0007-readme-requirements-and-opinions.md` line 91, "Worktree
  isolation on contention", now contradicts ADR 0003, and Step 5 makes
  the README follow ADR 0003. Editing an accepted ADR is the human's
  call; it is escalated and unanswered. No step edits ADR 0007.

## Progress notes
