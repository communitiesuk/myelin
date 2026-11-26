#!/usr/bin/env bash
# A stand-in for gh used by land.sh. Records every invocation to
# $GH_STUB_LOG. "pr create" prints a URL. "pr merge" refuses when
# GH_STUB_MERGE=refuse, otherwise performs a real merge commit in the bare
# origin at $GH_STUB_BARE onto $GH_STUB_TRUNK, as the host module now does:
# it merges only and does not delete the remote branch (the script owns
# that). If --delete-branch is nevertheless passed, the stub emulates real
# gh's local side-effects — a non-force worktree removal and local branch
# delete in the caller's repo, printing gh's warning and skipping on
# failure — so a caller that still passes the flag reproduces the
# worktree-cleanup bug. "repo view" reports merge settings from
# GH_STUB_SQUASH.
# "pr view" reports an open pull request, printing its URL, only when
# GH_STUB_PR=open; it ignores --json and --jq. "pr edit" succeeds.
# "api" prints what the host module's --jq would select, ignoring --jq:
# for a .../rules/branches/... path, the contexts in
# GH_STUB_RULESET_REQUIRED, otherwise for a .../branches/... path those in
# GH_STUB_REQUIRED, one per line; GH_STUB_API=fail makes it fail.
# "pr checks" prints name<TAB>bucket lines, ignoring --json and --jq, from
# GH_STUB_CHECKS: snapshots separated by "|", each space-separated
# name=bucket pairs; each call takes the next snapshot and the last one
# repeats. An empty snapshot reports no checks, exit 1, as real gh does.
set -u
printf '%s\n' "$*" >> "${GH_STUB_LOG:?}"
case "${1:-} ${2:-}" in
  "auth status") echo "Logged in"; exit 0 ;;
  "pr create") echo "https://github.com/example/repo/pull/7"; exit 0 ;;
  "pr merge")
    if [ "${GH_STUB_MERGE:-ok}" = refuse ]; then
      echo "Permission for this action was denied by the session's permission classifier. Reason: [Merge Without Review]." >&2
      exit 1
    fi
    branch="${3:?}"; tmp="$(mktemp -d)"
    git clone -q "${GH_STUB_BARE:?}" "$tmp/c" \
      && git -C "$tmp/c" switch -q "${GH_STUB_TRUNK:?}" \
      && git -C "$tmp/c" merge -q --no-ff -m "Merge pull request #7 from example/$branch" "origin/$branch" \
      && git -C "$tmp/c" push -q origin "$GH_STUB_TRUNK"
    rc=$?; rm -rf "$tmp"
    [ "$rc" -eq 0 ] || exit "$rc"
    # The host module merges only; the remote branch is the caller's to
    # delete, so the stub no longer does it. But if a caller still passes
    # --delete-branch, emulate real gh's local side-effects: gh removes the
    # branch's worktree without --force and, on failure, prints this warning
    # and skips the local branch delete. Exit 0 regardless — the merge
    # succeeded — exactly as real gh does.
    case " $* " in
      *" --delete-branch "*)
        wt="$(git worktree list --porcelain | awk -v b="refs/heads/$branch" '
          $1=="worktree"{p=$2} $1=="branch" && $2==b {print p}')"
        if [ -n "$wt" ]; then
          git worktree remove "$wt" 2>/dev/null \
            || echo "! Could not remove worktree $wt; skipping local branch delete: failed to run git: fatal: '$wt' contains modified or untracked files, use --force to delete it" >&2
        else
          git branch -d "$branch" >/dev/null 2>&1 || true
        fi ;;
    esac
    exit 0 ;;
  "repo view") printf '{"squashMergeAllowed":%s,"rebaseMergeAllowed":false}\n' "${GH_STUB_SQUASH:-false}"; exit 0 ;;
  "pr view")
    [ "${GH_STUB_PR:-none}" = open ] || { echo "no pull requests found for branch" >&2; exit 1; }
    echo "https://github.com/example/repo/pull/7"; exit 0 ;;
  "pr edit") exit 0 ;;
  "api "*)
    [ "${GH_STUB_API:-ok}" = fail ] && { echo "gh: HTTP 500" >&2; exit 1; }
    case "$2" in
      */rules/branches/*) list="${GH_STUB_RULESET_REQUIRED:-}" ;;
      */branches/*) list="${GH_STUB_REQUIRED:-}" ;;
      *) list="" ;;
    esac
    for c in $list; do printf '%s\n' "$c"; done
    exit 0 ;;
  "pr checks")
    n="$(cat "$GH_STUB_LOG.checks" 2>/dev/null || echo 0)"; echo $((n + 1)) > "$GH_STUB_LOG.checks"
    snap="$(printf '%s' "${GH_STUB_CHECKS:-}" | awk -v RS='|' -v i="$n" '{s[NR-1]=$0} END{print (i in s) ? s[i] : s[NR-1]}')"
    [ -n "$(printf '%s' "$snap" | tr -d ' \n')" ] || { echo "no checks reported on the '$3' branch" >&2; exit 1; }
    for p in $snap; do printf '%s\t%s\n' "${p%%=*}" "${p#*=}"; done
    exit 0 ;;
  *) echo "stub gh: unsupported: $*" >&2; exit 1 ;;
esac
