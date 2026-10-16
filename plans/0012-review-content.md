---
title: Review what each stage adds, and fix findings by cutting
status: draft
adr: 0008
date: 2026-10-16
deferred_reason: null
---

# Review what each stage adds, and fix findings by cutting

## Reference

Implements the revision of `docs/adr/0008-stage-reviews.md` merged in
PR #95 (`git diff 87934d2 615f362 -- docs/adr/0008-stage-reviews.md`):
"Each stage checks what it adds", "Findings are fixed by cutting, not
by adding", and "The briefs keep the existing check categories and
sections". Plan 0011 implemented the rest of ADR 0008 and has left the
tree.

## Steps

Steps 1 to 3 edit existing skill bodies and references and change no
`description`, so they carry no wrapper. Step 1's commit also flips
this plan to `status: in-progress`. Steps 1 to 3 spend no credits;
Step 4 spends some, and says how many.

### Step 1 — Add the new checks to both reviewer briefs

Edit only the `## What you check` section of each brief.

In `skills/adr/references/review.md`, replace

```
ADR says nothing about implementation. Until ADR 0004's history skill
```

with

```
ADR says nothing about implementation. Check form against the rules
in the `adr` skill's `SKILL.md`: for example, frontmatter, required
sections, a question-shaped title and the forward-pointer. Text the
ADR does not need is a finding: cut it. Until ADR 0004's history skill
```

In `skills/plans/references/review.md`, replace the section's text
from `Check fidelity:` to the end of the file with

```
Check the plan's internal consistency. Check fidelity: everything the
ADR decided is implemented, and nothing it did not decide. Check
verifiability by trying it: apply the plan's checks to a scratch copy
of the repository, never the repository itself, and run them; and
confirm that every file, line and quoted string the plan refers to
exists as described. For each assertion the plan requires: can it be
observed afterwards, and does another step destroy the evidence? Each
eval assertion must discriminate: doing nothing cannot pass it, and
nothing is scored from what the scorer cannot see. Check form against
the rules in the `plans` skill's `SKILL.md`: for example, frontmatter,
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
for p in 'internal consistency' 'scratch copy' 'quoted string' 'doing nothing cannot pass it' 'verbatim wrappers' 'is an escalation'; do grep -c "$p" skills/plans/references/review.md; done   # expect 1 six times
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

> Spends credits: two quality reviews at 10 each, and two eval runs
> without baseline at 15 to 67 each, so 50 to 154 in all. A run below
> 90 is re-run once with `-n 2`, up to about 135 more each. Run one
> scenario at a time, never the whole `evals/` directory.

`plans-0` and `adr-0` exercise the review loop and its closing pass,
where the changed drafter section and briefs apply. Their last scores
are 100 (`01a1439c`, `01a143bc`).

```sh
tessl review run quality skills/adr
tessl review run quality skills/plans
tessl eval lint evals/plans-0   # free; expect 1 scenario valid, no errors
tessl eval lint evals/adr-0     # free; expect 1 scenario valid, no errors
tessl eval run evals/plans-0 --context . --skip-baseline --agent claude --model deepseek-v4.1-flash --label "plan 0012 regression plans-0" --wait --json --yes
tessl eval run evals/adr-0 --context . --skip-baseline --agent claude --model deepseek-v4.1-flash --label "plan 0012 regression adr-0" --wait --json --yes
```

Expected output: each quality score is 84% or more (the last were 88%
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
