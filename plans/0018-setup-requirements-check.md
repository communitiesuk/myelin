---
title: Declare and verify myelin's repository requirements
status: draft
adr: 0013
date: 2026-10-29
deferred_reason: null
---

# Declare and verify myelin's repository requirements

## Reference

Implements `docs/adr/0013-requirements-declared-and-verified.md`. All
rationale — the tiers, why the model floor stays out of the manifest,
why the hook runs networked checks, why fixes are consent-gated — lives
there; this plan only orders the work.

This plan discharges the two deferrals recorded as `Defers:` trailers on
the ADR 0013 branch:

- `Defers: .claude/skills/release/SKILL.md ... (add a manifest-regeneration step for the requirements/opinions section)` — discharged by Step 6.
- `Defers: .tessl-plugin/plugin.json ... (declare the SessionStart hook and check script)` — discharged by Step 3.

Related: ADR 0007 (`docs/adr/0007-readme-requirements-and-opinions.md`,
the requirements/opinions contract whose verification deferral ADR 0013
reverses) and ADR 0005 (`docs/adr/0005-releases.md`, gate 4, revised so
the requirements section is regenerated rather than only read).

## Steps

The manifest, check script, render script and setup skill all live under
`skills/setup/`, so they ship in the package (everything under `skills/`
is packed) and are reachable from `${TESSL_PLUGIN_DIR}/skills/setup/...`
at hook time. Step 1 creates that directory; Step 4 adds its `SKILL.md`.

### Step 1 — Author the requirements manifest

Create `skills/setup/manifest.json`, the single source of truth for the
repository requirements myelin carries. JSON, to match
`.tessl-plugin/plugin.json` and read cheaply with `jq`.

Encode three groups (see ADR 0013 for the tiers):

- **`required`** — `git` present, Bash present, and a route to the remote
  where a remote exists (a remote is configured and a trunk resolves:
  local `dev`/`develop` or `refs/remotes/origin/HEAD`). Each item carries
  an `id`, a `label`, the human-facing prose used by the README render
  (Step 5), and the exact fix command (for the remote route:
  `git remote set-head origin -a`).
- **`desirable`** — the merge-settings opinion: host configured for merge
  commits only (no squash, no rebase, no fast-forward). Fix command:
  the `gh api -X PATCH` that disables the squash and rebase buttons.
- **`reported`** — the `gh pr merge` opt-in, held apart from both tiers.
  It carries the exact opt-in line `Bash(gh pr merge *)` and the note
  that it goes in `.claude/settings.json` or `.claude/settings.local.json`.
  It is a user decision: reported, **never** checked pass/fail and never
  set.

Do **not** encode the `git-workflow` model floor: it is owned by that
skill's `compatibility` frontmatter and serviced by the release-time
README read, not a repository fact a script checks (ADR 0013).

Commit: `Add the requirements manifest (skills/setup/manifest.json)`.

Verify: `jq . skills/setup/manifest.json` parses; the three groups and
the REQUIRED/DESIRABLE/reported items above are present; the model floor
is absent.

### Step 2 — Author the check script

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Create `skills/setup/scripts/check` (shape it on `skills/history/scripts/`
— a Bash script plus a `scripts/tests/` suite run by a `run.sh`). It is
**read-only**: it checks, never changes.

Behaviour:

- Resolves `manifest.json` relative to its own directory, so it runs
  correctly when invoked as `${TESSL_PLUGIN_DIR}/skills/setup/scripts/check`.
- Reads the manifest and, for each REQUIRED and DESIRABLE item, emits one
  line: pass/fail plus, on failure, the exact fix command from the
  manifest. Prints the `reported` item's opt-in line verbatim; never
  tests or sets it.
- Default mode: full per-item report (this is what the `doctor` skill
  runs).
- `--hook` mode (for Step 3): quiet when every REQUIRED and DESIRABLE
  check passes; on failure, surfaces REQUIRED failures prominently and
  DESIRABLE failures as a nudge; **always exits 0** and never blocks —
  the same exit-0/advisory discipline as `.claude/hooks/refresh-myelin.sh`.

Tests (under `skills/setup/scripts/tests/`, each building fixtures in a
fresh temp repo): a healthy repo passes silently in `--hook` mode; a repo
with no resolvable trunk fails the remote-route REQUIRED check and prints
`git remote set-head origin -a`; a repo whose host allows squash/rebase
fails the DESIRABLE check and prints its fix command; the reported opt-in
line is printed verbatim and never acted on; `--hook` mode exits 0 in
every case.

Commit: `Add the setup check script (skills/setup/scripts/check)`.

Verify: `bash skills/setup/scripts/tests/run.sh` is green.

### Step 3 — Declare the SessionStart hook (discharges the plugin.json deferral)

Edit `.tessl-plugin/plugin.json` to declare a cross-agent `SessionStart`
hook that runs the Step 2 script in `--hook` mode from the plugin
directory:

```json
"hooks": {
  "SessionStart": [
    { "hooks": [
        { "type": "command", "command": "bash",
          "args": ["${TESSL_PLUGIN_DIR}/skills/setup/scripts/check", "--hook"] }
    ] }
  ]
}
```

(Confirm the key — `hooks` for cross-agent vs `nativeHooks` for
Claude-Code-only — against the tessl hooks reference in ADR 0013's
References before committing; use the cross-agent `hooks` form so every
host agent gets the tripwire.) No executable logic is added here — the
quiet/advisory/exit-0 behaviour lives in the Step 2 script — so this step
is configuration only.

This discharges `Defers: .tessl-plugin/plugin.json`.

Commit: `Declare the SessionStart requirements-check hook in the manifest`.

Verify: `jq . .tessl-plugin/plugin.json` parses with the new `hooks`
block; `tessl plugin publish --dry-run` still passes.

### Step 4 — Author the setup/doctor skill

> **Directive for the implementer**: this step will author a new skill. Load the `skill-forge` skill before writing the `SKILL.md` (frontmatter → failing eval scenario → skill body).

Author `skills/setup/SKILL.md` (and its eval scenario under `evals/`, the
skill-forge contract). The skill is the manual delivery path: on-demand
re-check and consented, admin-gated fixes.

Skill body:

- Runs the Step 2 check script (default mode) from `$SKILL_DIR/scripts/check`
  and reports its output.
- For each failing DESIRABLE check, offers the manifest's fix command
  (the `gh api -X PATCH` disabling squash/rebase). A fix is applied
  **only** with the user's explicit consent **and only** where the user
  holds host admin (`gh api repos/{owner}/{repo} --jq .permissions.admin`
  is true) — never silently (ADR 0013). The fix commands are run by the
  agent from the skill body, consent-gated, in the style the `release`
  skill runs `gh` inline; no separate fix script ships.
- The `gh pr merge` opt-in is **reported** with its exact line
  (`Bash(gh pr merge *)`), never set.

The eval scenario asserts: the skill re-runs the check; it does not apply
any fix without consent; it does not attempt the merge-settings PATCH
when `.permissions.admin` is false; and it reports, never sets, the
`gh pr merge` opt-in.

Commit: the skill-forge sequence lands as its own commits
(frontmatter, eval scenario, body) per that skill.

Verify: `tessl eval lint .` passes; the new scenario runs; the skill
loads as a project/packaged skill.

### Step 5 — Author the README render script

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Create `skills/setup/scripts/render-requirements`. It reads
`skills/setup/manifest.json` and emits the manifest-owned Markdown for the
README Requirements section — the REQUIRED and DESIRABLE bullets and the
reported `gh pr merge` opt-in subsection — matching the prose shape
already in `README.md` (`## Requirements` and its "Letting the agent land
its own work" subsection).

The model-floor bullet is **not** rendered: it is owned by `git-workflow`
frontmatter and stays serviced by the release-time README read (ADR 0013,
ADR 0005 gate 4). The script emits only what the manifest owns.

Tests: the rendered output contains a bullet per manifest REQUIRED and
DESIRABLE item with its fix command, and the exact opt-in line
`Bash(gh pr merge *)`; it emits no model-floor bullet.

Commit: `Add the README requirements render script`.

Verify: `bash skills/setup/scripts/tests/run.sh` green; piping the
render output and comparing against the current `## Requirements`
manifest-owned bullets shows only intended differences.

### Step 6 — Add the regeneration step to the release skill (discharges the release deferral)

Edit `.claude/skills/release/SKILL.md` gate 4 (the README read, ~line 69):
add a step that **regenerates** the README requirements section from the
manifest by running `skills/setup/scripts/render-requirements` and
replacing that section, rather than only reading the README for
contradictions. The read remains for what the manifest does not own (the
model floor and the Opinions prose). This is a prose edit to the skill
body; its logic lives in the Step 5 script, so no code is written here.

This discharges `Defers: .claude/skills/release/SKILL.md`.

Commit: `Regenerate the README requirements section at release (gate 4)`.

Verify: the gate-4 text invokes the render script and replaces the
section; a dry run of gate 4 against the current tree regenerates the
Requirements section with no unintended change.

## Verification

End-to-end, in a disposable scratch repo (never the plugin repo — eval
fixtures git-init the cwd):

1. **Scripts.** `bash skills/setup/scripts/tests/run.sh` is green for
   both the check and render suites.
2. **Hook, healthy.** Install the plugin into a well-formed scratch repo
   (resolvable trunk, merge-commits-only host) and start a session: the
   `SessionStart` hook runs the check and is silent.
3. **Hook, broken.** In a scratch repo with no resolvable trunk and a
   host allowing squash/rebase, start a session: the hook surfaces the
   REQUIRED remote-route failure prominently with
   `git remote set-head origin -a`, nudges on the DESIRABLE
   merge-settings failure with its `gh api -X PATCH` fix, reports the
   `gh pr merge` opt-in line, and the session still starts (exit 0).
4. **Doctor.** Invoke the setup/doctor skill in the broken repo: it
   re-runs the check; offers the merge-settings fix only on consent and
   only where `.permissions.admin` is true; applies nothing silently;
   reports but never sets `gh pr merge`.
5. **Release regeneration.** Run gate 4 of the release skill against the
   plugin tree: the Requirements section is regenerated from the manifest
   and the model-floor bullet / Opinions prose are left to the read.
6. **Gates intact.** `tessl plugin publish --dry-run` and
   `tessl eval lint .` pass with the new hook, scripts, skill and
   scenario in place.

## Progress notes

- 2026-10-29: Plan drafted from accepted ADR 0013.
