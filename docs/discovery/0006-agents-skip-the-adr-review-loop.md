---
title: Why do agents skip the adr skill's summariser and review loop?
status: in-progress
date: 2026-11-19
---

# Why do agents skip the adr skill's summariser and review loop?

## Problem

The 0.6.0 release failed Gate 3. `adr-0` scored a median of 56 against 100
for 0.5.2, and `adr-1` 80 against 100. In each failing `adr-0` repeat, the
agent wrote a good ADR straight onto its branch and stopped. It ran no
summariser and no review loop, so there was no summary, no round record and
no closing pass. Every criterion about the ADR itself scored full marks.
Every criterion about the process around it scored 0.

The release is on hold until the `adr` skill reliably runs its own flow.
The general rule this points to is tracked in #204.

## What we've covered

### Bisect

`adr-0` on claude-sonnet-5-5, three repeats each:

| tree | repeats | failures |
| --- | --- | --- |
| v0.5.2 | 100, 100, 100 | 0 / 3 |
| + roots and in-place edits (`01f693e`) | 100, 100, 56 | 1 / 3 |
| + abandoning an ADR (`26ba1c7`) | 63, 56, 100 | 2 / 3 |
| + a worktree for every artefact (0.6.0 candidate, run `01a1f340-1bc0-72fa-8955-27ae0debf0ca`) | 56, 56, 56 | 3 / 3 |

So this is not model drift: v0.5.2 still passes on today's model. No single
change caused it. The failure rate rose with each change. `adr-1` scores 80
at least once on every tree, v0.5.2 included, so its low 0.6.0 median is
probably noise.

### Diagnosis: a role switch

`adr` and `plans` are each read by two roles: the parent, which runs the
summariser and the review loop, and the drafter subagent, whose instructions
were "this skill". So each skill carried a role switch:

> **If you are a drafter subagent.** You draft or revise the artefact your
> task names, from the inputs it gives you.
>
> **Drafting and review.** If you are a drafter or reviewer subagent, skip
> this section.

The test for being a drafter describes the shape of the task, so a top-level
agent told "Write the ADR" and handed the decisions fits it. Once it decides
it is the drafter, "skip this section" removes the summariser, the flow and
the review loop together.

The switch predates 0.5.2. None of the three changes says anything that
allows skipping. But each made `git-workflow`'s own procedure longer and
more complete: begin, work in `dir=`, get the first commit's trailers right,
land, and for a decision "pushed and proposed, a human merges it… stop". An
agent half-identifying as the drafter can follow every instruction it is
attending to and end at a tidy stopping point. That would explain the
gradual rise. The failure shows up only in evals, not on reading the skill.

### Experiment: a drafter brief

The drafter's instructions moved into `references/drafter.md`, handed to
drafter subagents as the reviewer's `references/review.md` already is, and
both switches were deleted. On the 0.6.0 candidate, `adr-0` scored
**100, 100, 100** (run `01a1f36d-944f-759d-90c6-1c6739cc1de3`).

### The fix branch: not yet solid

`chore-drafter-brief` applies the same change to both `adr` and `plans`,
forked from `dev`, and is not landed. Its run
(`01a1f386-3b47-75f5-9dfd-54901effc740`) gave `plans-0` and `plans-1`
100 across the board and `adr-1` 100, 100, 80. But `adr-0` gave
**78, 0, 97**, two failures, each in a new way:

- **0:** loaded `adr` but never `git-workflow`. It wrote the ADR, staged it
  in the primary checkout, and never committed or branched. That is what an
  agent following the drafter brief ("Edit files, and never commit") would
  do. `adr` names `references/drafter.md` in its review loop. The agent may
  have opened the brief, read "You are the drafter subagent", and taken the
  role. If so, the change moved the role switch rather than removing it:
  any brief addressed to "you" that the parent can reach can still be
  adopted by the parent.
- **78:** ran the summariser and committed the round-1 draft, then never
  dispatched a reviewer. That is stopping part-way through the loop, not
  misreading the role.

Across six repeats on the drafter-brief content, four were clean.

### Tooling limits that shaped the investigation

- `tessl eval view <id> --json` gives per-run scorer notes and the skills
  each run activated. The text view shows only notes merged across repeats.
- `tessl eval download-solutions` gives each run's final repository state,
  not its transcript. So both remaining failures are inferred, not observed.
- `--context-commit` does not work with a plugin context, so the bisect used
  detached worktrees at each ref. A scenarios directory must be inside the
  repository.

## Open questions

- Did the 0-scoring run open `references/drafter.md` and adopt it? Only a
  transcript can say.
- Where did the 78-scoring run decide it was done after the round-1 draft?
- Is a brief written about a role, in the third person ("The drafter edits
  files and never commits"), safe for the parent to read, where a
  second-person brief is not?
- Is there a simpler, more basic cause, such as the agent not reading a long
  skill through, with the role switch only one contributor? `adr` is about
  5.3k tokens, over the registry's recommended 5k.
- How should a three-repeat gate treat a scenario that passes four times in
  six? #155 (right-sizing the pinned model) and the gate's threshold are
  related.

## Next steps

1. Reproduce `adr-0` locally with the Claude CLI on claude-sonnet-5-5, in a
   scratch copy of the fixture with the `chore-drafter-brief` plugin
   installed, about five times, keeping full transcripts.
2. Change the fix branch according to what the transcripts show, re-run
   `adr-0`, `adr-1`, `plans-0` and `plans-1`, and amend its commit message,
   which currently claims a full fix.
3. Land the fix. Re-cut `chore-release-0.6.0` from the new `dev` and run all
   five gates again.
4. Revise ADR 0002 to rule out role switches in any skill text (#204). This
   note informs that revision.
