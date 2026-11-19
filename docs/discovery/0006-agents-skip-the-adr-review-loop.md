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

The release is on hold. This note first diagnosed a role switch in the
`adr` skill's text. Later the same day that diagnosis was tested and not
supported. The note now records both, and what the evidence does show:
under the eval harness's prompt, an agent runs the `adr` flow about half
the time, on every version of the skills from 0.5.2 to `dev`, and the
release gate cannot tell that from a regression.

## What we've covered

### The first diagnosis, now superseded

The first investigation bisected `adr-0` in the cloud and blamed a role
switch: `adr` and `plans` are each read by the parent and by the drafter
subagent, and each said "If you are a drafter or reviewer subagent, skip
this section." The theory was that a top-level agent told "Write the ADR"
takes itself for the drafter and skips the flow. A branch,
`chore-drafter-brief`, moved the drafter's instructions into
`references/drafter.md` and deleted the switch.

Three things undo that account:

- **The baseline was a cache replay.** The bisect's "v0.5.2 today" run
  (`01a1f353-1b9a-741c-827c-aa8ff421bbda`) has the same scores, turns and
  durations as the 0.5.2 gate run of 6 November, and no run metadata.
  `tessl eval run` replays solved cases unless given `-f`. So v0.5.2 was
  never re-run, and "not model drift" was never shown.
- **The role-switch text is not new.** It is identical in v0.5.2, at the
  same line numbers.
- **No transcript shows a misread role.** Every failing agent whose words
  we have knew it was the parent and knew the process.

### What a failing agent says

An instrumented cloud run on `dev` (`01a1f3d2-ba8b-74f6-9def-641b2b3aa5a8`)
captured one failing transcript. The agent loaded `adr`, read ADR 0001 and
the README, wrote the file and stopped: five tool calls in 21 seconds. Its
final message:

> I wrote the ADR at `docs/adr/0002-job-retry.md`. It isn't committed, and
> I didn't run the skill's full process. That process includes a branch, a
> summariser subagent, a drafter/reviewer loop, and landing. I left it out
> because the task only said to write the ADR.

Local failures say the same: "I did not run the skill's branch,
subagent-review or commit workflow… Say so if you want that done", and "I
skipped the skill's review loop". The agent judges the process out of
proportion to the request and cuts it short, at different depths: before
git, after a bare commit, after `begin`, or after the draft.

Reflogs in the downloaded cloud solutions agree. The three 0.6.0 gate
failures each made one bare `git checkout -b` and commit in the primary
checkout, 12 to 16 seconds after the fixture was built, with no worktree.
There was no time for a subagent.

Cut-short runs do not think less. Across 159 local runs, the median early
thinking was about 230 tokens for cut-short runs and 206 for full ones.

### The harness's prompt is the trigger

The cloud solver is launched as:

```
claude --verbose --dangerously-skip-permissions --output-format stream-json \
  --model recipe-runner-claude-sonnet-5-5 -p "<wrapper>"
```

The wrapper is not the bare `task.md`. It opens "You are solving a task in
your working directory.", puts the task in `<task>` tags, and appends:

> If the task specifies output files to generate:
>
> - Write the output files in the working directory as instructed.
>
> ## Available skills
>
> One or more skills should be available to help with this task. You must
> use them if needed.

Locally, on Claude Code 2.1.328 with claude-sonnet-5-5:

| tree | prompt | full flow |
| --- | --- | --- |
| `dev` | bare `task.md` | 5 / 5 |
| `chore-drafter-brief` | bare `task.md` | 10 / 10 |
| `dev` | cloud wrapper | 5 / 15 |
| `chore-drafter-brief` | cloud wrapper | 3 / 5 |

So the wrapper explains why local runs passed and cloud runs failed. It
does not explain a regression, unless the wrapper itself changed since
6 November, which we do not know.

### What changed since the 0.5.2 gate run

| | 0.5.2 gate, 6 Nov | 19 Nov |
| --- | --- | --- |
| skills | v0.5.2 | three merged changes (`01f693e`, `26ba1c7`, `871b70d`) |
| Claude Code in the sandbox | 2.1.287 | 2.1.290 |
| tessl recipe runner | 0.1.0 | `dev` |
| prompt wrapper | unknown | as above |
| model | claude-sonnet-5-5 | same id |
| `adr-0` scenario, plugin manifest | | unchanged |

Skill descriptions did not change at `26ba1c7`, and `begin` and `land`
print the same text at `01f693e` and `26ba1c7`.

### v0.5.2 fails too

Forced with `-f` on the 19 November harness
(`01a1f3f4-9333-72e2-8231-9981c31dae78`), v0.5.2 scored 63, 100, 100. The
63 has the usual shape: 8 turns, 27 seconds, no summariser, no record. The
6 November gate run already had one such repeat, on `adr-1` (80, 8 turns,
22 seconds). Locally under the wrapper v0.5.2 ran the full flow 11 times
in 15.

Cloud `adr-0` on 19 November, all real runs:

| tree | run | repeats |
| --- | --- | --- |
| v0.5.2, forced | `01a1f3f4-9333-72e2-8231-9981c31dae78` | 63, 100, 100 |
| `01f693e` | `01a1f35e-1f9b-71b0-8c3f-93ca69c4521c` | 100, 100, 56 |
| `26ba1c7` | `01a1f353-1bd7-77ff-97c6-f33f7d907022` | 63, 56, 100 |
| 0.6.0 candidate | `01a1f340-1bc0-72fa-8955-27ae0debf0ca` | 56, 56, 56 |
| 0.6.0 + drafter brief | `01a1f36d-944f-759d-90c6-1c6739cc1de3` | 100, 100, 100 |
| `chore-drafter-brief` | `01a1f386-3b47-75f5-9dfd-54901effc740` | 78, 0, 97 |
| `dev`, instrumented, unscored | `01a1f3d2-ba8b-74f6-9def-641b2b3aa5a8` | full, skipped, full |

### No text change is shown to matter

A local bisect under the wrapper, 15 repeats a tree, in separate jobs,
seemed to find a step:

| tree | full flow |
| --- | --- |
| v0.5.2 | 11 / 15 |
| `01f693e` | 10 / 15 |
| `26ba1c7` | 0 / 15 |
| `dev` | 5 / 15 |
| `01f693e` with `26ba1c7`'s `adr` text | 3 / 15 |
| `26ba1c7` with `01f693e`'s `adr` text | 4 / 15 |

It did not survive a same-moment test. Six arms ran together, two repeats
an arm in each of eight rounds: `01f693e`, `26ba1c7`, and `01f693e` plus
each of four groups of `26ba1c7`'s text edits.

| arm | full flow |
| --- | --- |
| `01f693e` | 3 / 16 |
| + `adr`'s `Abandons` paragraph | 8 / 16 |
| + `adr`'s two one-line `Abandons` mentions | 7 / 16 |
| + `git-workflow`'s exit-3 line | 6 / 16 |
| + `git-workflow`'s trailer rows and verdict paragraph | 11 / 16 |
| `26ba1c7` | 6 / 16 |

The arms do not differ (p ≈ 0.11), and the base did worst. The overall
rate was 41 in 96, rising from 3 in 12 in the first round to 7 in 12 in
the last. So the rate moves with something outside the skills, results
from separate jobs cannot be compared, and nothing here shows that any
change since 0.5.2 affects whether the flow runs. That includes the
drafter brief, and the first investigation's "rate rose with each change".

Skill length was considered and not tested. The step that seemed to break
things was a 4% increase, and the pattern was not monotonic.

### What this says about the gate

At a full-flow rate near 45%, three failures in three happens about one
time in six, and three passes about one time in eleven. The 0.5.2 pass and
the 0.6.0 failure are both ordinary outcomes of one behaviour. A gate of
three repeats, compared with medians recorded under an older harness,
cannot separate a regression from a bad hour.

### Tooling

- `tessl eval view <id> --json` gives per-run scores, turns, durations,
  activated skills, and the sandbox's Claude Code and recipe-runner
  versions. Failing runs are short: about 6 to 8 turns and 20 seconds.
- `tessl eval download-solutions` returns each solution with its `.git`,
  so reflogs give a timeline for free.
- Transcripts can be had from the cloud. In a detached worktree, add
  `SessionStart`, `PostToolUse` and `Stop` hooks to the plugin that
  silently copy the session's transcript and the solver's process ancestry
  under `<git-dir>/diag/`. tessl rejects `SessionEnd` and `SubagentStop`.
  Passing runs logged only their first 45 seconds or so; why is unknown.
- `--context-commit` does not work with a plugin context, so a bisect uses
  detached worktrees. A scenarios directory must be inside the repository.
- The local harness: build the fixture with the scenario's `setup.sh`,
  `tessl install file:<worktree> --yes --agent claude-code`, leave the
  installed files untracked as the cloud does, and run
  `claude -p "<wrapper>" --model claude-sonnet-5-5 --output-format
  stream-json --verbose --setting-sources project --strict-mcp-config
  --permission-mode bypassPermissions`. The OS sandbox refuses
  `git worktree add`, so the solver runs unconfined and a human launches
  it. A run costs 10 to 60 cents. Concurrent runs share `/tmp`, which was
  flagged and not fixed. The scripts and transcripts were in a session
  scratchpad and are not kept.

## Open questions

- What made `01f693e` run the full flow 10 times in 15 and `26ba1c7` 0 in
  15, in batches a few minutes apart, when the same trees run together
  gave 3 and 6 in 16? It is too extreme for chance. Interference between
  concurrent runs through shared `/tmp` paths is a candidate, with no
  mechanism shown.
- How far, and how fast, does the full-flow rate move with time or load?
  One unchanged arm run through a day would say.
- Has the rate changed since 6 November, or was 0.5.2's pass luck? We have
  three repeats from that day, and no copy of that day's wrapper.
- Does wording that makes "write the ADR" mean the whole flow raise the
  rate? Not tested.
- Would mechanical enforcement hold where prose does not: `land` refusing
  an ADR branch with no summary markers or no round-1 record, and a `Stop`
  hook for the agent that never reaches `land`?
- Do the prompts people really give trigger the shortcut? The bare task
  ran the flow 15 times in 15; the harness wrapper is not what a user
  types.
- How should Gate 3 compare: against a same-moment forced run of the
  previous release, with how many repeats? #155 is related.

## Next steps

1. Decide whether 0.6.0 ships. The evidence does not show that it
   regressed. A same-moment forced control of 0.5.2 beside the candidate,
   with more than three repeats on `adr-0` and `adr-1`, would be the
   like-for-like comparison.
2. Revise Gate 3 (ADR 0005 and the release skill): always `-f`, compare
   with a same-moment control and not with a tag's medians, record the
   harness versions in the tag, and size the repeats to the noise.
3. Decide, in an ADR, whether the `adr` and `plans` flows get mechanical
   enforcement.
4. Decide what happens to `chore-drafter-brief`. Its commit message claims
   a fix the evidence does not support. Removing the role switch may still
   be worth doing as a simplification, without that claim.
5. Reconsider #204. It proposes a rule against role switches in skill
   text, on the strength of the diagnosis this note no longer holds.
6. If more local measurement is wanted: give each run its own temporary
   directory, run arms in the same minutes, and keep the scripts in the
   repository.
