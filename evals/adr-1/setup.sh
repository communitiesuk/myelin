#!/usr/bin/env bash
#
# Fixture for evals/adr-1.
#
# The same repository as adr-0: a job runner with one accepted ADR, on
# `dev`, clean, and no remote. The task gives the same decision, but
# unlabelled ("ADR: we've decided ..."). Under the adr skill an
# unlabelled statement is conversation: it goes through the summariser
# and the human's confirmation, and with no human to confirm a summary
# the agent stops and asks. Every criterion scores what the agent did
# NOT do, so this scenario discriminates only read together with adr-0.
#
#   - `dev` is tagged `fixture-base-dev`, so "no commits"
#     (`git log --all fixture-base-dev..` empty) and "dev unchanged" are
#     decidable. An agent that drafts anyway leaves a commit and fails.
#   - HEAD on `dev`, clean, with no untracked files, so any new file
#     under `docs/adr/` in `git status` is the agent's; an agent that
#     drafts without committing fails there.
#   - `dev` is the only branch, so any branch the agent begins shows up
#     in `git for-each-ref refs/heads/`.
#   - ADR 0001 answers a different question (when jobs run), so nothing
#     in the repository already settles retries and lets the agent skip
#     the confirmation.
#   - No remote, as in adr-0, so the two scenarios differ only in the
#     label.
#   - ADR frontmatter has `title` and `date` only, as in adr-0, so the
#     two fixtures are identical and only the task's label differs.
#   - README.md says ADRs live under `docs/adr/`, so an agent that
#     drafts writes there and the `docs/adr/` status criterion sees it.
#   - A fixed local identity (`Ledger Maintainers`), so an agent that
#     drafts can commit with no global git identity, and its commit
#     shows up in `git log --all fixture-base-dev..` rather than
#     failing silently.
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
