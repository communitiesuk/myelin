# begin: name the branch from the artefact path, branch in place or into a
# worktree from the trunk, bootstrap the worktree, and touch nothing else.

R="$TMP_ROOT/begin"
begin() { local d="$1"; shift; (cd "$d" && bash "$SCRIPT" begin "$@" 2>&1); }
line() { printf '%s\n' "$1" | grep "^$2=" | head -1; }
tip() { (cd "$1" && git rev-parse "$2"); }

t "naming: docs/adr/NNNN-slug.md -> adr-NNNN-slug"
  fixture "$R/n1" --trunk dev >/dev/null
  out="$(begin "$R/n1" docs/adr/0007-sample-heartbeats.md)"
  assert_eq "branch=adr-0007-sample-heartbeats" "$(line "$out" branch)" "$out"

t "naming: plans/NNNN-slug.md -> plan-NNNN-slug"
  fixture "$R/n2" --trunk dev >/dev/null
  out="$(begin "$R/n2" plans/0005-script.md)"
  assert_eq "branch=plan-0005-script" "$(line "$out" branch)" "$out"

t "naming: docs/discovery/NNNN-slug.md -> discovery-NNNN-slug"
  fixture "$R/n3" --trunk dev >/dev/null
  out="$(begin "$R/n3" docs/discovery/0002-thing.md)"
  assert_eq "branch=discovery-0002-thing" "$(line "$out" branch)" "$out"

t "naming: skills/<name>/SKILL.md -> skill-<name>"
  fixture "$R/n4" --trunk dev >/dev/null
  out="$(begin "$R/n4" skills/history/SKILL.md)"
  assert_eq "branch=skill-history" "$(line "$out" branch)" "$out"

t "naming: an ungoverned path needs --slug and gives chore-<slug>"
  fixture "$R/n5" --trunk dev >/dev/null
  out="$( (cd "$R/n5" && bash "$SCRIPT" begin src/thing.py 2>&1); echo "exit=$?" )"
  assert_contains "$out" "exit=2"; assert_contains "$out" "slug"
  assert_eq "dev" "$(cd "$R/n5" && git rev-parse --abbrev-ref HEAD)" "refusal must change nothing"
  out="$(begin "$R/n5" src/thing.py --slug fix-thing)"
  assert_eq "branch=chore-fix-thing" "$(line "$out" branch)" "$out"

t "in place: on the trunk and clean, the primary checkout moves to the new branch"
  fixture "$R/p1" --trunk dev --config >/dev/null
  out="$(begin "$R/p1" docs/adr/0002-x.md)"
  assert_eq "trunk=dev" "$(line "$out" trunk)" "$out"
  assert_eq "dir=$(cd "$R/p1" && pwd -P)" "$(line "$out" dir)" "$out"
  assert_eq "adr-0002-x" "$(cd "$R/p1" && git rev-parse --abbrev-ref HEAD)"
  assert_eq "$(tip "$R/p1" dev)" "$(tip "$R/p1" adr-0002-x)" "branch must start at the trunk tip"
  assert_eq "0" "$(cd "$R/p1" && git worktree list | grep -c worktrees)" "no worktree in place"

t "worktree: on another branch, the worktree forks from the trunk, not from HEAD"
  fixture "$R/w1" --trunk dev --branch topic --config >/dev/null
  (cd "$R/w1" && g switch -q topic)
  out="$(begin "$R/w1" docs/adr/0002-x.md)"
  wt="$R/w1/.worktrees/adr-0002-x"
  assert_eq "dir=$(cd "$R/w1" && pwd -P)/.worktrees/adr-0002-x" "$(line "$out" dir)" "$out"
  [ -d "$wt" ] || fail "worktree directory missing"
  assert_eq "adr-0002-x" "$(cd "$wt" && git rev-parse --abbrev-ref HEAD)"
  assert_eq "$(tip "$R/w1" dev)" "$(cd "$wt" && git rev-parse HEAD~0 2>/dev/null | head -1)" "worktree HEAD must be the trunk tip (no gitignore commit expected here)"
  [ -f "$wt/TRUNK-ONLY.md" ] || fail "trunk-only file missing: forked from the wrong branch"
  [ -f "$wt/BRANCH-ONLY.md" ] && fail "branch-only file present: forked from HEAD, not the trunk"
  assert_eq "topic" "$(cd "$R/w1" && git rev-parse --abbrev-ref HEAD)" "primary checkout must stay where it was"
  # this fixture already ignores .worktrees/ so no bookkeeping commit is made
  true

t "worktree: on the trunk but dirty, no checkout line in the primary reflog and dirt untouched"
  fixture "$R/w2" --trunk dev --dirty --config >/dev/null
  (cd "$R/w2" && printf '.worktrees/\n' >> .gitignore && g add .gitignore && g commit -q -m "ignore worktrees" && printf 'TODO: unfinished edit\n' >> README.md)
  before="$(cd "$R/w2" && git status --porcelain | sort)"
  begin "$R/w2" docs/adr/0002-x.md >/dev/null
  [ -d "$R/w2/.worktrees/adr-0002-x" ] || fail "worktree not created"
  assert_eq "adr-0002-x" "$(cd "$R/w2/.worktrees/adr-0002-x" 2>/dev/null && git rev-parse --abbrev-ref HEAD)" "worktree not on the branch"
  assert_eq "0" "$(cd "$R/w2" && grep -c 'checkout: moving from dev' .git/logs/HEAD)" "primary reflog gained a checkout line"
  assert_eq "dev" "$(cd "$R/w2" && git rev-parse --abbrev-ref HEAD)"
  assert_eq "$before" "$(cd "$R/w2" && git status --porcelain | grep -v worktrees | sort)" "dirt must be exactly as it was"
  assert_contains "$(cd "$R/w2" && git status --porcelain)" " M README.md"
  assert_contains "$(cd "$R/w2" && git status --porcelain)" "?? notes.txt"

t "bootstrap: config files copied, built dependencies left behind, base checkout intact"
  fixture "$R/w3" --trunk dev --branch topic --ignored >/dev/null
  (cd "$R/w3" && printf 'KEY=1\n' > .env && printf '{}\n' > .mcp.json && g switch -q topic)
  begin "$R/w3" docs/adr/0002-x.md >/dev/null
  wt="$R/w3/.worktrees/adr-0002-x"
  [ -f "$wt/.claude/settings.local.json" ] || fail ".claude not copied"
  [ -f "$wt/.env" ] || fail ".env not copied"
  [ -f "$wt/.mcp.json" ] || fail ".mcp.json not copied"
  [ -d "$wt/.venv" ] && fail ".venv copied"
  [ -d "$wt/node_modules" ] && fail "node_modules copied"
  [ -f "$R/w3/.claude/settings.local.json" ] || fail ".claude missing from base checkout: moved, not copied"
  [ -d "$R/w3/.venv" ] || fail ".venv missing from base checkout"
  [ -d "$R/w3/node_modules" ] || fail "node_modules missing from base checkout"
  true

t "bookkeeping: the .worktrees/ line is committed inside the worktree when missing"
  fixture "$R/w4" --trunk dev --branch topic >/dev/null
  (cd "$R/w4" && g switch -q topic)
  begin "$R/w4" docs/adr/0002-x.md >/dev/null
  wt="$R/w4/.worktrees/adr-0002-x"
  (cd "$wt" && git check-ignore -q .worktrees) || fail ".worktrees/ not ignored in the worktree"
  assert_eq "1" "$(cd "$wt" && git rev-list --count dev..HEAD)" "exactly one bookkeeping commit on the branch"
  assert_eq "" "$(cd "$wt" && git status --porcelain)" "worktree must be clean after the commit"
  assert_eq "0" "$(cd "$R/w4" && grep -c '^\.worktrees/$' .gitignore)" "primary checkout's .gitignore must be untouched"
  assert_eq "$(tip "$R/w4" dev)" "$(cd "$R/w4" && git rev-parse dev)" "trunk must not move"

t "bookkeeping: no commit when the line already exists"
  fixture "$R/w5" --trunk dev --branch topic >/dev/null
  (cd "$R/w5" && printf '.worktrees/\n' >> .gitignore && g add .gitignore && g commit -q -m "ignore worktrees" && g switch -q topic)
  begin "$R/w5" docs/adr/0002-x.md >/dev/null
  assert_eq "0" "$(cd "$R/w5/.worktrees/adr-0002-x" && git rev-list --count dev..HEAD)"

t "refusal: the branch already exists"
  fixture "$R/r1" --trunk dev --branch adr-0002-x >/dev/null
  out="$( (cd "$R/r1" && bash "$SCRIPT" begin docs/adr/0002-x.md 2>&1); echo "exit=$?" )"
  assert_contains "$out" "exit=2"
  assert_contains "$out" "already exists"
  assert_eq "dev" "$(cd "$R/r1" && git rev-parse --abbrev-ref HEAD)"
  [ -d "$R/r1/.worktrees" ] && fail "worktree created despite refusal"
  true

t "refusal: check's failures propagate (no trunk resolves)"
  fixture "$R/r2" --trunk main >/dev/null
  out="$( (cd "$R/r2" && bash "$SCRIPT" begin docs/adr/0002-x.md 2>&1); echo "exit=$?" )"
  assert_contains "$out" "exit=2"
  assert_contains "$out" "refs/heads/dev"

t "output: trunk, branch and dir lines are all printed"
  fixture "$R/o1" --trunk dev >/dev/null
  out="$(begin "$R/o1" docs/adr/0002-x.md)"
  for k in trunk branch dir; do [ -n "$(line "$out" $k)" ] || fail "missing $k="; done
