---
title: State myelin's operating contract in the README
status: draft
adr: 0007
date: 2026-09-28
deferred_reason: null
---

# State myelin's operating contract in the README

## Reference

Implements `docs/adr/0007-readme-requirements-and-opinions.md`. The ADR
decides the README states myelin's requirements and opinions as prose,
up front, with runtime verification deferred to the init-check twin.
All steps below edit `README.md` only; none writes executable code.

## Steps

1. **Requirements section.** Add an explicit, up-front **Requirements**
   section to `README.md` (near the top, alongside Installing), listing:
   `git` and Bash; the host CLI (`gh` for GitHub) wherever a repo has a
   remote; `origin/HEAD` set — or a local `dev`/`develop` — with the
   one-command fix `git remote set-head origin -a`; and the model floor,
   with the term explained in plain language (the least-capable model a
   skill is known to run reliably on, below which behaviour degrades) and
   stated as whatever `git-workflow`'s `compatibility` frontmatter
   currently lands on (as of 2026-09-28, no floor).

2. **The `gh pr merge` permission, as a distinct callout.** Not folded
   into the requirements list. Explain that, absent a harness permission
   for the merge command, `git-workflow` deliberately stops at `land` and
   the artefact waits as an open PR; give the exact opt-in line
   (`Bash(gh pr merge *)` in `.claude/settings.json` for a repo, or
   `.claude/settings.local.json` per clone), and say the stop is by
   design.

3. **Opinions section.** Add an explicit **Opinions** section stating:
   branch before any edit (markdown artefacts included); one branch per
   artefact; the fork point is derived (`dev` → `develop` → `origin/HEAD`),
   never configured; merge commits only (no squash/rebase/fast-forward),
   with the repo-level recommendation to disable the squash/rebase
   buttons; PR by default where a remote exists, ADRs and `Revises`
   branches landed by a human and everything else by the agent; worktree
   isolation on contention (`.worktrees/` gitignored); and seeds in a
   user-owned store located by an optional `AGENTS.md`/`CLAUDE.md`
   pointer, read but never written by agents.

4. **Usage beyond install.** Add usage that carries a reader through the
   workflow end to end — the discovery → ADR → plan → implementation
   progression, and how a skill is invoked — rather than the install
   command alone.

5. **Complete the plan.** On the final commit of the implementation
   branch, delete this plan file with a `Completes:
   plans/0007-readme-operating-contract.md` trailer and a body saying
   what the README now states.

## Verification

- **ADR 0005 gate 4, mechanical half.** The release skill's skill-list
  diff (README's numbered skill list vs. the packaged `skills/*/`) still
  prints nothing — the new sections must not disturb that list.
- **ADR 0005 gate 4, read half.** Read the README once: the requirements,
  the `gh pr merge` callout, the opinions and the usage must each be
  present and contradict nothing in the tree — in particular the model
  floor matches `git-workflow`'s frontmatter (no floor) and the
  `gh pr merge` line matches the permission mechanism.
- The document renders as valid Markdown and every internal link (e.g. to
  `docs/adr/*`) resolves.

## Progress notes

- 2026-09-28: plan written from accepted ADR 0007.
