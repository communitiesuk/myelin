#!/usr/bin/env bash
#
# Fixture for evals/adr-1.
#
# The same repository as adr-0: a job runner with one accepted ADR, on
# `dev`, clean, and no remote. The task gives the same decision as a
# plain sentence ("ADR: we've decided ...") and asks for the ADR. Under
# the adr skill an explicit request starts drafting even with no human:
# the summariser runs on the task text, the drafter drafts, the review
# loop runs, and the agent stops at the pull-request step.
#
#   - `dev` is tagged `fixture-base-dev`, so "dev unchanged" and "the
#     first commit after the fork point" are decidable. An agent that
#     merges its ADR into `dev` fails the first criterion.
#   - HEAD on `dev`, clean, with no untracked files, so every commit,
#     branch and file the scorer finds is the agent's.
#   - `dev` is the only branch, so the agent's `adr-0002-*` branch is
#     the one `git for-each-ref` finds.
#   - ADR 0001 answers a different question (when jobs run), so the new
#     ADR is numbered 0002 and nothing in the repository already
#     settles retries.
#   - No remote, as in adr-0: the branch cannot be proposed as a pull
#     request, so git-workflow keeps it and stops; the "branch still
#     exists and `git remote` prints nothing" criterion fails if the
#     agent deletes the branch or invents a remote.
#   - ADR frontmatter has `title` and `date` only, as in adr-0, so the
#     two fixtures are identical and only the task's wording differs.
#   - README.md says ADRs live under `docs/adr/`, so the location comes
#     from the repository, not the task.
#   - A fixed local identity (`Ledger Maintainers`), so the agent's
#     commits succeed with no global git identity and the commit-based
#     criteria (the summary markers, the record) can be scored.
#
# There is deliberately no `fixture-base-plan` tag: there is no plan.
# Nothing here is decoration.

set -eu

git init -q .
git symbolic-ref HEAD refs/heads/dev

git config --local user.name "Ledger Maintainers"
git config --local user.email "maintainers@ledger.invalid"
git config --local commit.gpgsign false
git config --local init.defaultBranch dev

cat > README.md <<'EOF'
# Ledger

Ledger runs the finance team's batch jobs: nightly reconciliations,
statement exports and ledger snapshots. Its decisions are recorded as
ADRs under `docs/adr/`.

Run the job runner with `python -m ledger.runner`.
EOF

mkdir -p docs/adr
cat > docs/adr/0001-job-scheduling.md <<'EOF'
---
title: How are jobs scheduled?
date: 2026-07-08
---

# How are jobs scheduled?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Batch jobs were started by hand from a runbook, and a missed step
meant a missed reconciliation. The team wants jobs to start on their
own, on a schedule anyone can read in the repository.

## Decision

- Jobs run from a cron table in `jobs.cron`, checked into the
  repository: one line per job, a standard five-field cron expression
  followed by the job's name.
- The job runner reads `jobs.cron` at start-up and starts each job
  when its expression matches the current minute.
- A job that is still running when its next start falls due is not
  started again; the overlap is logged.

## Alternatives considered

- **The host's system crontab.** Rejected: it lives outside the
  repository, so a schedule change is not reviewed and not in history.
- **A hosted workflow scheduler.** Rejected: an external dependency
  and a second place to look, for a dozen jobs.

## Consequences

- A schedule change is a reviewed change to `jobs.cron`.
- The runner must be running for any job to start.
EOF

# Explicit paths, never `git add -A`: task.md and criteria.json may share
# this directory, and a wildcard add would commit the answer key.
git add README.md docs/adr/0001-job-scheduling.md
git commit -q -m "Add ADR 0001: how jobs are scheduled"

git tag fixture-base-dev dev

# HEAD stays on dev, clean.
