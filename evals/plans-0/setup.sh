#!/usr/bin/env bash
#
# Fixture for evals/plans-0.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs:
# an accepted ADR on `dev`, and a drafted but unreviewed plan for it on
# its own branch, checked out in place. The task asks only that the plan
# be taken through to landing; the plans skill must supply the review
# loop. The plan carries four planted defects, each a finding a reviewer
# should raise:
#
#   - D1 (High): step 3 builds the on-disk forecast cache the ADR's
#     Alternatives section rejects. Lets the "D1 appears as a finding"
#     and "the merged plan has no on-disk cache" criteria fail.
#   - D2 (High): step 4 logs to `run.log` instead of stdout, step 5
#     deletes `run.log` on shutdown, and Verification reads `run.log`
#     after the run, so the evidence is destroyed before it is read.
#     Lets the "logs to stdout" and "no step deletes what Verification
#     reads" criteria fail.
#   - D3 (High): nothing implements the ADR's 6-hour staleness rule.
#     Lets the "implements the 6-hour rule" criterion fail.
#   - D4 (Low): the H1 does not match the `title`. Lets the criterion
#     on acting on a Medium or Low (a later draft or the closing pass)
#     fail.
#
# The other elements:
#
#   - The plan is one commit on its branch, carrying `Derives-From` and
#     tagged `fixture-base-plan`. It is an unreviewed draft already on
#     the branch, so the loop starts at its review and round 1's record
#     gives the drafter as `not a subagent`; lets the models criterion
#     fail. The tag lets every "commit after fixture-base-plan"
#     criterion be scored.
#   - `dev` is tagged `fixture-base-dev`, so the two-parent merge of the
#     plan branch and an unchanged `docs/adr/` can be scored against it.
#   - No remote: under git-workflow a plan with no remote lands by a
#     local merge into `dev`, so the merge criterion is decidable from
#     git alone.
#   - ADR frontmatter has `title` and `date` only, as the adr skill now
#     requires, so a reviewer has no stale `status` field to flag.
#   - The code-writing steps carry the plans skill's wrapper, so a
#     missing wrapper is not a finding that crowds out D1 to D4.
#   - HEAD on the plan branch, clean: the skill takes an unreviewed
#     draft already on its branch as round 1's draft, so an agent that
#     begins a second branch or redrafts before reviewing shows up in
#     git, and every commit after `fixture-base-plan` is the agent's.
#   - README.md says ADRs live under `docs/adr/` and plans under
#     `plans/`, so the conventions come from the repository, not the
#     task, and a misplaced artefact is the agent's failure.
#   - A fixed local identity (`Meadow Maintainers`), so the agent's
#     commits succeed with no global git identity and every
#     commit-based criterion can be scored.
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

# Forecast source with a fallback

## Reference

Implements [ADR 0001](../docs/adr/0001-forecast-source.md).

## Steps

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

1. Read `FORECAST_PRIMARY_URL` and `FORECAST_FALLBACK_URL` in
   `meadow/config.py`, exiting with an error naming either when unset.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

2. In `meadow/forecast.py`, call the primary, and the fallback when
   the request fails.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

3. Write each fetched forecast to `cache/forecast.json` and read it
   when both providers fail.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

4. On every tick, append the JSON line to `run.log`.

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

5. On shutdown, the scheduler deletes `run.log`.

## Verification

Run the scheduler for three ticks with the primary stopped, then read
`run.log`; every line names `fallback`.

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
