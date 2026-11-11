---
title: Roots and in-place edits
status: draft
adr: 0004
date: 2026-11-11
deferred_reason: null
---

# Roots and in-place edits

## Reference

Implements the revision of `docs/adr/0004-where-does-history-live.md`
merged in e1b0426 (PR #186): `Origin:` for a root, `Clarifies:` on any
artefact in the tree, `Consumed-By:` for source material and for a note
informing several ADRs. It also implements the companion changes that
merge made to `docs/adr/0003-git-workflow.md` (the land rule's
exceptions; `facilitated-discovery` governs a note whatever its input)
and `docs/adr/0006-where-do-captured-ideas-live.md` (a seed is a second
input to a note). Fixes #182 and #184.

## Deferrals

| Downstream | Origin | Verdict | Where |
| --- | --- | --- | --- |
| `skills/history/SKILL.md` | 0004 | `Confirms:` | Landing |
| `docs/adr/0010-history-retrieval.md` | 0004 | `Confirms:` | Landing |
| `skills/git-workflow/SKILL.md` | 0003 | `Reconciles:` | Step 1 |
| `skills/git-workflow/scripts/tests/land.sh` | 0003 | `Reconciles:` | Step 2 |
| `skills/facilitated-discovery/SKILL.md` | 0003 | `Reconciles:` | Step 4 |
| `skills/plans/SKILL.md` | 0003 | `Reconciles:` | Step 5 |
| `skills/git-workflow/references/RULES.md` | 0003 | `Confirms:` | Step 6 |
| `skills/git-workflow/scripts/tests/begin.sh`, `lib.sh`, `check.sh`, `contract.sh`, `run.sh` | 0003 | `Confirms:` | Step 6 |
| `evals/git-workflow-0/criteria.json`, `scenario.json` | 0003 | `Confirms:` | Step 6 |
| `evals/plan-numbering-0/criteria.json`, `scenario.json`, `setup.sh`, `task.md` | 0003 | `Confirms:` | Step 6 |
| `.claude/skills/release/SKILL.md` | 0003 | `Confirms:` | Step 6 |
| `docs/discovery/0003-escalation-and-orchestration.md`, `docs/discovery/0005-compression-and-handover.md` | 0003 | `Confirms:` | Step 6 |
| `.gitignore`, `AGENTS.md` | 0003 | `Confirms:` | Step 6 |

Each `Confirms:` is found unaffected for this reason: none of these
files states the land rule's exceptions, the `Clarifies` scope, the
`Consumed-By` value, or a discovery note's inputs. The history script
follows `Derives-From` forward only, so a root, which carries none,
already ends traversal, and `Origin` is not read. The release skill's
version bump adds no artefact, so it is not a root and keeps its own
landing.

The two `Landing` verdicts are a precondition of landing this plan:
its introducing commit's `Derives-From` makes them due, and `land`
refuses the branch without them. After the closing pass, if any, and
before `land`, commit, empty, `Confirm the history skill and ADR 0010 against ADR
0004's revision`, its body giving the reason above, carrying
`Confirms: skills/history/SKILL.md` and
`Confirms: docs/adr/0010-history-retrieval.md`.

## Steps

Steps 1 to 6 run on one implementation branch:
`begin skills/git-workflow/scripts/git-workflow.sh --slug roots-and-in-place-edits`
(`chore-roots-and-in-place-edits`).

1. **Document the land rule and the trailer vocabulary.**
   - `skills/git-workflow/SKILL.md`, Rule 2: after "Work governed by no
     skill…", add ADR 0003's sentence: `facilitated-discovery` governs a
     discovery note whatever its input — a conversation, a seed, source
     material, or an experiment.
   - `skills/git-workflow/SKILL.md`, Rule 9: make the table match ADR
     0004's — add the `Origin:` row, widen `Clarifies:` to any artefact
     in the tree (any edit to a discovery note or source material), and
     make `Consumed-By:` remove a discovery note or source material,
     one trailer per artefact informed. In the paragraph after it: values
     are repository-relative paths except `Origin`'s and the condition
     `Defers` carries; a first commit needs no `Derives-From` on a
     decision, with a `Clarifies` naming a path at the fork point, or
     with a non-empty `Origin`; a root is the
     first commit adding an artefact with no upstream in the repository
     (a bootstrap, source material, a note from a conversation or seed),
     and an imported artefact records its provenance as
     `Origin: <owner>/<repo>@<rev>[:<path>]`, not in a prose header.
   - `README.md`: add `Origin` to the trailer list.

   Flip this plan's `status` to `in-progress` in the same commit.
   Commit: `Document roots and in-place edits in git-workflow (plan 0022 Step 1)`,
   carrying `Derives-From: plans/0022-roots-and-in-place-edits.md` and
   `Reconciles: skills/git-workflow/SKILL.md`.

2. **Document the land rule's exceptions and add failing tests.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   First, the doc-comments, committed on their own: in
   `skills/git-workflow/scripts/git-workflow.sh`, the usage text's
   `land` entry, step 2 of `cmd_land`'s numbered doc-comment and the
   inline comment above its trailer reads say that the first commit
   needs no `Derives-From` when the branch is a decision, when it
   carries `Clarifies:` naming a path that existed at the fork point
   (any artefact, not only an ADR), or when it carries `Origin:` with a
   non-empty value, which is not checked as a path; refuse (exit 2)
   otherwise. Commit: `Document roots and in-place edits at land (plan
   0022 Step 2)`.

   Then, in `skills/git-workflow/scripts/tests/land.sh`, extend the
   `artefact()` fixture: when `ORIGIN` is set (even to empty, tested with
   `${ORIGIN+x}`), the first commit carries `Origin: $ORIGIN` instead of
   `Derives-From`, winning over `CLARIFIES` and `NOTRAILER`; `ALSO`, when
   set, is appended as a further trailer line. Update its header
   comment. Add, with no remote unless stated:
   1. `Origin: bootstrap of this repository` and no `Derives-From`
      lands: exit 0, two-parent merge on `dev`, branch gone.
   2. `Origin: communitiesuk/myelin@abc1234:docs/discovery/0001-x.md`
      lands: exit 0 (the value is not path-checked).
   3. An empty `Origin:` is refused: exit 2, output contains
      `Origin must not be empty`, the branch unchanged.
   4. `Clarifies: docs/discovery/0001-note.md` editing that note (on the
      trunk in `lib.sh`'s fixture) lands: exit 0 (#184).
   5. `Clarifies` naming the file the branch itself adds
      (`docs/discovery/0002-x.md`) is refused: exit 2, output contains
      `does not exist at the fork point`.
   6. `Derives-From` with `ALSO='Origin:'` is refused: exit 2, output
      contains `Origin must not be empty`.

   Run `bash skills/git-workflow/scripts/tests/run.sh skills/git-workflow/scripts/tests/land.sh`:
   tests 1, 2, 3, 5 and 6 fail; test 4 already passes and guards #184.
   Every existing assertion is unchanged.
   Commit: `Add failing tests for roots and in-place edits (plan 0022 Step 2)`,
   carrying `Reconciles: skills/git-workflow/scripts/tests/land.sh`.

3. **Implement the land rule.**

   > **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

   In `cmd_land`, beside the existing `Derives-From`/`Clarifies` reads
   of the first commit: read `Origin` with `%(trailers:key=Origin)` so
   a present key is seen even with an empty value, and refuse (exit 2,
   `Origin must not be empty`) when it is present with no non-blank
   value. For each `Clarifies` value, keep the repository-relative check
   and add `git cat-file -e "$(git merge-base "$trunk" HEAD):$value"`,
   refusing (exit 2, `Clarifies: <value> does not exist at the fork
   point <sha>`). Accept
   a missing `Derives-From` when the branch is a decision, carries a
   valid `Clarifies`, or a valid `Origin`; otherwise refuse with a
   message naming `Derives-From`, `Clarifies` and `Origin`, keeping
   `Derives-From` and `first commit`, which existing assertions match. `Origin` joins neither the
   discharge-due trigger pool nor the verdict pool.

   Run `bash skills/git-workflow/scripts/tests/run.sh` and
   `bash skills/history/scripts/tests/run.sh`: all green.
   Commit: `Implement roots and in-place edits at land (plan 0022 Step 3)`.

4. **Reconcile `facilitated-discovery`.** In
   `skills/facilitated-discovery/SKILL.md`:
   - The numbering paragraph: a note leaves when the ADR or ADRs it
     informed are accepted.
   - Replace "A discovery note has two entry points" with its inputs: a
     conversation (Path B), a seed (the developed capture), source
     material, or an experiment; the skill governs the note whichever.
     Widening its trigger to these inputs is seed #188; the `description`
     is unchanged.
     Keep the developed capture's human gating (ADR 0006). The note's
     first commit carries `Derives-From` naming its upstream in the repository
     (source material, or an earlier note); with none, `Origin:` giving
     its provenance in words (`Origin: seed #<n>`, or the conversation
     and date), or a pinned `<owner>/<repo>@<rev>:<path>` for a note
     copied from another repository.
   - Source material: any file brought in from outside the workflow as
     input to discovery lives in `docs/discovery/sources/`. It enters on
     its own branch (`begin docs/discovery/sources/<file> --slug <slug>`), whose first commit adds only
     that material and carries `Origin:`; a note drawing on it derives
     from it on the note's own branch, and records what it draws from
     it. It leaves on the branch of the last note drawing on it, by a
     later commit carrying `Consumed-By` naming each note it informed.
   - A landed note or source material is edited in place, any edit, on
     its own branch (`begin <path>`, with `--slug` for source material),
     whose first commit carries `Clarifies: <path>`; `land` sends it to
     trunk.
   - Leaving: the note is deleted on the branch of the last ADR it
     informs, by a commit carrying one `Consumed-By` per ADR informed.
     A note that informs none is abandoned by a deleting commit that
     says why.

   Commit: `Reconcile facilitated-discovery to roots and in-place edits (plan 0022 Step 4)`,
   carrying `Reconciles: skills/facilitated-discovery/SKILL.md`.

5. **Reconcile `plans`.** In `skills/plans/SKILL.md`, "Status
   lifecycle", outside the review-loop block, add: a plan in the tree is
   edited in place. A substantive change made because its ADR was
   revised carries `Reconciles: plans/NNNN-<slug>.md` (ADR 0011), on the
   revising branch or the branch that brings its deferral due; an edit
   changing no decision and no behaviour (typo, citation, metadata, or
   an uncaught cross-reference) carries `Clarifies:` and lands direct to
   trunk.
   Commit: `Reconcile plans to in-place edits (plan 0022 Step 5)`,
   carrying `Reconciles: skills/plans/SKILL.md`.

6. **Complete the plan.** Delete this file. The commit carries
   `Completes: plans/0022-roots-and-in-place-edits.md` and one
   `Confirms:` for each of the 17 files the "Deferrals" table assigns to
   Step 6. Its body says what the plan produced, and why each confirmed
   file is unaffected. Land. Then, one `gh issue close` per call, close
   #182 and #184, each with a comment naming the merge.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` and
  `bash skills/history/scripts/tests/run.sh`: all green, with Step 2's
  six tests added and no existing assertion changed.
- `bash skills/history/scripts/history.sh outstanding-deferrals` on
  trunk after Step 6 lands lists none of the deferrals in
  "Deferrals".
- Smoke, in a scratch repository with the plugin's script: a branch
  whose first commit adds `docs/discovery/sources/x.txt` with
  `Origin: brought in by hand` lands; a branch editing a landed note
  with `Clarifies:` naming it lands; a branch with none of the three
  trailers is refused naming each.
