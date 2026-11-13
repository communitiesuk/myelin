---
title: Abandoning an ADR
status: in-progress
adr: 0004
date: 2026-11-13
deferred_reason: null
---

# Abandoning an ADR

## Reference

Implements the revision of `docs/adr/0004-where-does-history-live.md`
merged in 428fbfc (PR #192): `Abandons:` removes a whole artefact (an
ADR reversed outright, a plan, a discovery note informing no ADR,
source material informing no note), and `land` accepts it as a first
commit. It also implements what that merge decided in
`docs/adr/0003-git-workflow.md` (the `Abandons` exception to the land
rule; a branch abandoning an ADR is a decision),
`docs/adr/0010-history-retrieval.md` (`Abandons: <origin>` makes a
deferral due), `docs/adr/0011-revision-process.md` (an abandoned ADR's
downstreams each get a verdict on its branch, with no blast-radius
default; a skill or code existing only for it is deleted under
`Reconciles`) and `docs/adr/0012-discharging-deferrals.md` (the
due-deferral check covers an abandoned origin). `README.md` states
the human-merge rule as `docs/adr/0007-readme-requirements-and-opinions.md`
requires. Fixes #191.

## Deferrals

| Downstream | Origin | Verdict | Where |
| --- | --- | --- | --- |
| `skills/git-workflow/SKILL.md` | 0004 | `Defers:` to this plan, then `Reconciles:` | Landing, Step 1 |
| `skills/git-workflow/references/RULES.md` | 0004 | `Defers:` to this plan, then `Reconciles:` | Landing, Step 1 |
| `README.md` | 0004 | `Defers:` to this plan, then `Reconciles:` | Landing, Step 1 |
| `skills/history/SKILL.md` | 0004 | `Defers:` to this plan, then `Reconciles:` | Landing, Step 2 |
| `skills/git-workflow/scripts/tests/land.sh` | 0004 | `Defers:` to this plan, then `Reconciles:` | Landing, Step 3 |
| `skills/facilitated-discovery/SKILL.md` | 0004 | `Defers:` to this plan, then `Reconciles:` | Landing, Step 6 |
| `skills/plans/SKILL.md` | 0004 | `Defers:` to this plan, then `Reconciles:` | Landing, Step 7 |
| `skills/git-workflow/scripts/tests/begin.sh`, `lib.sh`, `check.sh`, `contract.sh`, `run.sh` | 0004 | `Confirms:` | Landing |
| `evals/plan-numbering-0/criteria.json`, `scenario.json`, `setup.sh`, `task.md` | 0004 | `Confirms:` | Landing |
| `.claude/skills/release/SKILL.md` | 0004 | `Confirms:` | Landing |
| `skills/adr/SKILL.md` | 0011 | `Reconciles:` | Step 5 |
| `docs/adr/0006-where-do-captured-ideas-live.md` | 0003 | `Confirms:` | Step 8 |
| `docs/discovery/0003-escalation-and-orchestration.md`, `docs/discovery/0005-compression-and-handover.md` | 0003 | `Confirms:` | Step 8 |
| `evals/git-workflow-0/criteria.json`, `scenario.json` | 0003 | `Confirms:` | Step 8 |
| `.gitignore`, `AGENTS.md` | 0003 | `Confirms:` | Step 8 |

**Landing.** This plan's introducing commit carries
`Derives-From: docs/adr/0004-where-does-history-live.md`, so its
landing satisfies every deferral whose origin is ADR 0004, and `land`
refuses this plan's branch without a verdict for each (ADR 0012). After the closing pass, if
any, and before `land`, commit, empty,
`Account for ADR 0004's deferrals at plan 0023's landing`, carrying:

- one `Confirms:` for each of the ten files the table confirms at
  Landing. Its body gives the reason: none states the land rule's
  exceptions, which branches are decisions, the `Abandons` scope, or
  what makes a deferral due. The release skill's version bump still
  carries none of `Derives-From`, `Clarifies`, `Abandons` or `Origin`,
  so its own landing stands.
- for each of the seven files the table reconciles in a step,
  `Defers: <file> plans/0023-abandoning-an-adr.md until plan 0023's implementation lands`.
  Its body says these are reconciled by the implementation branch.
  ADR 0011's anchor rule governs a chain's root, here ADR 0004; a
  re-defer answers to ADR 0012's escape alone.

The implementation branch's first commit carries
`Derives-From: plans/0023-abandoning-an-adr.md`, so `land` refuses it
until each of the seven carries `Reconciles:`. The 0003 and 0011
deferrals are brought due by neither branch; Steps 5 and 8 discharge
them anyway.

## Steps

Steps 1 to 8 run on one implementation branch:
`begin skills/git-workflow/scripts/git-workflow.sh --slug abandoning-an-adr`
(`chore-abandoning-an-adr`).

1. **Document the land rule and the trailer vocabulary.**
   - `skills/git-workflow/SKILL.md`, Rule 9 table: make the `Abandons:`
     and `Reconciles:` rows match ADR 0004's. In the paragraph after
     it, a first commit needs no `Derives-From` when it carries
     `Abandons` naming a path that existed at the fork point, as for
     `Clarifies`; abandoning an ADR is a decision. In the verdict
     paragraph: verdicts are recorded on a `Revises` branch or one
     carrying `Abandons` naming an ADR, and an abandoned ADR gets no
     auto-defer: its branch judges each downstream.
   - `skills/git-workflow/SKILL.md`, the `land` exit 3 bullet: the
     branch adds an ADR, carries `Revises`, or carries `Abandons`
     naming an ADR; an abandoned ADR's `artefact:` link is the ADR as
     it stands on the trunk.
   - `skills/git-workflow/references/RULES.md`, Rule 11: a decision
     also includes a branch whose commits carry `Abandons` naming a
     file under `docs/adr/`. Rule 15: the gate also covers such a
     branch; there the downstream set is filtered to paths in the fork
     point's tree, less those the branch removes with `Abandons`, so a
     skill or code deleted for the abandoned ADR needs `Reconciles:`
     and a plan removed with `Abandons` needs none.
   - `README.md`, the merge-permission paragraph and the
     "Pull request by default" opinion: an ADR, and any branch that
     revises or abandons one, is left for a human to merge. In "The
     working tree holds the current intention", the verdicts are those
     a revision or abandonment of an ADR records.

   Flip this plan's `status` to `in-progress` in the same commit.
   Commit: `Document abandonment in git-workflow (plan 0023 Step 1)`,
   carrying `Derives-From: plans/0023-abandoning-an-adr.md`,
   `Reconciles: skills/git-workflow/SKILL.md`,
   `Reconciles: skills/git-workflow/references/RULES.md` and
   `Reconciles: README.md`.

2. **Make an abandoned origin bring a deferral due.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   In `skills/history/scripts/history.sh`, the `outstanding-deferrals`
   doc-comment says a later commit carrying `Abandons:` naming the
   origin also makes the deferral due. In
   `skills/history/scripts/tests/outstanding-deferrals.sh`, update the
   header comment and add:
   1. A deferral on ADR 0001, then `git rm docs/adr/0001-bus.md` and
      `gc` with body `Abandons: docs/adr/0001-bus.md`:
      `due: true`, with a `candidate:` line naming that commit.
   2. A deferral on ADR 0001, then a later `Abandons:` naming another
      path: `due: false`.

   Test 1 fails. Then add `Abandons` to `_outstanding_deferrals_log`'s
   format and to the due-trigger pool in `cmd_outstanding_deferrals`,
   never to the D-verdicts. In `skills/history/SKILL.md`, `origin:` is
   the path whose landing or abandonment re-triggers the check. Run
   `bash skills/history/scripts/tests/run.sh`: all green.
   The commit editing `skills/history/SKILL.md` carries
   `Reconciles: skills/history/SKILL.md`.

3. **Document abandonment at land and add failing tests.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   First, the doc-comments, committed on their own: in
   `skills/git-workflow/scripts/git-workflow.sh`, the usage text's
   `land` entry and `cmd_land`'s numbered doc-comment, steps 2 to 2c
   and the inline comments above the code they describe:
   - 2: a decision is also a branch whose commits carry `Abandons`
     naming a file under `docs/adr/`. A first commit carrying
     `Abandons` needs no `Derives-From`; each value must be
     repository-relative and exist at the fork point, or `land`
     refuses (exit 2).
   - 2a: skipped for abandoned ADRs; runs over `Revises` values only,
     and never slates a downstream of an ADR this branch abandons, even
     one shared with a revised ADR: a choice, reading ADR 0011's "its
     abandoning branch judges each downstream" as covering it, since
     nothing upstream settles a shared one.
     `Abandons` joins its trigger-pool exclusion.
   - 2b: also runs for each distinct `Abandons` value under
     `docs/adr/`, over that ADR's downstream filtered to paths in the
     fork point's tree, less every path this branch carries `Abandons`
     for.
   - 2c: `Abandons` joins the branch-local trigger pool and the
     trunk-wide pool a re-defer's origin must be absent from.
   - The decision report links an abandoned ADR as it stands on the
     trunk (the host's `link` verb, given the trunk for the branch).

   Commit: `Document abandonment at land (plan 0023 Step 3)`.

   Then add, with no remote unless stated, in
   `skills/git-workflow/scripts/tests/land.sh` (extending the
   `artefact()` fixture or adding a helper, its header comment updated):
   1. A branch whose only commit deletes `docs/discovery/0001-note.md`
      with `Abandons: docs/discovery/0001-note.md` lands: exit 0,
      two-parent merge on `dev`, the note gone (#191).
   2. `Abandons` naming a path absent at the fork point is refused:
      exit 2, output contains `does not exist at the fork point`.
   3. `Abandons: ./docs/discovery/0001-note.md` is refused: exit 2,
      output contains `Abandons must be a repository-relative path`.
   4. With a GitHub remote, a branch deleting `docs/adr/0001-one.md`
      with `Abandons: docs/adr/0001-one.md`: exit 3, the pull request
      opened and not merged, and an `artefact:` line ending
      `/blob/dev/docs/adr/0001-one.md`.
   5. With no remote and `plans/9001-downstream.md` committed on `dev`,
      the default `artefact` branch plus a later commit deleting that
      plan with `Abandons: plans/9001-downstream.md` is not a decision:
      exit 0.

   And, beside the existing gate tests, with
   `plans/9001-downstream.md` and `skills/x/SKILL.md` each committed on
   `dev` with `Derives-From: docs/adr/0001-one.md`, then a branch
   abandoning `docs/adr/0001-one.md`:
   6. No verdicts: exit 2 naming both, and no
      `Auto-defer the untouched blast radius` commit on the branch.
   7. `Reconciles: plans/9001-downstream.md` and
      `Confirms: skills/x/SKILL.md`: exit 3.
   8. The plan removed with `Abandons: plans/9001-downstream.md` and the
      skill deleted with `Reconciles: skills/x/SKILL.md`: exit 3.
   9. The skill deleted with no verdict, the plan abandoned: exit 2
      naming `skills/x/SKILL.md`.
   10. With `docs/adr/0003-three.md` on `dev`, then `src/shared.sh`
       added by one commit carrying `Derives-From:` for both ADRs, a
       branch carrying `Revises:` for the first and abandoning the
       second, with no verdict: exit 2 naming `src/shared.sh`, and no
       `Defers:` naming it.

   In `skills/git-workflow/scripts/tests/discharge.sh`:
   11. With `O1_PATH` committed on `dev` after the base fixture's
       deferral, a branch abandoning `O1_PATH` with no verdict for
       `D_PATH`:
       exit 2, output contains
       `triggers a due deferral with no discharge verdict for:` and
       `D_PATH`; with `Confirms: D_PATH` it gets past the check (exit 3).
   12. On a branch whose first commit carries `Derives-From: O1_PATH`,
       a re-defer `Defers: D_PATH O2_PATH …` where trunk already
       carries `Abandons: O2_PATH` is refused as an invalid re-defer.

   Run `bash skills/git-workflow/scripts/tests/run.sh`: tests 1 to 4
   and 6 to 12 fail; test 5 already passes. Every existing assertion
   is unchanged.
   Commit: `Add failing tests for abandonment at land (plan 0023 Step 3)`,
   carrying `Reconciles: skills/git-workflow/scripts/tests/land.sh`.

4. **Implement abandonment at land.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   In `cmd_land`, as Step 3's doc-comments say:
   - Set `decision=1` when any `Abandons` value on `trunk..HEAD` starts
     `docs/adr/`.
   - Read the first commit's `Abandons` beside `Clarifies`, and
     validate it the same way, with messages naming `Abandons`. Set
     `fork` whenever any `Abandons` is present on `trunk..HEAD`, not
     only under `Clarifies`. Accept a missing `Derives-From` when the
     first commit carries a valid `Abandons`, and name `Abandons` in the
     refusal message, keeping `Derives-From` and `first commit`.
   - Read `Abandons` values once on `trunk..HEAD`; the ADR ones are
     `$abandons_adr`. Add all values to `autodefer_pool`,
     `trigger_pool` and (over `$trunk`) `trunk_pool`.
   - 2a, still guarded by `$revises`: skip any `d` in the downstream of
     an `$abandons_adr` value.
   - 2b: guard on `$revises` or `$abandons_adr` being non-empty. Keep
     the `Revises` walk as is; add a walk over `$abandons_adr` whose
     in-tree filter is `git cat-file -e "$fork:$d"` and which skips a
     `d` in the branch's `Abandons` values. Report both walks' missing
     paths in the one existing refusal.
   - The decision report's link loop also covers `$abandons_adr`,
     passing `$trunk` as the branch.

   Run `bash skills/git-workflow/scripts/tests/run.sh` and
   `bash skills/history/scripts/tests/run.sh`: all green.
   Commit: `Implement abandonment at land (plan 0023 Step 4)`.

5. **Reconcile `adr`.** In `skills/adr/SKILL.md`, replace "A decision
   that is reversed outright is deleted, not marked. The commit that
   deletes it says why." with: an ADR reversed outright is deleted on
   its own branch (`begin docs/adr/NNNN-<slug>.md`), by a commit
   carrying `Abandons: docs/adr/NNNN-<slug>.md`, copied exactly, whose
   body says why. The same branch gives each durable downstream in the
   tree a verdict, judged one by one (there is no auto-defer): a plan
   of the ADR leaves with `Abandons`; a skill or code existing only for
   it is deleted under `Reconciles`; anything else is reconciled,
   confirmed or deferred. A human lands it. Align the "Do not" bullet
   on keeping a reversed ADR, and add `Abandons` beside the `Revises`
   commit rule.
   Commit: `Reconcile adr to abandonment (plan 0023 Step 5)`, carrying
   `Reconciles: skills/adr/SKILL.md`.

6. **Reconcile `facilitated-discovery`.** In
   `skills/facilitated-discovery/SKILL.md`: a note that informs no ADR
   is decided against, and leaves on its own branch (`begin <path>`) by
   a deleting commit carrying `Abandons: <path>`, copied exactly, whose
   body says why; `land` accepts it alone. Source material that informed
   no note leaves the same way (`--slug` as for its other branches).
   Commit: `Reconcile facilitated-discovery to abandonment (plan 0023 Step 6)`,
   carrying `Reconciles: skills/facilitated-discovery/SKILL.md`.

7. **Reconcile `plans`.** In `skills/plans/SKILL.md`, "Status
   lifecycle", outside the review-loop block: a plan of an ADR
   abandoned outright leaves on the abandoning branch with `Abandons`
   and needs no verdict. In the in-place edit paragraph, a substantive
   change carries `Reconciles:`, the verdict on an ADR's downstream
   (ADR 0004), on the branch revising or abandoning that ADR or
   bringing its deferral due.
   Commit: `Reconcile plans to abandonment (plan 0023 Step 7)`,
   carrying `Reconciles: skills/plans/SKILL.md`.

8. **Complete the plan.** Delete this file. The commit carries
   `Completes: plans/0023-abandoning-an-adr.md` and one `Confirms:` for
   each of the seven files the "Deferrals" table assigns to Step 8. Its
   body says what the plan produced, and why each confirmed file is
   unaffected: ADR 0006 names abandonment as a way out without stating
   its trailer; a discovery note records the thinking of its time, so
   note 0003's routing, written before `Abandons`, stands; the
   `git-workflow-0` eval scores a new ADR's landing, which is
   unchanged; `.gitignore` and `AGENTS.md` state none of this. Land. Then, one `gh issue close` per
   call, close #191 with a comment naming the merge.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` and
  `bash skills/history/scripts/tests/run.sh`: all green, with Steps 2
  and 3's tests added and no existing assertion changed.
- `bash skills/history/scripts/history.sh outstanding-deferrals` on
  trunk after Step 8 lands lists none of the deferrals in "Deferrals".
- Smoke, in a scratch repository with the plugin's scripts: a branch
  that only deletes a landed note with `Abandons:` naming it lands; a
  branch deleting an ADR with `Abandons:` and a downstream plan in the
  tree is refused naming the plan, then, with the plan removed under
  `Abandons:`, stops at exit 3 for a human.
