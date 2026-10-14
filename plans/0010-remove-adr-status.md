---
title: Remove the ADR status field
status: draft
adr: 0009
date: 2026-10-14
deferred_reason: null
---

# Remove the ADR status field

## Reference

Implements [ADR 0009](../docs/adr/0009-adr-acceptance.md), which revised [ADR 0004](../docs/adr/0004-where-does-history-live.md) (commit `ab0479f`). Related: plan 0011 (ADR 0008, stage reviews) also edits `skills/adr/SKILL.md` and is implemented after this one. This plan's edits to that file are confined to the "Frontmatter", "Status lifecycle" and "Revising an ADR" sections named in Step 3.

## Steps

The trunk is `dev` (resolved by `git-workflow`; `workflow.trunk` is unset). Branching, the `Derives-From: plans/0010-remove-adr-status.md` trailer on the implementation branch's first commit, and landing all follow `git-workflow`. The plans skill puts two commits in fixed places. The first implementation change flips this plan's `status` from `draft` to `in-progress` in the same commit. The commit in Step 7 deletes this plan. Nothing else here fixes commit boundaries.

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

prints `title date` for all nine files. `git diff -U0 -- docs/adr/` shows eight removed lines and no added lines.

### Step 2: Update the eval criteria that require a `status` field

Edit the checks first, so the next run tests the skill text that Steps 3 and 4 write.

`evals/scenario-0/criteria.json`:

- `context`: replace `its frontmatter is the three-field schema` with `its frontmatter is the two-field schema of title and date`.
- The check named `Frontmatter is exactly title, status and date`: rename it to `Frontmatter is exactly title and date`. Set its description to `The ADR's YAML frontmatter contains exactly two fields: title and date, and no others. A status field, or any other additional field, fails this check`. Keep `max_score` at 10.
- The check named `No replaced-record vocabulary`: in its description, replace `no frontmatter field naming a record this one replaces or is replaced by, no status value other than proposed or accepted, and no body prose` with `no frontmatter field naming a record this one replaces or is replaced by, and no body prose`. Keep `max_score` at 10.

`evals/scenario-0/task.md`: delete the line `status: accepted` (line 18) from the fixture ADR `docs/adr/0001-which-database.md`. That way the record the agent revises already follows the two-field schema the check scores.

`evals/scenario-1/criteria.json`:

- The check named `ADR frontmatter completeness`: set its description to `The ADR file's YAML frontmatter contains exactly two fields: title and date — and no others`. Keep `max_score` at 8.
- Delete the whole check object named `ADR status validity` (`max_score` 7). That leaves 12 checks.

Do not change:

- `evals/git-workflow-0/` and `evals/git-workflow-1/`. Their `setup.sh` and `task.md` describe the `orchard` fixture project's own house style (`title`, `status`, `date`), and none of their criteria scores a `status` field.
- `evals/plan-numbering-0/setup.sh`. Its fixture ADRs carry `status: accepted`, but no criterion scores it.
- `evals/scenario-3/` and `evals/scenario-4/`. Their "Plan status updated" checks are about a plan's `status`, not an ADR's.

Check:

```sh
for f in evals/scenario-0/criteria.json evals/scenario-1/criteria.json; do jq -e . "$f" >/dev/null && echo "$f ok"; done
jq '.checklist | length' evals/scenario-1/criteria.json        # 12
grep -nE 'title, status|status value|status field is set|status validity|proposed or accepted|three-field' evals/scenario-0 evals/scenario-1 -r   # no output
grep -n '^status:' evals/scenario-0/task.md                    # no output
```

### Step 3: Update `skills/adr/SKILL.md`

Change only the three places listed here. The `description` stays as it is.

1. **Frontmatter section.** Delete the `status: proposed` line from the YAML example, which leaves `title` and `date`. Delete this bullet:

   ```markdown
   - **status**: `proposed` | `accepted`.
   ```

   Add this bullet after the `date` bullet:

   ```markdown
   - There is no `status` field. Where an ADR is says whether it is accepted (see "Proposed and accepted"). Do not add one.
   ```
2. **The `## Status lifecycle` section.** Rename the heading to `## Proposed and accepted`. Replace its two `proposed`/`accepted` bullets with the following text, and keep the existing closing paragraph ("A decision that is reversed outright is deleted, not marked. The commit that deletes it says why."):
   - **Proposed**: not yet on the trunk. The ADR is on its own branch (the branch that adds it) and that branch's open pull request. It may change during review.
   - **Accepted**: on the trunk. It is the current decision of record, and it stays accepted while a revision of it is proposed on another branch. It may or may not be implemented yet. Implementation state is tracked in the corresponding `plans/` entry, not here.
   - **The human's merge is the act of accepting.** The merge commit records who accepted and when. There is nothing to set or flip.
   - **Not accepting** is either asking for changes, after which work continues on the branch, or closing the pull request unmerged. An ADR whose pull request is closed unmerged was not accepted and is no longer proposed. It never reaches the trunk.
3. **Revising an ADR section, last bullet.** Replace

   ```markdown
   and nor does an edit to a `proposed` ADR, which is still being drafted.
   ```

   with

   ```markdown
   and nor does an edit made on the ADR's own branch before it merges, which is still drafting.
   ```

Leave these as they are. "Accepted" in them now means "on the trunk", so they stay true:

- `The commit that changes what an accepted ADR decides` in "Revising an ADR".
- `Do not keep a reversed ADR in the tree under a status flag.` in "Do not".

Check:

```sh
grep -nE '^status: |`proposed` \||## Status lifecycle|edit to a `proposed` ADR' skills/adr/SKILL.md   # no output
grep -c "own branch before it merges" skills/adr/SKILL.md                                            # 1
grep -c '^## Proposed and accepted$' skills/adr/SKILL.md                                             # 1
git diff -- skills/adr/SKILL.md | grep -E '^[-+]description:'                                        # no output (trigger contract unchanged)
```

### Step 4: Update the plans skill's ADR check in `skills/plans/SKILL.md`

Under "Foundational rule", replace

```markdown
Before writing a plan, verify a corresponding ADR exists in `docs/adr/` and is at least `proposed` (ideally `accepted`). If no ADR exists:
```

with

```markdown
Before writing a plan, verify a corresponding ADR exists in `docs/adr/`, either accepted (on the trunk) or proposed (on its own branch, with that branch's pull request open). Accepted is better. An ADR carries no status field; where it is says which (see the `adr` skill). `git log --oneline <trunk> -- docs/adr/NNNN-<slug>.md` prints the commit that brought it onto the trunk if it is accepted, and nothing if it is not. An ADR whose pull request was closed unmerged is neither. Treat it as absent. If no ADR exists:
```

Keep the numbered list that follows unchanged. The plan frontmatter's own `status` field (`draft` | `in-progress` | `deferred`) is a plan's status, not an ADR's, and does not change.

Check:

```sh
grep -c 'at least `proposed`' skills/plans/SKILL.md             # 0
grep -c 'either accepted (on the trunk) or proposed' skills/plans/SKILL.md   # 1
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

Leave the rest of the paragraph alone. Also leave lines 44 and 56 ("an accepted ADR", "the accepted ADR"): they stay true when accepted means "on the trunk".

Check: `grep -c 'marked `accepted`' README.md` prints `0`.

### Step 6: Sweep for remaining ADR-status references

```sh
grep -rnE '^status: (proposed|accepted)' docs skills evals README.md
```

This prints exactly the ten fixture lines that Step 2 leaves alone: `evals/git-workflow-0/setup.sh` lines 89 and 114, `evals/git-workflow-1/setup.sh` lines 78 and 103, and `evals/plan-numbering-0/setup.sh` lines 59, 74, 89, 104, 120 and 138. Any other hit is a missed edit.

Leave the following alone, because none of them is an ADR status field or a rule about one:

- `proposed` used as a verb about pull requests in `skills/git-workflow/` (the `SKILL.md` exit-code 3 text, `references/RULES.md`, `scripts/git-workflow`, `scripts/tests/land.sh`).
- The `status` fields of discovery notes and plans.
- The narrative mentions in `docs/discovery/0003-escalation-and-orchestration.md` (line 138) and `docs/discovery/0004-skill-freshness-and-distribution.md` (line 214).
- `plans/0007-history-based-artefact-numbering.md`.

### Step 7: Complete the plan

Delete `plans/0010-remove-adr-status.md` in the final commit on the last implementation branch. That commit carries this trailer:

```
Completes: plans/0010-remove-adr-status.md
```

Its body says, in sentences, what the plan produced: the ADRs lost their `status` field, the `adr` and `plans` skills describe acceptance by location, the scenario 0 and 1 checks no longer require a status, and the README caveat was reworded.

## Verification

Run these on the implementation branch before landing, with `RANGE=dev..HEAD` and `DIFF=dev...HEAD`. After landing, run them again with `M` set to the merge commit, `RANGE=M^1..M^2` and `DIFF=M^1...M^2`. Every check reads the tree or history, so deleting the plan file in Step 7 removes no evidence.

1. Every ADR's frontmatter is exactly `title` and `date`. The loop in Step 1 prints `title date` for every file in `docs/adr/`.
2. The ADR edits removed the status lines and nothing else. `git diff -U0 $DIFF -- docs/adr/ | grep -E '^[-+]' | grep -vE '^(---|\+\+\+) '` prints exactly eight lines: seven `-status: accepted` and one `-status: proposed`.
3. No commit revised a decision. `git log --format='%(trailers:key=Revises,valueonly)' $RANGE | sed '/^$/d'` prints nothing. `git diff --name-status $DIFF -- docs/adr/ | grep -c '^M'` prints `8`, and `git diff --name-status $DIFF -- docs/adr/ | grep -vc '^M'` prints `0`.
4. The `adr` skill matches ADR 0009. The Step 3 checks pass, and `git diff $DIFF -- skills/adr/SKILL.md` touches only the Frontmatter, Proposed and accepted (formerly Status lifecycle) and Revising an ADR sections.
5. The plans skill no longer depends on a status field. The Step 4 checks pass.
6. The eval criteria no longer require a status field and still parse. The Step 2 checks pass.
7. The README caveat no longer refers to a status. The Step 5 check passes.
8. The sweep in Step 6 prints exactly the ten fixture lines listed there.
9. The plan is complete. `test ! -e plans/0010-remove-adr-status.md` succeeds on the trunk, and `git log --all --format='%(trailers:key=Completes,valueonly)' | grep -x 'plans/0010-remove-adr-status.md'` prints one line.

## Progress notes

