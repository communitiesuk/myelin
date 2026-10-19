---
title: Title pull requests from the branch's first commit
status: draft
adr: 0003
date: 2026-10-19
deferred_reason: null
---

# Title pull requests from the branch's first commit

## Reference

Implements `docs/adr/0003-git-workflow.md` (Rule 11: the pull request
is the integration path; what a commit contains is the governing
skill's). Work item: issue #61. No related plans.

## The defect

`skills/git-workflow/scripts/hosts/github` `propose` opens the pull
request with `gh pr create --head "$2" --base "$3" --fill-verbose`. On
a one-commit branch gh titles it with that commit's subject; on a
multi-commit branch it titles it with the humanised branch slug.
`.claude/skills/release/SKILL.md` Gate 5 builds release notes from the
pull request title (the first body line of the host's merge commit), so
the notes carry slugs.

## The choice

Title = the **subject of the first commit since the fork point**
(`git log --reverse --format=%s "$3..$2"`, first line). Recent merged
branches show why: first commits read as the artefact's title ("Add plan
0012: put ADR 0008's review content into the skills", "Revise ADR
0008: ..."), last commits are bookkeeping ("Apply the closing pass to
...", "Complete plan 0011: ..."). `land` has already refused an empty
range, so a first commit always exists and the slug is never reached.
The body stays what `propose` already writes on rewrite: every commit's
message and body, oldest first (`git log --reverse --format=%B`).

## Steps

### Step 1 — Specify the new `propose` contract

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Edit the comment headers only: the `propose` entry in
`skills/git-workflow/scripts/hosts/github` ("its description every
commit's message and body, oldest first") and the `propose` entry in
the host-module list of `skills/git-workflow/scripts/git-workflow`
(lines 31-34). Add: its title is the first commit's subject; an open
pull request's title and description are both rewritten. Commit:
`Specify that a pull request is titled from the first commit`.

### Step 2 — Add the failing tests (red)

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

In `skills/git-workflow/scripts/tests/land.sh`:

1. Line 101 asserts `--fill-verbose`; replace it with an assertion
   that the `pr create` line contains `--title Add ADR` and not
   `--fill`.
2. Add a decision case beside "decision: a new docs/adr file is
   proposed" using `ADRPATH=docs/adr/0002-x.md EXTRA=1 artefact ...`
   (two commits, subjects `Add ADR` and `Extend ADR`). Assert the
   `pr create` line contains `--title Add ADR`, does not contain
   `--title Extend ADR`, and its body contains `Extend ADR` and
   `Derives-From: docs/discovery/0001-note.md`.
3. Add the same two-commit assertion for a non-decision branch on the
   GitHub path, modelled on "github: the pull request is opened against
   the derived trunk" (line 231), with `EXTRA=1`.
4. Line 115 asserts `pr edit adr-0002-x --body`; change it to
   `pr edit adr-0002-x --title Add ADR --body`.

`skills/git-workflow/scripts/tests/stub-gh` needs no change: it already
logs `$*`, which includes `--title` and `--body`.

Run `bash skills/git-workflow/scripts/tests/run.sh`: the four changed or
new cases fail and nothing else does. Commit:
`Add failing tests for pull request titles (red)`.

### Step 3 — Make `propose` pass `--title` (green)

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

In `skills/git-workflow/scripts/hosts/github` `propose`, compute once
`title="$(git log --reverse --format=%s "$3..$2" | sed -n 1p)"` and
`body="$(git log --reverse --format=%B "$3..$2")"`. Create with
`gh pr create --head "$2" --base "$3" --title "$title" --body "$body"`
(no `--fill`); rewrite with `gh pr edit "$2" --title "$title" --body
"$body"`. Run `bash skills/git-workflow/scripts/tests/run.sh`: all
pass. Commit: `Title pull requests from the first commit (green)`.

### Step 4 — Say it in the skill

Add one sentence to `skills/git-workflow/SKILL.md` under the `land`
moment, and to `references/RULES.md` Rule 11: the pull request is
titled with the first commit's subject, and release notes are drawn
from that title, so the first commit's subject should read as the
artefact's title. This is a doc edit to an existing skill body with no
`description` change; no wrapper.

### Step 5 — Complete

In the last implementation commit delete this plan, with the trailer
`Completes: plans/0013-pr-titles-from-first-commit.md` and a body
saying what the plan produced.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` reports no failures.
- `grep -n -- '--fill' skills/git-workflow/scripts/hosts/github`
  prints nothing.
- End to end: land this plan's own implementation branch, then
  `gh pr view <n> --json title --jq .title` prints the subject of the
  branch's first commit, not the slug `plan-0013-...` or
  `chore-...`.
