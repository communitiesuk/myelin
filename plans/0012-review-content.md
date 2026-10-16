---
title: Review what each stage adds, and fix findings by cutting
status: in-progress
adr: 0008
date: 2026-10-16
deferred_reason: null
---

# Review what each stage adds, and fix findings by cutting

## Reference

Implements the revision of `docs/adr/0008-stage-reviews.md` merged in
PR #95. Related: plan 0011, which implemented the rest of ADR 0008 and
has left the tree.

## Steps

Step 1's commit also flips this plan to `status: in-progress`.

### Step 1 — Add the new checks to both reviewer briefs

Edit only the `## What you check` section of each brief.

In `skills/adr/references/review.md`, replace the section's last line,
`directly.`, with

```
directly. Check form against the rules in the `adr` skill's
`SKILL.md`: for example, frontmatter, required sections, a
question-shaped title and the forward-pointer. Text the ADR does not
need is a finding: cut it.
```

In `skills/plans/references/review.md`, replace the section's text
from `The upstream is` to the end of the file with

```
The upstream is the ADR the plan implements. Rely on the ADR being
consistent; do not review it. Check the plan's internal consistency.
Check fidelity: everything the ADR decided is implemented, and nothing
it did not decide. Check verifiability by trying it: on a scratch copy
of the repository, apply the plan's steps, then run its checks. Do not
run `tessl eval run` or `tessl review run`, which spend credits; check
that they are well formed instead (lint, paths, flags). Confirm that
every file, line and quoted string the plan refers to exists as
described. For each assertion the plan requires: can it be observed
afterwards, and does another step destroy the evidence? Each eval
assertion must discriminate: doing nothing cannot pass it, and nothing
is scored from what the scorer cannot see. Check form against the
rules in the `plans` skill's `SKILL.md`: for example, frontmatter,
required sections and verbatim wrappers. Text the plan does not need
is a finding: cut it. A plan that cannot be faithful without changing
the ADR is an escalation.
```

Check:

```sh
for s in adr plans; do f=skills/$s/references/review.md; diff <(git show 615f362:$f | sed '/^## What you check$/q') <(sed '/^## What you check$/q' $f) && echo "$s kept"; done   # expect adr kept, plans kept
grep -c '^## ' skills/adr/references/review.md skills/plans/references/review.md                                                                  # expect 4 for each
grep -c 'is a finding: cut it\.' skills/adr/references/review.md skills/plans/references/review.md                                                  # expect 1 for each
grep -c 'Check form against' skills/adr/references/review.md skills/plans/references/review.md                                                      # expect 1 for each
for p in 'internal consistency' 'scratch copy' 'quoted string' 'doing nothing cannot pass it' 'verbatim wrappers' 'is an escalation' 'well formed'; do grep -c "$p" skills/plans/references/review.md; done   # expect 1 seven times
```

Commit: `Add form, cut-it and tried-verifiability checks to the reviewer briefs`.

### Step 2 — Tell drafters to fix findings by cutting

In both `skills/adr/SKILL.md` and `skills/plans/SKILL.md`, in
`## If you are a drafter subagent`, insert immediately above the line
`- Finish the whole task, even after you find an escalation.`:

```
- Aim for concision and consistency, but do not let them hold you up.
- When you revise existing text, act only on the recorded decisions
  and any change you are applying. Apply each by cutting text where
  that loses no fidelity, consistency or verifiability; then by
  replacing it, which includes correcting it, aiming to lower the
  character count. Add text only as a last resort.
```

Check:

```sh
d() { sed -n '/^## If you are a drafter subagent$/,/^## Drafting and review$/p' "$1"; }
diff <(d skills/adr/SKILL.md) <(d skills/plans/SKILL.md) && echo same                                                   # expect same
d skills/plans/SKILL.md | grep -c 'Add text only as a last resort\.'                                                       # expect 1
block() { sed -n '/<!-- review-loop:begin -->/,/<!-- review-loop:end -->/p' "$1"; }
diff <(block skills/adr/SKILL.md) <(block skills/plans/SKILL.md) && echo same                                            # expect same
diff <(git show 615f362:skills/plans/SKILL.md | block /dev/stdin) <(block skills/plans/SKILL.md) && echo unchanged          # expect unchanged
```

Commit: `Tell drafters to fix findings by cutting, then replacing`.

### Step 3 — Cap a new ADR at the two-minute guideline

In `skills/adr/SKILL.md`, under `## Body`, replace

```
Keep it tight — a reader should be able to scan an ADR in under two minutes.
```

with

```
Keep it tight — a reader should be able to scan an ADR in under two minutes. That caps a new ADR: one that goes over it is cut, not split. An existing ADR over it is a candidate for decomposition.
```

Check:

```sh
grep -c 'That caps a new ADR: one that goes over it is cut, not split\.' skills/adr/SKILL.md   # expect 1
grep -c 'candidate for decomposition\.' skills/adr/SKILL.md                                  # expect 1
```

Commit: `Cap a new ADR at the two-minute scanning guideline`.

### Step 4 — Run the regressions (spends credits)

> Spends credits: two quality reviews at 10 each, and four eval runs
> without baseline at 15 to 67 each, so 80 to 288 in all. A run below
> 90 is re-run once with `-n 2`, up to about 135 more each. Run one
> scenario at a time, never the whole `evals/` directory.

`plans-0`, `plans-1`, `adr-0` and `adr-1` exercise the review loop,
where the changed drafter section and briefs apply. Their last scores
are 100 (`01a1439c`, `01a140c8`, `01a143bc`, `01a140b0`).

```sh
tessl review run quality skills/adr --threshold 84
tessl review run quality skills/plans --threshold 84
for s in plans-0 plans-1 adr-0 adr-1; do tessl eval lint evals/$s; done   # free; expect 1 scenario valid, four times
for s in plans-0 plans-1 adr-0 adr-1; do tessl eval run evals/$s --context . --skip-baseline --agent claude --model deepseek-v4.1-flash --label "plan 0012 regression $s" --wait --json --yes; done
```

For a run below 90, with `s` set to its scenario:

```sh
tessl eval run evals/$s --context . --skip-baseline --agent claude --model deepseek-v4.1-flash -n 2 --label "plan 0012 regression $s re-run" --wait --json --yes
```

Expected output: each quality review exits zero (the last scored 88%
for both, and identical runs vary by up to 4 points); each eval run
scores 90 or more, or its `-n 2` median does. A run still below 90 is
an escalation to the human.

Record each run id, score and cost in Progress notes, in the commit
`Record plan 0012's regression runs`.

## Verification

- Every check in Steps 1 to 3 gives its expected output on the final
  tree.
- Step 4's scores meet their thresholds.
- The plan is deleted in the last commit, which carries
  `Completes: plans/0012-review-content.md` and says in its body what
  the plan produced.

## Progress notes
