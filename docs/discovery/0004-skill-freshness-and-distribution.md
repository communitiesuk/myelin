---
title: How do myelin's skills stay current in the repositories that use them?
status: in-progress
date: 2026-09-28
---

# How do myelin's skills stay current in the repositories that use them?

## Problem

myelin publishes its skills as a versioned plugin, but nothing keeps an
*installed* copy current, and Claude Code's skill-resolution rules let a
stale install silently win. The result: an agent can run week-old skill
bodies while the repository's own source, and the latest published
version, both say something different — with no error to signal it.

This is not hypothetical. It is what this session ran into.

## What surfaced it

A plan was mis-numbered `0007`, colliding with the existing
`plans/0007-history-based-artefact-numbering.md`. The rule that would
have prevented it — "take the next plan number from history, not the
tree" — had landed in `skills/plans/SKILL.md` on `dev` on 2026-09-25
(commit `4cc0511`). But the agent, invoking the `plans` skill through
the harness, was served a copy that predated it and so never saw the
rule. The irony: the collision is exactly the failure mode that landed
rule exists to prevent.

## The mechanism

Tracing it produced a chain of compounding causes:

1. **The harness loads *installed* skills, not repository source.** The
   `Skill` tool resolves whatever is registered in the harness's skills
   directory, not the working tree. So editing `skills/*/SKILL.md` on
   `dev` does not change what the running agent loads. myelin was not
   eating its own cooking.
2. **Publishing is not installing.** `tessl plugin publish` records a
   version in the registry; it updates no install anywhere. The global
   install on this machine was `majerr/myelin@0.1.0` from 2026-09-22 and
   had never been refreshed, so 0.1.1 and 0.2.0 existed in the registry
   while every consumer stayed on 0.1.0.
3. **Personal scope shadows project scope.** Claude Code resolves
   same-named skills **enterprise > personal (`~/.claude*/skills`) >
   project (`.claude/skills`)** (docs: code.claude.com/docs/en/skills.md
   — "the project skill is not accessible … shadowed by personal").
4. **tessl installs collide by bare name.** tessl symlinks each skill
   into the skills directory as `tessl__<skill>` — the same name in
   every scope, and *not* the `/plugin-name:skill` namespace a
   marketplace plugin would get (which would coexist). So a project
   install of the plugin is shadowed by a same-named personal install.
5. **Workspace renames leave shadows behind.** The plugin has been
   `myelin/myelin`, `majerr/myelin`, `communitiesuk/myelin` and now
   `mhclg-aaai/myelin`. A stale install under an old name is not touched
   by installing the new one; it lingers and keeps shadowing.

## Demonstrated

In `~/projects/myelin-launch-talk` the plugin was project-installed as
`communitiesuk/myelin` (2026-09-24). Both that project install and the
global `majerr/myelin@0.1.0` expose a skill named `tessl__plans`; by the
precedence above the **global 0.1.0 won**, and the project install sat
inert and unreachable by name. That repository has been running 0.1.0
regardless of what was installed into it.

## What this rules out, and the options left

The obvious fix — "project-scope the repo's own skills so development
uses `dev`" — **does not work on its own**, because personal outranks
project: a same-named global keeps shadowing the project copy. Getting a
per-repository version to actually load requires one of:

- **Uninstall / reconcile stale globals** so project installs surface.
  An updater must *remove* old-workspace-name installs, not merely
  upgrade the current one.
- **`skillOverrides` in the repo's `.claude/settings.json`** to disable
  the global by name (exact key unverified against the docs — confirm
  before relying on it).
- **Restructure myelin as a marketplace plugin**, so its skills are
  namespaced `/myelin:skill` and coexist with project skills rather than
  colliding.

Orthogonally, freshness for *consumers* wants an **updater** that runs
after a release (seed below), and freshness for *development of myelin
itself* wants the running agent to load `dev`'s skills, not the last
published version — a different target the updater alone does not serve.

## Open questions for the facilitated-discovery

- Which layer owns freshness: an updater skill, a `release` step that
  calls it, a `SessionStart` check, or the init-check twin?
- Does the release skill call the updater before exit (seed #57), and
  what exactly does "update" mean across the workspace renames?
- Dev-mode: how does an agent developing myelin load the repo's `dev`
  skills over any install — project-scope + global-uninstall, an
  override, or a `--watch-local` install from source?
- Is the right long-term shape a marketplace plugin (namespaced,
  non-colliding) rather than bare `tessl__`-named skills?
- Does any of this change ADR 0005 (releases), and is a `Revises`
  warranted?

## Immediate mitigation taken this session

Refreshed the personal install: uninstalled `majerr/myelin` and
installed `mhclg-aaai/myelin@0.2.0` globally, so every repo falling back
to the personal scope now gets current skills. This is a stopgap, not
the decision; the questions above remain.

## References

- Seed #57 (`Updater skill`) — the update-installed-plugins partner to
  the release skill; this note develops the case for it.
- `docs/adr/0005-releases.md` — the release/publish decision this
  distribution question sits on top of; likely revision target.
- `docs/adr/0004-where-does-history-live.md` — the tree-is-current rule
  and history-based numbering whose absence in the stale install caused
  the triggering incident.
- Seed #66 — when an ADR flips `proposed`→`accepted`; tangential, raised
  the same day.
- Claude Code skills docs: https://code.claude.com/docs/en/skills.md —
  scope precedence and plugin namespacing.
