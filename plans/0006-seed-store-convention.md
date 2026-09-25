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
edits existing skill and documentation prose only. Related: the roadmap
item to surface what myelin requires and is opinionated about, which the
README step below advances.

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

3. **Surface the seed-store convention in the README.** Add a short
   entry to `README.md` (under the opinions/prerequisites material) that
   a project may record, in one line in its `AGENTS.md`/`CLAUDE.md`,
   where its seeds live — an org file, a `seeds.md`, host issues, or
   several — so an agent need not be told each session; that the pointer
   is optional and the store may move; and that agents read that store
   but never write a human's private one.
   Verify: the README names the convention and the read-not-write rule;
   no statement in it contradicts ADR 0006 or the tree; the skills list
   in the README is unchanged (this adds prose, not a skill).

## Verification

- The seed-pointer convention and the read-not-write rule appear in both
  `skills/facilitated-discovery/SKILL.md` (as agent behaviour) and
  `README.md` (as a project-setup opinion), and neither contradicts
  `docs/adr/0006-where-do-captured-ideas-live.md`.
- `tessl review run skills/facilitated-discovery` passes after the edits.
- `git diff` shows the skill's `description` field unchanged, confirming
  no new trigger contract and so no skill-forge pass required.
- No new skill, no new eval scenario directory, and no new store are
  created — matching the ADR's "no new skill and no new store".

## Progress notes

- 2026-09-25: ADR 0006 accepted separately (PR #44, `e7650d0`); the
  accept status-flip did not ride with this plan's branch, per the
  `plans` rule against editing an ADR from a plan's commits.
- Open for the implementer of Step 1/2: these are skill-*body* edits that
  add behaviour, and the standing question of whether a body edit that
  adds behaviour needs an eval scenario that fails without it is
  unresolved (the "body edit has a downstream" concern in the backlog).
  `skill-forge` scopes itself to new skills and does not mandate one
  here. If a scenario is wanted, the seam is a `facilitated-discovery`
  scenario asserting the agent reads a named seed and does not write the
  seed store — but note that a scenario cannot easily observe the
  read-only property, so weigh it rather than assume it.
