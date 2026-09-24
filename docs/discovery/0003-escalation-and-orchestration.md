---
title: How should myelin escalate to a human, and does it need an orchestrator?
status: in-progress
date: 2026-09-24
---

# How should myelin escalate to a human, and does it need an orchestrator?

## Problem

ADR 0003 decided that an agent lands its own work by default and
deferred the question of when it must escalate to a human instead
("the gate later carves out when it must escalate"). That deferred
question was framed as a **landing gate**: a rule, enforced at
`gh pr merge`, deciding whether the agent may merge its own work or
must hand it to a human.

This session set out to design that gate and instead concluded the
gate framing is the wrong one. The question underneath it — *when does
work need a human, and how does that get enforced?* — is real, but it
is not a merge-time question, and answering it well appears to require
an architectural change to myelin. This note records how far the
thinking got. **It is not close to a decision.**

## What we've covered

### The landing gate is a blind alley as a standalone target

Not refuted — *subsumed*. Two things were wrong with it:

- **Wrong moment.** The situations that actually need a human fire
  *during* the work, not at the merge. By the time you reach
  `gh pr merge`, either the problem was caught upstream or it was never
  a merge-time problem.
- **Wrong altitude.** "May this land itself?" is not a gate you design;
  it is an *output* of a more general capability. Given something that
  can escalate mid-flight, the landing answer falls out for free —
  landing is just the most common place a verdict gets consumed.

The thread's real payoff was diagnostic: it was the fourth signal
pointing at an orchestrator (see convergence, below), and following it
is what surfaced the architecture.

**One small piece survives independently:** the *enforcement plumbing*
at the merge point — rule 11's by-kind routing (an ADR or a `Revises`
branch goes to a human) plus a deterministic `PreToolUse` hook that
refuses a merge lacking a verdict. That is buildable and useful
regardless of the larger architecture, because something must enforce
whatever a judge decides and the merge command is a genuinely
deterministic signal. It is downstream of and subordinate to the
decision, not where the decision is made — do not discard it with the
blind-alley framing.

### Four kinds of "this needs a human"

Surfaced as the real triggers, sitting on different axes and firing at
different times:

1. **The decision is wrong, discovered downstream.** An agent
   struggling to implement a human's decision may be evidence the
   decision needs revising. Escalates *upward* to revisit the ADR —
   feeds [[Formalize the revision process end to end]] and ADR 0004's
   revision machinery, not a landing gate.
2. **Irreversible / high blast radius.** Altering a shared resource,
   deleting data, damaging another project. Fires *before* the
   dangerous action, at any point in the work.
3. **The decision is silent, not wrong.** The agent hits a fork the ADR
   never anticipated and cannot resolve it from the decision. Not
   "revise" — "you didn't say; choose."
4. **The reviewers are uncertain or disagree.** "Confidence not earned"
   in its most literal form, and the trigger closest to a mechanical
   read.

Cost/credit thresholds and security-surface triggers were considered
and folded into (2) rather than listed separately.

### A candidate architecture: interlocutor / worker / observer

The human's picture, recorded as the candidate to probe, **not** as a
decision:

- **Interlocutor** — the agent the human talks to. Interprets intent,
  explains what is going on, decides which skills apply. Loads
  *conversational* skills itself (e.g. `facilitated-discovery`, which is
  about how it talks to the human); *launches a worker* for anything
  that is not talking to the human (drafting, coding, ADRs).
- **Worker subagent** — given a prompt and the relevant skills
  (git-workflow, adr, …), does one task.
- **Observer subagent** — launched paired with the worker to watch it
  and raise a block.
- **Containers** — workers (and perhaps observers) run sandboxed, to
  bound blast radius.

The escalation capability the human is reaching for is: *the ability to
impose a block, in response to behaviour, that must be resolved before
work continues.* A block is therefore a first-class, durable object —
work suspends, the reason persists, a human resolves it. That is the
same object as the escalation queue in [[Reviewers]] / [[Ticket skill]]
and the reason plan steps would need to become **suspendable** (a
plan-schema consequence).

### Observer and container cover different triggers — they are not redundant

The sharpest result of the session:

- **(2) is point-in-time.** An observer that watches-then-reacts is
  structurally *too late* for an irreversible action — it has already
  happened. What stops (2) is making it *impossible* (a container) or
  refusing it *synchronously before it runs* (a `PreToolUse` hook), not
  observing it. So **(2) → container + hook.**
- **(1), (3), (4) are trajectory-level.** You catch them by watching a
  pattern over time, and a slightly-late block costs nothing because
  nothing irreversible is in flight. So **(1)(3)(4) → observer.**

This partition dissolves the observer's hardest feasibility problem: it
no longer needs to interrupt in real time. It also fixes the
"who watches?" problem — a separate observer does not depend on the
worker (the thrashing or reckless worker is the one least able to
police itself).

### Convergence: this is the orchestrator turn

The landing gate is the *fourth* parked thread asking for the same
thing — an orchestrator running workers under supervision, rather than
a set of skills a single agent loads:

- [[Use subagents to enforce skill use]] — orchestrator instead of
  skills chaining themselves via artefact reminders.
- [[Skill/subagent builder]] — the deferred skill-building "harness".
- [[ADR <-> plan loop as HTN]] — the orchestration graph.
- This note — supervised execution and escalation.

The real weight of the landing-gate work is that it makes the
orchestrator question concrete and forces it.

## Open questions

Two are decisive and directly **probeable** on the current harness;
answer them before any ADR:

1. **Does delegating to a worker make skill-use reliable, or just move
   the trigger problem down a level?** The architecture assumes the
   interlocutor can hand a worker "the relevant skills" and the worker
   will load and follow them. But a spawned worker still has to *load*
   git-workflow/adr — the same probabilistic trigger as
   [[Framework to test whether a skill gets loaded]]. If a worker
   launched with "use git-workflow" reliably obeys, that is a large win
   and quietly resolves much of [[Use subagents to enforce skill use]].
   If not, the orchestrator buys structure but not enforcement. Not yet
   measured.
2. **Can a sibling observer actually *see* the worker and *impose* a
   block, given this harness's subagent model?** The model here favours
   workers that *return a result to a parent*, not workers that
   *broadcast tool calls to a peer*, and gives stop-control to the
   parent, not to siblings. If a peer observer cannot observe or halt,
   the "observer" is really a *function of the interlocutor* (launch the
   worker in the background, watch its output, stop it) or a hook —
   *not* a paired peer subagent. Whether the pair-of-agents picture maps
   onto the harness primitives is unproven.

Larger and not yet decidable:

- **Is myelin taking the orchestrator turn at all?** This is a
  whole-system architecture change. The landing gate alone probably
  does not justify it; its being the fourth converging thread might.
  That is the decision the eventual ADR has to make, and it should be
  made on the combined evidence, not on the gate alone.
- **What does the observer read to judge (1)(3)(4)?** The worker's tool
  calls, its outputs, the diff, the governing ADR? And what is the
  structured form of a "block" so the interlocutor/human can act on it?
- **Container boundary vs git.** A sandboxed worker still needs to push
  and open PRs, so credentials cross the boundary — a container holding
  push access to a shared remote is only partly contained. How the
  worktree/dependency bootstrap (ADR 0003's `.venv`/`node_modules`
  split) works inside a container is unresolved. Connects to
  [[Azure container skills]].
- **Relationship to the harness's own gates.** The harness already
  gates dangerous commands via its permission layer — but by *command
  pattern*, not by understanding blast radius, and (observed
  2026-09-24) *non-deterministically*: it refused `gh pr merge` on
  2026-09-23 and allowed it on 2026-09-24 with no valid explicit
  permission. A myelin blast-radius guard would be a second layer over
  an unreliable one. Whether myelin replaces, wraps, or defers to the
  harness gate is open. A **second** harness gate is now confirmed by
  observation: editing `.claude/settings.local.json` to grant the
  landing permission was refused as `[Self-Modification]` (2026-09-24).
  So the permission decision is irreducibly the human's — the agent
  cannot grant itself the right to land, whatever the orchestration
  design. Any observer/hook machinery must therefore operate *within* a
  permission boundary it cannot alter, and escalation-to-human is not
  merely a policy myelin chooses but a harness-enforced floor it builds
  on top of.

## Next steps

- **Probe 1 (skill-loading in workers).** Launch a subagent with an
  explicit instruction to use git-workflow on a trivial artefact and
  measure whether it loads and follows. Cheap; no credits beyond the
  run. This is also material for
  [[Framework to test whether a skill gets loaded]].
- **Probe 2 (observer feasibility).** Establish what one subagent can
  observe of another and whether it (or the parent) can halt it, from
  the harness/SDK capabilities — before assuming the paired-observer
  picture is buildable.
- **Do not** open an ADR until both probes are answered; the
  architecture rests on them.
- **Reframe [[Reviewers]]** so its landing-gate material becomes input
  to this question rather than an active thread of its own, matching the
  reclassification above.
- The small enforcement piece (rule 11 routing + a merge-verdict hook)
  can be specified independently if a merge gate is wanted before the
  architecture lands — but note it has nowhere to read a verdict *from*
  until a judge exists.
