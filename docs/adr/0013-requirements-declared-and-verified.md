---
title: How are myelin's requirements declared and verified in a repository?
date: 2026-10-29
---

# How are myelin's requirements declared and verified in a repository?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Interest in myelin is growing and the maintainer wants as little
friction as possible for a new user — in particular, a new user should
not have to know they must invoke a setup skill. ADR 0007 states
myelin's requirements and opinions in README prose and *defers*
verifying them, leaving the executable twin (a `SessionStart` hook or a
`doctor` command) to its own decision. That deferral is reversed here:
prose a user skims closed neither the `gh pr merge` surprise nor the
host merge-settings misconfiguration seed #122 was raised for — as in
issue #76, where the host still allowed squash and rebase merges and
nothing caught it until land time.

A plugin can now distribute a hook, not just skills: it declares hooks
in `.tessl-plugin/plugin.json`, `SessionStart` is supported, and
`${TESSL_PLUGIN_DIR}` lets the hook script ship inside the plugin and
run from there without being copied into the user's repo (see
References). `.tessl-plugin/plugin.json` already exists, so this
is a small extension, not a new packaging regime.

## Decision

A machine-readable **manifest** in the plugin is the single source of
truth for the repository requirements it carries — the tiered checks
below. (The model floor—a property of the model running the agent,
established by evals—is not a pass/fail repository fact a script can
check, so it stays outside the manifest and remains owned by
`git-workflow`'s `compatibility` frontmatter, serviced by the release-time
README read.) One check script, shipped in the plugin, reads it; two
delivery paths run that script; and ADR 0007's README requirements section
is regenerated from the same manifest.

### The manifest and its tiers

The manifest classifies each check into one of three kinds:

- **REQUIRED** — myelin cannot operate without it: `git`, Bash, and a
  route to the remote where a remote exists.
- **DESIRABLE** — strongly encouraged but non-breaking: the
  merge-settings opinion (no squash, no rebase, no fast-forward).
- **Reported user-decision**, held apart from both tiers — the
  `gh pr merge` opt-in. This is a decision the user must make, not a
  pass/fail fact, so it is *reported* with the exact opt-in line and
  **never set** (ADR 0007).

### One check script, two delivery paths

The script lives in the plugin and runs from `${TESSL_PLUGIN_DIR}`; it
is never copied into the user's repository.

- **A distributed `SessionStart` hook**, declared in
  `.tessl-plugin/plugin.json`, is the zero-friction tripwire: quiet
  when healthy, advisory, never blocks the session, and always exits 0
  (as `refresh-myelin.sh` does). A REQUIRED failure is surfaced
  prominently; a DESIRABLE failure is a nudge. It runs without the user
  knowing it exists.
- **A manual `setup`/`doctor` skill** does on-demand re-check and owns
  the consented fixes — e.g. the `gh api` PATCH that disables the
  squash/rebase buttons. A fix is applied only with the user's
  `.permissions.admin` consent, and never silently.

### The README section is regenerated

The README requirements/opinions section is regenerated from the
manifest as part of the existing release-time README step (ADR 0005,
ADR 0007), rather than hand-maintained and read for contradictions.

## Alternatives considered

- **Manual skill only; defer the hook.** The seed's original scope and
  ADR 0007's adopted deferral: ship prose now, leave verification to a
  skill the user invokes. Reversed because it does not remove new-user
  friction — the user must know to invoke it, which is exactly what the
  maintainer wants to avoid.
- **The hook runs only local checks; merge-settings is left to the
  manual skill.** Rejected: per-session network latency is negligible
  for a networked coding agent (no network, no myelin), and the #76
  host merge-settings misconfiguration is precisely what should be
  caught up front rather than waiting for a user to run `doctor`.
- **A third hand-maintained prose restatement instead of a manifest.**
  Rejected: it adds a third place to drift. The README is for humans
  and should be generated from the machine-readable source.

## Consequences

- New-user friction is removed: the checks run on session start without
  the user knowing the skill exists, while the manual skill remains for
  on-demand re-check and fixes.
- The manifest becomes the one coupling point for requirements; the
  README section and both delivery paths derive from it. This revises
  ADR 0005's gate-4 README read: for this section the release
  regenerates from the manifest rather than reading it.
- Fixes that change a user's repository or host settings are gated on
  explicit `.permissions.admin` consent and never applied silently; the
  `gh pr merge` opt-in is reported, never set.
- Out of scope: deeper harness wiring beyond the `SessionStart` hook.

## References

- `docs/adr/0007-readme-requirements-and-opinions.md` — the
  requirements/opinions contract this decision verifies, and the
  runtime-verification deferral it reverses.
- `docs/adr/0003-git-workflow.md` — the merge-commits-only contract the
  DESIRABLE merge-settings check enforces.
- `docs/adr/0005-releases.md` — its gate-4 README read, revised here
  so this section is regenerated from the manifest rather than read.
- tessl hooks documentation,
  https://docs.tessl.io/reference/configuration#hooks — that a plugin
  distributes a `SessionStart` hook via `.tessl-plugin/plugin.json` and
  `${TESSL_PLUGIN_DIR}`.
- seed #122 (the setup/init check) and concrete case #76 (the host
  merge-settings misconfiguration) — what prompted this.
