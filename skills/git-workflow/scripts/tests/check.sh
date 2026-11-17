# check: derive the trunk, the remote and the host facts, and nothing else.
# Every fixture carries the decoys the eval scenarios use: a
# workflow.trunk config key and a CONTRIBUTING.md that both say main.

R="$TMP_ROOT/check"
check() { (cd "$1" && bash "$SCRIPT" check 2>&1); }
line() { printf '%s\n' "$1" | grep "^$2=" | head -1; }

t "trunk: local dev wins over develop and origin/HEAD"
  fixture "$R/a" --trunk main --remote origin --config >/dev/null
  (cd "$R/a" && g branch dev && g branch develop)
  out="$(check "$R/a")"; assert_eq "trunk=dev" "$(line "$out" trunk)" "$out"

t "trunk: local develop wins over origin/HEAD"
  fixture "$R/b" --trunk main --remote origin --config >/dev/null
  (cd "$R/b" && g branch develop)
  out="$(check "$R/b")"; assert_eq "trunk=develop" "$(line "$out" trunk)" "$out"

t "trunk: origin/HEAD alone resolves"
  fixture "$R/c" --trunk main --remote origin --config >/dev/null
  out="$(check "$R/c")"; assert_eq "trunk=main" "$(line "$out" trunk)" "$out"

t "trunk: no rung resolves -> exit 2 naming the three refs"
  fixture "$R/d" --trunk main --config >/dev/null
  out="$( (cd "$R/d" && bash "$SCRIPT" check 2>&1); echo "exit=$?" )"
  assert_contains "$out" "exit=2"
  for ref in dev develop refs/remotes/origin/HEAD; do assert_contains "$out" "$ref"; done
  case "$out" in *"trunk="*) fail "printed a trunk when none resolves" ;; esac

t "remote: none when git remote prints nothing"
  fixture "$R/e" --trunk dev >/dev/null
  out="$(check "$R/e")"
  assert_eq "remote=none" "$(line "$out" remote)" "$out"
  assert_eq "host=none" "$(line "$out" host)" "$out"

t "host: origin at an https github.com URL is github"
  fixture "$R/f" --trunk dev --remote origin --remote-url https://github.com/example/repo.git >/dev/null
  out="$(check "$R/f")"
  assert_eq "remote=origin" "$(line "$out" remote)" "$out"
  assert_eq "host=github" "$(line "$out" host)" "$out"

t "host: origin at an ssh github.com URL is github"
  fixture "$R/g" --trunk dev --remote origin --remote-url git@github.com:example/repo.git >/dev/null
  out="$(check "$R/g")"; assert_eq "host=github" "$(line "$out" host)" "$out"

t "remote: a sole remote not named origin is used, host from its URL"
  fixture "$R/h" --trunk dev --remote upstream --remote-url https://github.com/example/repo.git >/dev/null
  out="$(check "$R/h")"
  assert_eq "remote=upstream" "$(line "$out" remote)" "$out"
  assert_eq "host=github" "$(line "$out" host)" "$out"

t "remote: two remotes and no origin -> exit 2 naming both"
  fixture "$R/i" --trunk dev --remote upstream --remote-url https://github.com/example/repo.git >/dev/null
  (cd "$R/i" && g remote add fork https://github.com/me/repo.git)
  out="$( (cd "$R/i" && bash "$SCRIPT" check 2>&1); echo "exit=$?" )"
  assert_contains "$out" "exit=2"; assert_contains "$out" "upstream"; assert_contains "$out" "fork"

t "host: a non-github URL is unknown:<url>"
  fixture "$R/j" --trunk dev --remote origin --remote-url https://gitlab.example.org/x/y.git >/dev/null
  out="$(check "$R/j")"; assert_eq "host=unknown:https://gitlab.example.org/x/y.git" "$(line "$out" host)" "$out"

t "output: exactly trunk=, remote=, host= on a clean trunk, a dirty trunk and another branch, and no contention= line"
  fixture "$R/k" --trunk dev --config >/dev/null
  fixture "$R/l" --trunk dev --dirty >/dev/null
  fixture "$R/m" --trunk dev --branch topic >/dev/null; (cd "$R/m" && g switch -q topic)
  for d in k l m; do
    out="$(check "$R/$d")"
    assert_eq "$(printf 'trunk=dev\nremote=none\nhost=none')" "$out" "$d: $out"
    case "$out" in *contention=*) fail "$d: printed a contention= line" ;; esac
  done
  true
