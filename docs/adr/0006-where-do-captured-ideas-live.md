---
title: Where do captured ideas and proposals live?
status: accepted
date: 2026-09-25
---

# Where do captured ideas and proposals live?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Two kinds of thing get written down that are neither a discovery note,
an ADR, a plan, nor code. A human jots a one-line reminder to explore
something later. An agent, mid-work, spots a direction worth capturing
or hits a wall it cannot resolve alone. The plugin has no home for
either, and the `Ticket skill` line on the roadmap has stood as a vague
"interact with tickets" placeholder because it was never clear what a
ticket *is*.

The friction is real and current. The author's own backlog file was set
up for human reminders and has become a mixed store of one-line
reminders, project proposals, and agent-generated working notes,
addressed to different audiences and interleaved in one blob. Adding a
note to an item is fraught: a human reminder poisons an agent's context,
there is no obvious place to put it, and it cannot be found again once an
agent has written more text around it.

Pulling on it surfaced that "ticket" was covering several different
things at once, spread along a spectrum of definedness — from a vague
"think about this" to a fully-specified plan step — written and read by
both humans and agents. Four in particular:

1. **A seed**: an undeveloped idea to explore later. Human- or
   agent-originated.
2. **An escalation**: an agent hits something needing a human and must
   route to somewhere rather than thrash.
3. **Pick-up and triage**: reading the next item and deciding whether it
   is ready to implement or needs a conversation first.
4. **A plan line**: the fully-specified end of the spectrum. A plan's
   steps are implicitly tickets, and are the closest thing to the JIRA
   tickets most developers picture on hearing the word. This end is
   telling, because it is *already* an artefact the workflow owns — a
   plan step, with an ADR behind it — and needs no ticket concept at all.
   It marks the boundary: what is defined enough to act on has graduated
   out of "ticket" and into the discovery → ADR → plan chain, so a ticket
   concept need only cover the undeveloped end.

Two constraints bound the answer. myelin today is a plugin, not an
orchestrator or a harness — agent↔agent asynchronous communication,
which several of these uses ultimately want, is out of scope and belongs
to the escalation/orchestration question in
`docs/discovery/0003-escalation-and-orchestration.md`. And the first
external users arrive in the week of 2026-09-28, so whatever is decided
must be liveable and shippable now, and must not hardcode one person's
tools.

## Decision

There is no ticket store and no ticket skill in this version. Captured
ideas live in one of two places already available, split by role, and
the rest is deferred with named triggers.

### A seed lives in a user-owned store

An undeveloped idea — a "seed" — lives wherever its owner already keeps
such things: an org file, a `seeds.md`, an issue tagged on the host, or
several of these at once. The store is not fixed and not myelin's to
own. A project may record **where its seeds live** in a one-line pointer
in its agent instructions (`AGENTS.md` / `CLAUDE.md`), so that an agent
need not be told each session; the pointer is optional and the store may
move without breaking anything.

An agent **reads** the seed store as a starting point for a conversation.
An agent does **not write** into a human's private store. This is the
addressing rule that dissolves the friction above: agent-generated
content stops landing in the blob a human writes reminders into.

The store is not abstracted into a platform module, and no store is
named as the default. Naming one — org, or the host's issues — would
repeat, one level up, the error ADR 0003 exists to correct: hardcoding
one repository's convention as everyone's. "Read the seeds *here*" is a
per-project fact, told once, not built in.

### A developed capture becomes a discovery note

When a seed's time comes, an agent reads it, converses with the human,
and the thinking either goes nowhere, goes straight to an ADR, or is
captured as a **discovery note** — the existing artefact from
`facilitated-discovery`. Discovery notes are already the shared,
one-per-topic, git-tracked store this needs: they separate each
suggestion, they are readable and writable by human and agent alike, and
they already *graduate* — a note is consumed into its ADR (`Consumed-By`)
or leaves by abandonment. This is the boundary between a "ticket" and the
rest of the workflow: the ticket concept owns only the *undeveloped* end
of the spectrum, and anything defined enough to act on graduates into the
discovery → ADR → plan chain that already exists.

Nothing new is built for this. The rule is that a developed project
capture is a discovery note, not a new kind of object.

### The graveyard is bounded by presence and pruning

Two things keep the discovery-note store from filling with ideas no ADR
will ever consume. For now, an agent captures in the flow of work a human
is directly involved in, so the human is the gate on what becomes a note.
And retirement is a periodic human review of both stores — stale seeds
and stale notes are pruned by the same discipline, the same way the
backlog file is already pruned.

### Escalation, triage and a platform module are deferred

Three capabilities are explicitly *not* in this version, each with the
trigger that would bring it back:

- **Escalate-don't-thrash** — a defined route for an agent that hits a
  human-needs-to-decide wall. Becomes necessary when plans parallelise
  and subagents run with less supervision; until then, linear plans mean
  an agent rarely has anywhere to thrash, and the present human is the
  route. This is the escalation queue of
  `docs/discovery/0003-escalation-and-orchestration.md`, and belongs to
  that decision.
- **Pick-up and triage** — an agent reading the next item and deciding
  ready-to-implement versus needs-a-conversation. Wants the same
  parallel-execution and asynchronous-communication era.
- **A platform-abstraction module** — routing tickets to org / host
  issues / JIRA by type, the way ADR 0003's host module routes landing
  by remote. Waits with the above. If it is built, it is a module of the
  same shape as the git-workflow host module, not a new subsystem.

Agent↔agent asynchronous communication underlies all three and is
wholly `docs/discovery/0003-escalation-and-orchestration.md`'s.

## Alternatives considered

- **Build a dedicated ticket skill with a platform-abstraction layer
  now.** Rejected as premature. The pressures that justify a real ticket
  system — a graveyard of parked ideas, an agent thrashing with nowhere
  to escalate, unsupervised parallel subagents — are not here yet, and a
  next-week launch is better served by flexibility than by a subsystem
  built ahead of its need. The capabilities are deferred with the
  triggers that would revive them, above.
- **Hardcode an org file as the seed store.** Rejected: it is exactly
  ADR 0003's `dev`/`feature/*` mistake one level up. The author uses org;
  most users will not. The store is told, not built in.
- **Make the host's issues the fixed default seed store.** Rejected: it
  over-commits before launch and still names one tool as everyone's. A
  project that wants issues records that in its pointer; myelin does not
  decide it.
- **Invent a new "ticket" artefact for developed captures.** Rejected:
  the discovery note already is one — shared, separated, graduating — and
  a second object would duplicate it and need its own lifecycle,
  trailers and skill.
- **Let agents write into the human's backlog store.** Rejected: it
  reproduces the exact friction this decision removes — interleaved
  audiences, context poisoning, and lost reminders. Agents read that
  store; they do not write it.

## Consequences

- The `Ticket skill` roadmap item is answered for now by *not* building
  one: seeds are user-owned with an optional pointer, developed captures
  are discovery notes, and escalation/triage/platform are deferred with
  named triggers.
- The only buildable piece is documentation and convention: the
  seed-pointer line in a project's agent instructions and the
  read-not-write rule. There is no new skill and no new store.
- The discovery-note artefact acquires a second entry path. It was the
  output of a `facilitated-discovery` session; it may now also be a
  developed capture written more directly, gated by the present human.
  Whether `facilitated-discovery` should say so is a plan-level question.
- The graveyard risk is managed by human gating and periodic pruning,
  not by machinery. If parked notes accumulate faster than they are
  pruned, that is the signal that the deferred capture/triage capability
  has become necessary.
- The deferred capabilities are recorded here and cross-referenced from
  `docs/discovery/0003-escalation-and-orchestration.md`, so the
  orchestrator work inherits them rather than rediscovering them.
- Nothing here binds a target repository. A project with no seed store
  and no pointer simply has no seeds for an agent to read, which is the
  correct behaviour, not a failure.

## References

- `docs/discovery/0003-escalation-and-orchestration.md` — the
  escalation queue this decision defers to, and where the deferred
  escalate/triage/platform capabilities are inherited. The `Ticket skill`
  it names as "the same object as the escalation queue" is the concern
  this ADR bounds a v1 answer for.
- `docs/adr/0003-git-workflow.md` — the derive-don't-configure principle
  this decision reuses for the seed store, and the host-module shape a
  future platform module would take.
- `docs/adr/0004-where-does-history-live.md` — the discovery-note
  lifecycle (`Consumed-By`, abandonment) that makes a note the right home
  for a developed capture.
- `skills/facilitated-discovery/SKILL.md` — the skill that produces
  discovery notes and reads a seed as a conversation's starting point.
