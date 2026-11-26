#!/usr/bin/env bash
# hosts/github.sh — the GitHub module for the git-workflow script.
#
# Usage:
#   bash hosts/github.sh propose <branch> <trunk>   open a pull request from the
#                                                pushed branch onto the trunk,
#                                                its title the first commit's
#                                                subject and its description
#                                                every commit's message and
#                                                body, oldest first; when one
#                                                is already open, rewrite its
#                                                title and description from
#                                                those instead; prints its URL
#   bash hosts/github.sh checks <branch> <trunk>    wait for the status checks the
#                                                trunk requires (branch
#                                                protection's and every
#                                                ruleset's) to pass on that
#                                                pull request: exit 0 at
#                                                once when the trunk
#                                                requires none or the
#                                                requirement cannot be read
#                                                (the host still enforces
#                                                it at merge), 0 when each
#                                                has reported pass or
#                                                skipping, 1 as soon as one
#                                                reports fail or cancel
#                                                (naming it on stderr), 4
#                                                when any is still pending
#                                                or unreported after
#                                                GIT_WORKFLOW_CHECKS_TIMEOUT
#                                                seconds (default 300),
#                                                polling every
#                                                GIT_WORKFLOW_CHECKS_INTERVAL
#                                                seconds (default 10)
#   bash hosts/github.sh merge <branch> <trunk>     merge that pull request with a
#                                                merge commit, never a squash
#                                                or a rebase. It merges only:
#                                                branch teardown (local, remote
#                                                and worktree) is the caller's,
#                                                so gh never trips over the
#                                                artefact's worktree.
#   bash hosts/github.sh link <pr-url> <branch> <path>
#                                                print the URL that shows
#                                                <path> as it stands at the
#                                                tip of <branch>, in the
#                                                repository the pull request
#                                                <pr-url> belongs to; prints
#                                                nothing and exits 1 when
#                                                <pr-url> is not a pull
#                                                request URL
#   bash hosts/github.sh settings                   print squash=<true|false>
#                                                rebase=<true|false> as the
#                                                repository allows them
#
# Depends on gh. Exit 0 done; 1 the host refused, the command failed, or
# (checks) a required check failed; 4 (checks) a required check had not
# passed in time; 127 gh is not on PATH.
set -u
command -v gh >/dev/null 2>&1 || exit 127
case "${1:-}" in
  propose)
    [ $# -ge 3 ] || { echo "usage: propose <branch> <trunk>" >&2; exit 2; }
    title="$(git log --reverse --format=%s "$3..$2" | sed -n 1p)"
    body="$(git log --reverse --format=%B "$3..$2")"
    url="$(gh pr view "$2" --json state,url --jq 'select(.state == "OPEN") | .url' 2>/dev/null)"
    if [ -n "$url" ]; then
      gh pr edit "$2" --title "$title" --body "$body" >/dev/null || exit 1
      printf '%s\n' "$url"
    else
      gh pr create --head "$2" --base "$3" --title "$title" --body "$body" || exit 1
    fi ;;
  checks)
    [ $# -ge 3 ] || { echo "usage: checks <branch> <trunk>" >&2; exit 2; }
    # The branch endpoint's protection summary and the rules endpoint are
    # both readable with read access; the protection endpoint needs admin.
    prot="$(gh api "repos/{owner}/{repo}/branches/$3" --jq '.protection.required_status_checks.contexts[]?' 2>/dev/null)" || exit 0
    rules="$(gh api "repos/{owner}/{repo}/rules/branches/$3" --jq '.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context' 2>/dev/null)" || rules=""
    required="$(printf '%s\n%s\n' "$prot" "$rules" | sed '/^$/d' | sort -u)"
    [ -n "$required" ] || exit 0
    timeout="${GIT_WORKFLOW_CHECKS_TIMEOUT:-300}"; interval="${GIT_WORKFLOW_CHECKS_INTERVAL:-10}"
    start=$SECONDS
    while :; do
      # A check not yet reported, as just after the pull request opens,
      # counts as pending, never as passed.
      report="$(gh pr checks "$2" --json name,bucket --jq '.[] | "\(.name)\t\(.bucket)"' 2>/dev/null)"
      waiting=""
      while IFS= read -r c; do
        b="$(printf '%s\n' "$report" | awk -F '\t' -v n="$c" '$1 == n {print $2}')"
        case "$b" in *fail*|*cancel*) printf '%s\n' "$c" >&2; exit 1 ;; esac
        case "$b" in ""|*pending*) waiting="${waiting:+$waiting, }$c" ;; esac
      done <<< "$required"
      [ -z "$waiting" ] && exit 0
      [ $((SECONDS - start)) -ge "$timeout" ] && { printf '%s\n' "$waiting" >&2; exit 4; }
      sleep "$interval"
    done ;;
  merge)
    [ $# -ge 3 ] || { echo "usage: merge <branch> <trunk>" >&2; exit 2; }
    gh pr merge "$2" --merge || exit 1 ;;
  link)
    [ $# -ge 4 ] || { echo "usage: link <pr-url> <branch> <path>" >&2; exit 2; }
    case "$2" in https://*/pull/[0-9]*) ;; *) exit 1 ;; esac
    printf '%s/blob/%s/%s\n' "${2%/pull/*}" "$3" "$4" ;;
  settings)
    out="$(gh repo view --json squashMergeAllowed,rebaseMergeAllowed)" || exit 1
    sq=false; rb=false
    printf '%s' "$out" | grep -qE '"squashMergeAllowed":[[:space:]]*true' && sq=true
    printf '%s' "$out" | grep -qE '"rebaseMergeAllowed":[[:space:]]*true' && rb=true
    printf 'squash=%s rebase=%s\n' "$sq" "$rb" ;;
  *) echo "usage: hosts/github.sh propose|checks|merge|link|settings" >&2; exit 2 ;;
esac
