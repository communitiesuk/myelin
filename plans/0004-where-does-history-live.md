---
title: Where does history live?
status: draft
adr: 0004
date: 2026-09-16
deferred_reason: null
---

# Where does history live?

## Reference

Implements `docs/adr/0004-where-does-history-live.md`. Revises plan
0003 (`plans/0003-git-workflow.md`, Step 6) under the ADR's rule that
revising an ADR revises its plans. Draws the content for Step 1 from
the unmerged branch `adr-0004-bookkeeping-not-an-artefact`.

## Execution shape

Every step here edits markdown. No step writes executable code and no
step authors a new skill, so no step carries a directive wrapper.
Edits to the three existing skill bodies leave their `description`
fields untouched.

Under ADR 0003, the artefacts and their branches are:

- **Step 1**, a revision of ADR 0003 — branch `adr-0003-git-workflow`.
  A revision takes the identifier of the artefact it revises; the
  original branch of that name was deleted on merge and is free.
- **Steps 2–4**, edits to the `adr`, `plans` and
  `facilitated-discovery` skill bodies — one artefact, branch
  `skills-0004-where-does-history-live`. They are one artefact
  because no subset of them can merge alone without leaving the
  skills contradicting each other (the `adr` skill saying plans
  leave the tree while the `plans` skill forbids deletion). One
  commit per skill.
- **Step 5**, retiring plans 0001 and 0002 — branch
  `plans-retire-done`. One commit per plan.
- **Step 6**, a revision of plan 0003 — on its existing unmerged
  branch `plan-0003-git-workflow`.
- **Step 7** integrates. Its last act removes this plan.

This plan is itself an artefact of the `plans` skill, written on
branch `plan-0004-where-does-history-live` in a worktree, because the
primary checkout was on another artefact's branch.

## Steps

1. **Revise ADR 0003 in place.**
   - **Depends on**: ADR 0004 accepted and merged.
   - Source text:
     `git show adr-0004-bookkeeping-not-an-artefact:docs/adr/0004-bookkeeping-not-an-artefact.md`.
   - Add a subsection to Decision, after "Commit cadence is
     delegated", titled "Bookkeeping is not an artefact". It carries,
     condensed and without paraphrase drift: the truth-condition test
     (a change is bookkeeping when it is true only because some other
     work is true); the rule (bookkeeping gets no branch of its own
     and rides with the change that makes it true; bookkeeping with
     nothing to ride on is work); that classification is relational,
     with the three-row table; and the scope (exempt from branching,
     from nothing else).
   - Add to Alternatives the three rejected options that bear on
     0003's rule: enumerating bookkeeping by file or section; treating
     all ungoverned work as bookkeeping; leaving it to each plan.
   - Add to Consequences: "branch before edit" acquires a bounded
     exception and the test must appear in the skill body as a rule;
     classification is per change; an eval scenario should cover a
     bookkeeping change.
   - Under "Integration preserves structure", add that a squash also
     discards the trailers ADR 0004 requires, which is a second reason
     it is prohibited.
   - In Context, the second bullet describes the `adr` skill's
     merged-ADR rule as a reason squashing is harmful. That rule is
     withdrawn by ADR 0004. Rewrite the bullet to say so in one
     sentence and keep the first bullet (test-first's auditability
     claim), which still holds.
   - In Consequences, delete the bullet "The `adr` skill's
     prohibition on editing a merged ADR becomes meaningful, because
     an ADR now has a merge of its own." It is no longer true.
   - Do not change the `date` field. Do not touch the frontmatter
     otherwise; Step 2 handles the schema.
   - One commit. Trailer `Revises: docs/adr/0003-git-workflow.md`.
     The body states both changes and why: the bookkeeping exception
     adopted from the abandoned refining ADR, and the withdrawal of
     the immutability consequence by ADR 0004.
   - Flip this plan's status to `in-progress` in the same commit. It
     is bookkeeping by 0003's own new test.
   - Files changed: `docs/adr/0003-git-workflow.md`,
     `plans/0004-where-does-history-live.md`.

2. **Edit `skills/adr/SKILL.md`.**
   - **Depends on**: Step 1 merged, so the skill is never ahead of
     the ADR it describes.
   - "Location and naming": replace "One ADR per decision. Do not
     amend a merged ADR to record a new decision — supersede it" with
     one ADR per question, the title is the question, and the test:
     if a revision still answers the title's question, edit in place;
     if it answers a new question, write a new ADR and edit the old
     one only where the new decision changes it.
   - "Frontmatter": schema becomes `title`, `status`, `date`. The
     `title` is phrased as a question. Remove `supersedes` and
     `superseded_by` and their bullets.
   - "Status lifecycle": `proposed` and `accepted` only. Remove
     `superseded`. Add: a decision reversed outright is deleted, and
     the deleting commit says why.
   - New section "Revising an ADR", after "Status lifecycle":
     edit in place; the commit carries `Revises: <path>` and a body
     saying what changed and why; when a revision reverses an
     adopted path, add an Alternatives entry summarising the
     reversal; on the same branch, every plan in the tree whose
     `adr:` names this ADR is revised to match or set to `deferred`
     with a reason naming the revision. A typo fix carries no
     trailer. Quote the trailer form once so it is copied, not
     paraphrased.
   - "Do not": replace "Do not edit a merged ADR to change the
     decision. Write a superseding ADR." with "Do not write a new ADR
     to change the answer to a question an existing ADR already
     answers. Revise it." Replace "Do not delete superseded ADRs.
     They are the historical record." with "Do not keep a reversed
     ADR in the tree under a status flag. Delete it; the commit and
     git history are the record."
   - Leave the `description` and the "Required forward-pointer"
     section unchanged. The history-skill directive is ADR 0005's.
   - In the same commit, remove the `supersedes` and `superseded_by`
     lines from the frontmatter of ADRs 0001, 0002 and 0003. This is
     bookkeeping made true by the schema change.
   - Files changed: `skills/adr/SKILL.md`,
     `docs/adr/0001-artifact-embedded-skill-directives.md`,
     `docs/adr/0002-skill-forge.md`, `docs/adr/0003-git-workflow.md`.

3. **Edit `skills/plans/SKILL.md`.**
   - **Depends on**: Step 2 (same branch, sequential commits).
   - Opening paragraph: replace "live permanently in the repo so the
     whole team (and future agents) can see what work has been done,
     is in flight, is paused, or was abandoned" with: plans live in
     the tree while their work is intended and leave it when the work
     is done or abandoned; git history holds what has been done.
   - "Frontmatter" and "Status lifecycle": `status` is `draft`,
     `in-progress` or `deferred`. Remove `done` and `abandoned`.
     Replace their bullets with: completion is expressed by deleting
     the plan file in the final commit on the last implementation
     branch, trailer `Completes: <path>`; abandonment by deleting it
     with trailer `Abandons: <path>` and a body saying why. Keep
     `deferred` as is.
   - "Status updates ride with the code changes": keep, and make the
     completion case concrete: the deleting commit is the one that
     makes completion true.
   - "Location and naming" or a new short section: the commit that
     introduces a plan carries `Derives-From: docs/adr/NNNN-<slug>.md`.
   - "Do not": remove "Do not delete plans on completion. Set
     `status: done` and leave them." and "Do not archive plans to a
     separate directory. `plans/` holds the full lifecycle." Add "Do
     not leave a finished or abandoned plan in the tree." Keep "Do
     not edit the ADR from within the plan's commits"; the ADR-to-plan
     revision rule runs the other way and lives in the `adr` skill.
   - The sentence under "What does NOT belong in a plan" that
     suggests the ADR be amended is now literally correct. Leave it.
   - Leave the `description` and the per-step wrapper section
     unchanged.
   - Files changed: `skills/plans/SKILL.md`.

4. **Edit `skills/facilitated-discovery/SKILL.md`.**
   - **Depends on**: Step 3 (same branch, sequential commits).
   - Phase 6B: after the note is written, add that it leaves the tree
     when the ADR it informed is accepted, deleted on that ADR's
     branch with trailer `Consumed-By: <ADR path>`, and that the
     ADR's introducing commit carries `Derives-From: <note path>`.
   - Phase 6A: add that the ADR's introducing commit carries
     `Derives-From` naming the discovery note, where one exists.
   - Nothing else changes.
   - Files changed: `skills/facilitated-discovery/SKILL.md`.

5. **Retire plans 0001 and 0002.**
   - **Depends on**: Steps 2–4 merged, so the rule exists before it
     is applied.
   - `git rm plans/0001-artifact-embedded-skill-directives.md`. One
     commit, trailer
     `Completes: plans/0001-artifact-embedded-skill-directives.md`.
     Body: one sentence on what it produced (the per-step directive
     wrappers in the `plans` skill) and that it landed in `74e880c`.
   - `git rm plans/0002-skill-forge.md`. One commit, trailer
     `Completes: plans/0002-skill-forge.md`. Body: one sentence on
     what it produced (the `skill-forge` skill and
     `evals/skill-forge-0/`) and that it landed in `1e7d948`.
   - Files changed: both plan files removed.

6. **Revise plan 0003 on its branch.**
   - **Depends on**: Step 1 merged. ADR 0004's same-branch rule does
     not bind here, because plan 0003 is not in trunk's tree; it is
     on its own unmerged branch, and that is where it is revised.
   - Rebase or merge trunk into `plan-0003-git-workflow` first, so
     the plan is revised against the revised ADR 0003.
   - Step 4 of plan 0003 (the skill body): add a bullet requiring the
     git-workflow skill to state the trailer vocabulary from ADR
     0004, verbatim as a table, and the rule that trailers carry the
     edge and the body carries the reason. Add a bullet requiring
     the skill body to carry the bookkeeping test and rule from
     revised ADR 0003.
   - Step 6 of plan 0003: replace the flip to `status: done` with
     deletion of the plan file in the final commit before the last
     merge, trailer `Completes: plans/0003-git-workflow.md`. Keep the
     flip to `in-progress`.
   - Step 3 of plan 0003 (the eval scenario): add an assertion that
     a bookkeeping change made during the scenario rides with the
     artefact's commit rather than taking a branch, per ADR 0003's
     Consequences after Step 1.
   - "Execution shape" and "Verification" of plan 0003: update the
     sentences that describe Step 6 and the "frontmatter reads
     `status: done`" check to match.
   - One commit on `plan-0003-git-workflow`. No trailer: the plan is
     unmerged and `Revises` is defined for ADRs.
   - Files changed: `plans/0003-git-workflow.md`.

7. **Integrate and clean up, per ADR 0003.**
   - **Depends on**: Steps 1–6.
   - Merge order into trunk, each with `git merge --no-ff`:
     `adr-0004-where-does-history-live` (if not already merged at
     acceptance), `plan-0004-where-does-history-live`,
     `adr-0003-git-workflow`, `skills-0004-where-does-history-live`,
     `plans-retire-done`.
   - Before merging `plans-retire-done`, make its final commit the
     removal of this plan: `git rm plans/0004-where-does-history-live.md`,
     trailer `Completes: plans/0004-where-does-history-live.md`.
   - Merge `discovery-0001-history-skill` whenever convenient; it is
     independent of the rest and stays in the tree until ADR 0005 is
     accepted.
   - Delete each merged branch; remove each worktree under
     `.worktrees/` that backed one.
   - Leave `adr-0004-bookkeeping-not-an-artefact` and its worktree
     alone. It is unmerged and ADR 0003 says nothing removes such
     work automatically. Once Step 1 has merged, its adopted content
     is in trunk's history and its rejected fields are recorded in
     Step 1's commit body; deleting the branch after that is the
     user's call, and would lose the original 221-line text.
   - Return the primary checkout to trunk.
   - Files changed: none tracked beyond the removal above.

## Non-goals

- The history skill and the `adr` skill's directive to it. ADR 0005,
  from `docs/discovery/0001-history-skill.md`.
- The git-workflow skill body and its eval. Plan 0003.
- A `commit-msg` hook enforcing trailers. ADR 0003 parks enforcement
  and ADR 0004 does not unpark it.
- The copies of these skills installed outside the repository (for
  example under `~/.claude/skills/`). They are `tessl install`
  outputs, not sources.

## Verification

- `grep -l 'supersede' docs/adr/*.md` returns nothing.
- `grep -c 'truth condition\|truth-condition' docs/adr/0003-git-workflow.md`
  is at least 1, and the file contains no sentence claiming the
  `adr` skill's prohibition on editing a merged ADR "becomes
  meaningful".
- `git log --format='%(trailers:key=Revises,valueonly)' | grep -c docs/adr/0003`
  is at least 1.
- `git log --format='%(trailers:key=Completes,valueonly)'` lists
  plans 0001, 0002 and 0004; none of those files is in the tree.
- `skills/adr/SKILL.md` contains no "Do not edit a merged ADR" and
  no `superseded_by`; contains "Revises:" and the question test.
- `skills/plans/SKILL.md` contains no `done` status and no "Do not
  delete plans"; contains "Completes:" and "Abandons:" and
  "Derives-From:".
- `skills/facilitated-discovery/SKILL.md` contains "Consumed-By:".
- On branch `plan-0003-git-workflow`, `plans/0003-git-workflow.md`
  contains "Completes: plans/0003-git-workflow.md" and no
  "status: done".
- `git log --merges --format=%p -n 6` shows two parents for every
  integration merge.
- `git branch --list adr-0004-bookkeeping-not-an-artefact` still
  exists unless the user has removed it.

## Progress notes

- 2026-09-16: drafted against ADR 0004 (status `proposed`) on branch
  `plan-0004-where-does-history-live`, in a worktree because the
  primary checkout was on `plan-0003-git-workflow`. Written before
  the ADR is accepted; nothing here executes until it is.
