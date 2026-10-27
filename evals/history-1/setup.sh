#!/usr/bin/env bash
#
# Fixture for evals/history-1 — the history skill's downstream/graph query.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs:
# a service, `relay`, whose artefact graph has a two-hop closure
# (ADR -> plan -> code) off the queried ADR, plus the two decoys ADR 0010
# rejects for the downstream query.
#
# The fixture is built here with `git init` and scripted commits rather
# than described in task.md, mirroring evals/adr-0 and evals/git-workflow-0:
# the downstream query resolves edges from `Derives-From` trailer fields
# and node identity from each commit's changed files, so only a real
# commit graph exercises it.
#
# The query is: history downstream docs/adr/0001-event-bus.md
# The transitive closure the skill must report is exactly:
#   plans/0001-event-bus.md   (hop 1: derives from the ADR)
#   src/event_bus.py          (hop 2: derives from the plan)
# and it must NOT list the queried ADR itself as a downstream node.
#
# DECOY 1 (subject-only) — a commit naming docs/adr/0001-event-bus.md in
# its SUBJECT LINE but carrying no `Derives-From` trailer. A subject-grep
# implementation (the alternative ADR 0010 rejects) would wrongly pull its
# changed file (README.md) into the closure. The trailer-filtering query
# must exclude it.
#
# DECOY 2 (number-sharing) — plans/0001-releases.md and src/releases.py,
# a second artefact pair whose plan shares the number 0001 with the real
# plans/0001-event-bus.md but not its path, and which derives from a
# different ADR. A number-keying implementation (the other alternative
# ADR 0010 rejects) would conflate the two 0001 plans and pull
# src/releases.py into the closure. Path-keying must exclude both.

set -eu

git init -q .
git symbolic-ref HEAD refs/heads/dev

git config --local user.name "Relay Maintainers"
git config --local user.email "maintainers@relay.invalid"
git config --local commit.gpgsign false
git config --local init.defaultBranch dev

cat > README.md <<'EOF'
# Relay

Relay routes events between services. Its decisions are recorded as
ADRs under `docs/adr/`, planned under `plans/`, and implemented under
`src/`.
EOF

mkdir -p docs/adr plans src

# ---------------------------------------------------------------------------
# Commit 1: README and the queried ADR. Not a derivation commit.
# ---------------------------------------------------------------------------
cat > docs/adr/0001-event-bus.md <<'EOF'
---
title: How do services exchange events?
date: 2026-05-02
---

# How do services exchange events?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Services polled each other for changes, which was slow and chatty.

## Decision

Introduce an in-process event bus: publishers post events, subscribers
register handlers, delivery is synchronous and in order.

## Consequences

A subscriber's handler runs on the publisher's thread.
EOF

git add README.md docs/adr/0001-event-bus.md
git commit -q -m "Add ADR 0001: an in-process event bus"

# ---------------------------------------------------------------------------
# Commit 2 (hop 1): the plan derives from the ADR. Changed file is the
# plan, which is the node the next hop recurses from.
# ---------------------------------------------------------------------------
cat > plans/0001-event-bus.md <<'EOF'
---
title: Build the event bus
status: draft
adr: 0001
date: 2026-05-10
deferred_reason: null
---

# Build the event bus

## Reference

Implements `docs/adr/0001-event-bus.md`.

## Steps

### Step 1 — the bus

Build the publish/subscribe bus with synchronous, in-order delivery.
EOF

git add plans/0001-event-bus.md
git commit -q --cleanup=whitespace -F - <<'EOF'
Add plan 0001: build the event bus

Derives-From: docs/adr/0001-event-bus.md
EOF

# ---------------------------------------------------------------------------
# Commit 3 (hop 2): the code derives from the plan. Changed file is the
# code, the second and last node of the closure.
# ---------------------------------------------------------------------------
cat > src/event_bus.py <<'EOF'
"""An in-process publish/subscribe event bus with synchronous delivery."""


class EventBus:
    def __init__(self):
        self._handlers = {}

    def subscribe(self, topic, handler):
        self._handlers.setdefault(topic, []).append(handler)

    def publish(self, topic, event):
        for handler in self._handlers.get(topic, []):
            handler(event)
EOF

git add src/event_bus.py
git commit -q --cleanup=whitespace -F - <<'EOF'
Build the event bus

Derives-From: plans/0001-event-bus.md
EOF

# ---------------------------------------------------------------------------
# Commit 4 (DECOY 2 upstream): an unrelated ADR, so the number-sharing
# decoy plan has a real upstream that is NOT the queried ADR.
# ---------------------------------------------------------------------------
cat > docs/adr/0002-releases.md <<'EOF'
---
title: How are releases cut?
date: 2026-05-20
---

# How are releases cut?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Releases were cut by hand and the steps drifted.

## Decision

Cut releases from a tagged commit with a scripted checklist.

## Consequences

A release is reproducible from its tag.
EOF

git add docs/adr/0002-releases.md
git commit -q -m "Add ADR 0002: how releases are cut"

# ---------------------------------------------------------------------------
# Commit 5 (DECOY 2): a plan sharing the number 0001 with the real plan
# but NOT its path, deriving from the unrelated ADR 0002.
# ---------------------------------------------------------------------------
cat > plans/0001-releases.md <<'EOF'
---
title: Build the release checklist
status: draft
adr: 0002
date: 2026-05-25
deferred_reason: null
---

# Build the release checklist

## Reference

Implements `docs/adr/0002-releases.md`.

## Steps

### Step 1 — the checklist

Script the release checklist against a tagged commit.
EOF

git add plans/0001-releases.md
git commit -q --cleanup=whitespace -F - <<'EOF'
Add plan 0001: build the release checklist

Derives-From: docs/adr/0002-releases.md
EOF

# ---------------------------------------------------------------------------
# Commit 6 (DECOY 2): code deriving from the number-sharing decoy plan.
# A number-keyer conflating the two 0001 plans would pull this in.
# ---------------------------------------------------------------------------
cat > src/releases.py <<'EOF'
"""The scripted release checklist."""


def cut_release(tag):
    return f"cutting release from {tag}"
EOF

git add src/releases.py
git commit -q --cleanup=whitespace -F - <<'EOF'
Build the release checklist

Derives-From: plans/0001-releases.md
EOF

# ---------------------------------------------------------------------------
# Commit 7 (DECOY 1): names the queried ADR's path in its SUBJECT but
# carries no trailer. A subject-grep would pull README.md into the
# closure; the trailer-filtering query must not.
# ---------------------------------------------------------------------------
cat >> README.md <<'EOF'

See docs/adr/0001-event-bus.md for the event-bus design.
EOF

git add README.md
git commit -q -m "Document docs/adr/0001-event-bus.md in the README"

git tag fixture-base-dev dev

# HEAD stays on dev, clean.
