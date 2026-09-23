---
title: Which parts of git-workflow should be a script rather than instructions?
status: in-progress
date: 2026-09-23
---

# Which parts of git-workflow should be a script rather than instructions?

## Problem

`git-workflow` is a 196-line skill body that an agent is expected to
follow at every stage of work, from the first discovery note to the
release. On 2026-09-23 its behaviour was measured under two models on
an unchanged body and fixture (`evals/git-workflow-1`, three repeats
each): claude-sonnet-5 scored 94, 100, 100; deepseek-v4-flash scored
18, 0, 0, where the agent merged into trunk against the rules or
never branched at all. The skill now declares a sonnet-class model
floor in its frontmatter and the release gate is pinned to that
model at ten times the cost per scenario execution.

The rules the weak model broke are mechanical: derive the trunk from
three refs, read two contention facts, name a branch from a path,
create a branch or worktree and copy small config files, push, open
a pull request or stop and report, clean up only on merge. None of
them needs judgement. Running them as instructions asks a model to
be deterministic, and the measurement says the smaller ones are not.
The judgement in the skill is elsewhere: what the artefact is, what
it derives from, what a commit contains, all of which ADR 0003 already
delegates to the governing skill.

## What we've covered

- The open Agent Skills specification supports a `scripts/` directory
  in a skill, so a script ships with the skill and is loaded on
  demand. Nothing in tessl's packaging prevents it.
- ADR 0003 decides the workflow, not its implementation; it says the
  commands that realise integration on a host belong to whatever
  skill knows the host. A script is within that decision, but "the
  mechanics are a shipped script and the model decides what and when"
  changes how the skill body reads and is worth a short revision of
  ADR 0003 so the decision says it.
- ADR 0004 is untouched: trailers still ride on commits, which stay
  with the model and the governing skill. The eval criteria are
  untouched: they score git state, not how it was produced.
- The cost is smaller than every ADR that commits. Rule 3 delegates
  commit content already; the governing skills change only in that
  "branch before edit" points at a command. The git-workflow body
  shrinks to "run this at these moments", which it needs anyway: it
  is over the spec's 5,000-token guideline.
- The same day's data separates two failure modes that the current
  body cannot: "merged into trunk when it should not", which a script
  that owns landing removes outright, since it never merges locally
  when `git remote` prints a remote; and "never branched at all",
  which is the model not invoking the skill at the right moment. The
  second survives a script. On the sonnet gate run for 0.1.1, with
  the whole plugin injected, `git-workflow-0` scored 20, 72, 68 and
  activated only the `adr` skill in the low repeats; with only
  git-workflow injected the day before it scored 82 and 95. The
  eval record's per-repeat `activatedSkills` field is the direct
  observation of this, and tessl has said the measurement is theirs
  and under development.

## Open questions

- **What the script's interface is.** Two verbs look sufficient,
  `begin <artefact-path>` and `land`, plus perhaps `check`. Whether
  `begin` takes the upstream path for `Derives-From` or leaves the
  trailer to the governing skill's commit is open; the trailer is
  the one mechanical thing that sits on a commit.
- **Language and dependencies.** Bash is what the fixtures use and
  has no dependency; the spec says supported languages depend on the
  harness. A script that needs Python or a host CLI changes the
  `compatibility` field.
- **The host half.** Opening and merging a pull request is the
  platform-specific part ADR 0003 leaves to a platform skill that
  does not exist. A script can shell out to `gh` where present and
  stop and report where not, which is the rule the body carries now,
  but that makes the script host-aware in a way the body avoided.
- **Whether the model floor comes off, and for which half.** If the
  script absorbs the mechanics, the floor applies only to the trigger
  and the judgement that remain. That is measurable, below, and the
  release gate's pin and cost follow from the answer.

## Next steps

These are the tests the plan must carry; do not let them drop.

1. **Before and after on the weak model.** Run `git-workflow-0` and
   `git-workflow-1` on deepseek-v4-flash, three repeats each, before
   and after the script. Before is already measured: 18, 0, 0 on
   `git-workflow-1` (run `01a0ce24-dd76-729a-ab72-dd5ac616799d`).
   If the script absorbs the mechanics, the after climbs toward
   sonnet's 94, 100, 100. This is the acceptance criterion, and it
   fails without the change.
2. **Show which failure mode remains.** After the script, read the
   per-repeat `activatedSkills` and the scorer's reasoning on any
   low repeat: what is left should be "never invoked", not "merged
   wrongly". That number is the input the enforcement and
   landing-gate work needs.
3. **Shell tests for the script itself**, under `test-first-workflow`:
   each rung of trunk derivation and the stop when none resolves;
   contention on and off trunk, clean and dirty; naming from a path;
   bootstrap copying without built dependencies; push-then-stop when
   no host command exists; cleanup only after merge. These are the
   scenarios' criteria as unit tests, and they cost no credits.
4. **Remove the model floor on evidence.** If (1) puts deepseek
   within the gate's threshold of sonnet, take `model: sonnet` off
   git-workflow, rewrite `compatibility` citing the runs, and move
   the release gate's pin with it. If not, the floor stays and the
   evals say why.

Then: a revision of ADR 0003 stating that the mechanics are a shipped
script, and a plan numbered from history, which is 0005. Eval runs
wait for the credit renewal on 2026-09-28; the shell tests do not.
