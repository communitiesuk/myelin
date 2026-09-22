#!/usr/bin/env bash
#
# Fixture for evals/git-workflow-0.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs.
# The fixture is built here rather than described in task.md on purpose:
# for a skill that governs git, telling the agent to initialise its own
# repository would let the skill under test set up its own exam.
#
# Every element below exists so that some criterion in criteria.json can
# fail. Nothing here is decoration. See the comments against each block.

set -eu

# ---------------------------------------------------------------------------
# Repository, identity, and the two decoy configuration values.
# ---------------------------------------------------------------------------

git init -q .
git symbolic-ref HEAD refs/heads/main

git config --local user.name "Orchard Maintainers"
git config --local user.email "maintainers@orchard.invalid"
git config --local commit.gpgsign false

# DECOY 1 (configuration). ADR 0003 requires the fork point to be derived
# and never read from per-repository configuration. Both keys below name
# `main`; the derivation must nevertheless land on the local `dev` branch.
git config --local init.defaultBranch main
git config --local workflow.trunk main

# ---------------------------------------------------------------------------
# Commit 1 on main: the shared base.
# ---------------------------------------------------------------------------

cat > README.md <<'EOF'
# Orchard

Orchard ingests telemetry events from the field fleet and writes them to
the warehouse. It is a small service with a long tail of operational
decisions, which is why the `docs/adr/` directory exists.

Run the ingester with `python -m orchard.ingest`.
EOF

# `.venv/` is deliberately NOT ignored here: the entry reads `venv/`, the
# common misspelling. So a body that copies built dependencies into a
# worktree and then stages everything will commit them, and the criterion
# on built dependencies can actually fail. `.worktrees/` is deliberately
# absent: the workflow has to add it, which is the bookkeeping criterion.
cat > .gitignore <<'EOF'
node_modules/
venv/
.claude/
*.log
EOF

# DECOY 2 (prose). A plausible, confidently-worded contributing guide that
# is wrong about the trunk, wrong about squashing, and wrong about pull
# requests for this repository (it has no remote). Without it, "the fork
# point was derived", "the merge was not squashed" and "the local-merge
# fallback was taken" are only failable by an incompetent body, not by a
# plausible one.
cat > CONTRIBUTING.md <<'EOF'
# Contributing to Orchard

## Branching

All branches are cut from `main`. The trunk for this repository is
recorded in git configuration under `workflow.trunk`; read it rather
than guessing.

Do not branch from `dev`. `dev` is a slow integration branch kept for
reference and is not where work starts.

Branch names are `feature/<your-initials>-<short-description>`.

## Landing your change

Open a pull request on GitHub and squash-merge it once it is green. We
keep `main` to one commit per change so that `git log --oneline` reads
as a changelog.
EOF

mkdir -p docs/adr
cat > docs/adr/0001-http-client-timeouts.md <<'EOF'
---
title: Bound every outbound HTTP call with an explicit timeout
status: accepted
date: 2026-04-02
---

# Bound every outbound HTTP call with an explicit timeout

## Context

Three incidents in the first quarter traced back to an outbound call
with no timeout, holding a worker until the pod was restarted.

## Decision

Every outbound HTTP call passes an explicit connect and read timeout.
There is no default; a call without one fails review.

## Consequences

Callers must choose a number, which forces a conversation about what
latency is acceptable for each dependency.
EOF

cat > docs/adr/0002-configuration-loading.md <<'EOF'
---
title: Configuration is read once at start-up
status: accepted
date: 2026-06-11
---

# Configuration is read once at start-up

## Context

Reading environment variables at the point of use made behaviour depend
on when a code path first ran.

## Decision

Configuration is parsed into a frozen object at start-up. Nothing reads
the environment after that point.

## Consequences

A configuration change requires a restart. This is acceptable; it is
also honest about what was already true.
EOF

# Stage explicit paths, never `git add -A`. The harness documents only
# that setup.sh is "auto-run if present" and does not say what else shares
# the directory it runs in. If task.md or criteria.json were colocated, a
# wildcard add would commit the answer key into the agent's own repository
# and every criterion below would become an instruction-following test.
git add README.md .gitignore CONTRIBUTING.md docs
git commit -q -m "Initial import of the orchard service"

# ---------------------------------------------------------------------------
# Commit 2 on main: a change dev does not have.
#
# This makes main and dev genuinely divergent, so that forking from main
# produces a different tree from forking from dev. Without divergence the
# fork-point criterion cannot tell a correct derivation from a lucky guess.
# ---------------------------------------------------------------------------

cat > RELEASE-NOTES.md <<'EOF'
# Release notes

## 1.4.0

- Batch warehouse writes in groups of 500.
- Drop the legacy `/v1/ingest` endpoint.
EOF

git add RELEASE-NOTES.md
git commit -q -m "Pin the release notes for 1.4"

# ---------------------------------------------------------------------------
# The dev branch, forked from commit 1, carrying the upstream artefact.
#
# The discovery note is the upstream the ADR derives from, so that the
# Derives-From criterion has a definite path to name. It lives on dev
# only, which is the second tell that distinguishes dev from main as the
# fork point.
# ---------------------------------------------------------------------------

git checkout -q -b dev "$(git rev-parse HEAD~1)"

mkdir -p docs/discovery
cat > docs/discovery/0001-event-volume.md <<'EOF'
---
title: Where is the ingest volume actually coming from?
status: open
date: 2026-09-09
---

# Where is the ingest volume actually coming from?

## What prompted this

Ingest volume has roughly tripled since June while the fleet grew by
about a fifth. Warehouse spend is following the events, not the fleet.

## What we found

- 71% of events come from four device models, all running the 3.x
  firmware, which emits a heartbeat every 5 seconds regardless of
  whether anything changed.
- Heartbeats are never read by any downstream query. Every dashboard
  and alert reads state-change events only.
- Sampling heartbeats at the ingest edge would remove roughly two
  thirds of stored rows and change no dashboard.
- Dropping them entirely would lose liveness detection, which two
  on-call runbooks depend on.

## Where this leaves us

The choice is between sampling heartbeats at a fixed rate at the ingest
edge, or having the firmware emit them less often. The firmware route is
correct and slow: a fleet-wide rollout is a two-quarter exercise. The
ingest-edge route is available now and is reversible.

This note is finished. Someone needs to make the decision and record it.
EOF

git add docs/discovery/0001-event-volume.md
git commit -q -m "Add discovery note on ingest event volume"

# Anchors for the scorer. These tags mark where the fixture ended, so that
# every criterion can talk about "commits added after the fixture" without
# guessing. They are scaffolding and the workflow has no reason to touch
# them.
git tag fixture-base-dev dev
git tag fixture-base-main main

# ---------------------------------------------------------------------------
# The working tree the agent meets: on dev, and dirty.
#
# Dirty on purpose, and dirty in three different ways, so that the
# contention check has something real to find and so that "the primary
# checkout was left alone" is falsifiable.
# ---------------------------------------------------------------------------

# An uncommitted modification to a tracked file. A body that stages the
# primary checkout, or that stashes and forgets to restore, loses this.
cat >> README.md <<'EOF'

TODO(orchard): document the retry budget before the 1.5 release.
EOF

# An untracked, unignored file. A body that runs `git add -A` in the
# primary checkout commits it.
cat > benchmark-notes.txt <<'EOF'
2026-09-18: p99 1.8s at 400 rps, measured against staging.
Re-run once heartbeat sampling is in place.
EOF

# Built dependencies with real contents. Without these, "the git workflow
# did not carry built dependencies into the worktree, and committed none
# of them" is vacuously true because there would be nothing to carry.
# `.venv/` is not ignored (see .gitignore above), so a body that copies it
# and stages everything commits it and fails that criterion.
mkdir -p .venv/bin .venv/lib/python3.12/site-packages/requests
printf 'home = /usr/local/opt/python@3.12/bin\ninclude-system-site-packages = false\nversion = 3.12.4\n' > .venv/pyvenv.cfg
printf '#!/usr/bin/env bash\nexec "$(dirname "$0")/python3" "$@"\n' > .venv/bin/python
chmod +x .venv/bin/python
printf '__version__ = "2.32.3"\n' > .venv/lib/python3.12/site-packages/requests/__init__.py

mkdir -p node_modules/.bin node_modules/left-pad
printf '{\n  "name": "left-pad",\n  "version": "1.3.0",\n  "main": "index.js"\n}\n' > node_modules/left-pad/package.json
printf 'module.exports = function leftPad(s, n, c) { return String(s).padStart(n, c || " "); };\n' > node_modules/left-pad/index.js

# Small configuration, gitignored rather than tracked. Gitignored is the
# point: a tracked .claude/ would be materialised by `git worktree add`
# and the bootstrap-copy rule would never be exercised. Because it is
# ignored, only an explicit copy puts it in a worktree -- and only a move
# rather than a copy removes it from here, which is what the criterion
# checks.
mkdir -p .claude
cat > .claude/settings.local.json <<'EOF'
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(python -m pytest:*)"
    ],
    "deny": []
  }
}
EOF

# ---------------------------------------------------------------------------
# No remote. ADR 0003 sends a repository with no remote down the
# local-merge fallback, and the eval harness has no host and no
# credentials, so this is also the only integration path that can be
# evaluated at all. The contributing guide above asks for a pull request;
# there is nothing to open one against.
# ---------------------------------------------------------------------------

git remote remove origin 2>/dev/null || true

# The agent is left on dev with a dirty tree. Note that nothing above
# checks dev out a second time: the fixture must leave NO reflog entry
# reading `checkout: moving from dev to ...` in .git/logs/HEAD, because
# the absence of exactly that entry is the durable evidence that the work
# was isolated into a worktree rather than branched in place.
