---
title: What must the README tell a new user before they rely on myelin?
status: accepted
date: 2026-09-28
---

# What must the README tell a new user before they rely on myelin?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The first external users arrive at a divisional away day in the week
of 2026-09-28, with a public launch targeted for 2026-10-01. The
README has grown past the skills outline it started as — it now covers
install, the skills left to right, how the repo records its own work,
a roadmap and a status caveat — but it still leaves a new user to
discover myelin's operating contract by hitting it.

The gap is not the skill descriptions. It is that the things a user
*must* have set up, and the things myelin is *opinionated* about, are
implicit in the ADRs and in `git-workflow`'s frontmatter, and a user
does not read those before running the plugin. The incident that
prompted this: a `git-workflow land` merged cleanly only because
`gh pr merge` was allowed in this repo's `.claude/settings.local.json`.
A new user has neither `gh` installed nor that permission, so the skill
correctly stops at `land` and reports rather than merging — but nothing
tells them beforehand that this is a prerequisite, and one of them is a
*decision they must make*, not a fact myelin can assert for them.

The related question of whether myelin should *verify* these
assumptions at runtime — a `SessionStart` hook or a `myelin doctor`
command that fails loudly instead of trusting prose — is harness-shaped
and under-determined. It is the executable twin of this one and is left
to its own decision (see References). This ADR answers only what the
README states, in prose, before launch.

## Decision

The README states myelin's operating contract to a new user in prose,
up front, as two explicit sections a reader meets before they run
anything — not left implicit in the ADRs, and not deferred to a
runtime check. Verification is out of scope here and deferred to the
init-check decision.

### Requirements — stated plainly, as an explicit section

- **`git` and Bash.**
- **The host CLI (`gh` for GitHub) wherever a repo has a remote.** The
  pull-request path needs it; without it `git-workflow` pushes and
  stops.
- **`origin/HEAD` set (or a local `dev`/`develop`).** The fork point is
  derived from these; a repo where none resolves is "not set up" and
  the workflow stops. State the one-command fix,
  `git remote set-head origin -a`.
- **The model floor `git-workflow` declares** — with the term itself
  explained in plain language, not left as jargon a new reader must
  already know: the least-capable model a skill is known to run
  reliably on, below which its behaviour degrades. State whatever the
  skill's `compatibility` frontmatter currently lands on rather than
  let a weak-model user conclude the skill is broken. As of
  2026-09-28 that is *no floor* (measured on deepseek-v4.1-flash); the
  README follows the frontmatter if it moves.

### The `gh pr merge` permission is stated as a deliberate choice, with the opt-in

This is the one item that is a *user decision*, not a fact, so it is
called out distinctly from the requirements list. The README explains
that, absent a harness permission for the merge command, the auto-mode
classifier refuses the merge and the artefact waits as an open PR —
that this is deliberate — and gives the exact opt-in line
(`Bash(gh pr merge *)` in `.claude/settings.json` for a repo, or
`.claude/settings.local.json` per clone).

### Opinions — surfaced, not buried in the ADRs

An explicit section states what myelin is opinionated about, so a user
meets it before it surprises them:

- Branch before *any* edit, markdown decision artefacts included.
- One branch per artefact; an artefact is what one skill produces in
  one invocation.
- The fork point is derived (`dev` → `develop` → `origin/HEAD`), never
  configured.
- Merge commits only: no squash, no rebase, no fast-forward; myelin
  recommends disabling the squash/rebase buttons at the repo level.
- PR by default where a remote exists; ADRs and `Revises` branches are
  landed by a human, everything else the agent lands itself.
- Worktree isolation on contention; `.worktrees/` is gitignored.
- Seeds live in a *user-owned* store, located by an optional one-line
  pointer in `AGENTS.md`/`CLAUDE.md`; agents *read* it and never write
  a human's private one (ADR 0006). This convention was deferred from
  plan 0006 to be documented here.

### Usage beyond install

The README carries enough usage to drive the workflow end to end
(discovery → ADR → plan → implementation, and how a skill is invoked),
not only the install command it has today.

## Alternatives considered

- **Verify at runtime instead of stating in prose** — a `SessionStart`
  hook or a `myelin doctor` command that checks the requirements and
  fails loudly. Not rejected on its merits; deferred. It is
  harness-shaped, under-determined (how much it knows about *this*
  repo; how it handles the permission it cannot decide for the user),
  and wants its own discovery. Prose ships now; the check is a later
  decision (see References). The `gh pr merge` permission is the item
  that most wants a check rather than prose a user skims, and is where
  that decision will bite first.
- **Leave requirements and opinions implicit in the ADRs and
  frontmatter, linking out from the README.** The status quo. Rejected:
  it is exactly what produced the `gh pr merge` surprise. A user does
  not read `git-workflow`'s frontmatter or ADR 0003 before running the
  plugin, and "surface, don't bury" is the whole point of this item.
- **List the permission alongside the factual requirements.** Rejected:
  it is a decision the user must make, not a box to tick, and flattening
  it into the requirements list loses that it is deliberate and how to
  opt in.

## Consequences

- The README now restates facts owned elsewhere — the model floor in
  `git-workflow`'s frontmatter, the `gh pr merge` line, the fork-point
  ladder. These are coupling points: if the floor moves or the landing
  behaviour changes, the README must follow. ADR 0005's documentation
  gate checks only the skill list mechanically; the rest is the
  `release` skill's README read — an agent read fired every release
  that looks for any statement the tree contradicts and fixes it on the
  release branch. So this coupling is serviced there, by a judgement
  read rather than a mechanical check.
- Prose does not enforce. A user can still ignore it and hit the wall
  the `gh pr merge` incident describes; closing that is the init-check
  decision's job, and its absence is felt until it lands. This ADR
  narrows the surprise to a user who skipped the README, not one who
  read it.
- The seed convention from ADR 0006 is now documented in a shipped
  artefact rather than waiting for a home, so plan 0006's dropped README
  step is discharged here.

## References

- `docs/adr/0003-git-workflow.md` — the source of most of the contract:
  the derived fork point, branch-before-edit, one-branch-per-artefact,
  merge-commits-only, the PR-by-default path, the human-lands-decisions
  rule, and the stop at `land` that the `gh pr merge` permission opts
  out of.
- `docs/adr/0004-where-does-history-live.md` — the tree-is-current and
  trailer conventions the README already states and that the opinions
  section keeps consistent with.
- `docs/adr/0005-releases.md` — gate 4, the documentation gate that
  reads the README, and the model-floor / release-gate pin the
  requirements section reflects.
- `docs/adr/0006-where-do-captured-ideas-live.md` — the user-owned seed
  store and read-not-write rule the opinions section documents, deferred
  here from plan 0006.
- `skills/git-workflow/SKILL.md` — the `compatibility` frontmatter that
  is the source of record for the requirements and the model floor the
  README restates.
- The setup/init-check decision (the harness-shaped twin) — where
  runtime verification of these same requirements is deferred, rather
  than stated as prose. Not yet an ADR; captured as a `#C` seed.
