---
title: How is an artefact checked before the next stage consumes it?
date: 2026-10-14
---

# How is an artefact checked before the next stage consumes it?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The maintainer often asks for a subagent review by hand before an
artefact lands. No skill or rule asks for it, and human acceptance of
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

Handing the summariser the conversation is feasible: a trial
extraction on the session that produced this ADR gave 31 KB of
dialogue from a 1.1 MB transcript.

## Decision

One mechanism covers ADRs and plans. What differs between artefact
types is what the reviewer checks, which is content; the mechanism is
shared. The governing principle is that **each subagent has one small
task**.

### The shape: drafter, reviewer, parent

A drafter subagent works from a written upstream. A reviewer subagent
checks the draft against that upstream. The parent decides on what
both surface, in rounds, until the stop rule below is met.

- **Plan.** Upstream is the ADR. Drafter writes the plan, the review
  loop runs, the plan lands.
- **ADR.** Upstream is a confirmed summary. Parent → summariser
  subagent → human confirms the summary → drafter → review loop →
  human acceptance.
  - The summariser's one task is to decide which parts of the
    conversation are relevant to the ADR's question. The parent does
    not filter.
  - The human confirms the summary, not the draft, and confirms the
    exact summary text the drafter receives. Anything the parent
    changes in it after confirmation is confirmed again before
    drafting.
  - The confirmed summary is the ADR's written upstream, even where
    there is no discovery note. The drafter works from it and what the
    rounds below add, nothing else, and the reviewer checks the ADR
    against it: does the ADR say what the human decided?
  - The review loop finishes before the human is asked to accept.
  - The summary lives in the body of the ADR's introducing commit.

### When no human can confirm

A task can supply the confirmed summary itself, for when no human is
available to confirm one, as in a one-turn eval. A statement labelled
"Confirmed summary:" is the confirmed summary: there is no summariser
step and no wait. The labelled text goes to the drafter verbatim, and
the parent does not edit it. **Only the label counts.** An unlabelled
statement, such as "ADR: we've decided X because Y" at the start of a
session, goes through the summariser and confirmation like any
conversation. With neither a labelled summary nor a human to confirm
one, the agent stops and asks.

With no human available, the agent stops and reports at the point
where it would surface an escalation or a High still open after 3
rounds: for an ADR, once the loop has finished; for a plan, at the
decision point of the round that raised it.

### Rounds

Each round runs a fresh drafter and a fresh reviewer, then the parent
decides. No subagent is resumed from an earlier round.

A round is a draft or revision by a fresh drafter followed by a
review by a fresh reviewer. Round 1 is the first draft and its
review. A High found in round N is fixed by round N+1's drafter and
confirmed fixed or reopened by round N+1's reviewer.

- **Drafter.** Gets the upstream and, after the first round, the
  current draft and the decisions recorded in earlier rounds. It
  drafts or revises, surfaces the issues it finds, and exits.
- **Reviewer.** Gets the upstream, the draft and the same recorded
  decisions, so it checks the draft against settled decisions rather
  than flagging them. It may flag a recorded parent decision that
  contradicts the upstream (see Escalation scope). It surfaces its
  findings and exits.
- **Parent.** Once both have reported, decides on both lists together,
  in one place, and records the decisions in the round's record, in
  the next commit on the branch (see the review record below). The
  decisions recorded in earlier rounds reach later drafters and
  reviewers as those rounds' output.

The parent makes no decisions before the first draft.

When the loop stops with issues or Medium or Low findings the parent
decided to act on, a fresh drafter applies them in a closing pass. It
gets the upstream, the draft and the recorded decisions. The pass is
not a round and is not re-reviewed; the parent checks that the change
matches the recorded decisions.

Changes the human requests at acceptance are recorded on the branch
like a round's decisions, before drafting, then applied by a fresh
drafter and reviewed as a round. That round counts if rounds remain;
if none do, it is reviewed once anyway, and any High it leaves open
is escalated.

**The reviewer is independent.** It gets the artefact, its upstream
sources and the recorded decisions, never the drafter's or the
parent's reasoning. The record of a decision, including a short
reason for not acting on a finding, is a round's output and goes to
later drafters and reviewers. The parent's deliberation beyond the
record does not.

### The parent owns the loop

Once the summary is confirmed, the parent decides on every issue and
finding, except those Escalation scope sends to the human, and has
the draft revised, and re-reviewed where the stop rule requires,
without asking the human. Choices the summary did not settle are the
parent's, because they revise nothing the human has agreed or seen;
the parent makes them at a round's decision point, like any other. It
has each Medium or Low finding fixed, in a later round or the closing
pass above, or records in the review record why not. The human next
sees the artefact drafted and reviewed, together with that record.

### Each stage checks what it adds

Each stage checks what it adds and relies on what upstream already
checked.

- **ADR review:** internal consistency; consistency with its discovery
  note or summary and with earlier ADRs, including the closed paths in
  their Alternatives sections and their revision history; and that it
  says nothing about implementation. Until ADR 0004's history skill
  exists, the reviewer reads `docs/adr/` and `git log` directly.
- **Plan review:** relies on the ADR being consistent. It checks
  fidelity — everything the ADR decided, nothing more — and
  verifiability. The brief asks, for each assertion the plan requires:
  can it be observed afterwards, and does another step destroy the
  evidence?

### Briefs and models

- One reviewer brief per artefact-producing skill in scope, `adr` and
  `plans`, kept with the skill at `skills/<skill>/references/review.md`.
  More reviewers per artefact, for example security or platform
  personas, are not ruled out.
- A cheaper model may draft; the reviewer should be at least as
  strong. The models used are recorded on every run.

### Stop rule — provisional

**The round limit and the stop criteria are temporary**, to be
revisited with evidence from the run logs.

Only High findings trigger another round. Stop after a round whose
review leaves no High open. Run at most 3 rounds, counting the first.
If a High is still open after round 3, the loop ends and the High is
escalated (see Escalation scope).

### Escalation scope

The parent surfaces a finding to the human only when acting on it
would change something the human has already agreed: the confirmed
summary, or an accepted ADR. A plan review that shows the ADR needs
revising is the example. It also surfaces any High finding still open
after 3 rounds, or left open by the review of changes requested at
acceptance, and always a reviewer's finding that a recorded parent
decision contradicts the upstream. The loop does not resolve these
itself; with no human available, the agent stops and reports them as
"When no human can confirm" sets out.

Escalations are batched. A drafter or reviewer that finds one carries
on to the end of its task. The parent collects every escalation from
the round's draft and review and surfaces them together, each with
its reason. For an ADR, they can wait until the human is shown the
reviewed draft. For a plan, which lands without a human, the loop
pauses at the decision point of the round that raised them, before
the next round or the landing, until the human answers.

### The review record is in git

Each round's record, the issues and findings and the parent's
decision on each, goes in the body of the next commit on the
artefact's branch: the next round's revision or the closing pass, or
a commit of its own if nothing follows. The closing pass's commit
records the parent's check. So the record is in git history whatever
the host. It carries no trailer.
Where there is a pull request, its description repeats the record, so
a future merge hook can read it.

### Passing the conversation to the summariser

Brand-neutral at the interface, harness-specific only in an adapter:
the shape of ADR 0003's git-host modules.

- **Interface.** The parent produces the dialogue as a file in a fixed
  format — human messages, assistant prose, and questions with their
  answers, in order, with tool output and reasoning left out — and
  passes the summariser its path. The summariser only ever sees that
  format.
- **Adapter.** One per harness. The first is for Claude Code and ships
  with the `adr` skill: a script that locates the session transcript
  from the session id and the project path, and extracts the dialogue
  with `jq`. The transcript format it reads is internal to
  Claude Code and undocumented, and may change between versions.
- **Fallback.** Where no adapter exists, the parent writes the
  dialogue out itself, unfiltered. This is a degraded mode: it costs
  output tokens, copies verbatim poorly, and risks the parent leaving
  things out.
- The summary records which mode produced it. For a labelled summary,
  the commit that carries it records that it was supplied labelled,
  outside the summary text; the labelled text itself is never edited.
- Anything the parent works out has to be stated in the conversation,
  because the summariser sees only the dialogue.

## Alternatives considered

- **A subagent orchestrator, rejected for now by ADR 0001.** ADR 0001
  rejected it because it moves the project toward a bespoke agent
  harness before there is evidence that artefact-embedded directives
  work. The rejection no longer holds because the maintainer has
  committed to the orchestrator turn. This ADR reopens the path only
  to draft and review decision artefacts; the per-step
  `implement-plan` form 0001 considered is not adopted, and nothing
  about the wider architecture is decided here.
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
- **The parent decides before the first draft, and resumes the same
  drafter between rounds.** How the loop first ran in practice: this
  ADR as first written had the drafter work from the upstream "and
  nothing else", and gave the parent's decisions no time or route.
  Rejected for the rounds above, which put decisions at one fixed
  point after the issues are in, give each subagent one small task,
  and stop any drafter carrying reasoning forward from earlier
  rounds.
- **The parent's decisions as part of the upstream, presented before
  drafting, with the reviewer flagging any that contradict the
  summary.** Not chosen: overtaken by the round structure the human
  set out. The reviewer's flag is kept, as a finding that always goes
  to the human.
- **With no human to confirm: an unlabelled written decision counts
  as the confirmed summary.** Rejected for the label: without a
  marker, an agent could treat a casual remark as a written decision.
  **The eval harness answers the confirmation**: more realistic, but
  doubtful where evals are one turn. **Rewriting the affected evals to
  score the summary and the stop**: honest about the behaviour, but
  loses their coverage of ADR drafting.

## Consequences

- ADR 0001's "rejected for now" entry now notes the commitment and
  that this ADR uses subagents to draft and review artefacts; its
  directive mechanism stands. ADR 0001's parking of orchestrated
  landing (in ADR 0003) and of reactive skill-building (in ADR 0002)
  is not reopened here, so those statements stand.
- ADR 0003's rationale for a human landing an ADR now names this
  review and rests on what only a human can confirm. Its rules are
  unchanged. The review in its "written and reviewed" plan merge is
  the one this ADR defines, including a closing pass checked by the
  parent, not re-reviewed.
- When an ADR is accepted, and how that is recorded, is ADR 0009's:
  the human's merge. This ADR requires only that review finishes
  before the human is asked to accept, which is no later than the
  merge.
- ADR 0006 deferred escalate-don't-thrash to the orchestration work.
  The review loop now has a bounded escalation route of its own; the
  general route stays deferred.
- Every ADR written under this loop has a written upstream: its
  discovery note, or else the confirmed summary in its introducing
  commit. The summary adds no edge to ADR 0004's graph, and
  ADR 0004's trailer table is unchanged.
- A revision of an accepted ADR carries `Revises` on its first
  revising commit; later round commits on the same revision branch
  are drafting of that revision and carry no trailer.
- Each round costs at least two subagent runs, a fresh drafter and a
  fresh reviewer.
- Open, for the orchestration work: what else a run should record as
  signal, for future iterations and for communication between agents.
- Out of scope, and deferred:
  - Reviews of tests and implementation. A reviewer that runs things
    may need a different mechanism, such as a hook or CI, and
    probably its own ADR, after orchestration.
  - The orchestration architecture, including reviewers as agent
    definitions; and whether myelin later builds separate harnesses
    for specific tasks and what they should record. The conversation
    adapter is the first harness adapter.
  - The merge-verdict hook that would read the review record.
  - Who makes revision commits, and the eval approach, are left to
    the plan.

## References

- `docs/adr/0001-artifact-embedded-skill-directives.md` — the subagent
  orchestrator it parked, which this ADR reopens for drafting and
  reviewing decision artefacts only; and the drift problem that rules
  out a per-turn log.
- `docs/adr/0003-git-workflow.md` — the host-module pattern the
  conversation adapter copies; the "written and reviewed" plan merge
  this loop defines; the human-lands-an-ADR rule this leaves in place.
- `docs/adr/0004-where-does-history-live.md` — git history as the
  record, which the review record and the summary's home follow; the
  trailer graph this leaves unchanged; the closed paths the ADR
  reviewer reads.
- `docs/adr/0006-where-do-captured-ideas-live.md` — the deferred
  escalation route, which this loop answers only within a review.
- `docs/discovery/0003-escalation-and-orchestration.md` — context: the
  orchestrator commitment, and the merged question this ADR separates.
  A reference, not an upstream: this ADR does not consume it, and it
  stays in the tree for the orchestration work.
- Issue #77, stage reviews; issue #66, ADR acceptance.
