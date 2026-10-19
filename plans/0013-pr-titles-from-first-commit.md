---
title: Title pull requests from the branch's first commit
status: in-progress
adr: 0003
date: 2026-10-19
deferred_reason: null
---

# Title pull requests from the branch's first commit

## Reference

Implements `docs/adr/0003-git-workflow.md` (integration goes through the
host's pull request; the skill's Rule 3 delegates what a commit
contains). The ADR is silent on titles. Work item: issue #61. No related
plans.

`propose` in `skills/git-workflow/scripts/hosts/github` runs
`gh pr create ... --fill-verbose`, which titles a multi-commit branch
with its humanised slug. The new title is the first commit's subject
(`git log --reverse --format=%s "$3..$2"`, first line); the body stays
every commit's message and body, oldest first.

## Steps

### Step 1 — Specify the new `propose` contract

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Edit the comment headers only: the `propose` entry in
`skills/git-workflow/scripts/hosts/github` ("its description every
commit's message and body, oldest first") and the `propose` entry in
the host-module list of `skills/git-workflow/scripts/git-workflow`
(lines 31-34). Add: its title is the first commit's subject; an open
pull request's title and description are both rewritten. In the same
commit flip this plan's `status` from `draft` to `in-progress`. Commit:
`Specify that a pull request is titled from the first commit`, with the
trailer `Derives-From: plans/0013-pr-titles-from-first-commit.md`.

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
   `--title Extend ADR`, and that the whole stub log
   (`$(cat "$GH_STUB_LOG")`, not the grepped line, since the body spans
   lines) contains `Extend ADR` and
   `Derives-From: docs/discovery/0001-note.md`.
3. Add the same two-commit assertions, against the whole log, for a
   non-decision branch on the GitHub path, modelled on "github: the pull
   request is opened against the derived trunk" (line 231), with
   `EXTRA=1`.
4. Rename the d7 test, whose name says it rewrites only the
   description, to say it rewrites title and description. Line 115 asserts `pr edit adr-0002-x --body`; change it to
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

### Step 4 — Say it in the skill, and complete

Add "that a pull request is titled with the first commit's subject" to
the "What the script decides" list in `skills/git-workflow/SKILL.md`,
and one sentence saying so to `skills/git-workflow/references/RULES.md`
Rule 11. This is a doc edit to an existing skill body with no
`description` change; no wrapper. Commit: `Document that a pull request
is titled from the first commit`. It also deletes this plan, with the
trailer
`Completes: plans/0013-pr-titles-from-first-commit.md` and a body saying
what the plan produced.

## Verification

- `bash skills/git-workflow/scripts/tests/run.sh` reports no failures.
- End to end: on this implementation branch, which has at least two
  commits, run the branch's own
  `bash skills/git-workflow/scripts/git-workflow land` (not the
  installed copy, which lacks the fix), the
  landing itself is the check. Then
  `gh pr view <branch> --json title --jq .title` prints `Specify that a pull
  request is titled from the first commit`, not the slug.
