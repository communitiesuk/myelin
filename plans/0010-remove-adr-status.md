---
title: Remove the ADR status field
status: draft
adr: 0009
date: 2026-10-14
deferred_reason: null
---

# Remove the ADR status field

## Reference

Implements [ADR 0009](../docs/adr/0009-adr-acceptance.md).
Related: `plans/0011-stage-reviews.md` (ADR 0008), implemented after this one.

## Steps

The trunk is `dev` (resolved by `git-workflow`; `workflow.trunk` is unset). All of Steps 1 to 7 are done on one implementation branch, cut from `dev`, and land in one merge. Branching, the `Derives-From: plans/0010-remove-adr-status.md` trailer on the implementation branch's first commit, and landing all follow `git-workflow`. The plans skill puts two commits in fixed places. The first implementation change flips this plan's `status` from `draft` to `in-progress` in the same commit. The commit in Step 7 deletes this plan. Nothing else here fixes commit boundaries.

No commit made under this plan carries a `Revises` trailer. None of these edits changes what any ADR decides.

### Step 1: Remove `status` from ADRs 0001 to 0008

Each of these eight files has its `status` line on line 3 of the frontmatter:

| File | Line 3 now |
| --- | --- |
| `docs/adr/0001-artifact-embedded-skill-directives.md` | `status: accepted` |
| `docs/adr/0002-skill-forge.md` | `status: accepted` |
| `docs/adr/0003-git-workflow.md` | `status: accepted` |
| `docs/adr/0004-where-does-history-live.md` | `status: accepted` |
| `docs/adr/0005-releases.md` | `status: accepted` |
| `docs/adr/0006-where-do-captured-ideas-live.md` | `status: accepted` |
| `docs/adr/0007-readme-requirements-and-opinions.md` | `status: accepted` |
| `docs/adr/0008-stage-reviews.md` | `status: proposed` (the stale value) |

`docs/adr/0009-adr-acceptance.md` already has no `status` line and does not change.

Delete line 3 from each file and change nothing else (BSD `sed`, as on this machine):

```sh
sed -i '' '3{/^status: /d;}' docs/adr/000[1-8]-*.md
```

Check:

```sh
for f in docs/adr/*.md; do printf '%s: ' "$f"; awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f{sub(/:.*/,"");printf "%s ",$0}' "$f"; echo; done
```

prints `title date` for all nine files, and

```sh
git diff -U0 dev...HEAD -- docs/adr/ | grep -E '^[-+]' | grep -vE '^(---|\+\+\+) '
```

run after committing, prints exactly eight lines: seven `-status: accepted` and one `-status: proposed`.

### Step 2: Update the evals that require or instruct a `status` field

The line numbers in Steps 2 and 3 and Verification 4 are those of `dev` when this plan was written. If `dev` has changed these files since, re-derive the line numbers from the quoted text.

`evals/scenario-0/criteria.json`:

- `context`: replace `its frontmatter is the three-field schema` with `its frontmatter is the two-field schema of title and date`.
- The check named `Frontmatter is exactly title, status and date`: rename it to `Frontmatter is exactly title and date`. Set its description to `The ADR's YAML frontmatter contains exactly two fields: title and date, and no others. A status field, or any other additional field, fails this check`. Keep `max_score` at 10.
- The check named `No replaced-record vocabulary`: in its description, replace `no frontmatter field naming a record this one replaces or is replaced by, no status value other than proposed or accepted, and no body prose` with `no frontmatter field naming a record this one replaces or is replaced by, and no body prose`. Keep `max_score` at 10.

`evals/scenario-0/task.md`:

- Delete the line `status: accepted` (line 18) from the fixture ADR `docs/adr/0001-which-database.md`.
- In the section ``## The existing record: `docs/adr/0001-which-database.md` ``, insert this as a new sentence immediately after the sentence ending `already exists in the project with the content below.`, in the same paragraph:

  ```markdown
  The record was accepted and has been on the project's main branch for some time.
  ```

`evals/scenario-1/criteria.json`:

- The check named `ADR frontmatter completeness`: set its description to `The ADR file's YAML frontmatter contains exactly two fields: title and date — and no others`. Keep `max_score` at 8.
- Delete the whole check object named `ADR status validity` (`max_score` 7). That leaves 12 checks.

`evals/git-workflow-0/task.md` and `evals/git-workflow-1/task.md` (identical text at these lines):

- Line 13: replace ``frontmatter with `title`, `status` and `date`, then `## Context`,`` with ``frontmatter with `title` and `date`, then `## Context`,``.
- Lines 38 to 44: replace the bullet

  ```markdown
  - A new ADR under `docs/adr/`, taking the next number in the sequence
    and following the file-naming and section structure of the two
    existing ADRs. It should record the decision above as `accepted`,
    give the reasoning from the discovery note as its context, name the
    firmware rollout as the alternative that was considered and deferred,
    and state the consequence that liveness detection now depends on a
    sampled signal.
  ```

  with

  ```markdown
  - A new ADR under `docs/adr/`, taking the next number in the sequence
    and following the file-naming and section structure of the two
    existing ADRs. It should give the reasoning from the discovery note
    as its context, name the firmware rollout as the alternative that
    was considered and deferred, and state the consequence that liveness
    detection now depends on a sampled signal.
  ```

`evals/git-workflow-0/setup.sh`: delete the `status: accepted` lines at 89 and 114, which are in the fixture ADRs `docs/adr/0001-http-client-timeouts.md` and `docs/adr/0002-configuration-loading.md`.

`evals/git-workflow-1/setup.sh`: delete the `status: accepted` lines at 78 and 103, in the same two fixture ADRs.

Do not change `evals/plan-numbering-0/setup.sh`, or the "Plan status updated" checks in `evals/scenario-3/` and `evals/scenario-4/`.

Check:

```sh
for f in evals/scenario-0/criteria.json evals/scenario-1/criteria.json; do jq -e . "$f" >/dev/null && echo "$f ok"; done
jq '.checklist | length' evals/scenario-1/criteria.json        # 12
grep -rnE 'title, status,? and date|status value|status field is set|status validity|proposed or accepted|three-field' evals/scenario-0 evals/scenario-1   # no output
grep -n '^status:' evals/scenario-0/task.md                    # no output
grep -nE 'status|as `accepted`' evals/git-workflow-*/task.md   # no output
grep -nE '^status: (proposed|accepted)' evals/git-workflow-*/setup.sh   # no output
bash -n evals/git-workflow-0/setup.sh && bash -n evals/git-workflow-1/setup.sh
tessl eval lint evals/                                         # 9 scenarios valid
```

### Step 3: Update `skills/adr/SKILL.md`

Change only the three places listed here, in the "Frontmatter", "Status lifecycle" and "Revising an ADR" sections. Plan 0011 also edits this file; touch nothing else in it. The `description` stays as it is.

1. **Frontmatter section.** Delete the `status: proposed` line from the YAML example, which leaves `title` and `date`. Delete this bullet:

   ```markdown
   - **status**: `proposed` | `accepted`.
   ```

   Add this bullet after the `date` bullet:

   ```markdown
   - There is no `status` field. Where an ADR is says whether it is accepted (see "Proposed and accepted"). Do not add one.
   ```
2. **The `## Status lifecycle` section.** Rename the heading to `## Proposed and accepted`. Replace its two `proposed`/`accepted` bullets with the following text, and keep the existing closing paragraph ("A decision that is reversed outright is deleted, not marked. The commit that deletes it says why."):

   ```markdown
   - **Proposed**: not yet on the trunk. The ADR is on its own branch (the branch that adds it), and in that branch's pull request once one is open. It may change during review.
   - **Accepted**: on the trunk. It is the current decision of record, and it stays accepted while a revision of it is proposed on another branch. It may or may not be implemented yet. Implementation state is tracked in the corresponding `plans/` entry, not here.
   - **The human's merge is the act of accepting.** The merge commit records who accepted and when. There is nothing to set or flip.
   - **Not accepting** is either asking for changes, after which work continues on the branch, or closing the pull request unmerged. An ADR whose pull request is closed unmerged was not accepted and is no longer proposed. It never reaches the trunk.
   ```
3. **Revising an ADR section, last bullet.** Replace

   ```markdown
   and nor does an edit to a `proposed` ADR, which is still being drafted.
   ```

   with

   ```markdown
   and nor does an edit made on the ADR's own branch before it merges, which is still drafting.
   ```

Leave these as they are:

- `The commit that changes what an accepted ADR decides` in "Revising an ADR".
- `Do not keep a reversed ADR in the tree under a status flag.` in "Do not".

Check:

```sh
grep -nE '^status: |`proposed` \||## Status lifecycle|edit to a `proposed` ADR' skills/adr/SKILL.md   # no output
grep -c "own branch before it merges" skills/adr/SKILL.md                                            # 1
grep -c '^## Proposed and accepted$' skills/adr/SKILL.md                                             # 1
git diff dev...HEAD -- skills/adr/SKILL.md | grep -E '^[-+]description:'                              # no output
```

### Step 4: Update the plans skill's ADR check in `skills/plans/SKILL.md`

Under "Foundational rule", replace

```markdown
Before writing a plan, verify a corresponding ADR exists in `docs/adr/` and is at least `proposed` (ideally `accepted`). If no ADR exists:
```

with

```markdown
Before writing a plan, verify a corresponding ADR exists in `docs/adr/`, either accepted (on the trunk) or proposed (on its own branch, the branch that adds it, whether or not its pull request is open yet). Accepted is better. An ADR carries no status field; where it is says which (see the `adr` skill). `git cat-file -e <trunk>:docs/adr/NNNN-<slug>.md` succeeds if and only if the ADR is on the trunk. An ADR whose pull request was closed unmerged is neither proposed nor accepted; treat it as absent. If no ADR exists:
```

Keep the numbered list that follows unchanged. The plan frontmatter's own `status` field (`draft` | `in-progress` | `deferred`) is a plan's status, not an ADR's, and does not change.

Check:

```sh
grep -c 'at least `proposed`' skills/plans/SKILL.md             # 0
grep -c 'either accepted (on the trunk) or proposed (on its own branch' skills/plans/SKILL.md   # 1
grep -c 'git cat-file -e <trunk>:docs/adr/' skills/plans/SKILL.md           # 1
```

### Step 5: Update the README's status caveat

In `README.md` under `## Status`, replace

```markdown
Decisions marked `accepted` in `docs/adr/` are the current line
```

with

```markdown
Decisions in `docs/adr/` on the trunk are the current line
```

Leave the rest of the paragraph alone. Also leave lines 44 and 56 ("an accepted ADR", "the accepted ADR").

Check: ``grep -c 'marked `accepted`' README.md`` prints `0`.

### Step 6: Sweep for remaining ADR-status references

```sh
grep -rnE '^status: (proposed|accepted)' docs skills evals README.md
```

This prints exactly the six fixture lines that Step 2 leaves alone: `evals/plan-numbering-0/setup.sh` lines 59, 74, 89, 104, 120 and 138. Any other hit is a missed edit.

Leave the following alone:

- `proposed` used as a verb about pull requests in `skills/git-workflow/` (the `SKILL.md` exit-code 3 text, `scripts/git-workflow`, `scripts/tests/land.sh`).
- The `status` fields of discovery notes and plans.
- Narrative mentions of status in `docs/discovery/`.
- `plans/0007-history-based-artefact-numbering.md`.

### Step 7: Complete the plan

Delete `plans/0010-remove-adr-status.md` in the final commit on the implementation branch. That commit carries this trailer:

```
Completes: plans/0010-remove-adr-status.md
```

Its body says, in sentences, what the plan produced: the ADRs lost their `status` field, the `adr` and `plans` skills describe acceptance by location, the evals no longer require or instruct a status, and the README caveat was reworded.

## Verification

All the work is on the single implementation branch, so these ranges cover all of it. Run these checks on that branch before landing, with `RANGE=dev..HEAD` and `DIFF=dev...HEAD`. After landing, run them again with `M` set to the merge commit, `RANGE=M^1..M^2` and `DIFF=M^1...M^2`. Every check reads the tree or history, so deleting the plan file in Step 7 removes no evidence.

1. Every ADR's frontmatter is exactly `title` and `date`. The loop in Step 1 prints `title date` for every file in `docs/adr/`.
2. The ADR edits removed the status lines and nothing else. `git diff -U0 $DIFF -- docs/adr/ | grep -E '^[-+]' | grep -vE '^(---|\+\+\+) '` prints exactly eight lines: seven `-status: accepted` and one `-status: proposed`.
3. No commit revised a decision. `git log --format='%(trailers:key=Revises,valueonly)' $RANGE | sed '/^$/d'` prints nothing. `git diff --name-status $DIFF -- docs/adr/ | grep -c '^M'` prints `8`, and `git diff --name-status $DIFF -- docs/adr/ | grep -vc '^M'` prints `0`.
4. The `adr` skill matches ADR 0009. The Step 3 checks pass (with `dev...HEAD` replaced by `$DIFF`). `git diff -U0 $DIFF -- skills/adr/SKILL.md | grep '^@@'` lists only hunks whose old-file start line (the number after `-`) lies in 29 to 41 (the Frontmatter example and bullets, and the Status lifecycle heading and bullets) or is 58 (the `Revises` exemption bullet), with at least one hunk at 29 and one at 58. Those numbers are the old file's lines, so they stay valid after landing.
5. The plans skill no longer depends on a status field. The Step 4 checks pass.
6. The evals no longer require or instruct a status field and still parse. The Step 2 checks pass, including `tessl eval lint evals/` printing `9 scenarios valid`.
7. The README caveat no longer refers to a status. The Step 5 check passes.
8. The sweep in Step 6 prints exactly the six fixture lines listed there.
9. The plan is complete. Before landing: `test ! -e plans/0010-remove-adr-status.md` succeeds on the branch, and `git log $RANGE --format='%(trailers:key=Completes,valueonly)' | grep -x 'plans/0010-remove-adr-status.md'` prints one line. After landing only: `git cat-file -e dev:plans/0010-remove-adr-status.md` fails, and `git log dev --format='%(trailers:key=Completes,valueonly)' | grep -x 'plans/0010-remove-adr-status.md'` prints one line.

## Progress notes

