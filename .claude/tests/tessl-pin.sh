#!/usr/bin/env bash
# tessl-pin.sh — check that tessl.json's pinned myelin dependency installs.
#
# The SessionStart hook (.claude/hooks/refresh-myelin.sh) installs myelin
# from the latest `dev` and then restores tessl.json, so the committed pin
# is never exercised by Claude sessions. Anything else that runs a plain
# `tessl install` (Cursor, CI, a fresh clone) installs exactly that pin,
# and fails if the pin predates a skill the include list names. This check
# catches that drift, and drift between the hook's --skill list and the
# include list.
#
# Usage (from anywhere in the repository):
#   bash .claude/tests/tessl-pin.sh
#
# Checks:
#   1. Every skill in the communitiesuk/myelin dependency's include list
#      has skills/<name>/SKILL.md at the pinned commit.
#   2. The hook's --skill arguments are the same set as the include list.
#
# Fetches the pinned commit from origin if it is not available locally.
# Exits 0 when both checks pass; 1 with one line per failure otherwise;
# 2 if tessl.json or the dependency cannot be read.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2

read_manifest() {
  python3 - <<'PY'
import json, sys
try:
    dep = json.load(open("tessl.json"))["dependencies"]["communitiesuk/myelin"]
    print(dep["version"])
    print(" ".join(dep["include"]["skills"]))
except (OSError, KeyError, ValueError) as e:
    sys.exit(f"tessl-pin: cannot read the communitiesuk/myelin dependency: {e}")
PY
}

manifest=$(read_manifest) || exit 2
pin=$(sed -n 1p <<<"$manifest")
include=$(sed -n 2p <<<"$manifest")

git cat-file -e "$pin^{commit}" 2>/dev/null || git fetch -q origin "$pin" 2>/dev/null
git cat-file -e "$pin^{commit}" 2>/dev/null || {
  echo "tessl-pin: pinned commit $pin is not in origin"
  exit 1
}

fail=0
for skill in $include; do
  git cat-file -e "$pin:skills/$skill/SKILL.md" 2>/dev/null || {
    echo "tessl-pin: skill '$skill' is in the include list but not at pinned commit ${pin:0:7}"
    fail=1
  }
done

hook_skills=$(grep -oE -- '--skill [a-z0-9-]+' .claude/hooks/refresh-myelin.sh | awk '{print $2}' | sort)
include_sorted=$(tr ' ' '\n' <<<"$include" | sort)
[ "$hook_skills" = "$include_sorted" ] || {
  echo "tessl-pin: the hook's --skill list differs from the include list:"
  diff <(echo "$include_sorted") <(echo "$hook_skills") | sed -n 's/^</  include only:/p; s/^>/  hook only:/p'
  fail=1
}

exit "$fail"
