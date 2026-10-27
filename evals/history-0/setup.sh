#!/usr/bin/env bash
#
# Fixture for evals/history-0 — the history skill's closed-paths query.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs:
# a notification service, `beacon`, whose rate-limiting decisions have
# real history — never-adopted alternatives, an adopted-then-reversed
# decision carried only in a `Revises` commit body, a reversal recorded
# in BOTH an Alternatives bullet and a `Revises` body (the dedupe case),
# a non-revising `Clarifies` edit that must not surface, and an
# off-topic decoy ADR.
#
# The fixture is built here with `git init` and scripted commits rather
# than described in task.md, mirroring evals/adr-0 and evals/git-workflow-0:
# the history skill reads git trailers and commit bodies, so only a real
# commit graph exercises it. Nothing below is decoration — every element
# exists so some criterion in criteria.json can fail.
#
# The query topic is "rate limiting". The three on-topic closed paths the
# skill must report:
#   1. ADR 0001's never-adopted fixed-window counter  (source: alternatives)
#   2. ADR 0002's in-process counter, adopted then reversed to Redis,
#      recorded ONLY in the Revises commit body               (source: revises)
#   3. ADR 0003's silently-dropping over-limit requests, reversed to 429,
#      recorded in BOTH its Alternatives bullet and a Revises body
#      — reported exactly once, preferring the in-tree bullet (source: alternatives)
# ADR 0004's Clarifies edit (a non-revising header-format fix) must NOT
# surface as a closed path. ADR 0005 (configuration loading) is off topic
# and must NOT surface.

set -eu

git init -q .
git symbolic-ref HEAD refs/heads/dev

git config --local user.name "Beacon Maintainers"
git config --local user.email "maintainers@beacon.invalid"
git config --local commit.gpgsign false
git config --local init.defaultBranch dev

cat > README.md <<'EOF'
# Beacon

Beacon delivers notifications to the field fleet. Its architecture
decisions are recorded as ADRs under `docs/adr/`.
EOF

mkdir -p docs/adr

# ---------------------------------------------------------------------------
# Commit 1: README and ADR 0001 — the token bucket, with a never-adopted
# fixed-window alternative in its Alternatives section. This is closed
# path #1, and its only source is the in-tree Alternatives bullet.
# ---------------------------------------------------------------------------
cat > docs/adr/0001-request-rate-limiting.md <<'EOF'
---
title: How is the request rate limited?
date: 2026-05-02
---

# How is the request rate limited?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

A single client could flood the delivery queue. We need a rate limit
on inbound requests.

## Decision

Limit each client with a token-bucket: a steady refill rate and a
burst ceiling, so a client may burst up to the ceiling and then is
held to the refill rate.

## Alternatives considered

- **A fixed-window counter.** Rejected: it lets a client send a full
  quota in the last second of one window and a second full quota in
  the first second of the next, so the effective rate doubles at every
  window boundary.

## Consequences

The burst ceiling is a tunable the operators choose per client.
EOF

git add README.md docs/adr/0001-request-rate-limiting.md
git commit -q -m "Add ADR 0001: token-bucket request rate limiting"

# ---------------------------------------------------------------------------
# Commit 2: ADR 0002 — where the rate-limit counter is stored. It first
# decides an in-process counter. Its Alternatives section rejects
# something unrelated to the later reversal (a per-request database
# write), so when the decision is later reversed the Alternatives section
# does NOT restate the reversal.
# ---------------------------------------------------------------------------
cat > docs/adr/0002-rate-limit-counter-store.md <<'EOF'
---
title: Where is the rate-limit counter stored?
date: 2026-05-20
---

# Where is the rate-limit counter stored?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The token-bucket limiter of ADR 0001 needs somewhere to keep each
client's remaining tokens.

## Decision

Keep the counter in process memory, in a map keyed by client id.

## Alternatives considered

- **A row per request in the primary database.** Rejected: a write on
  the hot path for every inbound request, for a value read far more
  often than it changes.

## Consequences

The counter is lost on restart; a restart briefly resets every
client's budget.
EOF

git add docs/adr/0002-rate-limit-counter-store.md
git commit -q -m "Add ADR 0002: store the rate-limit counter in process"

# ---------------------------------------------------------------------------
# Commit 3: REVISE ADR 0002 to Redis. The commit carries
# `Revises: docs/adr/0002-...` and its body gives the reason for the
# adopted-then-reversed decision. The revision drops ADR 0002's
# Alternatives section (the initial per-request-database-write rejection),
# so the revised ADR restates nothing and the Revises body is the ONLY
# source for closed path #2. ADR 0002's title still names rate limiting,
# so the prune keeps it and its Revises body is extracted.
# ---------------------------------------------------------------------------
cat > docs/adr/0002-rate-limit-counter-store.md <<'EOF'
---
title: Where is the rate-limit counter stored?
date: 2026-05-20
---

# Where is the rate-limit counter stored?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

The token-bucket limiter of ADR 0001 needs somewhere to keep each
client's remaining tokens.

## Decision

Keep the counter in Redis, keyed by client id, so every delivery node
reads and writes the same budget.

## Consequences

Redis is now on the request path; its availability bounds the
limiter's.
EOF

git add docs/adr/0002-rate-limit-counter-store.md
git commit -q --cleanup=whitespace -F - <<'EOF'
Revise ADR 0002: move the rate-limit counter to Redis

The in-process counter was adopted and then reversed. It was per node,
so a client spreading its requests across delivery nodes got the full
budget on each one and the effective limit scaled with the node count.
The counter now lives in Redis, shared across nodes.

Revises: docs/adr/0002-rate-limit-counter-store.md
EOF

# ---------------------------------------------------------------------------
# Commit 4: ADR 0003 — what happens over the limit. First decides to drop
# silently. Its Alternatives section rejects something else at this point.
# ---------------------------------------------------------------------------
cat > docs/adr/0003-over-limit-behaviour.md <<'EOF'
---
title: What happens when a client exceeds its rate limit?
date: 2026-06-04
---

# What happens when a client exceeds its rate limit?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Once a client is over its token-bucket budget, the limiter has to do
something with the request.

## Decision

Drop the over-limit request silently and record a metric.

## Alternatives considered

- **Blocking the caller until a token frees up.** Rejected: it ties up
  a server connection for an impatient client and invites timeouts.

## Consequences

A dropped request leaves no trace for the client, only a metric for us.
EOF

git add docs/adr/0003-over-limit-behaviour.md
git commit -q -m "Add ADR 0003: drop over-limit requests silently"

# ---------------------------------------------------------------------------
# Commit 5: REVISE ADR 0003 to return 429, AND restate the reversal in its
# Alternatives section. So closed path #3 has BOTH sources — the in-tree
# Alternatives bullet and the Revises commit body — describing the same
# reversed decision. The skill's model step must collapse them to one,
# preferring the in-tree bullet (source: alternatives).
# ---------------------------------------------------------------------------
cat > docs/adr/0003-over-limit-behaviour.md <<'EOF'
---
title: What happens when a client exceeds its rate limit?
date: 2026-06-04
---

# What happens when a client exceeds its rate limit?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Once a client is over its token-bucket budget, the limiter has to do
something with the request.

## Decision

Return HTTP 429 with a `Retry-After` header naming when the next token
frees up.

## Alternatives considered

- **Silently dropping the over-limit request.** Tried first, then
  reversed: with no signal, well-behaved clients retried blindly and
  the retries made the overload worse. A 429 with `Retry-After` tells
  the client to back off instead.

## Consequences

Clients must handle 429 and honour `Retry-After`.
EOF

git add docs/adr/0003-over-limit-behaviour.md
git commit -q --cleanup=whitespace -F - <<'EOF'
Revise ADR 0003: return 429 instead of dropping over-limit requests

Silently dropping the over-limit request was adopted first and then
reversed. Clients given no signal retried immediately and blindly, and
the retries deepened the very overload the limiter existed to shed. The
limiter now returns HTTP 429 with a Retry-After header so a client
backs off.

Revises: docs/adr/0003-over-limit-behaviour.md
EOF

# ---------------------------------------------------------------------------
# Commit 6: ADR 0004 — the rate-limit response headers. On topic (its
# title matches "rate limit"), but it has NO Alternatives section, so it
# contributes no closed path of its own.
# ---------------------------------------------------------------------------
cat > docs/adr/0004-rate-limit-headers.md <<'EOF'
---
title: How are the rate-limit headers formatted?
date: 2026-06-18
---

# How are the rate-limit headers formatted?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Clients need to see their remaining budget without guessing.

## Decision

Send `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` on
every response, following the draft IETF header names.

## Consequences

A client can read its budget from any response.
EOF

git add docs/adr/0004-rate-limit-headers.md
git commit -q -m "Add ADR 0004: rate-limit response headers"

# ---------------------------------------------------------------------------
# Commit 7: a CLARIFIES edit to ADR 0004 — a non-revising fix to a
# cross-reference. It changes NO decision and carries `Clarifies`, not
# `Revises`. The history skill reads the `Revises` trailer only and must
# NOT surface this edit as a closed path. A naive implementation that
# treated every self-edit as a revision would wrongly surface it.
# ---------------------------------------------------------------------------
cat > docs/adr/0004-rate-limit-headers.md <<'EOF'
---
title: How are the rate-limit headers formatted?
date: 2026-06-18
---

# How are the rate-limit headers formatted?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Clients need to see their remaining budget without guessing. The
budget itself is the token bucket of ADR 0001.

## Decision

Send `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` on
every response, following the draft IETF header names.

## Consequences

A client can read its budget from any response.
EOF

git add docs/adr/0004-rate-limit-headers.md
git commit -q --cleanup=whitespace -F - <<'EOF'
Clarify ADR 0004: cite ADR 0001 for the budget

Add the missing cross-reference to ADR 0001 in the Context. No decision
changes; the header set and their names are untouched.

Clarifies: docs/adr/0004-rate-limit-headers.md
EOF

# ---------------------------------------------------------------------------
# Commit 8: ADR 0005 — configuration loading. The off-topic decoy: its
# title and its Alternatives bullet have nothing to do with rate limiting,
# so the recall-biased prune must drop it and it must NOT surface.
# ---------------------------------------------------------------------------
cat > docs/adr/0005-configuration-loading.md <<'EOF'
---
title: How is configuration loaded?
date: 2026-07-01
---

# How is configuration loaded?

> **Directive for the implementer**: when implementing this ADR, invoke the `plans` skill to produce the corresponding plan artifact. Do not begin implementation without a plan.

## Context

Configuration was read from the environment at the point of use, so
behaviour depended on when a code path first ran.

## Decision

Parse configuration into a frozen object once at start-up.

## Alternatives considered

- **Reading environment variables at the point of use.** Rejected:
  behaviour then depends on first-use timing and is hard to test.

## Consequences

A configuration change requires a restart.
EOF

git add docs/adr/0005-configuration-loading.md
git commit -q -m "Add ADR 0005: load configuration once at start-up"

git tag fixture-base-dev dev

# HEAD stays on dev, clean.
