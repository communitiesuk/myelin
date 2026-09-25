# land: refuse, hand a decision to a human, merge locally where there is no
# remote or through the host module otherwise, stop and report when the
# host cannot, and clean up only after a merge.
#
# Coverage of the eval scenarios' FAILS IF conditions (criteria.json):
#   git-workflow-0 #1 commit straight onto trunk / non-merge on trunk -> "refusal: on the trunk", merges assert two parents
#   git-workflow-0 #2 branch naming                                    -> begin.sh naming tests
#   git-workflow-0 #3 in-place branching, no worktree                  -> begin.sh worktree tests
#   git-workflow-0 #4 primary files staged/stashed/reverted            -> "no remote: merge from a worktree ... dirt untouched"
#   git-workflow-0 #5 fork point                                       -> begin.sh fork-point test
#   git-workflow-0 #6 config moved, deps copied                        -> begin.sh bootstrap test
#   git-workflow-0 #7 squash / fast-forward / rebase                   -> two-parent assertions; "github: merge ... --merge"
#   git-workflow-0 #8 cleanup: branch left, worktree left, HEAD wrong  -> the merge tests' cleanup assertions
#   git-workflow-0 #9 .worktrees/ line uncommitted / on trunk          -> begin.sh bookkeeping tests
#   git-workflow-0 #10 trailer missing / not repo-relative / later     -> the trailer refusals
#   git-workflow-0 #11 a remote invented                               -> "no remote: ... git remote still empty"
#   git-workflow-1 #1 trunk moved locally or on origin                 -> decision and stop tests
#   git-workflow-1 #2 branch deleted after no merge                    -> stop tests assert the branch exists
#   git-workflow-1 #3 never pushed / origin behind                     -> "pushed at the same SHA" assertions
#   git-workflow-1 #5 worktree removed, HEAD moved, without a merge    -> stop tests

R="$TMP_ROOT/land"
mkdir -p "$R/bin" && cp "$(dirname "$SCRIPT")/tests/stub-gh" "$R/bin/gh" && chmod +x "$R/bin/gh"
export GH_STUB_LOG="$R/gh.log"; export PATH="$R/bin:$PATH"
land() { local d="$1"; shift; (cd "$d" && bash "$SCRIPT" land "$@" 2>&1); }
land_rc() { local d="$1"; shift; (cd "$d" && bash "$SCRIPT" land "$@" >/dev/null 2>&1); echo $?; }
parents() { (cd "$1" && git log -1 --format=%P "$2" | wc -w | tr -d ' '); }
bare_tip() { git --git-dir="$1/.origin/repo.git" rev-parse "$2" 2>/dev/null; }

# Build a repository with an artefact branch carrying one committed ADR.
#   artefact DIR [fixture options...] then: --where in-place|worktree
#   The trailer is written unless NOTRAILER=1; the artefact is docs/discovery/0002-x.md
#   (a note, so that landing it is not a decision)
#   unless ADRPATH is set; extra commits via EXTRA=1.
artefact() {
  local dir="$1"; shift
  local where=worktree opts=()
  while [ $# -gt 0 ]; do case "$1" in --where) where="$2"; shift 2 ;; *) opts+=("$1"); shift ;; esac; done
  fixture "$dir" --trunk dev "${opts[@]}" >/dev/null || return 2
  (cd "$dir" && printf '.worktrees/\n' >> .gitignore && g add .gitignore && g commit -q -m "ignore worktrees" && { git remote | grep -q . && g push -q origin dev || true; })
  if [ "$where" = worktree ]; then (cd "$dir" && g switch -q -c topic && printf 'x\n' > t.txt && g add t.txt && g commit -q -m topic); fi
  local out; out="$(cd "$dir" && bash "$SCRIPT" begin "${ADRPATH:-docs/discovery/0002-x.md}" 2>&1)" || { echo "$out"; return 2; }
  local wd; wd="$(printf '%s\n' "$out" | sed -n 's/^dir=//p')"
  ( cd "$wd" && mkdir -p "$(dirname "${ADRPATH:-docs/discovery/0002-x.md}")" && printf -- '---\ntitle: x\n---\n' > "${ADRPATH:-docs/discovery/0002-x.md}" && g add -A \
    && if [ "${NOTRAILER:-0}" = 1 ]; then g commit -q -m "Add ADR"; else g commit -q -m "$(printf 'Add ADR\n\nDerives-From: %s\n' "${TRAILER:-docs/discovery/0001-note.md}")"; fi )
  if [ "${EXTRA:-0}" = 1 ]; then ( cd "$wd" && printf 'more\n' >> "${ADRPATH:-docs/discovery/0002-x.md}" && g add -A && g commit -q -m "Extend ADR" ); fi
  echo "$wd"
}
# github-flavoured remote: origin's URL names github.com so host=github, and a
# url.insteadOf rewrite in the repository's config sends every fetch and push
# to the bare repository instead, so git and the stub host share one origin.
githubify() { (cd "$1" && git remote set-url origin https://github.com/example/repo.git && git config "url.$(pwd)/.origin/repo.git.insteadOf" https://github.com/example/repo.git); export GH_STUB_BARE="$1/.origin/repo.git" GH_STUB_TRUNK=dev; }

t "refusal: on the trunk"
  fixture "$R/r1" --trunk dev >/dev/null
  out="$(land "$R/r1"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "trunk"

t "refusal: dirty working tree"
  wd="$(artefact "$R/r2" --where in-place)"; (cd "$wd" && printf 'dirt\n' >> README.md)
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "dirty"
  assert_eq "discovery-0002-x" "$(cd "$R/r2" && git rev-parse --abbrev-ref HEAD)" "refusal must change nothing"

t "refusal: nothing since the fork point"
  fixture "$R/r3" --trunk dev --branch empty >/dev/null; (cd "$R/r3" && g switch -q empty && g reset -q --hard dev)
  out="$(land "$R/r3"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "nothing"

t "refusal: first commit has no Derives-From trailer"
  wd="$(NOTRAILER=1 artefact "$R/r4" --where in-place)"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "Derives-From"
  assert_eq "$(cd "$R/r4" && git rev-parse dev)" "$(cd "$R/r4" && git rev-parse dev)" ; assert_eq "1" "$(cd "$R/r4" && git rev-list --count dev..discovery-0002-x)"

t "refusal: trailer only on a later commit"
  wd="$(NOTRAILER=1 EXTRA=0 artefact "$R/r5" --where in-place)"
  (cd "$wd" && printf 'more\n' >> docs/adr/0002-x.md && g add -A && g commit -q -m "$(printf 'Extend\n\nDerives-From: docs/discovery/0001-note.md\n')")
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "first commit"

t "refusal: trailer value not repository-relative"
  wd="$(TRAILER=./docs/discovery/0001-note.md artefact "$R/r6" --where in-place)"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=2"; assert_contains "$out" "relative"
  wd="$(TRAILER=/docs/discovery/0001-note.md artefact "$R/r7" --where in-place)"
  assert_eq "2" "$(land_rc "$wd")"

t "decision: a new docs/adr file is proposed, never merged, exit 3"
  wd="$(ADRPATH=docs/adr/0002-x.md artefact "$R/d1" --remote origin --where worktree)"; githubify "$R/d1"; : > "$GH_STUB_LOG"
  out="$(land "$wd"; echo "exit=$?")"
  assert_contains "$out" "exit=3"; assert_contains "$out" "pull/7"; assert_contains "$out" "human"
  assert_eq "$(cd "$R/d1" && git rev-parse adr-0002-x)" "$(bare_tip "$R/d1" adr-0002-x)" "branch must be pushed at the same SHA"
  assert_contains "$(cat "$GH_STUB_LOG")" "pr create"
  case "$(cat "$GH_STUB_LOG")" in *"pr merge"*) fail "merge was attempted on a decision" ;; esac
  assert_eq "$(cd "$R/d1" && git rev-parse dev)" "$(bare_tip "$R/d1" dev)" "origin's trunk must equal the local trunk"
  assert_eq "0" "$(cd "$R/d1" && git log --merges --format=%H dev | wc -l | tr -d ' ')" "trunk gained a merge"
  assert_eq "0" "$(cd "$R/d1" && git rev-list --count dev ^"$(git merge-base dev adr-0002-x)")" "trunk moved locally"
  [ -d "$R/d1/.worktrees/adr-0002-x" ] || fail "worktree removed on a decision"

t "decision: a Revises trailer is proposed, never merged, exit 3"
  wd="$(ADRPATH=docs/adr/0001-one.md artefact "$R/d2" --remote origin --where in-place)"
  (cd "$wd" && printf 'changed\n' >> docs/adr/0001-one.md && g add -A && g commit -q -m "$(printf 'Revise\n\nRevises: docs/adr/0001-one.md\n')")
  githubify "$R/d2"; : > "$GH_STUB_LOG"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=3"
  case "$(cat "$GH_STUB_LOG")" in *"pr merge"*) fail "merge was attempted on a Revises branch" ;; esac
  assert_eq "adr-0001-one" "$(cd "$R/d2" && git rev-parse --abbrev-ref HEAD)" "primary checkout must stay on the branch"

t "decision: with no remote it cannot be proposed, exit 3, branch kept"
  wd="$(ADRPATH=docs/adr/0002-x.md artefact "$R/d3" --where worktree)"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=3"
  assert_eq "1" "$(cd "$R/d3" && git for-each-ref refs/heads/adr-0002-x | wc -l | tr -d ' ')"
  assert_eq "0" "$(cd "$R/d3" && git log --merges --format=%H dev | wc -l | tr -d ' ')"

t "not a decision: editing an existing ADR without Revises merges normally"
  wd="$(ADRPATH=docs/adr/0001-one.md artefact "$R/d4" --where in-place)"
  assert_eq "0" "$(land_rc "$wd")"; assert_eq "2" "$(parents "$R/d4" dev)"

t "no remote: merge in place, primary ends on the trunk, two parents, branch gone, no remote invented"
  wd="$(artefact "$R/m1" --where in-place)"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=0"
  assert_eq "dev" "$(cd "$R/m1" && git rev-parse --abbrev-ref HEAD)"
  assert_eq "2" "$(parents "$R/m1" dev)"
  assert_eq "0" "$(cd "$R/m1" && git for-each-ref refs/heads/discovery-0002-x | wc -l | tr -d ' ')"
  assert_eq "" "$(cd "$R/m1" && git remote)"; assert_eq "0" "$(cd "$R/m1" && git for-each-ref refs/remotes | wc -l | tr -d ' ')"

t "no remote: merge from a worktree with an untracked .venv, worktree removed, dirt untouched, no checkout line"
  wd="$(artefact "$R/m2" --dirty --where worktree)"
  (cd "$R/m2" && g switch -q dev 2>/dev/null || true)   # primary back on trunk, dirt travels with it
  before="$(cd "$R/m2" && git status --porcelain | sort)"
  reflog_before="$(cd "$R/m2" && grep -c 'checkout: moving from dev' .git/logs/HEAD)"   # the helper's own switch to topic
  mkdir -p "$wd/.venv/bin" && printf 'x\n' > "$wd/.venv/bin/python"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=0"
  assert_eq "2" "$(parents "$R/m2" dev)"
  [ -d "$R/m2/.worktrees/discovery-0002-x" ] && fail "worktree not removed"
  assert_eq "$before" "$(cd "$R/m2" && git status --porcelain | sort)" "primary dirt must be untouched"
  assert_contains "$(cd "$R/m2" && git status --porcelain)" " M README.md"
  assert_contains "$(cd "$R/m2" && git status --porcelain)" "?? notes.txt"
  assert_eq "$reflog_before" "$(cd "$R/m2" && grep -c 'checkout: moving from dev' .git/logs/HEAD)" "land added a checkout line to the primary reflog"
  assert_eq "0" "$(cd "$R/m2" && git for-each-ref refs/heads/discovery-0002-x | wc -l | tr -d ' ')"

t "no remote: primary checkout on neither trunk nor branch -> exit 1, nothing merged"
  wd="$(artefact "$R/m3" --where worktree)"   # primary is on topic
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=1"; assert_contains "$out" "trunk"
  assert_eq "0" "$(cd "$R/m3" && git log --merges --format=%H dev | wc -l | tr -d ' ')"
  [ -d "$R/m3/.worktrees/discovery-0002-x" ] || fail "worktree removed without a merge"

t "github: merge in place with --merge, local trunk fast-forwarded to origin, cleanup"
  wd="$(artefact "$R/g1" --remote origin --where in-place)"; githubify "$R/g1"; : > "$GH_STUB_LOG"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=0"
  merge_line="$(grep 'pr merge' "$GH_STUB_LOG")"; assert_contains "$merge_line" "--merge"
  case "$merge_line" in *--squash*|*--rebase*) fail "squash or rebase passed to the host" ;; esac
  assert_eq "dev" "$(cd "$R/g1" && git rev-parse --abbrev-ref HEAD)"
  assert_eq "$(bare_tip "$R/g1" dev)" "$(cd "$R/g1" && git rev-parse dev)" "local trunk must equal origin's"
  assert_eq "2" "$(parents "$R/g1" dev)"
  assert_eq "0" "$(cd "$R/g1" && git for-each-ref refs/heads/discovery-0002-x | wc -l | tr -d ' ')"

t "github: merge from a worktree, run from the primary checkout, worktree removed"
  wd="$(artefact "$R/g2" --remote origin --where worktree)"; (cd "$R/g2" && g switch -q dev); githubify "$R/g2"; : > "$GH_STUB_LOG"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=0"
  [ -d "$R/g2/.worktrees/discovery-0002-x" ] && fail "worktree not removed"
  assert_eq "$(bare_tip "$R/g2" dev)" "$(cd "$R/g2" && git rev-parse dev)"
  assert_eq "dev" "$(cd "$R/g2" && git rev-parse --abbrev-ref HEAD)"

t "github: settings that allow a squash are reported before merging"
  wd="$(artefact "$R/g3" --remote origin --where in-place)"; githubify "$R/g3"
  out="$(GH_STUB_SQUASH=true land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=0"; assert_contains "$out" "squash"

t "stop: the host refuses the merge -> pushed, branch and worktree kept, HEAD unchanged, exit 1 with the hint"
  wd="$(artefact "$R/s1" --remote origin --where worktree)"; githubify "$R/s1"; : > "$GH_STUB_LOG"
  head_before="$(cd "$R/s1" && git rev-parse --abbrev-ref HEAD)"; origin_before="$(bare_tip "$R/s1" dev)"
  out="$(GH_STUB_MERGE=refuse land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=1"
  assert_contains "$out" "pull/7"; assert_contains "$out" "gh pr merge"; assert_contains "$out" "Bash(gh pr merge *)"
  assert_eq "$(cd "$R/s1" && git rev-parse discovery-0002-x)" "$(bare_tip "$R/s1" discovery-0002-x)" "pushed at the same SHA"
  assert_eq "1" "$(cd "$R/s1" && git for-each-ref refs/heads/discovery-0002-x | wc -l | tr -d ' ')"
  [ -d "$R/s1/.worktrees/discovery-0002-x" ] || fail "worktree removed without a merge"
  assert_eq "$head_before" "$(cd "$R/s1" && git rev-parse --abbrev-ref HEAD)"
  assert_eq "$origin_before" "$(bare_tip "$R/s1" dev)" "origin trunk moved"

t "stop: gh absent from PATH -> pushed, kept, exit 1 naming gh"
  wd="$(artefact "$R/s2" --remote origin --where worktree)"; githubify "$R/s2"
  out="$( (cd "$wd" && PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v "^$R/bin$" | tr '\n' ':')" bash "$SCRIPT" land 2>&1); echo "exit=$?")"
  assert_contains "$out" "exit=1"; assert_contains "$out" "gh"
  assert_eq "$(cd "$R/s2" && git rev-parse discovery-0002-x)" "$(bare_tip "$R/s2" discovery-0002-x)" "pushed at the same SHA"
  assert_eq "1" "$(cd "$R/s2" && git for-each-ref refs/heads/discovery-0002-x | wc -l | tr -d ' ')"
  [ -d "$R/s2/.worktrees/discovery-0002-x" ] || fail "worktree removed without a merge"

t "stop: an unknown host -> pushed, kept, exit 1"
  wd="$(artefact "$R/s3" --remote origin --where worktree)"
  (cd "$R/s3" && git remote set-url origin https://gitlab.example.org/x/y.git && git config "url.$(pwd)/.origin/repo.git.insteadOf" https://gitlab.example.org/x/y.git)
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=1"; assert_contains "$out" "gitlab.example.org"
  assert_eq "$(cd "$R/s3" && git rev-parse discovery-0002-x)" "$(bare_tip "$R/s3" discovery-0002-x)" "pushed at the same SHA"
  assert_eq "0" "$(cd "$R/s3" && git log --merges --format=%H dev | wc -l | tr -d ' ')"

t "github: the pull request is opened against the derived trunk"
  wd="$(artefact "$R/g4" --remote origin --where in-place)"; githubify "$R/g4"; : > "$GH_STUB_LOG"
  assert_eq "0" "$(land_rc "$wd")"
  assert_contains "$(grep 'pr create' "$GH_STUB_LOG")" "--base dev"

t "github: land from inside the worktree with untracked files, primary off-trunk -> clean, no gh worktree warning (issue #46)"
  wd="$(artefact "$R/wc1" --remote origin --where worktree)"; githubify "$R/wc1"; : > "$GH_STUB_LOG"
  printf 'x\n' > "$wd/untracked-note.txt"   # a non-ignored untracked file, so a non-force worktree remove would refuse, as begin's copied .claude/ did in the wild
  out="$(land "$wd"; echo "exit=$?")"
  assert_contains "$out" "exit=0"
  case "$out" in *"could not remove worktree"*|*"contains modified"*) fail "gh's non-force worktree cleanup leaked into land's output" ;; esac
  [ -d "$R/wc1/.worktrees/discovery-0002-x" ] && fail "worktree not removed"
  assert_eq "0" "$(cd "$R/wc1" && git for-each-ref refs/heads/discovery-0002-x | wc -l | tr -d ' ')"
  assert_eq "2" "$(git --git-dir="$R/wc1/.origin/repo.git" log -1 --format=%P dev | wc -w | tr -d ' ')" "origin trunk is not a two-parent merge"

t "github: land from inside the worktree with untracked files, primary on trunk but dirty -> clean, dirt untouched (PR #52)"
  wd="$(artefact "$R/wc2" --remote origin --where worktree)"; githubify "$R/wc2"
  (cd "$R/wc2" && git switch -q dev && printf 'dirt\n' >> README.md)   # primary on trunk, dirty
  : > "$GH_STUB_LOG"
  printf 'x\n' > "$wd/untracked-note.txt"
  out="$(land "$wd"; echo "exit=$?")"
  assert_contains "$out" "exit=0"
  case "$out" in *"could not remove worktree"*|*"contains modified"*) fail "gh's non-force worktree cleanup leaked into land's output" ;; esac
  [ -d "$R/wc2/.worktrees/discovery-0002-x" ] && fail "worktree not removed"
  assert_eq "dev" "$(cd "$R/wc2" && git rev-parse --abbrev-ref HEAD)"
  assert_contains "$(cd "$R/wc2" && git status --porcelain)" " M README.md"

t "github: land deletes the remote branch itself, not the host module"
  wd="$(artefact "$R/wc3" --remote origin --where in-place)"; githubify "$R/wc3"; : > "$GH_STUB_LOG"
  out="$(land "$wd"; echo "exit=$?")"; assert_contains "$out" "exit=0"
  assert_eq "" "$(bare_tip "$R/wc3" discovery-0002-x)" "remote branch not deleted"
