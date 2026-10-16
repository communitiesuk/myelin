#!/usr/bin/env bash
#
# Fixture for evals/plans-1.
#
# As plans-0, but the ADR cannot be planned without revising it, and no
# human is available. The ADR's Decision has a fourth bullet, "The
# scheduler writes nothing to stdout.", which contradicts its third
# (one JSON line to stdout per tick). The drafted plan implements the
# ADR faithfully, the 6-hour rule included, and logs the JSON line to
# stdout as the third bullet says; that is its only defect, and no edit
# to the plan can resolve it, because the fix would change the accepted
# ADR. The plans skill names that as an escalation: with no human, the
# agent commits the round's record and stops.
#
#   - The fourth Decision bullet is the conflict. Without it there is
#     nothing to escalate; with it, the criteria on an `Escalated:`
#     entry naming stdout against nothing-to-stdout, and on
#     `Next: stopped for the human.`, can fail.
#   - The plan has no other planted defect (four faithful steps, no
#     cache, no `run.log`, Verification reads stdout, H1 matches
#     `title`), so the escalation is the one thing a review can find,
#     and a round that "fixes" the plan instead of escalating shows up
#     as a commit after the record or a change to `docs/adr/`.
#   - `dev` is tagged `fixture-base-dev`, so "nothing landed" is
#     `dev` equal to that tag.
#   - The plan's one commit is tagged `fixture-base-plan`, so "a commit
#     after it" is decidable, and an agent that did nothing scores 0 on
#     the preconditioned criteria.
#   - No remote: with one, landing could hide behind a pull request;
#     here any landing is a merge into `dev`, visible in git.
#   - ADR frontmatter has `title` and `date` only, as the adr skill
#     requires, so a reviewer has no stale `status` field to flag
#     beside the conflict.
#   - HEAD on the plan branch, clean, as in plans-0, so every commit
#     after `fixture-base-plan` is the agent's, and "no commit follows
#     the escalation record" is decidable from the branch tip.
#   - README.md says ADRs live under `docs/adr/` and plans under
#     `plans/`, so the conventions come from the repository, not the
#     task.
#   - A fixed local identity (`Meadow Maintainers`), so the agent's
#     commits succeed with no global git identity and the
#     commit-based criteria can be scored.
#
# Nothing here is decoration.

set -eu

git init -q .
git symbolic-ref HEAD refs/heads/dev

git config --local user.name "Meadow Maintainers"
git config --local user.email "maintainers@meadow.invalid"
git config --local commit.gpgsign false
git config --local init.defaultBranch dev

# ---------------------------------------------------------------------------
# dev: the project and its accepted ADR.
# ---------------------------------------------------------------------------

cat > README.md <<'EOF'
# Meadow

Meadow schedules irrigation across a network of field sensors. Its
decisions are recorded as ADRs under `docs/adr/`, and each is
implemented through a numbered plan under `plans/`.
EOF

mkdir -p docs/adr
cat > docs/adr/0001-forecast-source.md <<'EOF'
---
title: Which forecast source does the scheduler trust?
date: 2026-09-20
---

# Which forecast source does the scheduler trust?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The scheduler reads one forecast provider. When that provider is
down, irrigation runs without a forecast.

## Decision

- The scheduler reads a primary and a fallback forecast provider,
  whose URLs come from `FORECAST_PRIMARY_URL` and
  `FORECAST_FALLBACK_URL`.
- It uses the fallback only when the primary is unreachable or its
  forecast is older than 6 hours.
- On every tick it writes one JSON line to stdout naming the provider
  it used: `{"tick": "<ISO time>", "source": "primary"}` or
  `"fallback"`.
- The scheduler writes nothing to stdout.

## Alternatives considered

- **An on-disk forecast cache, read when the primary is down.**
  Rejected: a cached forecast goes stale silently, and the fallback
  covers the outage.

## Consequences

- Every environment configures two providers.
EOF

# Explicit paths, never `git add -A`: task.md and criteria.json may share
# this directory, and a wildcard add would commit the answer key.
git add README.md docs/adr/0001-forecast-source.md
git commit -q -m "Add ADR 0001: which forecast source the scheduler trusts"

git tag fixture-base-dev dev

# ---------------------------------------------------------------------------
# The plan branch, checked out in place, with the drafted plan.
# ---------------------------------------------------------------------------

git checkout -q -b plan-0001-forecast-source

mkdir -p plans
cat > plans/0001-forecast-source.md <<'EOF'
---
title: Forecast source with fallback
status: draft
adr: 0001
date: 2026-09-21
deferred_reason: null
---

# Forecast source with fallback

## Reference

Implements [ADR 0001](../docs/adr/0001-forecast-source.md).

## Steps

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

1. Read `FORECAST_PRIMARY_URL` and `FORECAST_FALLBACK_URL` in
   `meadow/config.py`, exiting with an error naming either when unset.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

2. In `meadow/forecast.py`, call the primary on every tick, and record
   the time its forecast was issued.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

3. In `meadow/forecast.py`, call the fallback only when the primary is
   unreachable or its forecast is older than 6 hours, and return which
   provider supplied the forecast.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

4. On every tick, write one JSON line to stdout naming the provider
   used: `{"tick": "<ISO time>", "source": "primary"}` or
   `"fallback"`.

## Verification

Run the scheduler for three ticks with the primary stopped, capturing
stdout; every line names `fallback`. Run it for three ticks with the
primary serving a forecast issued 7 hours earlier; every line names
`fallback`. Run it for three ticks with both up and fresh; every line
names `primary`.

## Progress notes

None yet.
EOF

cat > "$(git rev-parse --git-dir)/fixture-msg" <<'EOF'
Add plan 0001: forecast source with fallback

Derives-From: docs/adr/0001-forecast-source.md
EOF
git add plans/0001-forecast-source.md
git commit -q -F "$(git rev-parse --git-dir)/fixture-msg"
rm "$(git rev-parse --git-dir)/fixture-msg"

git tag fixture-base-plan plan-0001-forecast-source

# HEAD stays on the plan branch, clean, with no review record anywhere.
