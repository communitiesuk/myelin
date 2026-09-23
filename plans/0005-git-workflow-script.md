---
title: Ship git-workflow's mechanics as a script
status: in-progress
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

- The human-merge rule for decisions is on `dev` (pull request 33,
  merged 2026-09-23 at `06276bf`). Step 5 rewrites the file that pull
  request touched and forks from a `dev` that carries it.
- Verified 2026-09-23: `tessl plugin pack` includes a skill's
  `scripts/` and `references/` directories, but the archive does not
  preserve the executable bit, so the skill body invokes the script
  as `bash <skill-dir>/scripts/git-workflow …`, never by path alone.
- Steps 1 to 5 need no credits. Step 6 needs eval runs and waits for
  the credit renewal on 2026-09-28.

## Steps

Each step that changes a file is its own branch from `dev`, landed by
pull request with a merge commit; the first commit on each carries
`Derives-From: plans/0005-git-workflow-script.md`, and Step 1's first
commit flips this plan to `in-progress`. Steps 1 to 4 are test-first
and their cadence is observable: on each branch the commit adding
the tests precedes the commit adding the code, so
`git log --reverse --name-only <trunk>..<branch>` shows the test
file before the script.

The script is `skills/git-workflow/scripts/git-workflow`, Bash, with
subcommands `check`, `begin` and `land`, and host modules under
`skills/git-workflow/scripts/hosts/<name>`, each an executable with
two entry points, `propose <branch>` and `merge <branch>`, and a
third, `settings`, that reports whether the host allows squash or
rebase merges. The script depends on git and, where a host is
involved, on that host's command-line tool, and on nothing else. Its
tests are `skills/git-workflow/scripts/tests/run.sh` plus one file
per subcommand, each test building a temporary repository with plain
git and asserting on git state, the same facts the eval scenarios
score. Exit codes are part of the contract: 0 done; 1 stopped, with a
report, because a host command was missing, failed or refused; 2
usage or precondition failure; 3 stopped by design, because the
branch is a decision and a human merges it.

The script writes exactly one commit, and only when it has to: the
`.worktrees/` line it adds to `.gitignore` inside a new worktree,
committed there as bookkeeping, as Rule 5 requires. Every other
commit is the governing skill's.

### Step 1 — Contract and harness

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-contract`. Create the script with its
usage text only, exiting 2 on any subcommand; the usage text is the
docstring and names the three subcommands, their arguments, the host
module interface and the four exit codes. Create the test runner and
a helper that builds a fixture repository with a chosen trunk, an
optional bare-repository remote under a chosen name, optional dirt in
the working tree, and optional ignored directories with content. The
red phase of test-first is skipped for this step and said so in the
commit body: there is no behaviour yet to fail a test, and the
runner's own first test is "the usage text names all three
subcommands", which fails against an empty script.

Exit criteria:

- `bash skills/git-workflow/scripts/git-workflow --help` exits 0 and
  its output contains `check`, `begin`, `land`, `hosts/`, and the
  four exit codes.
- `bash skills/git-workflow/scripts/tests/run.sh` exits 0 and reports
  1 test.

### Step 2 — `check`: derive, do not act

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-check`. `check` prints, one per
line: `trunk=<ref>`, `remote=<name|none>`,
`host=<none|github|unknown:<url>>`,
`contention=<in-place|worktree>`. It exits 2 with a message naming
the three refs when no rung of the trunk ladder resolves, and exits 2
naming the candidates when there is more than one remote and none is
`origin`.

Tests in `scripts/tests/check.sh`, at least twelve, each failing
before the code and passing after:

- trunk: local `dev` wins over `develop` and `origin/HEAD`; `develop`
  wins over `origin/HEAD`; `origin/HEAD` alone resolves; none of the
  three → exit 2 and the message names `dev`, `develop` and
  `refs/remotes/origin/HEAD`. A `workflow.trunk` config key and a
  `CONTRIBUTING.md` naming `main` are present in every fixture and
  change nothing.
- remote and host: `git remote` prints nothing → `remote=none`,
  `host=none`; `origin` at a `github.com` URL, https and ssh forms →
  `github`; a sole remote not named `origin` → that remote, its host
  derived from its URL; two remotes with no `origin` → exit 2; any
  non-github URL → `unknown:<url>`.
- contention: on the derived trunk and clean → `in-place`; on trunk
  but dirty → `worktree`; clean but on another branch → `worktree`.

Exit criteria: `scripts/tests/check.sh` holds those tests; `run.sh`
exits 0 and reports at least 13 tests; the branch's commit adding
`check.sh` precedes the commit changing the script.

### Step 3 — `begin <artefact-path>`

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-begin`. `begin` derives the branch
name from the path (`docs/adr/NNNN-slug.md` → `adr-NNNN-slug`,
`plans/NNNN-slug.md` → `plan-NNNN-slug`,
`docs/discovery/NNNN-slug.md` → `discovery-NNNN-slug`,
`skills/<name>/SKILL.md` → `skill-<name>`, anything else →
`chore-<slug>` with `--slug` required), runs `check`, then either
branches in place or creates `.worktrees/<branch>` from the trunk,
copies `.claude/`, `.env` and `.mcp.json` into a worktree and never
`.venv/` or `node_modules/`, and, when the repository's `.gitignore`
lacks a `.worktrees/` line, adds it inside the worktree and commits
it there. It never stages, stashes, reverts or deletes anything in
the primary checkout. It prints `trunk=<ref>`, `branch=<name>` and
`dir=<path to work in>`, and refuses with exit 2 if the branch
already exists.

Tests in `scripts/tests/begin.sh`, at least fourteen:

- each naming rule, and the refusal without `--slug` for an
  ungoverned path;
- in-place branching when `check` says so, and the primary checkout
  then on the new branch;
- worktree creation when on another branch, forked from the trunk
  and not from HEAD, asserted by the worktree's first commit's
  parent and by a file that only the trunk carries;
- worktree creation when on the trunk but dirty, asserting no
  `checkout: moving from <trunk>` line is added to the primary
  reflog, and that the dirty files are still present, still
  unstaged and still untracked afterwards;
- the copied files present in the worktree and still present in the
  base checkout; `.venv/` and `node_modules/` present in the base
  checkout and absent from the worktree;
- the `.worktrees/` line committed inside the worktree when missing,
  and no commit made when the line already exists;
- the refusal when the branch exists.

Exit criteria: the tests exist; `run.sh` exits 0 and reports at
least 27 tests; test commit precedes code commit.

### Step 4 — `land`

> **Directive for the implementer**: this step will write or modify executable code. Load the `test-first-workflow` skill before writing the code (docstrings → failing tests → code).

Branch `code-git-workflow-script-land`. `land`, run from inside the
artefact's checkout, in order:

1. Refuses with exit 2 when: the current branch is the trunk; the
   working tree is dirty; the first commit since the fork point,
   `git rev-list --reverse <trunk>..HEAD | head -1`, carries no
   `Derives-From` trailer, read with
   `git log -1 --format='%(trailers:key=Derives-From,valueonly)'`;
   or that trailer's value is not repository-relative (starts with
   `/` or `./`).
2. Decides whether the branch is a decision: any commit since the
   fork point carries `Revises`, or `git diff --name-status
   <trunk>...HEAD` adds a file under `docs/adr/`. A decision is
   pushed and proposed through the host module's `propose`, then
   the script exits 3 with a report naming the pull request and
   saying a human merges it. With `host=none` a decision cannot be
   proposed anywhere: exit 3 with a report saying so, branch left in
   place.
3. Otherwise, by host. `none`: from the primary checkout with the
   trunk checked out — switching to it first when the work was in
   place — `git merge --no-ff <branch>`. `github` or any module:
   push, `propose`, then `merge`, both run from the primary checkout
   and never from inside a worktree; after the merge, on the trunk,
   `git fetch` and `git merge --ff-only <remote>/<trunk>` so the
   local trunk is current. `unknown`: push, exit 1 with a report.
   A missing host command, or one that fails or refuses: push if not
   yet pushed, exit 1 with a report giving the pull request URL if
   one was opened, the exact command that was missing or refused,
   the state left behind, and the permission hint
   `Bash(gh pr merge *)`.
4. On a merge only: `git worktree remove --force` where a worktree
   was used, `git branch -d <branch>`, and confirm the primary
   checkout is on the trunk by reading HEAD, not by checking it out.
   Where the work was in place the checkout was switched in step 3.

The `github` module: `propose` runs `gh pr create` with the branch;
`merge` runs `gh pr merge --merge --delete-branch`, never a squash or
rebase; `settings` reads the repository's squash and rebase
allowances through the host API and prints them, so `land` can
report, before merging, that the host would allow what ADR 0003
forbids. Reporting, not changing: settings need an administrator.

Tests in `scripts/tests/land.sh`, at least twenty, with a bare
repository as `origin` and a stub `gh` placed first on `PATH` by the
test itself, the stub recording every invocation's arguments to a
file:

- the four refusals: on trunk, dirty tree, no trailer, trailer with
  a leading `./` or `/`;
- the decision case for a `docs/adr/` file and for a `Revises`
  commit: branch pushed to origin at the same SHA, `propose`
  called, `merge` never called, no merge on the trunk locally or on
  origin, exit 3; and the no-remote decision → exit 3, branch
  present, trunk untouched;
- the no-remote merge, in place: primary checkout ends on the trunk,
  trunk tip has two parents, branch deleted, `git remote` still
  prints nothing and `refs/remotes/` is still empty, and dirt that
  was in the primary checkout before is still present, unstaged and
  untracked;
- the no-remote merge from a worktree: the same, plus the worktree
  removed even with an untracked `.venv/` inside it, and the primary
  checkout's HEAD reflog gaining no `checkout:` line;
- the github merge: `merge` called with `--merge` and without
  `--squash` or `--rebase`, both from the primary checkout; local
  trunk equals `origin/<trunk>` afterwards; cleanup as above;
- the stub refusing `merge`, `gh` absent from `PATH`, and an unknown
  host: in each, branch pushed at the same SHA as local, the local
  branch still exists, the worktree still exists, the primary
  checkout's HEAD unchanged, origin's trunk tip unchanged, exit 1,
  and the report text contains the command name and the permission
  hint;
- `settings` reporting an allowed squash from a stub that says so.

Every `FAILS IF` in `evals/git-workflow-0/criteria.json` and
`evals/git-workflow-1/criteria.json` maps to one of the tests above;
the mapping is a comment at the top of `land.sh`. As bookkeeping on
this branch, `evals/git-workflow-1/criteria.json`'s context text,
which still describes a stub `gh` the fixture no longer installs, is
brought into line with `setup.sh` and `scenario.json`.

Exit criteria: the tests exist with the mapping comment; `run.sh`
exits 0 and reports at least 47 tests; test commit precedes code
commit; `grep -c 'stub' evals/git-workflow-1/criteria.json` prints
0.

### Step 5 — The skill body names the moments

Branch `chore-git-workflow-body`, forked from a `dev` that carries
pull request 33 and Step 4. Rewrite `skills/git-workflow/SKILL.md`
to: how the script is found — the harness states the skill's base
directory when it loads the skill, and the command is
`bash <that directory>/scripts/git-workflow …`; when to run `begin
<path>` (before the first edit) and `land` (when the governing skill
says the artefact is complete); what the model still decides, kept
in the body as rules and not commentary: the artefact table and its
delegation (Rules 2 and 3), the bookkeeping truth-condition test
(Rule 4), the `Derives-From` upstream question and the trailer
vocabulary (Rule 9), never removing another's branch or worktree
(Rule 13), the deviations list, and what each exit code means for
the model's reply, including the full stop report. The rules the
script enforces are removed as instructions; their rationale moves
to `references/RULES.md`, which the package includes and the model
loads on demand. The `description` does not change. `compatibility`
names Bash, git and the host CLI. The release skill's sentence that
every branch follows git-workflow gains the clause that a release
branch lands with the release skill's own commands because a version
bump carries no trailer, as bookkeeping on this branch.

Exit criteria:

- `git diff origin/dev -- skills/git-workflow/SKILL.md | grep -c '^[-+]description:'` prints 0.
- `grep -cE 'git worktree add|git merge --no-ff|git rev-parse --verify|git branch --list' skills/git-workflow/SKILL.md` prints 0.
- `grep -c 'scripts/git-workflow' skills/git-workflow/SKILL.md` is at least 2 and `references/RULES.md` exists.
- `tessl plugin lint .` prints no token warning for git-workflow.
- `tessl review run skills/git-workflow` prints a review score of at
  least 85.

### Step 6 — Measure, after 2026-09-28

Branch `chore-git-workflow-script-measure`, forked after Step 5 has
merged, progress notes only.

1. One repeat of `evals/git-workflow-1` on deepseek first, about 10
   credits, and read the scorer's reasoning: if it says the script
   was not found, stop, fix how Step 5 says the path resolves, and
   return here. This is the only check that the eval sandbox carries
   `scripts/` at all.
2. Then `evals/git-workflow-0` and `evals/git-workflow-1` with
   `--context . -n 3 --skip-baseline --agent claude --model deepseek-v4-flash`,
   forced context activation left on, as the before runs had it.
   About 60 credits. The before is recorded: `git-workflow-1` 18, 0,
   0, median 0 (run `01a0ce24-dd76-729a-ab72-dd5ac616799d`);
   `git-workflow-0` 95, 97, 97, median 97 (run
   `01a0cdf9-fa57-7713-92ef-f84fb85da0c4`). The strong-model record
   is the `v0.1.1` tag's table: `git-workflow-1` median 96,
   `git-workflow-0` median 68 with the whole plugin injected.
3. For every repeat, record its score, its `activatedSkills`, and
   one line of the scorer's reasoning for any criterion under full
   marks, regardless of score.

Exit criteria, each capable of failing:

- `git-workflow-1`'s median on deepseek is at least 86: the strong
  model's recorded median, 96, less the release gate's threshold.
- `git-workflow-0`'s median on deepseek is at least 87: its own
  before, 97, less the threshold.
- No recorded reasoning line, on any repeat, describes a local merge
  where a remote exists, a fast-forward, a squash, or a worktree
  removed without a merge. Whatever remains is the script not being
  run.
- The run ids, the per-repeat table and the three facts above are in
  Progress notes.

### Step 7 — Decide the floor, then complete

On Step 6's branch. In either case `compatibility` on git-workflow is
rewritten to cite Step 6's run ids and medians. If both medians met
their bars: remove `model: sonnet`, and change the release skill's
gate pin to `deepseek-v4-flash`, whose record resets on that change.
If either failed: keep `model: sonnet` and say in `compatibility`
which scenario fell short and by how much. Then delete this plan as
the final commit with the `Completes:` trailer and a body saying
what the plan produced and which way the floor went.

## Verification

After Step 7, from a fresh clone of `dev` with `tessl` logged in:

1. `bash skills/git-workflow/scripts/tests/run.sh` exits 0 and
   reports at least 47 tests.
2. `tessl plugin pack --output /tmp/m.tgz && tar tzf /tmp/m.tgz`
   lists `skills/git-workflow/scripts/git-workflow`,
   `skills/git-workflow/scripts/hosts/github` and
   `skills/git-workflow/references/RULES.md`.
3. For each first-parent merge `M` on `dev` after this plan's own
   merge whose subject names a step branch of this plan,
   `git log -1 --format='%(trailers:key=Derives-From,valueonly)' $(git rev-list --reverse M^1..M^2 | head -1)`
   prints `plans/0005-git-workflow-script.md`.
4. The Step 6 run ids open with `tessl eval view` and show the
   medians the deleting commit's body records.
5. `compatibility` on git-workflow cites those run ids, and either
   `model:` is absent and the release skill pins deepseek, or
   `model: sonnet` remains and `compatibility` names the shortfall.

Not verified by this plan: whether a model invokes the script at the
right moment. Step 6's third criterion measures what remains once
the mechanics are code, and that number goes to the landing-gate
work rather than being closed here.

## Progress notes

- 2026-09-23 — Written the same evening as the ADR revisions it
  implements, by the same author. An independent review against the
  ADR ran before the pull request opened and found: `land` had no
  in-place path (Rule 14 and the ADR's Cleanup both require the
  primary checkout to return to trunk); the Step 6 bars were taken
  from minimum repeats rather than medians, both leniently; host
  derivation read only `origin`, so a sole `upstream` would have
  taken the local merge the ADR reserves for no remote; the
  `.worktrees/` line was staged but not committed against Rule 5;
  twelve FAILS IF conditions across the two scenarios had no shell
  test; nothing said how the model finds the script; the host module
  seam, the squash-setting check, `--force` on worktree removal, the
  stale local trunk after a host merge, the stop report's full
  contents, and which judgement rules stay in the body were all
  unstated; and Verification 3 was not runnable once branches are
  deleted. All fixed in the revision that followed. Left as found:
  forced context activation stays on in Step 6 for comparability,
  so `activatedSkills` there measures forced loading, and the
  trigger question stays with the landing-gate work.
- Judgement calls at authoring:
  - Steps 1 to 4 are `code-` branches under `test-first-workflow`:
    Rule 7 gives `code` for a working code change. Step 5 is a body
    edit with the description unchanged, so `skill-forge` does not
    govern it and it takes `chore`.
  - The script writes one commit, the `.worktrees/` gitignore line
    inside a new worktree, because Rule 5 says to commit it there;
    it is bookkeeping with nothing else to ride on at that moment.
    Everything else the script leaves to whoever commits.
  - `begin` does not take the upstream path. The `Derives-From`
    trailer stays with whoever commits, and `land` checks that it is
    there.
