#!/usr/bin/env bash
# refresh-myelin.sh — install myelin's skills from the latest `dev` on
# GitHub into this checkout, so agents working on myelin load its
# current skills (discovery 0004's dev mode).
#
# Runs as a Claude Code SessionStart hook (.claude/settings.json), and
# by hand whenever you want the latest `dev` mid-session:
#   bash .claude/hooks/refresh-myelin.sh
# A skill refreshed mid-session takes effect the next time it is
# invoked; refresh between tasks, not in the middle of one.
#
# The install rewrites the commit pinned in tessl.json. If tessl.json
# had no local changes beforehand, it is restored afterwards, so a
# refresh never leaves the tree dirty; commit a new pin deliberately if
# you want one recorded. It never fails the session: if tessl or the
# network is unavailable, the previous install stays in place.
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" || exit 0
command -v tessl >/dev/null 2>&1 || exit 0
git diff --quiet -- tessl.json 2>/dev/null && clean=1
tessl install github:communitiesuk/myelin \
  --skill adr --skill plans --skill git-workflow \
  --skill facilitated-discovery --skill test-first-workflow --skill skill-forge \
  --yes >/dev/null 2>&1
[ "${clean:-0}" = 1 ] && git checkout -q -- tessl.json 2>/dev/null
exit 0
