#!/usr/bin/env bash
#
# Fixture for evals/adr-0.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs:
# a job runner with one accepted ADR, on `dev`, clean, and no remote. The
# task asks for a new ADR and gives its decision as a list with no
# label; the adr skill must run the summariser on the task text, carry
# its summary into the introducing commit, run the review loop, and stop
# short of merging, because a decision is accepted by a human's merge.
#
#   - ADR 0001 (jobs run from a cron table in `jobs.cron`) is the only
#     ADR, so the new one is numbered 0002 and the `adr-0002-*` branch
#     criterion is decidable. It answers a different question (when jobs
#     run, not how failures are retried), so a correct agent writes a new
#     ADR rather than revising it, and a revision shows up as a change to
#     0001.
#   - `dev` is tagged `fixture-base-dev`, so "dev unchanged" and "the
#     first commit after the fork point" are decidable. An agent that
#     merges its ADR into `dev` fails the first criterion.
#   - No remote: the branch cannot be proposed as a pull request, so
#     git-workflow keeps it and stops; the "branch still exists and
#     `git remote` prints nothing" criterion fails if the agent deletes
#     the branch or invents a remote.
#   - HEAD on `dev`, clean, so every commit, branch and file the scorer
#     finds is the agent's.
#   - ADR frontmatter has `title` and `date` only, as the adr skill
#     requires, so the house style the agent copies is the current one.
#   - README.md says ADRs live under `docs/adr/`, so the location comes
#     from the repository, not the task, and the `docs/adr/0002-*.md`
#     criterion fails only if the agent misplaces the ADR.
#   - A fixed local identity (`Ledger Maintainers`), so the agent's
#     commits succeed with no global git identity and the commit-based
#     criteria (the summary markers, the records, the closing pass) can
#     be scored.
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
