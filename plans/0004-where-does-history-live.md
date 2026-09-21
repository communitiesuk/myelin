---
title: Where does history live?
status: in-progress
adr: 0004
date: 2026-09-16
deferred_reason: null
---

# Where does history live?

## Reference

Implements `docs/adr/0004-where-does-history-live.md`. Revises plan
0003 (`plans/0003-git-workflow.md`, Step 7) under the ADR's rule that
revising an ADR revises its plans. Draws the content for Step 1 from
the unmerged branch `adr-0004-bookkeeping-not-an-artefact`.

## Execution shape

Every step here edits markdown or JSON. No step writes executable
code and no step authors a new skill, so no step carries a directive
wrapper. Edits to the three existing skill bodies leave their
`description` fields untouched.

**Preconditions.** ADR 0004 is `accepted` and merged into trunk with
`--no-ff`. This plan's own branch, `plan-0004-where-does-history-live`,
is merged into trunk with `--no-ff` before Step 1 begins, so that the
plan file exists on trunk for later steps to update and remove.

**Integration is explicit.** Steps that must reach trunk before the
next step can begin end with a "Merge now" instruction. Nothing is
merged implicitly. Every merge is `git merge --no-ff` into trunk,
followed by deleting the branch and removing its worktree if it had
one. Trunk in this repository derives to `main`.

Under ADR 0003, the artefacts and their branches are:

- **Step 1**, a revision of ADR 0003 — branch `adr-0003-git-workflow`.
  A revision takes the identifier of the artefact it revises; the
  original branch of that name was deleted on merge and is free.
- **Steps 2–5**, the eval scenarios and the `adr`, `plans` and
  `facilitated-discovery` skill bodies — one artefact, branch
  `skills-where-does-history-live`. One artefact because no subset
  can merge alone without leaving the skills contradicting each
  other or the evals grading a withdrawn rule. The evals are
  rewritten first, mirroring `skill-forge`'s order of failing
  scenario before body. One commit per step.
- **Step 6**, retiring plans 0001 and 0002 — branch
  `plans-retire-done`. One commit per plan.
- **Step 7**, a revision of plan 0003 — on its existing unmerged
  branch `plan-0003-git-workflow`. Never merged by this plan.
- **Step 8**, removing this plan — branch
  `plan-0004-where-does-history-live`, free again after the
  precondition merge. Removal takes the artefact's identifier for
  the same reason a revision does.

Each branch is created in the primary checkout if it is on trunk and
clean, otherwise in a worktree at `.worktrees/<branch>`, per ADR
0003. Until plan 0003 Step 1 lands, `.worktrees/` is not ignored and
the checkout is never clean while a worktree exists, so expect every
branch here to take a worktree.

## Steps

1. **Revise ADR 0003 in place.**
   - **Depends on**: the preconditions.
   - Source text:
     `git show adr-0004-bookkeeping-not-an-artefact:docs/adr/0004-bookkeeping-not-an-artefact.md`.
   - Add a subsection to Decision, after "Commit cadence is
     delegated", titled "Bookkeeping is not an artefact". It carries,
     condensed and without paraphrase drift: the truth-condition test
     (a change is bookkeeping when it is true only because some other
     work is true); the rule (bookkeeping gets no branch of its own
     and rides with the change that makes it true; bookkeeping with
     nothing to ride on is work); that classification is relational,
     with the three-row table; the scope (exempt from branching, from
     nothing else); and the source's own sentence that the test is
     part of the decision rather than its rationale, because it is
     what closes the "only bookkeeping" escape hatch.
   - Add to Alternatives the four rejected options that bear on
     0003's rule: enumerating bookkeeping by file or section;
     treating all ungoverned work as bookkeeping; leaving it to each
     plan; requiring bookkeeping to be a separate commit, which 0003's
     cadence delegation already rules out.
   - Add to Consequences: "branch before edit" acquires a bounded
     exception and the test must appear in the skill body as a rule;
     classification is per change; an eval scenario should cover a
     bookkeeping change.
   - Under "Integration preserves structure", add that a squash also
     discards the trailers ADR 0004 requires, and that the
     no-fast-forward merge is what brackets the commits belonging to
     one artefact.
   - In Context, the second bullet describes the `adr` skill's
     merged-ADR rule as a reason squashing is harmful. That rule is
     withdrawn by ADR 0004. Rewrite the bullet to say so in one
     sentence and keep the first bullet (test-first's auditability
     claim), which still holds.
   - In Alternatives, the "One branch per decision" entry rejects on
     the grounds that it makes "the `adr` skill's lifecycle rules
     unenforceable". Replace that reason with the one that survives
     ADR 0004: the ADR would only ever be merged alongside the thing
     it authorised, so it would have no `Revises` history of its own
     and no moment at which it could be reviewed as a decision.
   - In Consequences, delete the bullet "The `adr` skill's
     prohibition on editing a merged ADR becomes meaningful, because
     an ADR now has a merge of its own." It is no longer true.
   - In References, replace "`skills/adr/SKILL.md` — merged-ADR
     lifecycle rules" with "`skills/adr/SKILL.md` — revision rules".
   - Do not change the `date` field. Do not touch the frontmatter
     otherwise; Step 3 handles the schema.
   - Flip this plan's status to `in-progress` in the same commit. It
     is bookkeeping by 0003's own new test.
   - One commit. Trailer `Revises: docs/adr/0003-git-workflow.md`.
     The body states, in sentences: the bookkeeping exception is
     adopted from the abandoned refining ADR on branch
     `adr-0004-bookkeeping-not-an-artefact`; that ADR's proposed
     `refines` and `refined_by` fields are not adopted and why; the
     immutability consequence is withdrawn by ADR 0004; the
     no-squash rule gains the trailer reason.
   - **Merge now.** Steps 2–5 edit the skill that describes this
     ADR, and the skill must never be ahead of the ADR.
   - Files changed: `docs/adr/0003-git-workflow.md`,
     `plans/0004-where-does-history-live.md`.

2. **Rewrite eval scenarios 0 and 1 against the new `adr` rules.**
   - **Depends on**: Step 1 merged.
   - Both scenarios currently grade the withdrawn schema.
     `evals/scenario-0` is built entirely on supersession: its task
     asks for two ADRs and says "leave all records in place", and six
     of its twelve checks assert `supersedes`, `superseded_by` or
     `status: superseded`. `evals/scenario-1` asserts a five-field
     frontmatter and a `superseded` status in two checks.
   - `evals/scenario-0`: rewrite `task.md` so the fixture already
     contains one accepted ADR, titled as a question ("Which database
     does the project management tool use?"), recording the SQLite
     decision with its Context, Decision, Alternatives and
     Consequences. Provide that ADR's full text in the task, since
     the scenario runs in a fresh checkout. The task then describes
     the PostgreSQL migration exactly as now and asks the agent to
     record it "using the project's standard architectural decision
     record practice". It must not say how many files to produce or
     whether to preserve anything. Rewrite `criteria.json` as a
     `weighted_checklist` asserting: exactly one ADR file exists for
     the database question afterwards, the original edited in place,
     not a second file; its title is still a question; its
     frontmatter is `title`, `status`, `date` and nothing else, with
     `status` one of `proposed` or `accepted`; its `date` is the
     original's, unchanged; the Decision section now decides
     PostgreSQL; the Alternatives section contains an entry for
     SQLite stating that it was the previous decision and why it was
     reversed; no `supersede` vocabulary appears anywhere in the
     file; no ordered task lists or verification content; and, if
     the agent committed, the commit carries
     `Revises: docs/adr/<file>` and a body giving the reason. Weight
     the one-file check and the Alternatives-entry check highest.
     Update `scenario.json`'s description to "ADR revised in place
     when the answer to its question changes".
   - `evals/scenario-1`: leave `task.md` unchanged. In
     `criteria.json`, change "ADR frontmatter completeness" to
     require exactly `title`, `status` and `date`; change "ADR status
     validity" to `proposed` or `accepted`; add a check that the ADR
     title is phrased as a question. Leave the plan-side checks
     unchanged, except "Plan frontmatter completeness", which still
     lists five fields and remains correct.
   - Author both by hand. Do not use `tessl scenario generate`.
   - One commit. Both scenarios are expected to fail against the
     unedited skill; that is the point of doing this step first.
   - Files changed: `evals/scenario-0/task.md`,
     `evals/scenario-0/criteria.json`, `evals/scenario-0/scenario.json`,
     `evals/scenario-1/criteria.json`.

3. **Edit `skills/adr/SKILL.md`.**
   - **Depends on**: Step 2 (same branch, sequential commits).
   - "Location and naming": replace "One ADR per decision. Do not
     amend a merged ADR to record a new decision — supersede it" with
     one ADR per question, the title is the question, and the test:
     if a revision still answers the title's question, edit in place;
     if it answers a new question, write a new ADR and edit the old
     one only where the new decision changes it. Filenames are
     unaffected by the title rule; the slug stays a short
     description.
   - "Frontmatter": schema becomes `title`, `status`, `date`. The
     `title` is phrased as a question. Remove `supersedes` and
     `superseded_by` and their bullets.
   - "Status lifecycle": `proposed` and `accepted` only. Remove
     `superseded`. Add: a decision reversed outright is deleted, and
     the deleting commit says why.
   - New section "Revising an ADR", after "Status lifecycle": edit in
     place; the commit carries `Revises: <path>` and a body saying
     what changed and why; when a revision reverses an adopted path,
     add an Alternatives entry summarising the reversal; on the same
     branch, every plan in the tree whose `adr:` names this ADR is
     revised to match or set to `deferred` with a reason naming the
     revision. State that `Revises` is for accepted ADRs: a typo fix
     carries no trailer, and nor does an edit to a `proposed` ADR
     still being drafted. Quote the trailer form once so it is
     copied, not paraphrased.
   - New short section "The introducing commit": the first commit on
     the ADR's branch carries `Derives-From: <path>` for each
     discovery note it derives from, where one exists. Direct
     upstreams only.
   - New section "Before writing", placed before "Location and
     naming" so it is met first: read every ADR in `docs/adr/`
     before writing a new one. The tree holds only current
     decisions, so this is the complete set of what is decided. Do
     not write an ADR that answers a question an existing ADR
     already answers (revise that one), and do not adopt a path an
     existing ADR's Alternatives section rejects without saying, in
     the new ADR's Alternatives, why the rejection no longer holds.
   - "Body", item 6 (References): expand from "related ADRs,
     external material" to: each ADR whose decision this one relies
     on or constrains, with a phrase saying which, plus external
     material. State that References records what a decision uses,
     and that `Derives-From` on the commit records what the artefact
     was produced from; the two are different relations.
   - "Do not": replace "Do not edit a merged ADR to change the
     decision. Write a superseding ADR." with "Do not write a new ADR
     to change the answer to a question an existing ADR already
     answers. Revise it." Replace "Do not delete superseded ADRs.
     They are the historical record." with "Do not keep a reversed
     ADR in the tree under a status flag. Delete it; the commit and
     git history are the record."
   - Leave the `description` and the "Required forward-pointer"
     section unchanged. The history-skill directive is ADR 0005's.
   - In the same commit, bring ADRs 0001, 0002 and 0003 to the new
     schema: remove their `supersedes` and `superseded_by` lines,
     and rephrase their `title` fields and H1s as questions. Use:
     0001 "How do downstream skills get loaded at the right moment?";
     0002 "How are new skills authored?"; 0003 "Where does work
     happen, and how does it land?". Filenames do not change. This
     is bookkeeping made true by the schema change.
   - Files changed: `skills/adr/SKILL.md`,
     `docs/adr/0001-artifact-embedded-skill-directives.md`,
     `docs/adr/0002-skill-forge.md`, `docs/adr/0003-git-workflow.md`.

4. **Edit `skills/plans/SKILL.md`.**
   - **Depends on**: Step 3 (same branch, sequential commits).
   - Opening paragraph: replace "live permanently in the repo so the
     whole team (and future agents) can see what work has been done,
     is in flight, is paused, or was abandoned" with: plans live in
     the tree while their work is intended and leave it when the work
     is done or abandoned; git history holds what has been finished.
   - "Frontmatter" and "Status lifecycle": `status` is `draft`,
     `in-progress` or `deferred`. Remove `done` and `abandoned`.
     Replace their bullets with: completion is expressed by deleting
     the plan file in the final commit on the last implementation
     branch, trailer `Completes: <path>`, body saying what the plan
     produced; abandonment by deleting it with trailer
     `Abandons: <path>` and a body saying why. Both bodies are
     mandatory. Keep `deferred` as is.
   - "Status updates ride with the code changes": keep, and make the
     completion case concrete: the deleting commit is the one that
     makes completion true.
   - New short section "The introducing commit": the first commit on
     the plan's branch carries
     `Derives-From: docs/adr/NNNN-<slug>.md`. A plan's direct
     upstream is its ADR; it does not name the discovery note behind
     the ADR.
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

5. **Edit `skills/facilitated-discovery/SKILL.md`.**
   - **Depends on**: Step 4 (same branch, sequential commits).
   - Phase 6B: after the note is written, add that it leaves the tree
     when the ADR it informed is accepted, deleted on that ADR's
     branch with trailer `Consumed-By: <ADR path>`.
   - Phase 6A: add that the ADR's first commit carries `Derives-From`
     naming the discovery note, where one exists, as the `adr` skill
     now states.
   - Nothing else changes.
   - **Merge now.** Step 6 applies the rule Step 4 writes.
   - Files changed: `skills/facilitated-discovery/SKILL.md`.

6. **Retire plans 0001 and 0002.**
   - **Depends on**: Steps 2–5 merged.
   - `git rm plans/0001-artifact-embedded-skill-directives.md`. One
     commit, trailer
     `Completes: plans/0001-artifact-embedded-skill-directives.md`.
     Body: one sentence on what it produced (the per-step directive
     wrappers in the `plans` skill) and that it landed in `74e880c`.
   - `git rm plans/0002-skill-forge.md`. One commit, trailer
     `Completes: plans/0002-skill-forge.md`. Body: one sentence on
     what it produced (the `skill-forge` skill and
     `evals/skill-forge-0/`) and that it landed in `1e7d948`.
   - **Merge now.**
   - Files changed: both plan files removed.

7. **Revise plan 0003 on its branch.**
   - **Depends on**: Step 1 merged. ADR 0004's same-branch rule does
     not bind here, because plan 0003 is not in trunk's tree; it is
     on its own unmerged branch, and that is where it is revised.
   - Merge trunk into `plan-0003-git-workflow` first (`git merge
     --no-ff main` from that branch), so the plan is revised against
     the revised ADR 0003 and the new skills. Do not rebase.
   - Step 4 of plan 0003 (the skill body): add bullets requiring the
     git-workflow skill to state, without paraphrase drift from ADR
     0004: the trailer vocabulary, verbatim as a table; that the
     graph is append-only and the table exhaustive; that
     `Derives-From` sits on the first commit of an artefact's branch
     and names direct upstreams only, one trailer each; that trailers
     record edges between artefacts and intra-artefact commit order
     belongs to the governing skill; that the body of a `Revises`,
     `Abandons` or deleting commit gives the reason; and that a
     squash discards trailers, as a second reason it is prohibited.
     Add a bullet requiring the body to carry the bookkeeping test
     and rule from revised ADR 0003.
   - Step 6 of plan 0003: replace the flip to `status: done` with
     deletion of the plan file in the final commit before the last
     merge, trailer `Completes: plans/0003-git-workflow.md`, body
     saying what it produced. Keep the flip to `in-progress`.
   - Step 3 of plan 0003 (the eval scenario): add an assertion that
     a bookkeeping change made during the scenario rides with the
     artefact's commit rather than taking a branch, and one that the
     first commit on the ADR branch carries a `Derives-From` trailer
     or, where there is no upstream, none.
   - "Execution shape" and "Verification" of plan 0003: update the
     sentences that describe Step 6 and the "frontmatter reads
     `status: done`" check to match.
   - One commit on `plan-0003-git-workflow`. No trailer: the plan's
     edges are unchanged, and ADR 0004 attaches no trailer to a
     content change that leaves edges as they were. The body says
     the revision follows ADR 0003's revision and ADR 0004.
   - Do not merge. Plan 0003 lands when its own work does.
   - Files changed: `plans/0003-git-workflow.md`.

8. **Remove this plan and clean up.**
   - **Depends on**: Steps 1–7.
   - Branch `plan-0004-where-does-history-live` from trunk.
     `git rm plans/0004-where-does-history-live.md`. One commit,
     trailer `Completes: plans/0004-where-does-history-live.md`.
     Body: one sentence on what it produced (ADR 0003 revised, three
     skills and two evals brought under ADR 0004, plans 0001 and
     0002 retired, plan 0003 revised).
   - **Merge now.** Delete the branch. Return the primary checkout
     to trunk.
   - Leave `adr-0004-bookkeeping-not-an-artefact` and its worktree
     alone. It is unmerged and ADR 0003 says nothing removes such
     work automatically. Its adopted content is in trunk's history
     after Step 1 and its rejected fields are recorded in Step 1's
     commit body; deleting the branch after that is the user's call,
     and would lose the original 221-line text.
   - Leave `discovery-0001-history-skill` alone. It belongs to ADR
     0005's chain and is merged on its own.
   - Files changed: this plan removed.

## Non-goals

- The history skill and the `adr` skill's directive to it. ADR 0005,
  from `docs/discovery/0001-history-skill.md`.
- The git-workflow skill body and its eval. Plan 0003.
- A `commit-msg` hook enforcing trailers. ADR 0003 parks enforcement
  and ADR 0004 does not unpark it.
- Renaming ADR files to match their new question titles. The slug is
  a description, not the title, and renaming breaks nothing that
  needs fixing.
- Gitignoring `.worktrees/`. Plan 0003 Step 1.
- The copies of these skills installed outside the repository (for
  example under `~/.claude/skills/`). They are `tessl install`
  outputs, not sources.

## Verification

- `grep -l '^supersede' docs/adr/*.md` returns nothing. (Anchored:
  the fields sat at column zero; ADR 0004 discusses the words in
  prose and must not match.)
- `grep -c '^title: .*?$' docs/adr/*.md` reports 1 for every ADR.
- `docs/adr/0003-git-workflow.md` contains "truth condition" or
  "truth-condition", contains no "becomes meaningful", no
  "lifecycle rules unenforceable" and no "merged-ADR lifecycle
  rules", and mentions trailers under its integration section.
- `git log --format='%(trailers:key=Revises,valueonly)' | grep -c docs/adr/0003`
  is at least 1.
- `git log --format='%(trailers:key=Completes,valueonly)'` lists
  plans 0001, 0002 and 0004; none of those files is in the tree.
- `skills/adr/SKILL.md` contains no "Do not edit a merged ADR" and
  no `superseded_by`; contains "Revises:", "Derives-From:", the
  question test, and a "Before writing" section that precedes
  "Location and naming".
- `grep -c '^- \*\*done\*\*\|^- \*\*abandoned\*\*' skills/plans/SKILL.md`
  is 0; the file contains "Completes:", "Abandons:" and
  "Derives-From:", and contains no "Do not delete plans".
- `skills/facilitated-discovery/SKILL.md` contains "Consumed-By:".
- `evals/scenario-0/criteria.json` and `evals/scenario-1/criteria.json`
  contain no "supersede"; `evals/scenario-0/task.md` contains the
  fixture ADR and does not say how many files to produce.
- On branch `plan-0003-git-workflow`, `plans/0003-git-workflow.md`
  contains "Completes: plans/0003-git-workflow.md", contains
  "append-only", and contains no "status: done".
- `git log --merges --format=%p main` shows two parents for every
  merge made by this plan, and `git log main --oneline | grep -c
  '^.\{7\} Merge'` has grown by five: the plan, Step 1, Steps 2–5,
  Step 6, Step 8.
- `git branch --list adr-0004-bookkeeping-not-an-artefact` still
  exists unless the user has removed it.

## Progress notes

- 2026-09-16: drafted against ADR 0004 (status `proposed`) on branch
  `plan-0004-where-does-history-live`, in a worktree because the
  primary checkout was on `plan-0003-git-workflow`.
- 2026-09-21: revised after independent review. The plan file had
  no route onto trunk before Step 1 tried to edit it; merges were
  implicit; the two eval scenarios grading the withdrawn schema were
  uncovered; ADR 0003 kept two stale references to the withdrawn
  rule; verification greps matched their own prose. Also brought in
  line with ADR 0004's revised trailer section (append-only graph,
  first-commit `Derives-From`, direct upstreams, intra-artefact
  exclusion). Nothing here executes until ADR 0004 is accepted.
