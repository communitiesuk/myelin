---
title: How is an artefact checked before the next stage consumes it?
status: proposed
date: 2026-10-14
---

# How is an artefact checked before the next stage consumes it?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The maintainer often asks for a subagent review by hand before an
artefact lands. No skill or rule asks for it, and human sign-off on
an ADR masks the need.

The evidence that it pays: on 2026-09-23 an independent agent
reviewed plan 0004 against ADR 0005 before its pull request was
opened. One run of about five minutes found a High contradiction, two
High unverifiable assertions and a High gap, all fixed in one
revision commit. The day before, the same kind of defect had taken
three reviews to find, all after landing. A separate finding: a
reviewer that executes is a different instrument from a reviewer that
reads.

`docs/discovery/0003-escalation-and-orchestration.md` had absorbed
reviews into the orchestration question. That merged two questions:
when a human must be involved, which needs orchestration, and what
checks an artefact passes before the next stage, which does not. This
ADR answers the second.

The maintainer has committed to the orchestrator turn: myelin will
move beyond skills for one agent, and soon. This loop is a way into
that work — a parent agent with worker subagents, used on real work.

## Decision

One mechanism covers ADRs and plans. What differs between artefact
types is what the reviewer checks, which is content; the mechanism is
shared. The governing principle is that **each subagent has one small
task**.

### The shape: drafter, reviewer, parent

A drafter subagent works from a written upstream. A reviewer subagent
checks the draft against that upstream. The parent triages the
findings, gets any decisions it needs from the human, and repeats
until the stop rule below is met.

- **Plan.** Upstream is the ADR. Drafter writes the plan, reviewer
  loop runs, the plan lands.
- **ADR.** Upstream is a confirmed summary. Parent → summariser
  subagent → human confirms the summary → drafter → reviewer loop →
  human sign-off.
  - The summariser's one task is to decide which parts of the
    conversation are relevant to the ADR's question. The parent does
    not filter.
  - The human confirms the summary, not the draft.
  - The confirmed summary is the ADR's written upstream, even where
    there is no discovery note. The drafter works from it and nothing
    else, and the reviewer checks the ADR against it: does the ADR say
    what the human decided?
  - The review loop runs before the human's sign-off.
  - The summary lives in the body of the ADR's introducing commit.

**The reviewer is independent.** It gets the artefact and its upstream
sources, never the drafter's or the parent's reasoning.

### Each stage checks what it adds

Each stage checks what it adds and relies on what upstream already
checked.

- **ADR review:** internal consistency; consistency with its discovery
  note or summary and with earlier ADRs, including the closed paths in
  their Alternatives sections and their revision history; and that it
  says nothing about implementation. Until the history skill of ADR
  0004 exists, the reviewer reads `docs/adr/` and `git log` directly.
- **Plan review:** relies on the ADR being consistent. It checks
  fidelity — everything the ADR decided, nothing more — and
  verifiability. The brief asks, for each assertion the plan requires:
  can it be observed afterwards, and does another step destroy the
  evidence?

### Briefs and models

- One reviewer brief per skill, kept with the skill at
  `skills/<skill>/references/review.md`. More reviewers per artefact
  are not ruled out later, for example personas reviewing from a
  security or platform perspective.
- A cheaper model may draft; the reviewer is at least as strong. The
  models used are recorded on every run.

### Stop rule — provisional

**This rule is temporary.** It is a starting point, to be revisited
with evidence from the run logs.

Stop when no High findings remain open, with at most 3 rounds. If
any High findings remain after 3 rounds, escalate them to the human.

The stop rule is also the escalation route. Whatever the round, the
parent surfaces to the human any finding that needs a human decision
— for example, a plan review that shows the ADR needs revising. The
loop does not resolve such findings itself.

### The review record is in git

A commit on the artefact's branch carries, in its body, the findings
and what was done about each, so the record is in git history
whatever the host. Where there is a pull request, its description
repeats the record, so a future merge hook can read it.

### Passing the conversation to the summariser

Brand-neutral at the interface, harness-specific only in an adapter:
the shape of ADR 0003's git-host modules.

- **Interface.** The parent produces the dialogue as a file in a fixed
  format — human messages, assistant prose, and questions with their
  answers, in order, with tool output and reasoning left out — and
  gives the summariser its path. The summariser only ever sees that
  format.
- **Adapter.** One per harness, shipped with the `adr` skill. The
  first is a script for Claude Code that locates the session
  transcript from `$CLAUDE_CODE_SESSION_ID` and the project path
  (`~/.claude/projects/<slugified cwd>/<id>.jsonl`) and extracts the
  dialogue with `jq`. On the session that produced this ADR it gave
  31 KB of dialogue from a 1.1 MB transcript. The transcript format is
  internal to Claude Code and undocumented, and may change between
  versions.
- **Fallback.** Where no adapter exists, the parent writes the
  dialogue out itself, unfiltered. This is a degraded mode: it costs
  output tokens, copies verbatim poorly, and risks the parent leaving
  things out.
- The summary records which mode produced it.
- Anything the parent works out has to be stated in the conversation,
  because the summariser sees only the dialogue.

## Alternatives considered

- **A subagent orchestrator, rejected for now by ADR 0001.** ADR 0001
  parked it until there was evidence the cheaper mechanism worked and
  so as not to become a bespoke harness early. The rejection no longer
  holds: the maintainer has committed to the orchestrator turn, and
  the 2026-09-23 review is evidence that an independent subagent finds
  defects the drafting agent does not. This ADR is the smallest piece
  of that turn, and decides nothing about the wider architecture.
- **The parent drafts the ADR; or the parent writes the summary for
  the drafter; or the whole conversation goes to the drafter.**
  Rejected: each gives one agent more than one task, or lets the
  parent filter.
- **Two ADRs, one for ADR review and one for plan review.** Rejected:
  the plan review could then not rely on the ADR review. Split only if
  a later kind of check works differently, not merely checks
  different things.
- **A stop rule of 2 rounds, or a single round.** Rejected: a single
  round never checks that the fixes introduced no new problems. The
  human chose 3, provisionally.
- **The review record in the pull request description only.**
  Rejected: it lives on the host, not in git, and does not exist
  without a remote. **No record at all**: gives a future merge gate
  nothing to read, and the orchestration design no evidence.
- **The summary as a discovery note.** Rejected: an extra branch and
  pull request per ADR.
- **The parent appends to a dialogue log every turn.** Rejected: it
  depends on per-turn model discipline, the drift problem of ADR 0001.
  **Waiting for a cross-harness standard**: none is reliable today.

## Consequences

- ADR 0003 says a plan merges once "written and reviewed"; that review
  is now this loop. ADR 0003 also says nothing checks an ADR but a
  human reading it. That is no longer so — a reviewer checks it first
  — but its rule that a human lands an ADR is unchanged.
- When an ADR flips from `proposed` to `accepted` is decided
  separately (#66). This ADR requires only that the review finishes
  before acceptance.
- ADR 0006 deferred escalate-don't-thrash to the orchestration work.
  The review loop now has an escalation route of its own, to the
  present human; the general route stays deferred.
- An ADR may now have no discovery note. Its upstream is then the
  summary in its introducing commit, which is not a file in the tree.
- Every review costs at least one extra subagent run per round, at a
  model at least as strong as the drafter's.
- The stop rule is a guess until the run logs say otherwise. What else
  a run should record as signal for future iterations is open, and
  belongs to the orchestration work.
- The Claude Code adapter couples the `adr` skill to an undocumented
  transcript format. Where it breaks, the fallback still works,
  degraded.
- The conversation adapter is the first harness adapter. Whether
  myelin later builds separate harnesses for specific tasks is for
  after orchestration.
- Out of scope, and deferred:
  - Reviews of tests and implementation. A reviewer that runs things
    may need a different mechanism, such as a hook or CI, and probably
    its own ADR, after orchestration.
  - The orchestration architecture, including reviewers as agent
    definitions and communication between agents.
  - The merge-verdict hook that would read the review record.

## References

- `docs/adr/0001-artifact-embedded-skill-directives.md` — the subagent
  orchestrator it parked, which this ADR takes up in its smallest
  form; and the drift problem that rules out a per-turn log.
- `docs/adr/0003-git-workflow.md` — the host-module pattern the
  conversation adapter copies; the "written and reviewed" plan merge
  this loop defines; the human-lands-an-ADR rule this leaves in place.
- `docs/adr/0004-where-does-history-live.md` — git history as the
  record, which the review record and the summary's home follow; the
  closed paths the ADR reviewer reads; the history skill whose absence
  the interim path covers.
- `docs/adr/0006-where-do-captured-ideas-live.md` — the deferred
  escalation route, which this loop answers only within a review.
- `docs/discovery/0003-escalation-and-orchestration.md` — the
  orchestrator commitment, and the merged question this ADR separates.
- Issue #77, stage reviews; issue #66, ADR acceptance.
