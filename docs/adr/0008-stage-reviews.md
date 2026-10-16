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

This revision was prompted by what the shipped reviews cover. The
reviews the maintainer ran by hand also ran a plan's checks, checked
its references against the repository and checked form; the briefs
do not. And nothing in the loop pushes towards cutting: this ADR grew
to about 430 lines over four revisions in two days, and plan 0011 to
2,117 lines over more than ten review passes, many of the added
clauses fixes for findings.

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
- **ADR.** Upstream is a summary, plus the discovery note where one
  exists, plus any changes requested at acceptance. Parent →
  summariser subagent → drafter → review loop → human acceptance.
  - An explicit request from the human to write the ADR starts
    drafting. Without one, the agent does not draft but asks the
    human, and with no human available it stops and reports. What must
    not happen is drafting before the conversation has reached a
    decision, while the human is still exploring. The `adr` skill's
    trigger, which fires only when a decision is ready, and
    facilitated-discovery's step of asking whether the human is ready
    to decide guard against it. Neither is deterministic, and no
    prompt can be; if both fail, the result is an unmerged branch, not
    a wrong decision of record, because only the human merges.
  - The summariser always runs on the conversation; in a one-turn
    task, the conversation is the task text. Where a discovery note
    exists, it joins the upstream alongside the summary. Its one task
    is to decide which parts of the conversation are relevant to the
    ADR's question. The parent does not filter. The summariser's text
    reaches the drafter verbatim; the parent never edits it on its own
    initiative.
  - The human need not approve the summary before drafting, but may
    ask to. Then the human approves the exact summary text the
    drafter receives. If the human asks for changes when approving,
    the parent applies those changes and no others, and the human
    approves the changed text before drafting.
  - The summary, with any changes requested at acceptance, is the
    ADR's written upstream, even where there is no discovery note.
    The drafter works from the upstream and, after the first draft,
    the current draft and the recorded decisions, nothing else, and
    the reviewer checks the ADR against the upstream: does the ADR
    say what the human decided? The human checks the whole at
    acceptance.
  - The review loop finishes before the human is asked to accept.
  - The summary lives in the body of the ADR's introducing commit, or
    of a revision's first revising commit.

### When no human is available

An explicit request to write the ADR goes ahead with no human
available: the summariser runs, the drafter drafts, the review loop
runs, and the agent opens the pull request and stops, with nothing
merged. It does not stop and wait.

With no human available, the agent stops and reports at the point
where it would surface an escalation (see Escalation scope): for an
ADR, once the loop has finished; for a plan, at the decision point of
the round that raised it.

### Rounds

A round is a draft or revision by a fresh drafter, then a review by
a fresh reviewer, then the parent's decisions. No subagent is resumed
from an earlier round. Round 1 is the first draft (or, after a
restart, the revision applying the change) and its review. A High
found in round N is fixed by round N+1's drafter and confirmed fixed
or reopened by round N+1's reviewer.

- **Drafter.** Gets the upstream and, after the first draft, the
  current draft and the decisions recorded in earlier rounds,
  including any earlier loop. It drafts or revises, surfaces the
  issues it finds, and exits.
- **Reviewer.** Gets the upstream, the draft and the same recorded
  decisions, so it checks the draft against settled decisions rather
  than reopening them, except that it may flag a recorded parent
  decision that contradicts the upstream (see Escalation scope). It
  surfaces its findings and exits.
- **Parent.** Once both have reported, decides on both lists together,
  in one place, and records the decisions in the round's record, in a
  commit made before the next round's draft or the closing pass, or in
  that commit itself, or in a commit of its own if nothing follows
  (see the review record below). The decisions recorded in earlier
  rounds reach later drafters and reviewers as those rounds' output.

The parent makes no decisions before the first draft.

When the loop stops with issues or Medium or Low findings the parent
decided to act on, a fresh drafter applies them in a closing pass. It
gets the upstream, the draft and the recorded decisions. The pass is
not a round and is not re-reviewed; the parent checks that the change
matches the recorded decisions.

For an ADR, a change requested at acceptance restarts the loop at
round 1, under the same rules: the closing pass above, and the round
limit, stop rule and Escalation scope below. It is the human's
decision and joins the upstream; it takes precedence over the summary
or any earlier change, and over any recorded parent decision it
contradicts, which the next round's record marks superseded; a
reviewer does not flag it. An answer to an escalation that changes the
draft is such a change, whenever it is given; one that leaves the
draft as it stands is not; it is recorded in the round's record as the
human's decision, and later reviewers treat it as settled. When the
loop finishes, the human is asked to accept again.

**The reviewer is independent.** It gets the artefact, its upstream
sources and the recorded decisions, never the drafter's or the
parent's reasoning. The record of a decision, including a short
reason for not acting on a finding, is a round's output and goes to
later drafters and reviewers. The parent's deliberation beyond the
record does not.

### The parent owns the loop

Once the upstream is settled (for an ADR, the summary written, and
approved where the human asked to approve it), the parent decides on
every issue and finding, except those Escalation scope sends to the
human, and has the draft revised, and re-reviewed where the stop rule
requires, without asking the human. Choices the upstream did not
settle are the parent's, because they revise nothing the human has
agreed; the parent makes them at a round's decision point, like any
other. It has each Medium or Low finding fixed, in a later
round or the closing pass above, or records in the review record why
not. The human next sees the artefact drafted and reviewed, together
with that record.

### Each stage checks what it adds

Each stage checks what it adds and relies on what upstream already
checked. Both reviews also check form against the governing skill's
rules, and either may find text unneeded: "cut it" is a finding.

- **ADR review:** internal consistency; consistency with its upstream
  (the summary, plus the discovery note where one exists, plus any
  changes requested at acceptance) and with earlier ADRs, including
  the closed paths in their Alternatives sections and their revision
  history; and that it says nothing about implementation. Until ADR
  0004's history skill exists, the reviewer reads `docs/adr/` and
  `git log` directly.
- **Plan review:** relies on the ADR being consistent. It checks the
  plan's internal consistency, fidelity — everything the ADR decided,
  nothing more — and verifiability, which means trying it: the
  reviewer applies the plan's checks to a scratch copy and runs them,
  and confirms that every file, line and quoted string the plan
  refers to exists as described. For each assertion the plan
  requires: can it be observed afterwards, and does another step
  destroy the evidence? Each eval assertion must discriminate: doing
  nothing cannot pass it, and nothing is scored from what the scorer
  cannot see.

### Findings are fixed by correcting, not by adding

Concision is a general principle, weighted by role. A drafter aims for
concision and consistency but does not let them hold it up. An editor,
a later round's drafter or the closing pass, acts on the recorded
decisions only, and fixes each by correcting, replacing or cutting
text, in that order of preference; adding text is the last resort.
Checks are not what makes an artefact grow; fixing each gap with a
new clause is, as fixing each bug with more code is. An ADR's length
is capped by the `adr` skill's two-minute reading guideline; going
over it calls for cutting, not for splitting the ADR.

### Briefs and models

- One reviewer brief per artefact-producing skill in scope, `adr` and
  `plans`, kept with the skill at `skills/<skill>/references/review.md`.
  Each keeps its existing checks and sections; new checks go within
  them.
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

The parent surfaces to the human:

- a finding whose fix would change something the human has already
  agreed (a summary the human approved, changes requested at
  acceptance, or an accepted ADR, for example a plan review that
  shows the ADR needs revising);
- a High still open after round 3; and
- any reviewer finding that a recorded parent decision contradicts
  the upstream.

The loop does not resolve these itself. Once the human answers, for
an ADR, an answer that changes the draft restarts the loop (see
Rounds). With no human available, the agent stops and reports them as
"When no human is available" sets out.

Escalations are batched. A drafter or reviewer that finds one carries
on to the end of its task. The parent collects every escalation from
the round's draft and review and surfaces them together, each with
its reason. For an ADR, they can wait until the human is shown the
reviewed draft. For a plan, which lands without a human, the loop
pauses at the decision point of the round that raised them, before
the next round or the landing, until the human answers.

### The review record is in git

Each round's record, the issues and findings and the parent's decision
on each, goes in the body of a commit on the artefact's branch made
before the next round's draft or the closing pass, or in that commit
itself, or in a commit of its own if nothing follows. The closing
pass's commit records the parent's check. So the record is in git
history whatever the host. Changes requested at acceptance are
recorded, quoting the text the human accepted or gave, in a commit of
their own before the loop restarts. The record carries no trailer.
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
- **Fallback.** Where no adapter exists, or it cannot produce the
  dialogue, the parent writes the dialogue out itself, unfiltered.
  This is a degraded mode: it costs output tokens, copies verbatim
  poorly, and risks the parent leaving things out.
- The summary records which mode produced it.
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
- **Deciding before the first draft; resuming the drafter between
  rounds.** This ADR as first written had the drafter work from the
  upstream "and nothing else" and gave the parent's decisions no time
  or route. Reversed: Rounds puts decisions at one point after the
  issues are in, gives each subagent one task, and carries no
  reasoning forward.
- **The parent's decisions as part of the upstream, presented before
  drafting, with the reviewer flagging any that contradict the
  summary.** Not chosen as a whole: overtaken by the round structure
  the human set out. Its reviewer flag is kept, against the upstream,
  as a finding that always goes to the human.
- **The human confirms the exact summary text before any drafting
  starts; with no "Confirmed summary:" label (see below) and no human,
  the agent stops and asks.** This ADR as earlier revised required
  both. Reversed: no prompt can be a deterministic gate, and the
  human's approval of the summary was a holding position. The gate the
  human cares about is timing, not drafting before the conversation
  has reached a decision, which the trigger and the readiness step
  protect, with the human's merge as the backstop. The reviewer's
  check against the summary and the human's check at acceptance
  remain. Approving the summary is kept as something the human can ask
  for. **Reading "before it is time" as before the human has approved
  the summary**: not chosen; the human meant before a decision is
  reached.
- **A "Confirmed summary:" label, whose text goes to the drafter
  with no summariser.** This ADR as earlier revised adopted it so a
  one-turn task, such as an eval, could supply a confirmed summary
  under the strict confirmation gate. Reversed: that gate is gone,
  so an explicit request starts drafting and the summariser runs on
  whatever conversation there is; and the label was the one path
  that skipped the summariser, which no prompt can stop a parent
  taking by labelling its own text. Wording the human wants exact is
  said in the conversation, which the summariser quotes. **A
  deterministic check for the label**: not chosen, since the agent
  could add the label itself.
- **With no human to confirm: an unlabelled written decision counts as
  the summary, with no summariser; the eval harness answers the
  confirmation; or the affected evals score the summary and the
  stop.** Part of the earlier revision, which weighed these against
  its stop for an unlabelled decision with no human, and chose the
  label and the stop. This revision reverses both, so these options no
  longer arise, and the summariser now always runs, so no written
  decision stands in for the summary.
- **For plan 0011's adr-1 failure: run it on Sonnet to find a model
  floor; one more wording attempt on the cheap model; or accept it
  as a known gap and relax the plan's gate.** Not chosen: the
  human's reframing of the gates, which an earlier revision records,
  replaced all three.
- **Changes requested at acceptance as an unreviewed closing pass, or
  as a reviewed round counted against those left.** Not chosen: the
  first leaves the change unreviewed; the second, accepted for a time,
  was reversed because its exceptions kept producing edge cases.
- **Editors tightening anywhere, beyond the recorded decisions.** Not
  chosen for now; it belongs with continuous refactoring and the
  orchestration work (#79). **Fewer checks, to limit growth**: not
  chosen, since growth comes from how findings are fixed, not from
  which checks run. **A plan that names sub-ADRs to write**: not
  chosen; it would offer agents a way to generate ADRs without bound.

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
  merge, and that a change requested at acceptance restarts the
  loop.
- ADR 0006 deferred escalate-don't-thrash to the orchestration work.
  The review loop now has a bounded escalation route of its own; the
  general route stays deferred.
- Every ADR written under this loop has a written upstream: the
  summary in its introducing commit (or a revision's first revising
  commit), plus its discovery note where one exists, plus any changes
  requested at acceptance. The summary adds no edge to ADR 0004's
  graph, and ADR 0004's trailer table is unchanged.
- Drafting need not wait for the human. Drafting started too early
  costs subagent runs and an unmerged branch, not a wrong decision of
  record: under ADR 0003 only the human merges an ADR, and that merge
  is the check that the ADR says what the human decided.
- A revision of an accepted ADR carries `Revises` on its first
  revising commit; later round commits on the same revision branch are
  drafting of that revision and carry no trailer, since under ADR 0004
  the `Revises` edge is added by exactly one commit.
- Each round costs at least two subagent runs, a fresh drafter and a
  fresh reviewer.
- Open, for the orchestration work: what else a run should record as
  signal, for future iterations and for communication between agents.
- Out of scope, and deferred:
  - Reviews of tests and implementation. Running a plan's checks on
    a scratch copy is part of reviewing the plan; reviewing what
    implementation produces may need a different mechanism, such as
    a hook or CI, and probably its own ADR, after orchestration.
  - How decisions decompose from strategic to implementation level,
    including the two-minute guideline as a level detector (#94); ADR
    Consequences that name their downstreams (#92); and a myelin-wide
    rules file for all writing, including code, which waits for #79
    or #94.
  - The orchestration architecture, including reviewers as agent
    definitions; and whether myelin later builds separate harnesses
    for specific tasks and what they should record. The conversation
    adapter is the first harness adapter.
  - The merge-verdict hook that would read the review record.
  - A deterministic gate on the human's confirmation, such as a hook
    that reads the transcript for a human turn after the summary.
  - An eval for gate (a), that no ADR is drafted mid-exploration,
    which belongs to facilitated-discovery.
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
  trailer graph this leaves unchanged, in which the `Revises` edge is
  added by exactly one commit; the closed paths the ADR reviewer
  reads.
- `docs/adr/0006-where-do-captured-ideas-live.md` — the deferred
  escalation route, which this loop answers only within a review.
- `docs/adr/0009-adr-acceptance.md` — acceptance is the human's merge;
  a change requested at acceptance restarts the loop before the human
  is asked again.
- `docs/discovery/0003-escalation-and-orchestration.md` — context: the
  orchestrator commitment, and the merged question this ADR separates.
  A reference, not an upstream: this ADR does not consume it, and it
  stays in the tree for the orchestration work.
- Issue #77, stage reviews; issue #66, ADR acceptance; issue #79,
  continuous refactoring; issue #92, Consequences that name their
  downstreams; seed #94, decision decomposition.
