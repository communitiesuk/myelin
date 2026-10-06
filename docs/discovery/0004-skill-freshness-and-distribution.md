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

## What the facilitated-discovery established (2026-10-06)

Verified against the Claude Code docs and this machine:

- **Skill precedence is hardcoded** (enterprise > personal > project >
  bundled) and cannot be reordered by any setting; `skillOverrides`
  controls visibility only. So "make the repo copy win" has exactly two
  levers: namespace it, or remove the competitor.
- **Namespacing yields coexistence, not a winner.** A plugin skill
  (`myelin:plans`) and a bare skill (`plans`) both load. This kills the
  *silent precedence shadow*, but it does not adjudicate two skills that
  do the same job: a user picks explicitly by name, but when the *model*
  triggers a skill autonomously it chooses among distinct-named
  overlapping skills by description, with no deterministic tie-break — so
  a stale duplicate can still be picked.
- **Two distinct failure modes, and namespacing fixes only one.**
  (1) *silent precedence shadowing of same-named skills* — the
  demonstrated bug; (2) *two differently-named skills doing the same job,
  one stale*, competing for the same trigger, with nothing invalidating
  one cache against the other. Namespacing removes (1); it leaves (2).
- **tessl mechanics.** An install is a *materialised snapshot of the
  published version* under `.tessl/plugins/<workspace>/<plugin>/skills/`,
  surfaced through a single symlink from `.claude/skills/tessl__<skill>`
  — not a view of the repo's `skills/` source, even for an in-repo
  install. Editing a skill on `dev` changes nothing an agent loads until
  re-install. `tessl install --watch-local` reinstalls a local source on
  change (the dev-mode primitive; there is no "install from a branch").
  Concretely, **the myelin repo has no in-repo install**, so an agent
  working in it falls back to personal scope — which is how this session
  loaded stale skills.
- **A namespaced marketplace plugin is viable and cheap for consumers.**
  A private marketplace is a git repo + `marketplace.json`; the
  self-serve path (`/plugin marketplace add`) needs only git credentials
  — **no Team/Enterprise subscription**. Updates are `claude plugin
  update`: a clean in-place replace, old versions GC'd after 14 days. The
  org-managed claude.ai sync path (auto-update, no per-user git creds)
  *does* need Team/Enterprise. On the consumer's paved path — one plugin,
  updated in place — failure mode (1) cannot arise; only a self-inflicted
  vendored duplicate reaches mode (2).

## A third option: fresh containers

A fresh agent in a fresh container with a single injected skills cache
dissolves *both* failure modes by construction — nothing stale is
present and nothing competes — independent of namespacing. This is a
second, independent driver converging on the container/orchestrator
capability already explored in [[0003-escalation-and-orchestration]],
whose container was motivated by blast-radius, not freshness. But it is
major scope creep for this issue, helps only if the environment is
genuinely rebuilt per run, is orthogonal to how skills are *distributed*,
and inherits 0003's unresolved credential-boundary question.

## Where this landed: defer the restructure, mitigate now

The marketplace restructure fixes only failure mode (1), carries real
cost (a `Revises` to ADR 0005 and a migration), and the complete fix
(fresh containers) belongs to the out-of-scope orchestration direction.
So the decision is to **defer the structural change** and mitigate in the
near term, pending the container/orchestration call:

1. **Remove stale personal-scope myelin installs** so nothing shadows a
   repo copy — done this session (see below).
2. **A dev-mode procedure, not just a warning:** to develop myelin,
   ensure no global myelin install exists and install into the repo
   (project scope) or `tessl install --watch-local` against the checkout;
   with no personal copy, the project/local one wins. This closes the
   eating-own-cooking failure (Scenario 1) without a restructure.
3. **A README warning** for consumers that a personal/global install
   silently outranks a project install of the same bare-named skill.

The namespaced-marketplace route stays documented here as the structural
option to revisit once the container/orchestration direction is decided.

## Open questions

Resolved by the 2026-10-06 session:

- *Dev-mode* — answered for now by the procedure above (no global
  install + project-scope/`--watch-local`); the structural answer waits
  on the container decision.
- *Long-term shape* — a namespaced marketplace plugin is the structural
  route, but it fixes only failure mode (1), so it is deferred rather
  than adopted.
- *Does it change ADR 0005* — yes, the restructure would `Revise` it;
  deferred with the restructure.

Still open:

- **Sequencing against containers/orchestration.** The complete fix is a
  fresh-container-per-run model owned by [[0003-escalation-and-orchestration]].
  How urgent the distribution restructure is depends on whether agents
  will run in fresh containers anyway. This is the real gate on any ADR
  here.
- **Mode (2) in general.** Even with namespacing or an updater, nothing
  invalidates one skills cache against another; only removing the
  competitor or rebuilding the environment does. Is there a lighter
  mechanism than a container rebuild?
- Which layer owns consumer freshness if the restructure is deferred: an
  updater skill (seed #57), a `release` step that calls it, or a
  `SessionStart` check?

## Mitigation taken

- **2026-09-28.** Refreshed the personal install: uninstalled
  `majerr/myelin` and installed `mhclg-aaai/myelin@0.2.0` globally. This
  did *not* fully reconcile — it left the `~/.claude/skills/tessl__*`
  symlinks dangling at the removed `majerr` path, a concrete instance of
  "a stale install under an old name lingers" and of an uninstall that
  cleans `.tessl/plugins/` but not the skills-dir symlinks.
- **2026-10-06.** Removed myelin's personal-scope skills entirely — the
  four dangling `tessl__*` symlinks and four bare-named copies
  (`adr`, `plans`, `facilitated-discovery`, `test-first-workflow`) — so
  no personal copy shadows a repo copy. Non-myelin personal skills were
  left untouched. This is the near-term mitigation above, not the
  decision; the sequencing question against containers remains.

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
