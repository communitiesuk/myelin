#!/usr/bin/env bash
#
# Fixture for evals/plan-numbering-0.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs.
# This fixture reproduces the production failure that motivated the skill
# edit (the duplicate plans/0004 found 2026-09-23), not a tidier stand-in
# for it. At the moment the real agent chose its number, the plans/ tree was
# EMPTY and history had added plans 0001 through 0004, the highest (0004)
# having just been completed and removed. The correct next number was one
# greater than the highest ever added, i.e. 0005; the agent instead reused
# 0004 — it dropped a new plan into the number of the retired top plan whose
# slot now looked free. So:
#
#   - a body that counts the tree (`ls plans/`) sees nothing and picks 0001;
#   - a body that reuses the highest retired number lands on 0004 — the real
#     bug, a collision with a plan that already existed under that number;
#   - a body that matches the plan's number to the ADR it implements picks
#     0006 (the ADR here is 0006, deliberately distinct from the plan answer);
#   - a body that reads history and increments past the highest ever added
#     picks 0005.
#
# Only the last is correct. The discriminator is 0005-vs-0004: incrementing
# past the retired top versus reusing it. A dense, unbroken run of plans
# would NOT discriminate, because "+1 past an obvious maximum" is trivial;
# the sparse, retired-top state is the one that actually broke. Every element
# below exists so the numbering criterion can fail; nothing is decoration.

set -eu

git init -q .
git symbolic-ref HEAD refs/heads/dev

git config --local user.name "Meadow Maintainers"
git config --local user.email "maintainers@meadow.invalid"
git config --local commit.gpgsign false
git config --local init.defaultBranch dev

# ---------------------------------------------------------------------------
# Commit 1: an established project with a run of accepted ADRs. The ADR the
# agent must plan for, 0006, is deliberately NOT the next plan number, so a
# body that copies the ADR number lands on 0006 and is wrong for a reason
# distinct from reusing the retired top plan or counting the empty tree.
# ---------------------------------------------------------------------------

cat > README.md <<'EOF'
# Meadow

Meadow schedules irrigation across a network of field sensors. It has a
long tail of operational decisions, recorded as ADRs, and each is
implemented through a numbered plan.
EOF

mkdir -p docs/adr

cat > docs/adr/0001-sensor-polling-interval.md <<'EOF'
---
title: How often are field sensors polled?
status: accepted
date: 2026-01-14
---

# How often are field sensors polled?

## Decision

Sensors are polled every fifteen minutes, with a faster five-minute
cadence during an active irrigation cycle.
EOF

cat > docs/adr/0002-scheduling-backend.md <<'EOF'
---
title: What drives the irrigation schedule?
status: accepted
date: 2026-03-02
---

# What drives the irrigation schedule?

## Decision

A single scheduler process reads sensor state and the forecast on a
fixed tick and writes an explicit plan of valve operations.
EOF

cat > docs/adr/0003-valve-failure-handling.md <<'EOF'
---
title: What happens when a valve fails to actuate?
status: accepted
date: 2026-05-19
---

# What happens when a valve fails to actuate?

## Decision

A valve that does not confirm actuation within thirty seconds is marked
failed, its bed is flagged, and the next cycle routes around it.
EOF

cat > docs/adr/0004-sensor-battery-telemetry.md <<'EOF'
---
title: How is sensor battery health reported?
status: accepted
date: 2026-06-30
---

# How is sensor battery health reported?

## Decision

Each sensor reports battery voltage with every reading, and a nightly
job flags any sensor projected to fall below the safe threshold before
the next maintenance window.
EOF

cat > docs/adr/0005-irrigation-audit-log.md <<'EOF'
---
title: How are irrigation decisions audited?
status: accepted
date: 2026-08-11
---

# How are irrigation decisions audited?

## Decision

Every tick appends one row recording the sensor state, the forecast
read, and the valve operations issued, to an append-only audit log.
EOF

# The ADR the agent is asked to plan for. Accepted, so the agent goes
# straight to the plans skill without needing to author an ADR first. Its
# number, 0006, is higher than the correct plan number (0005) on purpose.
cat > docs/adr/0006-forecast-source.md <<'EOF'
---
title: Which forecast source does the scheduler trust?
status: accepted
date: 2026-09-20
---

# Which forecast source does the scheduler trust?

## Decision

The scheduler reads a primary provider and a fallback, both configured
by environment variable, and uses the fallback only when the primary is
unreachable or stale. The choice made for each tick is logged.
EOF

git add README.md docs/adr
git commit -q -m "Import the meadow scheduler and its accepted decisions"

# ---------------------------------------------------------------------------
# Commits 2-5: the four plans that implemented ADRs 0001-0004 over the
# project's life, each added in its own commit so history records four
# distinct plan numbers as added. The highest is 0004.
# ---------------------------------------------------------------------------

mkdir -p plans
for n in 0001 0002 0003 0004; do
  cat > "plans/${n}-retired-plan.md" <<EOF
---
title: Retired plan ${n}
status: in-progress
adr: ${n}
date: 2026-02-01
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
  git add "plans/${n}-retired-plan.md"
  git commit -q -m "Add plan ${n}"
done

# ---------------------------------------------------------------------------
# Commits 6-9: the plans leave the tree as they are completed, one by one, so
# the LAST plan-related commit in history is the removal of plan 0004 — the
# most recent and most salient plan number an agent glancing at history will
# see. After this plans/ is empty but history still holds 0001-0004 as added
# paths, 0004 being the highest.
# ---------------------------------------------------------------------------

for n in 0001 0002 0003 0004; do
  git rm -q "plans/${n}-retired-plan.md"
  git commit -q -m "Complete plan ${n} and remove it"
done

# Keep the directory present but empty so a tree-counting body genuinely
# sees nothing rather than erroring on a missing directory.
mkdir -p plans
touch plans/.gitkeep
git add plans/.gitkeep
git commit -q -m "Keep plans/ present while empty"

# Anchor for the scorer: everything after this tag is the agent's work.
git tag fixture-base dev

# No remote and no worktree churn: this scenario scores only the number the
# agent gives the plan it writes, so the fixture keeps the rest quiet.
