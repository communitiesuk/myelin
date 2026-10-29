#!/usr/bin/env bash
#
# Fixture for evals/setup-0.
#
# Builds the repository the agent is dropped into, BEFORE the agent runs.
# The repository is built here rather than described in task.md because
# the skill under test governs repository setup: telling the agent to
# initialise its own repository would let the skill set its own exam.
#
# The fixture establishes only what can be made deterministic offline: a
# git repository with an `origin` remote and a resolvable trunk, so the
# setup check's remote-route items are in scope and the required checks
# have a real repository to inspect. The two host facts the scenario
# turns on — the host allowing squash/rebase merges, and the user not
# holding admin — cannot be reproduced without a live, credentialed
# host, so they are stated as givens in task.md instead. The eval
# harness has no host and no credentials, so a `gh` call here would fail
# and prove nothing; the check reports the merge-settings item as a pass
# it could not assess, and the scenario's fix-gating criteria are scored
# against the agent's behaviour and the untouched settings, not against a
# flagged check. See the per-skill notes: setup-0 is the red Phase-2
# contract, which need not pass.

set -eu

git init -q .
git symbolic-ref HEAD refs/heads/dev

git config --local user.name "Setup Fixture"
git config --local user.email "setup@fixture.invalid"
git config --local commit.gpgsign false

# A minimal first commit on the trunk `dev`, so the repository has a
# history and a resolvable local trunk (git-workflow derives `dev` without
# reading configuration). resolvable_trunk_ok passes on the local `dev`.
cat > README.md <<'EOF'
# Example

A repository that uses the myelin plugin.
EOF

git add README.md
git commit -q -m "Initial commit"

# An `origin` remote, so `git remote` prints a remote and the manifest's
# `when: remote-exists` items (host CLI, resolvable trunk, and the
# desirable merge-settings opinion) are evaluated rather than skipped.
# The URL is never contacted: no push, no fetch. The eval harness has no
# credentials, so any real network call fails regardless.
git remote add origin https://github.com/example/example.git

# No `gh` stub is installed on PATH. A stub was deliberately avoided in
# the git-workflow fixtures because copying one onto whichever PATH
# directory happened to be writable made the agent's situation vary from
# run to run. The host facts this scenario needs are givens in task.md.

# A checked-in settings file WITHOUT the gh pr merge opt-in, so a
# criterion can check that the agent reports the opt-in line and does not
# write it in here.
mkdir -p .claude
cat > .claude/settings.json <<'EOF'
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)"
    ],
    "deny": []
  }
}
EOF
git add .claude/settings.json
git commit -q -m "Add repository settings"
