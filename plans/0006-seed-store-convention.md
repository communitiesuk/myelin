---
title: Document the seed-store convention and the read-not-write rule
status: draft
adr: 0006
date: 2026-09-25
deferred_reason: null
---

# Document the seed-store convention and the read-not-write rule

## Reference

Implements `docs/adr/0006-where-do-captured-ideas-live.md`. That ADR's
Consequences state the only buildable piece is documentation and
convention: there is no new skill and no new store. This plan therefore
edits existing skill prose only.

Scope note: the ADR's buildable piece has two halves — the agent
*behaviour* (read a seed, never write a human's store; the developed
capture path) and the user-facing *documentation* of the seed-pointer
convention. This plan implements the first half in
`facilitated-discovery`. The second half is deferred to the roadmap
item "surface what myelin requires and is opinionated about", where the
seed-store convention is now captured as an opinion to state, rather
than placed in the README here and relocated when that section is
built. So this plan does not fully discharge the ADR alone; the
user-facing documentation rides with that later work.

## Steps

1. **Teach `facilitated-discovery` to read a seed and never write one.**
   Edit `skills/facilitated-discovery/SKILL.md` (body only; the
   `description` trigger contract is unchanged). Add, in the Opening
   phase, that where the project's agent instructions name a seed store,
   the relevant seed is read as the conversation's starting point; and a
   short standing rule that a human's seed store is read-only to the
   agent — read it for context, never write into it. Keep it to a few
   sentences; do not restate ADR 0006's reasoning, link to it.
   Verify: the two rules are present and worded as instructions;
   `tessl review run skills/facilitated-discovery` passes; the
   `description` is byte-for-byte unchanged (so no skill-forge retrigger).

2. **State the second entry path to a discovery note.** In the same
   file, in Phase 6B (or a note beside it), record that a discovery note
   may also be written as a *developed capture* mid-work — an idea worth
   keeping that is not the output of a full session — and that in this
   version that capture is gated by the human who is present, not
   written unattended. This is the plan-level question ADR 0006 left
   open, decided here in the affirmative.
   Verify: the entry path is stated; it does not contradict the existing
   Path A / Path B split; `tessl review run` still passes.

The user-facing documentation of the seed-pointer convention (a project
recording where its seeds live) is **not** a step here — it is deferred
to the README opinions/prerequisites roadmap item, per the Reference
scope note.

## Verification

- The read-a-named-seed behaviour, the read-not-write rule, and the
  developed-capture entry path appear in
  `skills/facilitated-discovery/SKILL.md`, and none contradicts
  `docs/adr/0006-where-do-captured-ideas-live.md`. (The user-facing
  documentation of the seed-pointer convention is out of scope here and
  is verified by the deferred README work, not this plan.)
- `tessl review run skills/facilitated-discovery` passes after the edits.
- `git diff` shows the skill's `description` field unchanged, confirming
  no new trigger contract and so no skill-forge pass required.
- No new skill, no new eval scenario directory, and no new store are
  created — matching the ADR's "no new skill and no new store".

## Progress notes

- 2026-09-25: ADR 0006 accepted separately (PR #44, `e7650d0`); the
  accept status-flip did not ride with this plan's branch, per the
  `plans` rule against editing an ADR from a plan's commits.
- 2026-09-25: revised after an independent review against ADR 0006. The
  review confirmed complete coverage, no contradictions, and no
  unauthorised additions; its findings were minor README-placement nits.
  Following those and a scoping decision, the README step was dropped and
  the seed-pointer convention captured into the README opinions/
  prerequisites roadmap item instead, so it is documented there rather
  than placed here and relocated. This plan now covers only the
  `facilitated-discovery` behaviour.
- Open for the implementer of Step 1/2: these are skill-*body* edits that
  add behaviour, and the standing question of whether a body edit that
  adds behaviour needs an eval scenario that fails without it is
  unresolved (the "body edit has a downstream" concern in the backlog).
  `skill-forge` scopes itself to new skills and does not mandate one
  here. If a scenario is wanted, the seam is a `facilitated-discovery`
  scenario asserting the agent reads a named seed and does not write the
  seed store — but note that a scenario cannot easily observe the
  read-only property, so weigh it rather than assume it.
