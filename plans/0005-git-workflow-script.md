---
title: Ship git-workflow's mechanics as a script
status: draft
adr: 0003
date: 2026-09-23
deferred_reason: null
---

# Ship git-workflow's mechanics as a script

## Reference

Implements `docs/adr/0003-git-workflow.md` as revised on 2026-09-23:
the section "The mechanics are a script; the model decides what and
when", and the section "A decision lands only when a human merges
it". The thinking behind the first is in the history of
`docs/discovery/0002-git-workflow-script.md`, consumed by that
revision. No related plans are in the tree.

## Preconditions

- The human-merge rule for decisions is on `dev` (pull request 33).
- Verified 2026-09-23: `tessl plugin pack` includes a skill's
  `scripts/` and `references/` directories, but the archive does not
  preserve the executable bit, so the skill body invokes the script
  as `bash scripts/git-workflow …`, never by path alone.
- Steps 1 to 5 need no credits. Steps 6 and 7 need eval runs and wait
  for the credit renewal on 2026-09-28.

## Steps

Each step that changes a file is its own branch from `dev`, landed by
pull request with a merge commit; the first commit on each carries
`Derives-From: plans/0005-git-workflow-script.md`, and Step 1's
commit flips this plan to `in-progress`. Steps 1 to 4 are test-first:
the usage text or function comment is the docstring, the shell test
is written and shown failing, then the code.

The script is `skills/git-workflow/scripts/git-workflow`, Bash, with
subcommands `check`, `begin` and `land`. It depends on git and, where
a host is involved, on that host's command-line tool, and on nothing
else. Its tests are `skills/git-workflow/scripts/tests/run.sh` plus
one file per subcommand, each test building a temporary repository
with plain git and asserting on git state, the same facts the eval
scenarios score.

### Step 1 — Contract and harness

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-contract`. Create the script with its
usage text only, exiting 2 on any subcommand; create the test runner
and a helper that builds a fixture repository with a chosen trunk,
optional remote and optional dirt. The usage text is the contract:
it names the three subcommands, their arguments, and the exit codes
(0 done, 1 stopped and reported, 2 usage or precondition failure).

Exit criteria:

- `bash skills/git-workflow/scripts/git-workflow --help` exits 0 and
  its output contains `check`, `begin`, `land`.
- `bash skills/git-workflow/scripts/tests/run.sh` exits 0 and reports
  0 tests, proving the runner runs.

### Step 2 — `check`: derive, do not act

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-check`. `check` prints, one per
line: `trunk=<ref>`, `host=<none|github|unknown:<url>>`,
`contention=<in-place|worktree>`, and exits 2 with a message naming
the three refs when no rung of the trunk ladder resolves.

Tests, each failing before the code and passing after:

- trunk: local `dev` wins over `develop` and `origin/HEAD`; `develop`
  wins over `origin/HEAD`; `origin/HEAD` alone resolves; none of the
  three → exit 2 and the message names `dev`, `develop` and
  `refs/remotes/origin/HEAD`. A `workflow.trunk` config key and a
  `CONTRIBUTING.md` naming `main` are present in every fixture and
  change nothing.
- host: no remote → `none`; `origin` at a `github.com` URL (https and
  ssh forms) → `github`; any other URL → `unknown:<url>`.
- contention: on the derived trunk and clean → `in-place`; on trunk
  but dirty, or clean but on another branch → `worktree`.

Exit criteria: the tests above exist in
`scripts/tests/check.sh`, and `run.sh` exits 0 with their count.

### Step 3 — `begin <artefact-path>`

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-begin`. `begin` derives the branch
name from the path (`docs/adr/NNNN-slug.md` → `adr-NNNN-slug`,
`plans/NNNN-slug.md` → `plan-NNNN-slug`,
`docs/discovery/NNNN-slug.md` → `discovery-NNNN-slug`,
`skills/<name>/SKILL.md` → `skill-<name>`, anything else →
`chore-<slug>` with `--slug` required), then branches in place or
creates `.worktrees/<branch>` from the trunk, copies `.claude/`,
`.env` and `.mcp.json` into a worktree and never `.venv/` or
`node_modules/`, stages a `.worktrees/` line into `.gitignore` inside
the worktree when the repository lacks one, and prints
`branch=<name>` and `dir=<path to work in>`. It refuses with exit 2
if the branch already exists.

Tests: each naming rule; in-place branching when `check` says so;
worktree creation from the trunk, not from HEAD, when the checkout
is on another branch; the copied and not-copied files; the staged
gitignore line present only when missing; the refusal.

Exit criteria: `scripts/tests/begin.sh` exists with those tests and
`run.sh` exits 0.

### Step 4 — `land`

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-land`. `land`, run from the artefact
branch, in order:

1. Refuses (exit 2) unless the first commit since the fork point
   carries a `Derives-From` trailer, read with
   `git log --format='%(trailers:key=Derives-From,valueonly)'`.
2. Decides whether the branch is a decision: any commit since the
   fork point carries `Revises`, or the diff against the trunk adds
   a file under `docs/adr/`. A decision is pushed, proposed through
   the host module, and left: exit 1 with a report naming the pull
   request and saying a human merges it. It is never merged by the
   script.
3. Otherwise, by host: `none` → `git merge --no-ff` into the trunk
   from the primary checkout; `github` → push, `gh pr create`,
   `gh pr merge --merge --delete-branch`; `unknown` → push, exit 1
   with a report. A missing host command, or one that fails or
   refuses, → push if not yet pushed, exit 1 with a report naming
   the command and the state left behind.
4. On a merge only: remove the worktree, delete the branch, and
   confirm the primary checkout is on the trunk without checking it
   out.

Tests, with a bare repository as `origin` and a stub `gh` placed
first on `PATH` by the test itself: the refusal without a trailer;
the decision case for `docs/adr/` and for `Revises`, asserting the
branch is pushed, no merge exists on the trunk, exit 1; the no-remote
merge with two parents and cleanup; the github merge through the
stub; the stub refusing → branch pushed, worktree present, trunk
untouched, exit 1; `gh` absent → the same; an unknown host → the
same. Every "FAILS IF" in `evals/git-workflow-0` and
`evals/git-workflow-1` has a test here.

Exit criteria: `scripts/tests/land.sh` exists with those tests and
`run.sh` exits 0.

### Step 5 — The skill body names the moments

Branch `chore-git-workflow-body`. Rewrite `skills/git-workflow/SKILL.md`
so that it says when to run `bash scripts/git-workflow begin <path>`
and `bash scripts/git-workflow land`, what the model still decides
(the artefact, its upstream for the `Derives-From` trailer, the
commits), and what a stopped landing means. Move the rules'
rationale that is worth keeping to `references/RULES.md`, which the
package includes and the model loads on demand. The `description`
does not change. Update `compatibility` to name Bash, git and the
host CLI. `tessl review run skills/git-workflow` green.

Exit criteria:

- `git diff dev -- skills/git-workflow/SKILL.md | grep -c '^[-+]description:'` prints 0.
- `tessl plugin lint .` prints no token warning for git-workflow.
- The body names `begin` and `land` and no longer states a rule the
  script enforces as an instruction to the model.

### Step 6 — Measure, after 2026-09-28

Branch `chore-git-workflow-script-measure`, progress notes only.

1. Run `evals/git-workflow-0` and `evals/git-workflow-1` with
   `--context . -n 3 --skip-baseline --agent claude --model deepseek-v4-flash`.
   The before is recorded: `git-workflow-1` 18, 0, 0 (run
   `01a0ce24-dd76-729a-ab72-dd5ac616799d`); `git-workflow-0` 95, 97,
   97 (run `01a0cdf9-fa57-7713-92ef-f84fb85da0c4`). About 60 credits.
2. Read the per-repeat `activatedSkills` and the scorer's reasoning
   on any repeat under 80.

Exit criteria, each capable of failing:

- `git-workflow-1`'s median on deepseek is at least 84, which is
  sonnet's 94 less the release gate's threshold.
- `git-workflow-0`'s median on deepseek is at least 85, its before
  less the threshold.
- No repeat under 80 has scorer reasoning describing a local merge
  where a remote exists, a fast-forward, or a squash. What remains
  is "no branch created" or "script not run".
- The run ids and the three facts above are in Progress notes.

### Step 7 — Decide the floor, then complete

On Step 6's branch. If both medians met their bars: remove
`model: sonnet` from `skills/git-workflow/SKILL.md`, rewrite
`compatibility` to cite the runs, and change the release skill's gate
pin to `deepseek-v4-flash`, whose record resets on that change. If
either failed: leave both and record why in Progress notes. Then
delete this plan as the final commit with the `Completes:` trailer
and a body saying what the plan produced and which way the floor
went.

## Verification

After Step 7, from a fresh clone plus the registry:

1. `bash skills/git-workflow/scripts/tests/run.sh` exits 0 and
   reports the tests of Steps 2 to 4.
2. `tessl plugin pack` produces an archive containing
   `skills/git-workflow/scripts/git-workflow` and, if written,
   `skills/git-workflow/references/RULES.md`.
3. `git log --format='%(trailers:key=Derives-From,valueonly)' <first commit of each step branch>`
   prints `plans/0005-git-workflow-script.md` for each.
4. The two Step 6 run ids open with `tessl eval view` and show the
   medians recorded.
5. Either `model:` is absent from git-workflow's frontmatter and the
   release skill pins deepseek, or both are unchanged and the
   Progress notes say why.

Not verified by this plan: whether a model invokes the script at the
right moment. Step 6's third criterion measures what remains once
the mechanics are code, and that number goes to the landing-gate
work rather than being closed here.

## Progress notes

- 2026-09-23 — Written the same evening as the ADR revisions it
  implements, by the same author. An independent review against the
  ADR runs before the pull request opens; findings go here.
- Judgement calls at authoring:
  - Steps 1 to 4 are `code-` branches under `test-first-workflow`:
    Rule 7 gives `code` for a working code change. Step 5 is a body
    edit with the description unchanged, so `skill-forge` does not
    govern it and it takes `chore`.
  - The script stages the `.worktrees/` gitignore line rather than
    committing it, so the script still writes no commits; the
    artefact's first commit carries the line as bookkeeping.
  - `begin` does not take the upstream path. The `Derives-From`
    trailer stays with whoever commits, and `land` checks that it is
    there.
