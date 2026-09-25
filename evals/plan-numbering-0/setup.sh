#!/usr/bin/env bash
#
# Fixture for evals/plan-numbering-0.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs.
# The point of this fixture is a single discriminator: the plans/ directory
# is EMPTY in the working tree, but the project's history holds six plans
# that were completed and removed under ADR 0004 (completed artefacts leave
# the tree). So:
#
#   - a body that takes the next number by counting the tree
#     (`ls plans/ | sort | tail -1`) sees nothing and picks 0001;
#   - a body that matches the plan's number to the ADR it implements picks
#     the ADR's number (0004 here);
#   - a body that reads history picks 0007, one past the highest plan ever
#     added.
#
# Only the last is correct. Every element below exists so that the numbering
# criterion can actually fail; nothing here is decoration.

set -eu

git init -q .
git symbolic-ref HEAD refs/heads/dev

git config --local user.name "Meadow Maintainers"
git config --local user.email "maintainers@meadow.invalid"
git config --local commit.gpgsign false
git config --local init.defaultBranch dev

# ---------------------------------------------------------------------------
# Commit 1: an established project with a run of accepted ADRs. The ADR the
# agent must plan for, 0004, is deliberately NOT the next plan number, so a
# body that matches the plan number to the ADR number lands on 0004 and is
# wrong for a reason distinct from counting the tree.
# ---------------------------------------------------------------------------

cat > README.md <<'EOF'
# Meadow

Meadow schedules irrigation across a network of field sensors. It has a
long tail of operational decisions, recorded as ADRs, and each is
implemented through a numbered plan.

Completed plans are removed from `plans/` once their work has landed;
git history is the record of what was done.
EOF

mkdir -p docs/adr

cat > docs/adr/0001-sensor-polling-interval.md <<'EOF'
---
title: How often are field sensors polled?
status: accepted
date: 2026-01-14
---

# How often are field sensors polled?

## Context

Sensors report soil moisture, and polling too often drains their
batteries while polling too rarely misses fast-drying beds.

## Decision

Sensors are polled every fifteen minutes, with a faster five-minute
cadence during an active irrigation cycle.

## Consequences

Battery life is modelled at just over a season, which matches the
maintenance window.
EOF

cat > docs/adr/0002-scheduling-backend.md <<'EOF'
---
title: What drives the irrigation schedule?
status: accepted
date: 2026-03-02
---

# What drives the irrigation schedule?

## Context

The schedule must react to sensor readings and to a weather forecast,
and it must be auditable after the fact.

## Decision

A single scheduler process reads sensor state and the forecast on a
fixed tick and writes an explicit plan of valve operations.

## Consequences

Every irrigation decision is a row that can be replayed.
EOF

cat > docs/adr/0003-valve-failure-handling.md <<'EOF'
---
title: What happens when a valve fails to actuate?
status: accepted
date: 2026-05-19
---

# What happens when a valve fails to actuate?

## Context

Valves occasionally fail to open, and a silent failure dries out a bed.

## Decision

A valve that does not confirm actuation within thirty seconds is marked
failed, its bed is flagged, and the next cycle routes around it.

## Consequences

A failed valve degrades coverage rather than causing a silent loss.
EOF

# The ADR the agent is asked to plan for. Accepted, so the agent goes
# straight to the plans skill without needing to author an ADR first.
cat > docs/adr/0004-forecast-source.md <<'EOF'
---
title: Which forecast source does the scheduler trust?
status: accepted
date: 2026-09-20
---

# Which forecast source does the scheduler trust?

## Context

Two forecast providers disagree by enough, on the day-ahead rain
probability, to change whether a cycle runs. The scheduler currently
hard-codes one of them.

## Decision

The scheduler reads a primary provider and a fallback, both configured
by environment variable, and uses the fallback only when the primary is
unreachable or stale. The choice made for each tick is logged.

## Consequences

A provider outage no longer stops scheduling, and after-the-fact audits
can see which forecast drove each decision.
EOF

git add README.md docs/adr
git commit -q -m "Import the meadow scheduler and its accepted decisions"

# ---------------------------------------------------------------------------
# Commit 2: the six plans that implemented ADRs 0001-0003 over the project's
# life. They are added here, in the tree, and REMOVED in commit 3 below, so
# that history records them as added (which is what a history-based next
# number reads) while the working tree the agent meets is empty.
# ---------------------------------------------------------------------------

mkdir -p plans
for n in 0001 0002 0003 0004 0005 0006; do
  cat > "plans/${n}-retired-plan.md" <<EOF
---
title: Retired plan ${n}
status: in-progress
adr: 0001
date: 2026-02-01
deferred_reason: null
---

# Retired plan ${n}

## Reference

One of the plans that carried the meadow scheduler to where it is. Its
work has landed; this file is here only so the fixture can remove it.

## Steps

1. Done.

## Verification

Landed.
EOF
done

git add plans
git commit -q -m "Record the plans that implemented ADRs 0001-0003"

# ---------------------------------------------------------------------------
# Commit 3: the plans leave the tree, as completed plans do under ADR 0004.
# After this commit plans/ is empty but history still holds plans/0001 to
# plans/0006 as added paths.
# ---------------------------------------------------------------------------

git rm -q plans/*.md
# Keep the directory present but empty so a tree-counting body genuinely
# sees nothing rather than erroring on a missing directory.
mkdir -p plans
touch plans/.gitkeep
git add plans/.gitkeep
git commit -q -m "Remove the completed plans; plans/ is empty, history is the record"

# Anchor for the scorer: everything after this tag is the agent's work.
git tag fixture-base dev

# No remote and no worktree churn: this scenario scores only the number the
# agent gives the plan it writes, so the fixture keeps the rest quiet.
