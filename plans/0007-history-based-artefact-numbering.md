---
title: Number plans and discovery notes from history, not the tree
status: deferred
adr: 0004
date: 2026-09-25
deferred_reason: >-
  Step 3 ran (2026-10-06) and the criterion did NOT discriminate: the
  pre-fix body scored the full 50/50 on the number criterion — a capable
  model picks 0007 without the skill-body command because the fixture's
  task.md itself states the record lives in history, leaking the
  discriminator. The completion gate is therefore unmet. Unblocks by
  redesigning the fixture/task so the pre-fix body genuinely fails (e.g.
  remove the history hint from task.md), then re-running the differential.
---

# Number plans and discovery notes from history, not the tree

## Reference

Implements `docs/adr/0004-where-does-history-live.md`: "Completed and
consumed artefacts leave the tree" means the `plans/` and
`docs/discovery/` directories empty out, so any next-number rule that
counts the tree repeats numbers once an artefact has left. No related
plans are in the tree.

The rename question the todo raised — whether `plans/0004-releases.md`
should become `0005` to resolve its collision with the retired
`0004-where-does-history-live.md` — is already settled and needs no
step here: the commit that completed plan 0004 (`8e67377`) records
that the number stays as it is, because paths are the identifier and
four commits already carry `plans/0004-releases.md`.

## The defect

- `skills/plans/SKILL.md` says the filename is a "monotonic sequence"
  but gives no command for the next number.
- `skills/facilitated-discovery/SKILL.md` tells the author to take the
  next number by `ls docs/discovery/ | sort | tail -1`, which counts a
  directory that empties when a note is consumed.

`skills/adr/SKILL.md` is **not** in scope: ADRs stay in the tree for
as long as their decision stands, so `ls docs/adr/ | sort | tail -1`
is correct there and must be left alone.

The correct source is the highest number ever added to the directory
in history:

```sh
git log --all --diff-filter=A --name-only --format= -- plans/ \
  | grep -oE 'plans/[0-9]{4}' | sort | tail -1
```

and the same with `docs/discovery/` for a discovery note. The next
number is one greater than the four-digit prefix this prints. History
is authoritative because a deferred artefact still in the tree was
also added in history, and a not-yet-committed artefact is numbered
before it is written.

## Steps

Steps 1 and 2 are edits to existing skill bodies — no `description`
(trigger contract) changes — so they are neither `test-first-workflow`
nor `skill-forge` work and carry no directive wrapper. Step 1's first
commit flips this plan to `in-progress`. Both steps write files only
and need no credits; Step 3, which runs the eval, is deferred to the
tessl credit renewal.

### Step 1 — Give both skills the history-based next-number command

Replace the tree-counting instruction in each body with the
history-based command above.

- `skills/plans/SKILL.md`: the "Location and naming" line that today
  reads only "Monotonic sequence independent of the ADR sequence"
  gains the command for `plans/` and states that the number comes from
  history, not from `ls plans/`, because plans leave the tree on
  completion.
- `skills/facilitated-discovery/SKILL.md`: the parenthetical
  "`NNNN` is the next unused number by `ls docs/discovery/ | sort |
  tail -1`" is replaced with the `docs/discovery/` form of the
  command, with the same note that the directory empties when a note
  is consumed.

Both edits name `skills/adr/SKILL.md` in a sentence as deliberately
unchanged, so a later reader does not "fix" it too.

### Step 2 — Author an eval criterion that discriminates the fix

The repository's rule for a skill-body edit that changes behaviour
(the 2026-09-23 note in the todo) is that it wants a criterion which
fails against the pre-fix body and passes against the fixed one. The
existing `plans` scenario is `evals/scenario-1` (ADR-first planning
workflow); it runs on a bare fixture with no history, so it cannot
exercise numbering.

Author a fixture and criterion — either a new scenario or a `setup.sh`
extension to an existing one — whose starting state is a `plans/`
directory that is **empty in the tree** but whose history contains a
higher-numbered plan that has been removed (e.g. history holds
`plans/0006-*.md`, tree holds none). A body that runs `ls plans/`
picks the wrong number (or none); a body that reads history picks the
next number correctly. The criterion scores the number the agent
chooses, so it fails for the tree-counting body and passes for the
history-reading body. Write the fixture so the assertion is capable of
failing (the retired plan must actually be present in history).

Writing these files costs no credits. Do **not** run `tessl eval run`
here.

### Step 3 — Validate the criterion (deferred: needs credits)

> Deferred to the tessl credit renewal (week of 2026-09-28). Do not
> start until credits are available.

Run the new criterion twice: once against the pre-fix skill body to
show it fails, once against the fixed body to show it passes — the
per-criterion differential check. Record the outcome in Progress
notes. If the criterion does not discriminate, fix the fixture or the
body wording and re-run. Only when it discriminates is the plan
complete.

## Verification

- `skills/plans/SKILL.md` and `skills/facilitated-discovery/SKILL.md`
  each contain the history-based command and no longer instruct an
  author to count the tree; `skills/adr/SKILL.md` is unchanged.
- Running the command by hand in this repo prints `plans/0006` and so
  yields `0007` as the next plan number, and prints the correct
  highest `docs/discovery/` number.
- Step 3's differential eval run shows the criterion failing without
  the fix and passing with it. **This is the completion gate and is
  deferred until credits are available.**

## Progress notes

- 2026-09-25: Plan written. Rename question confirmed already decided
  in commit `8e67377`; no step needed for it. Steps 1–2 to be executed
  now (no credits); Step 3 deferred to the credit renewal, so the plan
  is set `deferred` and stays in the tree until Step 3 passes.
- 2026-09-25: Step 1 done — both skills now read the next number from
  history; `skills/adr/SKILL.md` left counting the tree, as intended.
  Verified by hand: the command prints `plans/0006`→next `0007`
  before this plan landed, `docs/discovery/0003`→next `0004`.
- 2026-09-25: Step 2 done — added scenario `evals/plan-numbering-0`.
  Its fixture leaves `plans/` empty in the tree with plans 0001–0006
  in history, so counting the tree gives 0001, matching the ADR gives
  0004, and only reading history gives the correct 0007. Fixture
  test-run confirms the empty tree and the `plans/0006` history max.
  Not yet run through `tessl eval run` (Step 3, deferred to credits).
- 2026-10-06: Step 3 executed on `deepseek-v4.1-flash`, scoped to
  `evals/plan-numbering-0` alone: fixed body — run
  `01a0e75f-1c63-7227-a239-6d37f49f8799`; pre-fix v0.1.1 body — run
  `01a0e75f-264c-72d6-813e-be0fcbfd6cf6`. **Both scored 100%**, and the
  "plan number is derived from history" criterion scored the full 50/50
  on the *pre-fix* body too. The criterion does not discriminate: the
  agent numbers the plan 0007 without the history command, because
  `task.md` tells it the record lives in history. The completion gate
  (fails without the fix, passes with it) is therefore **unmet**, so the
  plan stays `deferred`. No new credits were spent today — the two runs
  already existed, and re-running the identical fixture would only
  reconfirm non-discrimination. Next action is a fixture fix: remove the
  "history is the record" hint from `task.md` (and the `README.md` built
  in `setup.sh`) so a tree-counting body genuinely lands on 0001, then
  re-run the differential.
- 2026-10-06: Fixture neutralised (`7349dc5`) — the hint stripped from
  `task.md`, the `setup.sh` README, and the removal commit message, so
  the agent now meets a genuinely blind task. Re-ran the differential as
  a baseline-vs-`--skill plans` comparison on `deepseek-v4.1-flash`, run
  `01a11201-e39e-7235-8751-9568936b4bf8` (87 credits). **Both arms scored
  100%**: all 16 solves, baseline (no skill) included, created
  `plans/0007-forecast-source.md`. The blind is now valid — the leak is
  gone — but the result is that history-based numbering is a behaviour a
  capable model already has, not one the skill supplies, so the criterion
  cannot discriminate on this model and the completion gate stays unmet.
  This is the same class as git-workflow-0 criterion 5 (the fixture's
  starting state makes the right answer the default). The skill edit
  itself remains correct and is verified by hand (Verification bullet 2).
  Awaiting a maintainer decision on how the gate should resolve.
